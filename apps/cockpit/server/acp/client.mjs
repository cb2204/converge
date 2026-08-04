import { spawn as nodeSpawn } from "node:child_process";
import path from "node:path";
import { Readable, Writable } from "node:stream";

import {
  PROTOCOL_VERSION,
  client as createClientApp,
  methods,
  ndJsonStream,
} from "@agentclientprotocol/sdk";

import { redactSensitiveText } from "../security.mjs";
import { truncateUtf8 } from "../ask-contract.mjs";

const SAFE_TOOL_KINDS = new Set(["read", "search", "think"]);
const EVENT_TEXT_LIMIT = 8 * 1024;

export class AcpClientError extends Error {
  constructor(code, { cause } = {}) {
    super(code, { cause });
    this.name = "AcpClientError";
    this.code = code;
  }
}

function safeText(value, maxBytes = EVENT_TEXT_LIMIT) {
  return truncateUtf8(redactSensitiveText(value ?? ""), maxBytes);
}

function relativeLocation(projectRoot, location) {
  if (!location || typeof location.path !== "string") return null;
  const relative = path.relative(projectRoot, location.path);
  if (
    relative.length === 0 ||
    relative === ".." ||
    relative.startsWith(`..${path.sep}`) ||
    path.isAbsolute(relative)
  ) {
    return null;
  }
  return Object.freeze({
    path: relative.split(path.sep).join("/"),
    line: Number.isInteger(location.line) && location.line > 0
      ? location.line
      : null,
  });
}

function normalizeTool(update, projectRoot, knownKinds) {
  const previousKind = knownKinds.get(update.toolCallId);
  const kind = typeof update.kind === "string" ? update.kind : previousKind ?? "other";
  knownKinds.set(update.toolCallId, kind);
  return Object.freeze({
    toolCallId: safeText(update.toolCallId, 256),
    title: safeText(update.title ?? "Agent tool", 512),
    kind,
    status: update.status ?? "pending",
    locations: Object.freeze(
      (Array.isArray(update.locations) ? update.locations : [])
        .map((location) => relativeLocation(projectRoot, location))
        .filter(Boolean)
        .slice(0, 12),
    ),
  });
}

export function normalizeSessionUpdate(update, projectRoot, knownKinds = new Map()) {
  if (!update || typeof update.sessionUpdate !== "string") return null;
  if (update.sessionUpdate === "agent_message_chunk") {
    if (update.content?.type !== "text") return null;
    return Object.freeze({
      type: "assistant.delta",
      payload: Object.freeze({ text: safeText(update.content.text) }),
    });
  }
  if (update.sessionUpdate === "agent_thought_chunk") {
    return Object.freeze({ type: "agent.thinking", payload: Object.freeze({}) });
  }
  if (
    update.sessionUpdate === "tool_call" ||
    update.sessionUpdate === "tool_call_update"
  ) {
    const tool = normalizeTool(update, projectRoot, knownKinds);
    const completed = tool.status === "completed" || tool.status === "failed";
    return Object.freeze({
      type: update.sessionUpdate === "tool_call"
        ? "tool.started"
        : completed
          ? "tool.completed"
          : "tool.updated",
      payload: tool,
    });
  }
  if (update.sessionUpdate === "plan") {
    return Object.freeze({
      type: "plan.updated",
      payload: Object.freeze({
        entries: Object.freeze(
          (Array.isArray(update.entries) ? update.entries : []).slice(0, 50).map((entry) =>
            Object.freeze({
              content: safeText(entry.content, 1024),
              priority: entry.priority,
              status: entry.status,
            })),
        ),
      }),
    });
  }
  return null;
}

function sanitizeAuthMethods(authMethods) {
  if (!Array.isArray(authMethods)) return Object.freeze([]);
  return Object.freeze(
    authMethods
      .filter((method) => !method.type || method.type === "agent")
      .filter((method) => typeof method.id === "string" && typeof method.name === "string")
      .map((method) => Object.freeze({
        id: safeText(method.id, 160),
        name: safeText(method.name, 160),
        description: method.description ? safeText(method.description, 512) : null,
        type: "agent",
      })),
  );
}

function sanitizeCapabilities(capabilities = {}) {
  return Object.freeze({
    loadSession: capabilities.loadSession === true,
    prompt: Object.freeze({
      image: capabilities.promptCapabilities?.image === true,
      audio: capabilities.promptCapabilities?.audio === true,
      embeddedContext: capabilities.promptCapabilities?.embeddedContext === true,
    }),
    session: Object.freeze({
      close: capabilities.sessionCapabilities?.close != null,
      delete: capabilities.sessionCapabilities?.delete != null,
      resume: capabilities.sessionCapabilities?.resume != null,
    }),
  });
}

function chooseRejection(options) {
  const rejection = Array.isArray(options)
    ? options.find((option) => option.kind === "reject_always") ??
      options.find((option) => option.kind === "reject_once")
    : null;
  return rejection
    ? { outcome: { outcome: "selected", optionId: rejection.optionId } }
    : { outcome: { outcome: "cancelled" } };
}

function terminateChild(child, detached, signal) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  try {
    if (detached && Number.isInteger(child.pid) && child.pid > 0) {
      process.kill(-child.pid, signal);
    } else {
      child.kill(signal);
    }
  } catch {
    try {
      child.kill(signal);
    } catch {
      // The process already exited.
    }
  }
}

export class AcpClient {
  constructor({
    adapter,
    onEvent = () => true,
    spawnImpl = nodeSpawn,
    initializeTimeoutMs = 15_000,
    turnTimeoutMs = 120_000,
    maxStderrBytes = 8 * 1024,
  }) {
    if (!adapter?.executable || !adapter?.cwd || !Array.isArray(adapter.args)) {
      throw new TypeError("AcpClient requires a resolved adapter configuration");
    }
    this.adapter = adapter;
    this.onEvent = onEvent;
    this.spawnImpl = spawnImpl;
    this.initializeTimeoutMs = initializeTimeoutMs;
    this.turnTimeoutMs = turnTimeoutMs;
    this.maxStderrBytes = maxStderrBytes;
    this.child = null;
    this.childOutcome = null;
    this.childExited = false;
    this.connection = null;
    this.agent = null;
    this.acpSessionId = null;
    this.initializeResult = null;
    this.authMethods = Object.freeze([]);
    this.capabilities = sanitizeCapabilities();
    this.knownToolKinds = new Map();
    this.outputRejected = false;
    this.unsafeToolObserved = false;
    this.safeModeEstablished = false;
    this.remoteSessionDeleted = false;
    this.closing = false;
    this.stderr = "";
  }

  async connect() {
    if (this.connection) throw new AcpClientError("ACP_ALREADY_CONNECTED");
    const detached = process.platform !== "win32";
    let child;
    try {
      child = this.spawnImpl(this.adapter.executable, [...this.adapter.args], {
        cwd: this.adapter.cwd,
        env: { ...this.adapter.environment },
        stdio: ["pipe", "pipe", "pipe"],
        shell: false,
        windowsHide: true,
        detached,
      });
    } catch (error) {
      throw new AcpClientError("ACP_ADAPTER_UNAVAILABLE", { cause: error });
    }
    if (!child?.stdin || !child?.stdout || !child?.stderr) {
      throw new AcpClientError("ACP_ADAPTER_UNAVAILABLE");
    }
    this.child = child;
    this.detached = detached;
    this.childOutcome = new Promise((resolve) => {
      child.once("error", (error) => {
        this.childExited = true;
        resolve({ type: "error", error });
      });
      child.once("exit", (code, signal) => {
        this.childExited = true;
        resolve({ type: "exit", code, signal });
      });
    });
    child.stderr.on("data", (chunk) => {
      if (Buffer.byteLength(this.stderr, "utf8") >= this.maxStderrBytes) return;
      this.stderr = truncateUtf8(
        `${this.stderr}${redactSensitiveText(chunk.toString("utf8"))}`,
        this.maxStderrBytes,
      );
    });

    const app = createClientApp({ name: "converge-cockpit" })
      .onRequest(methods.client.session.requestPermission, async ({ params }) => {
        await this.#emit({
          type: "permission.denied",
          payload: Object.freeze({
            toolCallId: safeText(params.toolCall?.toolCallId, 256),
            title: safeText(params.toolCall?.title ?? "Agent tool", 512),
            kind: params.toolCall?.kind ?? "other",
          }),
        });
        return chooseRejection(params.options);
      })
      .onNotification(methods.client.session.update, async ({ params }) => {
        if (this.acpSessionId && params.sessionId !== this.acpSessionId) return;
        const event = normalizeSessionUpdate(
          params.update,
          this.adapter.cwd,
          this.knownToolKinds,
        );
        if (!event) return;
        const kind = event.type.startsWith("tool.") ? event.payload.kind : null;
        if (kind && !SAFE_TOOL_KINDS.has(kind)) {
          this.unsafeToolObserved = true;
        }
        await this.#emit(event);
      });

    const output = Writable.toWeb(child.stdin);
    const input = Readable.toWeb(child.stdout);
    this.connection = app.connect(ndJsonStream(output, input));
    this.agent = this.connection.agent;
    try {
      const result = await this.#requestWithDeadline(
        this.agent.request(methods.agent.initialize, {
          protocolVersion: PROTOCOL_VERSION,
          clientCapabilities: {},
          clientInfo: {
            name: "converge-cockpit",
            title: "Converge Cockpit",
            version: "1.0.0",
          },
        }),
        this.initializeTimeoutMs,
      );
      if (result.protocolVersion !== PROTOCOL_VERSION) {
        throw new AcpClientError("ACP_PROTOCOL_MISMATCH");
      }
      this.initializeResult = result;
      this.authMethods = sanitizeAuthMethods(result.authMethods);
      this.capabilities = sanitizeCapabilities(result.agentCapabilities);
      return Object.freeze({
        protocolVersion: result.protocolVersion,
        agentInfo: result.agentInfo
          ? Object.freeze({
              name: safeText(result.agentInfo.name, 160),
              title: result.agentInfo.title ? safeText(result.agentInfo.title, 160) : null,
              version: safeText(result.agentInfo.version, 80),
            })
          : null,
        authMethods: this.authMethods,
        capabilities: this.capabilities,
      });
    } catch (error) {
      await this.close();
      if (error instanceof AcpClientError) throw error;
      throw new AcpClientError("ACP_INITIALIZE_FAILED", { cause: error });
    }
  }

  async authenticate(methodId) {
    if (!this.agent || this.acpSessionId) {
      throw new AcpClientError("ACP_AUTH_UNAVAILABLE");
    }
    if (!this.authMethods.some((method) => method.id === methodId)) {
      throw new AcpClientError("ACP_AUTH_UNSUPPORTED");
    }
    await this.#requestWithDeadline(
      this.agent.request(methods.agent.authenticate, { methodId }),
      this.initializeTimeoutMs,
    );
  }

  async createSession() {
    if (!this.agent || this.acpSessionId) {
      throw new AcpClientError("ACP_SESSION_STATE_INVALID");
    }
    const response = await this.#requestWithDeadline(
      this.agent.request(methods.agent.session.new, {
        cwd: this.adapter.cwd,
        mcpServers: [],
        ...(this.adapter.disableBuiltInTools
          ? {
              _meta: {
                disableBuiltInTools: true,
                claudeCode: {
                  options: {
                    tools: [],
                    settingSources: [],
                    mcpServers: {},
                  },
                },
              },
            }
          : {}),
      }),
      this.initializeTimeoutMs,
    );
    if (typeof response.sessionId !== "string" || response.sessionId.length === 0) {
      throw new AcpClientError("ACP_SESSION_INVALID");
    }
    this.acpSessionId = response.sessionId;
    let modes = response.modes ?? null;
    if (this.adapter.requiredMode) {
      const availableModes = Array.isArray(modes?.availableModes)
        ? modes.availableModes
        : [];
      if (!availableModes.some((mode) => mode?.id === this.adapter.requiredMode)) {
        throw new AcpClientError("ACP_SAFE_MODE_UNAVAILABLE");
      }
      if (modes?.currentModeId !== this.adapter.requiredMode) {
        await this.#requestWithDeadline(
          this.agent.request(methods.agent.session.setMode, {
            sessionId: response.sessionId,
            modeId: this.adapter.requiredMode,
          }),
          this.initializeTimeoutMs,
        );
      }
      modes = Object.freeze({
        ...modes,
        currentModeId: this.adapter.requiredMode,
        availableModes: Object.freeze([...availableModes]),
      });
      this.safeModeEstablished = true;
    } else {
      this.safeModeEstablished = this.adapter.disableBuiltInTools === true;
    }
    return Object.freeze({
      sessionId: response.sessionId,
      modes,
    });
  }

  async prompt(text) {
    if (!this.agent || !this.acpSessionId) {
      throw new AcpClientError("ACP_SESSION_STATE_INVALID");
    }
    if (!this.safeModeEstablished) {
      throw new AcpClientError("ACP_SAFE_MODE_UNAVAILABLE");
    }
    this.outputRejected = false;
    this.unsafeToolObserved = false;
    const response = await this.#requestWithDeadline(
      this.agent.request(methods.agent.session.prompt, {
        sessionId: this.acpSessionId,
        prompt: [{ type: "text", text }],
      }),
      this.turnTimeoutMs,
    );
    if (this.outputRejected) throw new AcpClientError("ACP_OUTPUT_LIMIT");
    if (this.unsafeToolObserved) throw new AcpClientError("ACP_UNSAFE_TOOL");
    return Object.freeze({ stopReason: response.stopReason });
  }

  async cancel() {
    if (!this.agent || !this.acpSessionId) return false;
    try {
      await this.agent.notify(methods.agent.session.cancel, {
        sessionId: this.acpSessionId,
      });
      return true;
    } catch {
      return false;
    }
  }

  async close() {
    if (this.closing) return;
    this.closing = true;
    if (
      this.agent &&
      this.acpSessionId &&
      this.capabilities.session.delete
    ) {
      try {
        await this.#requestWithDeadline(
          this.agent.request(methods.agent.session.delete, {
            sessionId: this.acpSessionId,
          }),
          Math.min(this.initializeTimeoutMs, 2_000),
        );
        this.remoteSessionDeleted = true;
      } catch {
        // Provider deletion is best effort; process cleanup still runs.
      }
    } else if (
      this.agent &&
      this.acpSessionId &&
      this.capabilities.session.close
    ) {
      try {
        await this.#requestWithDeadline(
          this.agent.request(methods.agent.session.close, {
            sessionId: this.acpSessionId,
          }),
          Math.min(this.initializeTimeoutMs, 2_000),
        );
      } catch {
        // Continue process cleanup if the optional close method fails.
      }
    }
    this.acpSessionId = null;
    try {
      this.connection?.close();
    } catch {
      // Continue process cleanup when the protocol connection is already gone.
    }
    if (!this.child || this.childExited) return;
    terminateChild(this.child, this.detached, "SIGTERM");
    await Promise.race([
      this.childOutcome,
      new Promise((resolve) => setTimeout(resolve, 400)),
    ]);
    if (!this.childExited) terminateChild(this.child, this.detached, "SIGKILL");
  }

  async #emit(event) {
    let accepted = true;
    try {
      accepted = (await this.onEvent(event)) !== false;
    } catch {
      accepted = false;
    }
    if (!accepted) this.outputRejected = true;
    if (!accepted || this.unsafeToolObserved) await this.cancel();
  }

  async #requestWithDeadline(request, timeoutMs) {
    let timer;
    const timeout = new Promise((_, reject) => {
      timer = setTimeout(
        () => reject(new AcpClientError("ACP_TIMEOUT")),
        timeoutMs,
      );
      timer.unref?.();
    });
    const childFailure = this.childOutcome.then((outcome) => {
      if (this.closing) return new Promise(() => {});
      throw new AcpClientError(
        outcome.type === "error" ? "ACP_ADAPTER_UNAVAILABLE" : "ACP_ADAPTER_EXITED",
        { cause: outcome.error },
      );
    });
    try {
      return await Promise.race([request, timeout, childFailure]);
    } catch (error) {
      // ACP reserves -32000 for authentication-required failures. Normalize it
      // here so callers never lose the actionable cause behind a generic
      // provider failure.
      if (error?.code === -32_000) {
        throw new AcpClientError("ACP_AUTH_REQUIRED", { cause: error });
      }
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }
}

export { SAFE_TOOL_KINDS, chooseRejection };
