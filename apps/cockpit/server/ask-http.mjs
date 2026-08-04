import {
  AskError,
  parseAskTurnRequest,
  parseCreateAskSessionRequest,
} from "./ask-contract.mjs";
import { redactSensitiveText } from "./security.mjs";

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseAskOnceRequest(value) {
  if (
    !isRecord(value) ||
    Object.keys(value).some(
      (key) => !["agentId", "snapshotId", "text", "context", "history"].includes(key),
    )
  ) {
    throw new AskError("ASK_INVALID_REQUEST");
  }
  const session = parseCreateAskSessionRequest({
    agentId: value.agentId,
    snapshotId: value.snapshotId,
    context: value.context,
  });
  const turn = parseAskTurnRequest({
    snapshotId: value.snapshotId,
    text: value.text,
    history: value.history,
  });
  return Object.freeze({
    agentId: session.agentId,
    snapshotId: session.snapshotId,
    text: turn.text,
    context: session.context,
    history: turn.history,
  });
}

function normalizeAgent(agent) {
  return {
    id: agent.id,
    label: agent.label,
    adapter:
      agent.id === "codex"
        ? "codex-acp"
        : agent.id === "claude"
          ? "claude-agent-acp"
          : agent.id,
    availability:
      ["available", "blocked"].includes(agent.availability)
        ? agent.availability
        : "unavailable",
    reason: agent.reason ?? null,
  };
}

export async function askCapabilitiesDocument(askService, requestToken) {
  const registry = await askService.listAgents();
  return {
    agents: registry.agents.map(normalizeAgent),
    requestToken,
    policy: {
      transport: "ACP",
      workspaceAccess: "enforced-safe-mode",
      persistence: "cockpit-ephemeral",
      evidenceBoundary:
        "Agent interpretation is not a Converge gate verdict, receipt, or proof.",
    },
  };
}

function activityFromEvents(events) {
  const activities = new Map();
  let thinking = 0;

  for (const event of events) {
    if (event.type === "agent.thinking") {
      thinking += 1;
      activities.set("thinking", {
        id: "thinking",
        kind: "think",
        label: "Reasoned over snapshot-bound context",
        status: "complete",
        detail: thinking > 1 ? `${thinking} bounded reasoning updates` : undefined,
      });
      continue;
    }
    if (event.type === "permission.denied") {
      const id = `permission:${event.sequence}`;
      activities.set(id, {
        id,
        kind: "permission",
        label: event.payload?.title ?? "Agent permission",
        status: "denied",
        detail: `${event.payload?.kind ?? "unknown"} permission denied`,
      });
      continue;
    }
    if (event.type.startsWith("tool.")) {
      const toolId = event.payload?.toolCallId ?? `tool:${event.sequence}`;
      const kind = ["read", "search", "think"].includes(event.payload?.kind)
        ? event.payload.kind
        : "status";
      activities.set(toolId, {
        id: toolId,
        kind,
        label: event.payload?.title ?? "Agent tool",
        status:
          event.type === "tool.completed"
            ? event.payload?.status === "failed"
              ? "denied"
              : "complete"
            : event.type === "tool.started"
              ? "active"
              : "pending",
        detail: Array.isArray(event.payload?.locations)
          ? event.payload.locations
              .map((location) =>
                location.line ? `${location.path}:${location.line}` : location.path,
              )
              .join(", ")
          : undefined,
      });
    }
  }
  return [...activities.values()];
}

function stepsFromEvents(events) {
  const steps = [];
  for (const event of events) {
    if (event.type !== "plan.updated" || !Array.isArray(event.payload?.entries)) {
      continue;
    }
    for (const entry of event.payload.entries) {
      const content = redactSensitiveText(entry?.content ?? "").trim();
      if (content && !steps.includes(content)) steps.push(content);
    }
  }
  return steps.slice(0, 24);
}

export async function runAskOnce(
  askService,
  candidate,
  { now = () => Date.now(), signal = null } = {},
) {
  const request = parseAskOnceRequest(candidate);
  const startedAt = now();
  let sessionId = null;
  let turnId = null;
  let grounding = null;
  let rejectWaitOnAbort = null;
  const cancelActiveTurn = () => {
    if (sessionId && turnId) {
      void askService.cancelTurn(sessionId, turnId).catch(() => {});
    }
  };
  signal?.addEventListener("abort", cancelActiveTurn, { once: true });

  try {
    if (signal?.aborted) throw new AskError("ASK_CANCELLED");
    const created = await askService.createSession({
      agentId: request.agentId,
      snapshotId: request.snapshotId,
      context: request.context,
    });
    sessionId = created.session.id;
    grounding = created.session.grounding;
    if (signal?.aborted) throw new AskError("ASK_CANCELLED");
    const turn = await askService.startTurn(sessionId, {
      text: request.text,
      snapshotId: request.snapshotId,
      history: request.history,
    });
    turnId = turn.turnId;
    if (signal?.aborted) {
      cancelActiveTurn();
      throw new AskError("ASK_CANCELLED");
    }
    const waitForTurn = askService.waitForTurn(sessionId);
    if (signal) {
      const aborted = new Promise((_, reject) => {
        rejectWaitOnAbort = () => reject(new AskError("ASK_CANCELLED"));
        signal.addEventListener("abort", rejectWaitOnAbort, { once: true });
      });
      await Promise.race([waitForTurn, aborted]);
    } else {
      await waitForTurn;
    }
    const eventDocument = askService.getEvents(sessionId);
    const failure = eventDocument.events.find(
      (event) => event.type === "turn.failed",
    );
    if (failure) {
      throw new AskError(failure.payload?.code ?? "ASK_AGENT_FAILED");
    }
    const completed = eventDocument.events.findLast(
      (event) => event.type === "turn.completed",
    );
    const answer = eventDocument.events
      .filter((event) => event.type === "assistant.delta")
      .map((event) => redactSensitiveText(event.payload?.text ?? ""))
      .join("");

    return {
      turnId: turn.turnId,
      agentId: request.agentId,
      snapshotId: request.snapshotId,
      grounding,
      answer,
      steps: stepsFromEvents(eventDocument.events),
      activity: activityFromEvents(eventDocument.events),
      stopReason: completed?.payload?.stopReason ?? "unknown",
      elapsedMs: Math.max(0, now() - startedAt),
    };
  } finally {
    signal?.removeEventListener("abort", cancelActiveTurn);
    if (rejectWaitOnAbort) {
      signal?.removeEventListener("abort", rejectWaitOnAbort);
    }
    if (sessionId) {
      try {
        await askService.deleteSession(sessionId);
      } catch {
        // The one-shot response is detached from ephemeral cleanup.
      }
    }
  }
}
