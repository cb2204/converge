import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { createPortal } from "react-dom";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ClipboardText,
  Code,
  FileText,
  ShieldCheck,
  Warning,
  X,
} from "@phosphor-icons/react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import type {
  ArtifactDocument,
  EvidenceRef,
  PassState,
  WorkspaceSnapshot,
} from "../types";
import { StatusGlyph } from "./StatusGlyph";

interface EvidencePanelProps {
  snapshot: WorkspaceSnapshot;
  pass: PassState;
}

type ArtifactState =
  | { status: "idle"; document: null; error: null; evidence: null }
  | {
      status: "loading";
      document: null;
      error: null;
      evidence: EvidenceRef;
    }
  | {
      status: "ready";
      document: ArtifactDocument;
      error: null;
      evidence: EvidenceRef;
    }
  | {
      status: "error";
      document: null;
      error: string;
      evidence: EvidenceRef;
    };

function semanticLabel(value: string | null) {
  if (!value) return "Not available";
  return value.replaceAll("_", " ");
}

export function EvidencePanel({ snapshot, pass }: EvidencePanelProps) {
  const reduceMotion = useReducedMotion();
  const [objectionIndex, setObjectionIndex] = useState(0);
  const [copied, setCopied] = useState(false);
  const [copyFailed, setCopyFailed] = useState(false);
  const [expandedEvidenceKinds, setExpandedEvidenceKinds] = useState<
    Set<string>
  >(new Set());
  const [artifact, setArtifact] = useState<ArtifactState>({
    status: "idle",
    document: null,
    error: null,
    evidence: null,
  });
  const artifactAbort = useRef<AbortController | null>(null);
  const artifactViewer = useRef<HTMLDivElement | null>(null);
  const artifactClose = useRef<HTMLButtonElement | null>(null);
  const artifactTrigger = useRef<HTMLButtonElement | null>(null);

  const isReview = pass.id === "pass-4" && snapshot.review;
  const objections = snapshot.review?.objections ?? [];
  const objection = objections[objectionIndex] ?? null;
  const blockingQuestions =
    snapshot.review?.openQuestions.filter((question) => question.blocksBuild) ??
    [];
  const isAuthorizedPass = snapshot.authorization.nextPassId === pass.id;

  useEffect(() => {
    artifactAbort.current?.abort();
    setObjectionIndex(0);
    setExpandedEvidenceKinds(new Set());
    setArtifact({
      status: "idle",
      document: null,
      error: null,
      evidence: null,
    });
  }, [pass.id, snapshot.snapshotId]);

  useEffect(() => () => artifactAbort.current?.abort(), []);

  const closeArtifact = useCallback(() => {
    artifactAbort.current?.abort();
    setArtifact({
      status: "idle",
      document: null,
      error: null,
      evidence: null,
    });
    window.requestAnimationFrame(() => artifactTrigger.current?.focus());
  }, []);

  useEffect(() => {
    if (artifact.status === "idle") return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    window.requestAnimationFrame(() => artifactClose.current?.focus());
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape") closeArtifact();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [artifact.status, closeArtifact]);

  const evidenceGroups = useMemo(() => {
    return pass.evidence.reduce<Record<string, EvidenceRef[]>>((groups, item) => {
      const key = item.kind;
      groups[key] ??= [];
      groups[key].push(item);
      return groups;
    }, {});
  }, [pass.evidence]);

  async function openArtifact(
    evidence: EvidenceRef,
    trigger: HTMLButtonElement,
  ) {
    artifactAbort.current?.abort();
    const controller = new AbortController();
    artifactAbort.current = controller;
    artifactTrigger.current = trigger;
    setArtifact({
      status: "loading",
      document: null,
      error: null,
      evidence,
    });
    try {
      const query = new URLSearchParams({
        path: evidence.path,
        snapshotId: snapshot.snapshotId,
      });
      if (evidence.sha256) query.set("sha256", evidence.sha256);
      const response = await fetch(`/api/artifact?${query.toString()}`, {
        signal: controller.signal,
        headers: { Accept: "application/json" },
      });
      if (!response.ok) {
        throw new Error(`Artifact is unavailable (${response.status})`);
      }
      const document = (await response.json()) as Partial<ArtifactDocument>;
      if (
        document.path !== evidence.path ||
        document.snapshotId !== snapshot.snapshotId ||
        typeof document.sha256 !== "string" ||
        (evidence.sha256 && document.sha256 !== evidence.sha256) ||
        typeof document.label !== "string" ||
        typeof document.kind !== "string" ||
        typeof document.content !== "string" ||
        typeof document.truncated !== "boolean"
      ) {
        throw new Error("Artifact no longer matches the selected proof");
      }
      setArtifact({
        status: "ready",
        document: document as ArtifactDocument,
        error: null,
        evidence,
      });
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      setArtifact({
        status: "error",
        document: null,
        error: error instanceof Error ? error.message : "Artifact is unavailable",
        evidence,
      });
    }
  }

  async function copyCommand() {
    if (!snapshot.authorization.command) return;
    try {
      await navigator.clipboard.writeText(snapshot.authorization.command);
      setCopyFailed(false);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      setCopied(false);
      setCopyFailed(true);
      window.setTimeout(() => setCopyFailed(false), 2200);
    }
  }

  function trapArtifactFocus(event: KeyboardEvent<HTMLDivElement>) {
    if (event.key !== "Tab" || !artifactViewer.current) return;
    const focusable = [
      ...artifactViewer.current.querySelectorAll<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
      ),
    ].filter((element) => !element.hasAttribute("disabled"));
    if (focusable.length === 0) return;
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  return (
    <>
      <aside className="evidence-panel" aria-label={`${pass.label} evidence`}>
      <header className="evidence-panel__header">
        <div className={`evidence-panel__glyph status-${pass.status}`}>
          <StatusGlyph status={pass.status} size={20} />
        </div>
        <div>
          <p>{pass.label}</p>
          <h2>{pass.summary}</h2>
        </div>
      </header>

      <div className="truth-grid" aria-label="Pass truth layers">
        <div>
          <span>Gate</span>
          <strong>{semanticLabel(pass.gate.verdict)}</strong>
          <small>{pass.gate.token ?? "No token yet"}</small>
        </div>
        <div>
          <span>Review</span>
          <strong>{isReview ? snapshot.review?.verdict : "Not applicable"}</strong>
          <small>
            {isReview ? `Round ${snapshot.review?.round}` : "Deterministic gate"}
          </small>
        </div>
        <div>
          <span>Pass authorization</span>
          <strong>
            {isAuthorizedPass
              ? semanticLabel(snapshot.authorization.state)
              : "Not this pass"}
          </strong>
          <small>
            {isAuthorizedPass
              ? "Current CLI frontier"
              : `Frontier: ${snapshot.authorization.nextPassId ?? "none"}`}
          </small>
        </div>
      </div>

      {isReview && objection ? (
        <section className="review-chamber" aria-labelledby="review-title">
          <div className="section-heading">
            <div>
              <span id="review-title">Adversarial review</span>
              <strong>
                {objections.length} objections · {blockingQuestions.length} blocking
              </strong>
            </div>
            <div className="carousel-controls">
              <button
                type="button"
                aria-label="Previous objection"
                onClick={() =>
                  setObjectionIndex(
                    (current) =>
                      (current - 1 + objections.length) % objections.length,
                  )
                }
              >
                <ArrowLeft />
              </button>
              <span>
                {objectionIndex + 1}/{objections.length}
              </span>
              <button
                type="button"
                aria-label="Next objection"
                onClick={() =>
                  setObjectionIndex(
                    (current) => (current + 1) % objections.length,
                  )
                }
              >
                <ArrowRight />
              </button>
            </div>
          </div>

          <AnimatePresence mode="wait" initial={false}>
            <motion.article
              key={objection.id}
              className="objection"
              initial={reduceMotion ? false : { opacity: 0, x: 12 }}
              animate={{ opacity: 1, x: 0 }}
              exit={reduceMotion ? undefined : { opacity: 0, x: -8 }}
              transition={{ duration: 0.2 }}
            >
              <div className="objection__meta">
                <span className={`severity severity--${objection.severity}`}>
                  <Warning weight="fill" />
                  {objection.severity}
                </span>
                <span>{objection.id}</span>
              </div>
              <h3>{objection.title}</h3>
              {objection.body ? <p>{objection.body}</p> : null}
              {objection.residualRisk ? (
                <div className="residual-risk">
                  <ShieldCheck aria-hidden="true" />
                  <span>
                    <strong>Residual risk</strong>
                    {objection.residualRisk}
                  </span>
                </div>
              ) : null}
            </motion.article>
          </AnimatePresence>
        </section>
      ) : null}

      <section className="evidence-list" aria-labelledby="evidence-title">
        <div className="section-heading">
          <div>
            <span id="evidence-title">Evidence</span>
            <strong>{pass.evidence.length} attached artifacts</strong>
          </div>
        </div>

        {pass.evidence.length === 0 ? (
          <p className="empty-copy">
            This pass has not emitted evidence in the current workspace.
          </p>
        ) : (
          <div className="evidence-list__groups">
            {Object.entries(evidenceGroups).map(([kind, items]) => (
              <div key={kind} className="evidence-group">
                <span>{kind}</span>
                {items
                  .slice(
                    0,
                    expandedEvidenceKinds.has(kind) ? items.length : 5,
                  )
                  .map((item) => (
                    <button
                      type="button"
                      key={item.id}
                      onClick={(event) =>
                        void openArtifact(item, event.currentTarget)
                      }
                    >
                      <FileText aria-hidden="true" />
                      <span>
                        <strong>{item.label}</strong>
                        <small>{item.path}</small>
                      </span>
                      <ArrowRight aria-hidden="true" />
                    </button>
                  ))}
                {items.length > 5 ? (
                  <button
                    type="button"
                    className="evidence-group__toggle"
                    aria-expanded={expandedEvidenceKinds.has(kind)}
                    onClick={() =>
                      setExpandedEvidenceKinds((current) => {
                        const next = new Set(current);
                        if (next.has(kind)) next.delete(kind);
                        else next.add(kind);
                        return next;
                      })
                    }
                  >
                    {expandedEvidenceKinds.has(kind)
                      ? "Show fewer"
                      : `Show all ${items.length}`}
                  </button>
                ) : null}
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="next-action" aria-labelledby="next-action-title">
        <div>
          <span id="next-action-title">Workspace next action</span>
          <strong>
            {snapshot.authorization.command ?? "No command is authorized"}
          </strong>
        </div>
        {snapshot.authorization.command ? (
          <button type="button" onClick={() => void copyCommand()}>
            {copied ? <Check weight="bold" /> : <ClipboardText />}
            {copied ? "Copied" : copyFailed ? "Unavailable" : "Copy"}
          </button>
        ) : null}
        <p>{snapshot.authorization.rationale}</p>
      </section>

      </aside>

      {createPortal(
        <AnimatePresence>
          {artifact.status !== "idle" ? (
            <motion.div
              className="artifact-backdrop"
              initial={reduceMotion ? false : { opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={reduceMotion ? undefined : { opacity: 0 }}
              onMouseDown={(event) => {
                if (event.currentTarget === event.target) closeArtifact();
              }}
            >
              <motion.div
                ref={artifactViewer}
                className="artifact-viewer"
                initial={reduceMotion ? false : { opacity: 0, y: 16, scale: 0.99 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={
                  reduceMotion ? undefined : { opacity: 0, y: 10, scale: 0.995 }
                }
                transition={{ duration: 0.2 }}
                role="dialog"
                aria-modal="true"
                aria-label="Artifact viewer"
                onKeyDown={trapArtifactFocus}
              >
                <header>
                  <span>
                    <Code aria-hidden="true" />
                    {artifact.document?.label ??
                      artifact.evidence.label ??
                      "Opening artifact"}
                  </span>
                  <button
                    ref={artifactClose}
                    type="button"
                    aria-label="Close artifact viewer"
                    onClick={closeArtifact}
                  >
                    <X />
                  </button>
                </header>
                {artifact.status === "loading" ? (
                  <div className="artifact-skeleton" aria-label="Loading artifact">
                    <span />
                    <span />
                    <span />
                    <span />
                  </div>
                ) : null}
                {artifact.status === "error" ? (
                  <p className="artifact-error">{artifact.error}</p>
                ) : null}
                {artifact.status === "ready" ? (
                  <>
                    <div className="artifact-proof">
                      <code>{artifact.document.path}</code>
                      <span>
                        snapshot {artifact.document.snapshotId.slice(0, 12)} · sha256{" "}
                        {artifact.document.sha256.slice(0, 12)}
                      </span>
                    </div>
                    <pre>{artifact.document.content}</pre>
                    {artifact.document.truncated ? (
                      <small>Preview truncated by the local controller.</small>
                    ) : null}
                  </>
                ) : null}
              </motion.div>
            </motion.div>
          ) : null}
        </AnimatePresence>,
        document.body,
      )}
    </>
  );
}
