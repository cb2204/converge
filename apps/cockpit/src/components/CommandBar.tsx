import {
  ArrowClockwise,
  Broadcast,
  GitBranch,
  SidebarSimple,
  WarningCircle,
} from "@phosphor-icons/react";
import type { TransportState, WorkspaceSnapshot } from "../types";
import { BrandMark } from "./BrandMark";

interface CommandBarProps {
  snapshot: WorkspaceSnapshot;
  transport: TransportState;
  loading: boolean;
  connectionPaused: boolean;
  leftExpanded: boolean;
  rightExpanded: boolean;
  onToggleLeft: () => void;
  onToggleRight: () => void;
  onRefresh: () => void;
}

export function CommandBar({
  snapshot,
  transport,
  loading,
  connectionPaused,
  leftExpanded,
  rightExpanded,
  onToggleLeft,
  onToggleRight,
  onRefresh,
}: CommandBarProps) {
  const git = snapshot.project.git;
  const sourceLabel =
    snapshot.source === "fixture"
      ? "Replay fixture"
      : transport.stale
        ? "Last-good snapshot"
        : connectionPaused
          ? "Signal paused"
          : "Live workspace";
  const sourceTone =
    transport.stale || connectionPaused
      ? "warning"
      : snapshot.source === "fixture"
        ? "fixture"
        : "live";

  return (
    <header className="command-bar">
      <div className="command-bar__leading">
        <button
          type="button"
          className="command-bar__panel-toggle command-bar__panel-toggle--left"
          onClick={onToggleLeft}
          aria-expanded={leftExpanded}
          aria-controls="cockpit-navigation"
          aria-label={leftExpanded ? "Collapse navigation" : "Expand navigation"}
          title={leftExpanded ? "Collapse navigation" : "Expand navigation"}
        >
          <SidebarSimple aria-hidden="true" />
        </button>
        <BrandMark />
      </div>

      <div className="command-bar__project">
        <strong>{snapshot.project.name}</strong>
        <span>
          <GitBranch aria-hidden="true" />
          {git.available
            ? `${git.branch ?? "detached"} / ${git.commit?.slice(0, 8) ?? "unknown"}`
            : "Git unavailable"}
          {git.dirty === true ? <em>local changes</em> : null}
        </span>
      </div>

      <div className="command-bar__actions">
        {snapshot.issues.some(
          (issue) => issue.severity === "blocking" || issue.severity === "error",
        ) ? (
          <span className="issue-count" title="Errors or blocking issues observed">
            <WarningCircle weight="fill" aria-hidden="true" />
            {
              snapshot.issues.filter(
                (issue) =>
                  issue.severity === "blocking" || issue.severity === "error",
              ).length
            }
          </span>
        ) : null}
        <span
          className={`connection-state connection-state--${sourceTone}`}
          role="status"
          aria-live="polite"
          aria-label={sourceLabel}
          title={sourceLabel}
        >
          <Broadcast weight="fill" aria-hidden="true" />
          <span>{sourceLabel}</span>
        </span>
        <button
          type="button"
          className="icon-button"
          onClick={onRefresh}
          disabled={loading}
          aria-label="Refresh workspace snapshot"
          title="Refresh workspace snapshot"
        >
          <ArrowClockwise
            className={loading ? "status-glyph--spin" : ""}
            aria-hidden="true"
          />
        </button>
        <button
          type="button"
          className="command-bar__panel-toggle command-bar__panel-toggle--right"
          onClick={onToggleRight}
          aria-expanded={rightExpanded}
          aria-controls="cockpit-inspector"
          aria-label={rightExpanded ? "Collapse inspector" : "Expand inspector"}
          title={rightExpanded ? "Collapse inspector" : "Expand inspector"}
        >
          <SidebarSimple mirrored aria-hidden="true" />
        </button>
      </div>
    </header>
  );
}
