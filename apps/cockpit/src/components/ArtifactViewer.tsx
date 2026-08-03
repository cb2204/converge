import {
  useEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { createPortal } from "react-dom";
import { Code, WarningCircle, X } from "@phosphor-icons/react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import type {
  ArtifactDocument,
  ArtifactRef,
  WorkspaceSnapshot,
} from "../types";

interface ArtifactViewerProps {
  snapshot: WorkspaceSnapshot;
  artifact: ArtifactRef | null;
  onClose: () => void;
}

type ViewerState =
  | { status: "idle"; document: null; error: null }
  | { status: "loading"; document: null; error: null }
  | { status: "ready"; document: ArtifactDocument; error: null }
  | { status: "error"; document: null; error: string };

export function ArtifactViewer({
  snapshot,
  artifact,
  onClose,
}: ArtifactViewerProps) {
  const reduceMotion = useReducedMotion();
  const [state, setState] = useState<ViewerState>({
    status: "idle",
    document: null,
    error: null,
  });
  const viewerRef = useRef<HTMLDivElement | null>(null);
  const closeRef = useRef<HTMLButtonElement | null>(null);

  useEffect(() => {
    if (!artifact) {
      setState({ status: "idle", document: null, error: null });
      return;
    }

    const controller = new AbortController();
    const load = async () => {
      setState({ status: "loading", document: null, error: null });
      try {
        const query = new URLSearchParams({
          path: artifact.path,
          snapshotId: snapshot.snapshotId,
          sha256: artifact.sha256,
        });
        const response = await fetch(`/api/artifact?${query.toString()}`, {
          method: "GET",
          signal: controller.signal,
          headers: { Accept: "application/json" },
        });
        if (!response.ok) {
          throw new Error(
            response.status === 409
              ? "This proof is stale. Refresh the workspace before opening it."
              : `Artifact is unavailable (${response.status})`,
          );
        }
        const candidate = (await response.json()) as Partial<ArtifactDocument>;
        if (
          candidate.path !== artifact.path ||
          candidate.snapshotId !== snapshot.snapshotId ||
          candidate.sha256 !== artifact.sha256 ||
          typeof candidate.label !== "string" ||
          typeof candidate.kind !== "string" ||
          typeof candidate.content !== "string" ||
          typeof candidate.truncated !== "boolean"
        ) {
          throw new Error("Artifact no longer matches the selected proof.");
        }
        setState({
          status: "ready",
          document: candidate as ArtifactDocument,
          error: null,
        });
      } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") return;
        setState({
          status: "error",
          document: null,
          error: error instanceof Error ? error.message : "Artifact is unavailable.",
        });
      }
    };
    void load();
    return () => controller.abort();
  }, [artifact, snapshot.snapshotId]);

  useEffect(() => {
    if (!artifact) return;
    const previousOverflow = document.body.style.overflow;
    const previousFocus = document.activeElement;
    document.body.style.overflow = "hidden";
    window.requestAnimationFrame(() => closeRef.current?.focus());
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
      if (previousFocus instanceof HTMLElement) previousFocus.focus();
    };
  }, [artifact, onClose]);

  function trapFocus(event: KeyboardEvent<HTMLDivElement>) {
    if (event.key !== "Tab" || !viewerRef.current) return;
    const focusable = [
      ...viewerRef.current.querySelectorAll<HTMLElement>(
        'button, [href], [tabindex]:not([tabindex="-1"])',
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

  return createPortal(
    <AnimatePresence>
      {artifact ? (
        <motion.div
          className="artifact-backdrop"
          initial={reduceMotion ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={reduceMotion ? undefined : { opacity: 0 }}
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) onClose();
          }}
        >
          <motion.div
            ref={viewerRef}
            className="artifact-viewer"
            role="dialog"
            aria-modal="true"
            aria-labelledby="artifact-viewer-title"
            onKeyDown={trapFocus}
            initial={reduceMotion ? false : { opacity: 0, y: 12, scale: 0.99 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? undefined : { opacity: 0, y: 8, scale: 0.995 }}
            transition={{ duration: 0.18 }}
          >
            <header>
              <div>
                <Code aria-hidden="true" />
                <span>
                  <strong id="artifact-viewer-title">{artifact.label}</strong>
                  <small>{artifact.path}</small>
                </span>
              </div>
              <button
                ref={closeRef}
                type="button"
                onClick={onClose}
                aria-label="Close artifact viewer"
              >
                <X aria-hidden="true" />
              </button>
            </header>

            <div className="artifact-proof">
              <span>snapshot {snapshot.snapshotId.slice(0, 12)}</span>
              <span>sha256 {artifact.sha256.slice(0, 12)}</span>
              <span>{artifact.provenance.truthClass}</span>
            </div>

            {state.status === "loading" ? (
              <div className="artifact-loading" aria-label="Loading artifact">
                <span />
                <span />
                <span />
                <span />
              </div>
            ) : null}

            {state.status === "error" ? (
              <div className="artifact-error" role="alert">
                <WarningCircle size={22} weight="fill" aria-hidden="true" />
                <div>
                  <strong>Proof unavailable</strong>
                  <p>{state.error}</p>
                </div>
              </div>
            ) : null}

            {state.status === "ready" ? (
              <>
                <pre>{state.document.content}</pre>
                {state.document.truncated ? (
                  <small>Preview truncated by the read-only local bridge.</small>
                ) : null}
              </>
            ) : null}
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
