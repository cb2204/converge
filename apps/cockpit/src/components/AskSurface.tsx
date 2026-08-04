import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import {
  ArrowRight,
  ArrowUp,
  Check,
  CircleNotch,
  CloudSlash,
  LockKey,
  MagnifyingGlass,
  Plus,
  ShieldCheck,
  Stop,
  WarningCircle,
  X,
} from "@phosphor-icons/react";
import claudeIconUrl from "@lobehub/icons-static-svg/icons/claude-color.svg?url&no-inline";
import codexIconUrl from "@lobehub/icons-static-svg/icons/codex-color.svg?url&no-inline";
import Markdown, { type Components } from "react-markdown";
import remarkGfm from "remark-gfm";
import type {
  AskAgent,
  AskCapabilities,
  AskTurnResponse,
} from "../ask/types";
import { resolveEntity } from "../lib/entities";
import type { EntityRef, WorkspaceSnapshot } from "../types";

interface AskSurfaceProps {
  snapshot: WorkspaceSnapshot;
  selected: EntityRef | null;
}

interface ConversationTurn {
  id: string;
  agentId: AskAgent["id"];
  question: string;
  scope: EntityRef | null;
  state: "pending" | "complete" | "error" | "cancelled";
  response: AskTurnResponse | null;
  error: AskFailure | null;
}

interface AskFailure {
  code: string;
  message: string;
  retryable: boolean;
}

class AskRequestError extends Error {
  code: string;
  retryable: boolean;

  constructor(failure: AskFailure) {
    super(failure.message);
    this.name = "AskRequestError";
    this.code = failure.code;
    this.retryable = failure.retryable;
  }
}

function safeAssistantLink(href: string | undefined) {
  if (!href) return null;
  if (href.startsWith("#")) return href;
  try {
    const parsed = new URL(href);
    return ["https:", "http:", "mailto:"].includes(parsed.protocol)
      ? href
      : null;
  } catch {
    return null;
  }
}

const askMarkdownComponents: Components = {
  a({ node: _node, href, children, ...props }) {
    const safeHref = safeAssistantLink(href);
    if (!safeHref) return <span className="ask-answer__unsafe-link">{children}</span>;
    const external = !safeHref.startsWith("#");
    return (
      <a
        {...props}
        href={safeHref}
        {...(external ? { target: "_blank", rel: "noreferrer noopener" } : {})}
      >
        {children}
      </a>
    );
  },
  img({ node: _node, alt }) {
    return (
      <span className="ask-answer__omitted-media" role="note">
        {alt ? `Image omitted: ${alt}` : "Image omitted from the answer"}
      </span>
    );
  },
  pre({ node: _node, children, ...props }) {
    return <pre {...props} tabIndex={0}>{children}</pre>;
  },
  table({ node: _node, children, ...props }) {
    return (
      <div className="ask-answer__table" role="region" aria-label="Scrollable answer table" tabIndex={0}>
        <table {...props}>{children}</table>
      </div>
    );
  },
};

export function suggestionsFor(
  snapshot: WorkspaceSnapshot,
  requestedEntity: EntityRef | null,
) {
  const activePass = snapshot.method.passes.find(
    (pass) => pass.id === snapshot.method.activePassId,
  );
  const activeLabel = activePass
    ? `Pass ${activePass.order}: ${activePass.label}`
    : "the current Converge frontier";
  const stateQuestion = activePass && snapshot.authorization.state === "blocked"
    ? `Why is this project blocked at ${activeLabel}, and what exact evidence or owner decision would authorize the next pass?`
    : !activePass && snapshot.authorization.state === "complete"
      ? "The Converge lane is complete, but is delivery complete? Explain the remaining work, execution, receipts, and unresolved evidence."
      : `Why is ${activeLabel} ${activePass?.status ?? "current"}, what evidence supports that state, and what should happen next?`;
  const riskQuestion = snapshot.review?.unresolvedCount
    ? `Which of the ${snapshot.review.unresolvedCount} unresolved review decisions carries the most downstream risk, and what does it block?`
    : snapshot.issues.length > 0
      ? `Which observed project issue matters most right now, what does it block, and how can the team verify the recovery?`
      : snapshot.work.frontier.taskIds.length > 0
        ? `Which task is genuinely dispatchable now, what does it depend on, and what proof will show it is done?`
        : "What changed most recently, and what should the team verify before continuing?";
  const projectSuggestions = [
    { label: "State and authority", question: stateQuestion },
    {
      label: "End-to-end trace",
      question:
        "Trace this project from intent through seams, tasks, execution, and proof. Where is the weakest link?",
    },
    { label: "Risk and evidence", question: riskQuestion },
  ];
  if (!requestedEntity) return projectSuggestions;
  const entity = resolveEntity(snapshot, requestedEntity);
  const title = entity?.title ?? `${requestedEntity.kind}:${requestedEntity.id}`;
  return [
    {
      label: "Selected context",
      question: `Explain ${title}: why it exists, what it depends on, what it produced, and what remains unresolved.`,
    },
    ...projectSuggestions.slice(0, 2),
  ];
}

const EMPTY_CAPABILITIES: AskCapabilities = {
  agents: [
    {
      id: "codex",
      label: "Codex",
      adapter: "codex-acp",
      availability: "not_configured",
      reason: "The Codex ACP adapter has not been configured.",
    },
    {
      id: "claude",
      label: "Claude Agent",
      adapter: "claude-agent-acp",
      availability: "not_configured",
      reason: "The Claude Agent ACP adapter has not been configured.",
    },
  ],
  requestToken: "",
  policy: {
    transport: "ACP",
    workspaceAccess: "enforced-safe-mode",
    persistence: "cockpit-ephemeral",
    evidenceBoundary:
      "Agent interpretation is not a Converge gate verdict, receipt, or proof.",
  },
};

function AgentIcon({ id }: { id: AskAgent["id"] }) {
  const label = id === "codex" ? "Codex" : "Claude Agent";
  return (
    <span className={`ask-agent-icon ask-agent-icon--${id}`} aria-hidden="true">
      <img
        src={id === "codex" ? codexIconUrl : claudeIconUrl}
        alt=""
        aria-hidden="true"
        draggable={false}
        data-provider-mark={id}
        title={label}
      />
    </span>
  );
}

function agentReady(agent: AskAgent | undefined) {
  return agent?.availability === "ready" || agent?.availability === "available";
}

function availabilityLabel(agent: AskAgent) {
  if (agent.availability === "available") return "Installed; auth checked when you ask";
  if (agent.availability === "ready") return "Ready over ACP";
  if (agent.availability === "authentication_required") return "Sign-in required";
  if (agent.availability === "not_configured") return "Adapter not configured";
  if (agent.availability === "blocked") return "Blocked by the safe-access policy";
  return "Unavailable";
}

function compactAvailabilityLabel(agent: AskAgent) {
  if (agent.availability === "available") return "Verify on send";
  if (agent.availability === "ready") return "Ready over ACP";
  if (agent.availability === "authentication_required") return "Sign-in required";
  if (agent.availability === "not_configured") return "Not configured";
  if (agent.availability === "blocked") return "Safe mode blocked";
  return "Unavailable";
}

function scopeLabel(selected: EntityRef | null) {
  return selected ? `${selected.kind}:${selected.id}` : "workspace snapshot";
}

function readableScopeLabel(snapshot: WorkspaceSnapshot, selected: EntityRef | null) {
  const entity = resolveEntity(snapshot, selected);
  if (!entity) return selected ? scopeLabel(selected) : "Workspace snapshot";
  return `${entity.eyebrow}: ${entity.title}`;
}

function contextKey(snapshotId: string, selected: EntityRef | null) {
  return `${snapshotId}:${selected?.kind ?? "workspace"}:${selected?.id ?? "all"}`;
}

function groundingMatches(
  value: unknown,
  snapshot: WorkspaceSnapshot,
  requestedEntity: EntityRef | null,
): value is AskTurnResponse["grounding"] {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const candidate = value as Partial<AskTurnResponse["grounding"]>;
  const entity = candidate.entity;
  const entityMatches =
    requestedEntity === null
      ? entity === null
      : entity?.kind === requestedEntity.kind && entity.id === requestedEntity.id;
  const artifacts = candidate.artifacts;
  const methodology = candidate.methodology;
  const methodologyMatches =
    methodology?.tool === "cvg" &&
    methodology.version === snapshot.method.version &&
    typeof methodology.digest === "string" &&
    /^[a-f0-9]{64}$/.test(methodology.digest);
  const artifactMetadataIsValid =
    Array.isArray(artifacts) &&
    artifacts.every(
      (artifact) =>
        typeof artifact?.id === "string" &&
        typeof artifact.label === "string" &&
        typeof artifact.path === "string" &&
        typeof artifact.sha256 === "string" &&
        typeof artifact.truncated === "boolean",
    );
  const selectedArtifact =
    requestedEntity?.kind === "artifact"
      ? snapshot.artifacts.find((artifact) => artifact.id === requestedEntity.id) ?? null
      : null;
  const artifactsMatch =
    artifactMetadataIsValid &&
    (requestedEntity?.kind === "artifact"
      ? selectedArtifact !== null &&
        artifacts.length === 1 &&
        artifacts[0].id === selectedArtifact.id &&
        artifacts[0].path === selectedArtifact.path &&
        artifacts[0].sha256 === selectedArtifact.sha256
      : artifacts.length === 0);
  return (
    candidate.snapshotId === snapshot.snapshotId &&
    typeof candidate.observedAt === "string" &&
    methodologyMatches &&
    entityMatches &&
    artifactsMatch
  );
}

function historyFrom(turns: ConversationTurn[]) {
  const bounded = (value: string) => {
    const bytes = new TextEncoder().encode(value);
    return bytes.byteLength <= 1_800
      ? value
      : new TextDecoder().decode(bytes.slice(0, 1_800));
  };
  return turns
    .filter((turn) => turn.state === "complete" && turn.response)
    .flatMap((turn) => [
      { role: "user" as const, text: bounded(turn.question) },
      { role: "assistant" as const, text: bounded(turn.response?.answer ?? "") },
    ])
    .slice(-6);
}

export function AskSurface({ snapshot, selected }: AskSurfaceProps) {
  const [capabilities, setCapabilities] = useState<AskCapabilities>(EMPTY_CAPABILITIES);
  const [agentId, setAgentId] = useState<AskAgent["id"]>("codex");
  const [question, setQuestion] = useState("");
  const [turns, setTurns] = useState<ConversationTurn[]>([]);
  const [includeSelection, setIncludeSelection] = useState(false);
  const [loadingAgents, setLoadingAgents] = useState(true);
  const [registryError, setRegistryError] = useState<string | null>(null);
  const requestRef = useRef<{ controller: AbortController; turnId: string } | null>(null);
  const transcriptRef = useRef<HTMLDivElement | null>(null);
  const formRef = useRef<HTMLFormElement | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);
  const projectIdentityRef = useRef(snapshot.project.root);
  const liveContextRef = useRef(contextKey(snapshot.snapshotId, selected));
  liveContextRef.current = contextKey(snapshot.snapshotId, selected);

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setLoadingAgents(true);
      try {
        const response = await fetch("/api/ask/agents", {
          method: "GET",
          headers: { Accept: "application/json" },
          signal: controller.signal,
        });
        if (!response.ok) throw new Error(`Agent registry unavailable (${response.status})`);
        const candidate = (await response.json()) as Partial<AskCapabilities>;
        if (
          !Array.isArray(candidate.agents) ||
          !candidate.policy ||
          typeof candidate.requestToken !== "string" ||
          candidate.requestToken.length < 16
        ) {
          throw new Error("Agent registry returned an invalid contract");
        }
        setCapabilities(candidate as AskCapabilities);
        const firstReady = candidate.agents.find(agentReady);
        if (firstReady) setAgentId(firstReady.id);
        setRegistryError(null);
      } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") return;
        setCapabilities(EMPTY_CAPABILITIES);
        setRegistryError(error instanceof Error ? error.message : "Agent registry unavailable");
      } finally {
        setLoadingAgents(false);
      }
    }
    void load();
    return () => controller.abort();
  }, []);

  useEffect(() => {
    if (projectIdentityRef.current === snapshot.project.root) return;
    projectIdentityRef.current = snapshot.project.root;
    requestRef.current?.controller.abort();
    requestRef.current = null;
    setTurns([]);
    setQuestion("");
    setIncludeSelection(false);
  }, [snapshot.project.root]);

  useEffect(
    () => () => {
      requestRef.current?.controller.abort();
    },
    [],
  );

  useEffect(() => {
    textareaRef.current?.focus();
  }, []);

  useEffect(() => {
    const textarea = textareaRef.current;
    if (!textarea) return;
    textarea.style.height = "auto";
    textarea.style.height = `${Math.min(textarea.scrollHeight, 220)}px`;
    textarea.style.overflowY = textarea.scrollHeight > 220 ? "auto" : "hidden";
  }, [question]);

  useEffect(() => {
    const transcript = transcriptRef.current;
    if (!transcript) return;
    if (turns.length === 0) {
      if (typeof transcript.scrollTo === "function") {
        transcript.scrollTo({ top: 0, behavior: "auto" });
      } else {
        transcript.scrollTop = 0;
      }
      return;
    }
    if (typeof transcript.scrollTo === "function") {
      transcript.scrollTo({ top: transcript.scrollHeight, behavior: "smooth" });
    } else {
      transcript.scrollTop = transcript.scrollHeight;
    }
  }, [turns]);

  const selectedAgent = useMemo(
    () => capabilities.agents.find((agent) => agent.id === agentId) ?? capabilities.agents[0],
    [agentId, capabilities.agents],
  );
  const replay = snapshot.source === "fixture";
  const asking = turns.some((turn) => turn.state === "pending");
  const requestedEntity = includeSelection ? selected : null;
  const alternateAgent = capabilities.agents.find(
    (agent) => agent.id !== selectedAgent?.id && agentReady(agent),
  );
  const visibleSuggestions = useMemo(
    () => suggestionsFor(snapshot, requestedEntity),
    [snapshot, requestedEntity],
  );
  const canAsk =
    !replay &&
    !asking &&
    question.trim().length >= 2 &&
    agentReady(selectedAgent);

  function patchTurn(turnId: string, patch: Partial<ConversationTurn>) {
    setTurns((current) =>
      current.map((turn) => (turn.id === turnId ? { ...turn, ...patch } : turn)),
    );
  }

  function stopTurn() {
    const active = requestRef.current;
    if (!active) return;
    active.controller.abort();
    requestRef.current = null;
    patchTurn(active.turnId, {
      state: "cancelled",
      error: {
        code: "ASK_CANCELLED",
        message: "Stopped before the provider completed the response.",
        retryable: true,
      },
    });
  }

  function clearConversation() {
    stopTurn();
    setTurns([]);
    setQuestion("");
    setIncludeSelection(false);
    textareaRef.current?.focus();
  }

  function chooseSuggestion(suggestion: string) {
    setQuestion(suggestion);
    textareaRef.current?.focus();
  }

  function retryTurn(turn: ConversationTurn) {
    setQuestion(turn.question);
    textareaRef.current?.focus();
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!canAsk || !selectedAgent) return;

    const text = question.trim();
    const turnId = `turn-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const turn: ConversationTurn = {
      id: turnId,
      agentId: selectedAgent.id,
      question: text,
      scope: requestedEntity,
      state: "pending",
      response: null,
      error: null,
    };
    const priorHistory = historyFrom(turns);
    setTurns((current) => [...current, turn]);
    setQuestion("");
    const controller = new AbortController();
    requestRef.current = { controller, turnId };
    const requestedContext = contextKey(snapshot.snapshotId, requestedEntity);

    try {
      const response = await fetch("/api/ask", {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-Converge-Request": "ask-v1",
          "X-Converge-CSRF": capabilities.requestToken,
        },
        body: JSON.stringify({
          agentId: selectedAgent.id,
          snapshotId: snapshot.snapshotId,
          text,
          history: priorHistory,
          context: {
            entity: requestedEntity,
            artifactIds:
              requestedEntity?.kind === "artifact" ? [requestedEntity.id] : [],
          },
        }),
        signal: controller.signal,
      });
      let body: Partial<AskTurnResponse> | {
        error?: { code?: string; message?: string; retryable?: boolean };
      } = {};
      try {
        body = await response.json() as typeof body;
      } catch {
        // Preserve a stable recovery message when an upstream response is empty
        // or malformed instead of surfacing a JSON parser exception.
      }
      if (!response.ok) {
        const failure = "error" in body ? body.error : undefined;
        throw new AskRequestError({
          code: failure?.code ?? "ASK_AGENT_FAILED",
          message:
            failure?.message ??
            "The selected agent did not return a valid response. Try again or choose another available engine.",
          retryable: failure?.retryable ?? response.status >= 500,
        });
      }
      if (
        !("answer" in body) ||
        typeof body.answer !== "string" ||
        body.snapshotId !== snapshot.snapshotId ||
        body.agentId !== selectedAgent.id ||
        !groundingMatches(body.grounding, snapshot, requestedEntity) ||
        !Array.isArray(body.steps) ||
        !Array.isArray(body.activity)
      ) {
        throw new Error("The agent response was not bound to this workspace snapshot.");
      }
      if (requestedEntity && liveContextRef.current !== requestedContext) {
        throw new Error("The selected project context changed before the answer completed.");
      }
      patchTurn(turnId, {
        state: "complete",
        response: body as AskTurnResponse,
        error: null,
      });
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      patchTurn(turnId, {
        state: "error",
        error:
          error instanceof AskRequestError
            ? { code: error.code, message: error.message, retryable: error.retryable }
            : {
                code: "ASK_AGENT_FAILED",
                message:
                  error instanceof Error
                    ? error.message
                    : "The agent could not answer this question.",
                retryable: true,
              },
      });
    } finally {
      if (requestRef.current?.controller === controller) requestRef.current = null;
    }
  }

  function composerKeyDown(event: KeyboardEvent<HTMLTextAreaElement>) {
    if (event.key !== "Enter" || event.shiftKey || event.nativeEvent.isComposing) return;
    event.preventDefault();
    formRef.current?.requestSubmit();
  }

  return (
    <section
      className={`surface surface--ask ask-chat${turns.length === 0 ? " ask-chat--empty" : ""}`}
      aria-labelledby="ask-title"
    >
      <header className="ask-chat__header">
        <div className="ask-chat__identity">
          <h1 id="ask-title">Ask</h1>
          <span>Converge and {snapshot.project.name}</span>
        </div>
        <button
          type="button"
          className="ask-new-chat"
          onClick={clearConversation}
          aria-label="Start new chat"
        >
          <Plus aria-hidden="true" />
          New chat
        </button>
      </header>

      <div className="ask-chat__transcript" ref={transcriptRef} aria-live="polite">
        {turns.length === 0 ? (
          <div className="ask-hero">
            <img
              className="ask-hero__mark"
              src="/brand/converge-icon-color-light.svg"
              alt=""
              width={64}
              height={64}
              draggable={false}
              aria-hidden="true"
            />
            <h2>What should we explore in {snapshot.project.name}?</h2>
            <p>Ask about the method, decisions, delivery, execution, or proof.</p>
          </div>
        ) : (
          <div className="ask-thread">
            {turns.map((turn) => {
              const agent = capabilities.agents.find((candidate) => candidate.id === turn.agentId);
              return (
                <article className="ask-turn" key={turn.id}>
                  <div className="ask-turn__user">
                    <div className="ask-bubble">
                      <p>{turn.question}</p>
                      {turn.scope ? <small>{scopeLabel(turn.scope)}</small> : null}
                    </div>
                  </div>
                  <div className="ask-reply">
                    <header className="ask-reply__provider">
                      <AgentIcon id={turn.agentId} />
                      <strong>{agent?.label ?? turn.agentId}</strong>
                      <small>via ACP</small>
                    </header>
                    {turn.state === "pending" ? (
                      <div className="ask-thinking-line" role="status">
                        <CircleNotch className="status-glyph--spin" aria-hidden="true" />
                        <span>Reading Converge and the live project context...</span>
                      </div>
                    ) : null}
                    {turn.state === "cancelled" ? (
                      <div className="ask-reply__error is-cancelled">
                        <Stop weight="fill" aria-hidden="true" />
                        {turn.error?.message}
                      </div>
                    ) : null}
                    {turn.state === "error" ? (
                      <div className="ask-reply__error" role="alert">
                        <WarningCircle weight="fill" aria-hidden="true" />
                        <div className="ask-reply__error-copy">
                          <strong>{turn.error?.message}</strong>
                          <span className="ask-reply__recovery">
                            {turn.error?.retryable ? (
                              <button type="button" onClick={() => retryTurn(turn)}>
                                Try again
                              </button>
                            ) : null}
                            {alternateAgent ? (
                              <button type="button" onClick={() => setAgentId(alternateAgent.id)}>
                                Use {alternateAgent.label}
                              </button>
                            ) : null}
                          </span>
                        </div>
                      </div>
                    ) : null}
                    {turn.response ? (
                      <>
                        <div className="ask-reply__answer">
                          <Markdown
                            remarkPlugins={[remarkGfm]}
                            components={askMarkdownComponents}
                            skipHtml
                          >
                            {turn.response.answer}
                          </Markdown>
                        </div>
                        {turn.response.steps.length > 0 ? (
                          <details className="ask-response-details">
                            <summary>{turn.response.steps.length} explanation steps</summary>
                            <ol>
                              {turn.response.steps.map((step, index) => (
                                <li key={`${index}-${step}`}><span>{index + 1}</span><p>{step}</p></li>
                              ))}
                            </ol>
                          </details>
                        ) : null}
                        {turn.response.activity.length > 0 ? (
                          <details className="ask-response-details">
                            <summary>{turn.response.activity.length} bounded activities</summary>
                            <ol>
                              {turn.response.activity.map((item) => (
                                <li key={item.id}>
                                  <span><Check aria-hidden="true" /></span>
                                  <p><strong>{item.label}</strong>{item.detail ? `: ${item.detail}` : ""}</p>
                                </li>
                              ))}
                            </ol>
                          </details>
                        ) : null}
                        <footer className="ask-reply__meta">
                          <ShieldCheck weight="fill" aria-hidden="true" />
                          <span>
                            Grounded in Converge {turn.response.grounding.methodology.version}, snapshot {turn.response.grounding.snapshotId.slice(0, 12)} · {(turn.response.elapsedMs / 1000).toFixed(1)}s
                          </span>
                        </footer>
                      </>
                    ) : null}
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>

      <div className="ask-chat__composer-zone">
        {registryError ? (
          <div className="ask-inline-state" role="alert">
            <WarningCircle weight="fill" aria-hidden="true" /> {registryError}
          </div>
        ) : null}
        {selectedAgent && !agentReady(selectedAgent) ? (
          <div className="ask-inline-state" role="status">
            <CloudSlash weight="fill" aria-hidden="true" />
            <span><strong>{selectedAgent.label} cannot start safely.</strong> {selectedAgent.reason ?? availabilityLabel(selectedAgent)}</span>
            {alternateAgent ? (
              <button
                type="button"
                className="ask-inline-state__action"
                onClick={() => setAgentId(alternateAgent.id)}
              >
                Use {alternateAgent.label}
                <ArrowRight aria-hidden="true" />
              </button>
            ) : null}
          </div>
        ) : null}
        {replay ? (
          <div className="ask-inline-state" role="status">
            <LockKey weight="fill" aria-hidden="true" /> Connect a live workspace to ask an ACP agent.
          </div>
        ) : null}

        <form ref={formRef} className="ask-composer" onSubmit={submit}>
          <textarea
            ref={textareaRef}
            value={question}
            onChange={(event) => setQuestion(event.target.value.slice(0, 8000))}
            onKeyDown={composerKeyDown}
            placeholder="Ask about the project or the Converge method..."
            aria-label="Question for the selected ACP agent"
            disabled={replay || loadingAgents}
            rows={1}
          />
          <div className="ask-composer__bar">
            <div className="ask-composer__tools">
              <div
                className="ask-engine-switcher"
                role="group"
                aria-label="Choose ACP agent"
              >
                {capabilities.agents.map((agent) => {
                  const active = agent.id === agentId;
                  const loadingLabel = "Checking ACP availability";
                  return (
                    <button
                      type="button"
                      key={agent.id}
                      className={active ? "is-active" : ""}
                      onClick={() => setAgentId(agent.id)}
                      disabled={loadingAgents}
                      aria-pressed={active}
                      aria-label={`${agent.label}, ${loadingAgents ? loadingLabel : availabilityLabel(agent)}`}
                      title={loadingAgents ? loadingLabel : agent.reason ?? availabilityLabel(agent)}
                    >
                      <AgentIcon id={agent.id} />
                      <span className="ask-engine-switcher__copy">
                        <strong>{agent.label}</strong>
                        <small>{loadingAgents ? "Checking" : compactAvailabilityLabel(agent)}</small>
                      </span>
                      <i className={`is-${agent.availability}`} aria-hidden="true" />
                    </button>
                  );
                })}
              </div>
              {selected ? (
                includeSelection ? (
                  <button
                    type="button"
                    className="ask-context-chip"
                    onClick={() => setIncludeSelection(false)}
                    title="Remove selected entity from this question"
                  >
                    <MagnifyingGlass aria-hidden="true" />
                    {readableScopeLabel(snapshot, selected)}
                    <X aria-hidden="true" />
                  </button>
                ) : (
                  <button type="button" className="ask-context-add" onClick={() => setIncludeSelection(true)}>
                    <Plus aria-hidden="true" /> Add selected context
                  </button>
                )
              ) : null}
            </div>
            <div className="ask-composer__actions">
              <span className="ask-composer__hint">
                {question.length >= 7_000
                  ? `${question.length.toLocaleString()} / 8,000`
                  : "Enter to send"}
              </span>
              {asking ? (
                <button type="button" className="ask-send ask-send--stop" onClick={stopTurn} aria-label="Stop response">
                  <Stop weight="fill" aria-hidden="true" />
                </button>
              ) : (
                <button type="submit" className="ask-send" disabled={!canAsk} aria-label="Send question">
                  <ArrowUp weight="bold" aria-hidden="true" />
                </button>
              )}
            </div>
          </div>
        </form>

        {turns.length === 0 ? (
          <div className="ask-suggestions" aria-label="Suggested questions">
            {visibleSuggestions.map((suggestion) => (
              <button
                type="button"
                key={suggestion.question}
                onClick={() => chooseSuggestion(suggestion.question)}
              >
                <span>
                  <strong>{suggestion.question}</strong>
                  <small>{suggestion.label}</small>
                </span>
                <ArrowRight aria-hidden="true" />
              </button>
            ))}
          </div>
        ) : null}

        <div className="ask-session-boundary" aria-label="Ask evidence boundary">
          <ShieldCheck weight="fill" aria-hidden="true" />
          <span>
            Read-only ACP. Converge {snapshot.method.version} / snapshot {snapshot.snapshotId.slice(0, 12)}. Answers are interpretation, never a gate verdict.
          </span>
        </div>
      </div>
    </section>
  );
}
