import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowClockwise,
  Broadcast,
  GitBranch,
  Lightning,
  Warning,
} from "@phosphor-icons/react";
import { motion, useReducedMotion } from "motion/react";
import { fallbackSnapshot } from "./data/fallback";
import type { WorkspaceSnapshot } from "./types";
import { ActivityRail } from "./components/ActivityRail";
import { BrandMark } from "./components/BrandMark";
import { EvidencePanel } from "./components/EvidencePanel";
import { LineageCanvas } from "./components/LineageCanvas";
import { isWorkspaceSnapshot } from "./lib/snapshot";

type ConnectionState = "connecting" | "connected" | "error";

export function App() {
  const reduceMotion = useReducedMotion();
  const [snapshot, setSnapshot] =
    useState<WorkspaceSnapshot>(fallbackSnapshot);
  const [selectedPassId, setSelectedPassId] = useState(
    fallbackSnapshot.method.activePassId,
  );
  const [connection, setConnection] =
    useState<ConnectionState>("connecting");
  const [refreshing, setRefreshing] = useState(false);
  const [warningsExpanded, setWarningsExpanded] = useState(false);

  const selectedPass = useMemo(
    () =>
      snapshot.method.passes.find((pass) => pass.id === selectedPassId) ??
      snapshot.method.passes.find(
        (pass) => pass.id === snapshot.method.activePassId,
      ) ??
      snapshot.method.passes[0],
    [selectedPassId, snapshot],
  );

  const nextPass = snapshot.method.passes.find(
    (pass) => pass.id === snapshot.authorization.nextPassId,
  );
  const connectionLabel =
    connection === "connecting"
      ? "Connecting"
      : snapshot.source === "fixture"
        ? connection === "error"
          ? "Replay fixture · bridge unavailable"
          : "Replay fixture"
        : connection === "error"
          ? "Live snapshot · signal paused"
          : "Live workspace";
  const hasConsensusAttention =
    snapshot.review !== null &&
    snapshot.method.passes.some(
      (pass) => pass.id === "pass-4" && pass.status === "attention",
    );

  const loadSnapshot = useCallback(async () => {
    setRefreshing(true);
    try {
      const response = await fetch("/api/snapshot", {
        headers: { Accept: "application/json" },
      });
      if (!response.ok) throw new Error(`Snapshot failed (${response.status})`);
      const candidate = (await response.json()) as unknown;
      if (!isWorkspaceSnapshot(candidate)) {
        throw new Error("Snapshot contract mismatch");
      }
      setSnapshot(candidate);
      setConnection("connected");
      setSelectedPassId((current) =>
        candidate.method.passes.some((pass) => pass.id === current)
          ? current
          : candidate.method.activePassId,
      );
    } catch {
      setConnection("error");
    } finally {
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    void loadSnapshot();

    const source = new EventSource("/api/events");
    const receive = (event: MessageEvent<string>) => {
      try {
        const candidate = JSON.parse(event.data) as
          | WorkspaceSnapshot
          | { snapshot: WorkspaceSnapshot };
        const next =
          "snapshot" in candidate ? candidate.snapshot : candidate;
        if (!isWorkspaceSnapshot(next)) return;
        setSnapshot(next);
        setConnection("connected");
      } catch {
        setConnection("error");
      }
    };

    source.onmessage = receive;
    source.addEventListener("snapshot", receive as EventListener);
    source.onerror = () => {
      setConnection("error");
    };

    return () => source.close();
  }, [loadSnapshot]);

  return (
    <main className="app-root">
      <div className="ambient ambient--one" aria-hidden="true" />
      <div className="ambient ambient--two" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />

      <motion.div
        className="control-room"
        initial={reduceMotion ? false : { opacity: 0, scale: 0.985, y: 4 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
      >
        <header className="top-rail">
          <BrandMark />

          <div className="workspace-identity">
            <span>{snapshot.project.name}</span>
            <small>
              <GitBranch aria-hidden="true" />
              {snapshot.project.branch} · {snapshot.project.commit.slice(0, 8)}
            </small>
          </div>

          <div className="top-rail__actions">
            <span
              className={`connection-state connection-state--${connection} connection-state--${snapshot.source}`}
              aria-live="polite"
            >
              <Broadcast weight="fill" aria-hidden="true" />
              {connectionLabel}
            </span>
            <button
              type="button"
              className="icon-button"
              onClick={() => void loadSnapshot()}
              disabled={refreshing}
              aria-label="Refresh workspace snapshot"
              title="Refresh workspace snapshot"
            >
              <ArrowClockwise
                className={refreshing ? "status-glyph--spin" : ""}
                aria-hidden="true"
              />
            </button>
          </div>
        </header>

        <section className="run-heading">
          <div>
            <p>Intent to proven delivery</p>
            <h1>{snapshot.method.name}</h1>
            <span>
              {snapshot.method.passes.filter((pass) => pass.status === "complete")
                .length}{" "}
              proven · {snapshot.cli.commandCount} CLI capabilities · lane{" "}
              {snapshot.project.lane}
            </span>
          </div>

          <div className="next-pass-summary">
            <span>
              <Lightning weight="fill" aria-hidden="true" />
              CLI position
            </span>
            <strong>
              {nextPass ? `${nextPass.order} ${nextPass.shortLabel}` : "Complete"}
            </strong>
            <code>
              {snapshot.authorization.command ?? "No next command available"}
            </code>
          </div>
        </section>

        {snapshot.warnings.length > 0 ? (
          <section className="truth-warning" aria-label="Workspace warnings">
            <Warning weight="fill" aria-hidden="true" />
            <span>
              <strong>Workspace needs attention.</strong>
              {snapshot.warnings[0]}
              {!warningsExpanded && snapshot.warnings.length > 1 ? (
                <em>+{snapshot.warnings.length - 1} more</em>
              ) : null}
            </span>
            <div className="truth-warning__actions">
              {snapshot.warnings.length > 1 ? (
                <button
                  type="button"
                  onClick={() => setWarningsExpanded((expanded) => !expanded)}
                  aria-expanded={warningsExpanded}
                >
                  {warningsExpanded ? "Collapse" : "View all"}
                </button>
              ) : null}
              {hasConsensusAttention ? (
                <button type="button" onClick={() => setSelectedPassId("pass-4")}>
                  Inspect consensus
                </button>
              ) : null}
            </div>
            {warningsExpanded ? (
              <ul>
                {snapshot.warnings.slice(1).map((warning) => (
                  <li key={warning}>{warning}</li>
                ))}
              </ul>
            ) : null}
          </section>
        ) : null}

        <div className="workspace-stage">
          <LineageCanvas
            snapshot={snapshot}
            selectedPassId={selectedPass.id}
            onSelectPass={setSelectedPassId}
          />
          <EvidencePanel snapshot={snapshot} pass={selectedPass} />
        </div>

        <ActivityRail
          items={snapshot.activity}
          selectedPassId={selectedPass.id}
          onSelectPass={setSelectedPassId}
        />

        <footer className="control-room__footer">
          <span>
            Snapshot {snapshot.snapshotId.slice(0, 12)} ·{" "}
            {snapshot.project.dirty ? "workspace has local changes" : "workspace clean"}
          </span>
          <span>
            Read-only projection · canonical truth stays in `cvg` and the repository
          </span>
        </footer>
      </motion.div>
    </main>
  );
}
