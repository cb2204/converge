import { useEffect, useMemo, useState } from "react";
import {
  Graph,
  ListBullets,
  LockKey,
  RocketLaunch,
  SealCheck,
} from "@phosphor-icons/react";
import type { EntityRef, WorkTask, WorkspaceSnapshot } from "../types";
import { WorkGraph } from "./WorkGraph";

interface WorkSurfaceProps {
  snapshot: WorkspaceSnapshot;
  selected: EntityRef | null;
  onSelect: (selection: EntityRef) => void;
}

type WorkView = "graph" | "list";

function isMobileViewport() {
  return typeof window !== "undefined" &&
    window.matchMedia("(max-width: 767px)").matches;
}

function WorkRow({
  task,
  selected,
  onSelect,
}: {
  task: WorkTask;
  selected: boolean;
  onSelect: (selection: EntityRef) => void;
}) {
  return (
    <button
      type="button"
      className={`work-row ${selected ? "work-row--selected" : ""}`}
      onClick={() => onSelect({ kind: "task", id: task.id })}
    >
      <span className={`state-mark state-mark--${task.status}`} aria-hidden="true" />
      <span className="work-row__copy">
        <strong>{task.title}</strong>
        <small>
          {task.id} / {task.dependsOn.length} dependencies
        </small>
      </span>
      <span className="work-row__meta">{task.status.replaceAll("_", " ")}</span>
    </button>
  );
}

export function WorkSurface({
  snapshot,
  selected,
  onSelect,
}: WorkSurfaceProps) {
  const [mobile, setMobile] = useState(isMobileViewport);
  const [view, setView] = useState<WorkView>(() =>
    isMobileViewport() ? "list" : "graph",
  );
  useEffect(() => {
    const media = window.matchMedia("(max-width: 767px)");
    const syncView = () => {
      setMobile(media.matches);
      if (media.matches) setView("list");
    };
    media.addEventListener("change", syncView);
    return () => media.removeEventListener("change", syncView);
  }, []);
  const frontier = useMemo(
    () =>
      snapshot.work.frontier.taskIds
        .map((id) => snapshot.work.tasks.find((task) => task.id === id))
        .filter((task): task is WorkTask => Boolean(task)),
    [snapshot.work.frontier.taskIds, snapshot.work.tasks],
  );
  const completed = snapshot.work.tasks.filter((task) => task.status === "done");
  const backlog = snapshot.work.tasks.filter(
    (task) =>
      task.status !== "done" &&
      !snapshot.work.frontier.taskIds.includes(task.id),
  );

  return (
    <section className="surface surface--work" aria-labelledby="work-title">
      <header className="surface-header">
        <div>
          <span>Execution inventory</span>
          <h1 id="work-title">Work</h1>
        </div>
        <div className="segmented-control" aria-label="Work presentation">
          <button
            type="button"
            className={view === "graph" ? "is-active" : ""}
            onClick={() => setView("graph")}
            aria-pressed={view === "graph"}
            disabled={mobile}
            title={mobile ? "Graph is available on wider screens" : undefined}
          >
            <Graph aria-hidden="true" />
            Graph
          </button>
          <button
            type="button"
            className={view === "list" ? "is-active" : ""}
            onClick={() => setView("list")}
            aria-pressed={view === "list"}
          >
            <ListBullets aria-hidden="true" />
            List
          </button>
        </div>
      </header>

      {snapshot.work.availability === "unavailable" ? (
        <div className="surface-state">
          <LockKey size={28} weight="fill" aria-hidden="true" />
          <strong>Work inventory unavailable</strong>
          <p>The snapshot did not expose a canonical task graph.</p>
        </div>
      ) : snapshot.work.availability === "empty" ||
        snapshot.work.tasks.length === 0 ? (
        <div className="surface-state">
          <RocketLaunch size={28} weight="fill" aria-hidden="true" />
          <strong>No work has been decomposed</strong>
          <p>Tasking will populate this view when canonical tasks exist.</p>
        </div>
      ) : (
        <>
          <div className="work-summary" aria-label="Work state summary">
            <span>
              <strong>{snapshot.work.stats.total}</strong>
              total
            </span>
            <span className="tone-active">
              <strong>{snapshot.work.frontier.taskIds.length}</strong>
              frontier
            </span>
            <span className="tone-danger">
              <strong>{snapshot.work.stats.blocked}</strong>
              blocked
            </span>
            <span className="tone-proven">
              <strong>{snapshot.work.stats.done}</strong>
              completed
            </span>
          </div>

          {view === "graph" && !mobile ? (
            <WorkGraph
              tasks={snapshot.work.tasks}
              frontierIds={snapshot.work.frontier.taskIds}
              selected={selected}
              onSelect={onSelect}
            />
          ) : (
            <div className="work-list-groups">
              <section>
                <header>
                  <RocketLaunch weight="fill" aria-hidden="true" />
                  <span>
                    <strong>Frontier</strong>
                    <small>{frontier.length} dispatchable</small>
                  </span>
                </header>
                <div>
                  {frontier.map((task) => (
                    <WorkRow
                      key={task.id}
                      task={task}
                      selected={selected?.kind === "task" && selected.id === task.id}
                      onSelect={onSelect}
                    />
                  ))}
                </div>
              </section>
              <section>
                <header>
                  <LockKey weight="fill" aria-hidden="true" />
                  <span>
                    <strong>Backlog</strong>
                    <small>{backlog.length} waiting or blocked</small>
                  </span>
                </header>
                <div>
                  {backlog.map((task) => (
                    <WorkRow
                      key={task.id}
                      task={task}
                      selected={selected?.kind === "task" && selected.id === task.id}
                      onSelect={onSelect}
                    />
                  ))}
                </div>
              </section>
              <section>
                <header>
                  <SealCheck weight="fill" aria-hidden="true" />
                  <span>
                    <strong>Completed</strong>
                    <small>{completed.length} settled</small>
                  </span>
                </header>
                <div>
                  {completed.map((task) => (
                    <WorkRow
                      key={task.id}
                      task={task}
                      selected={selected?.kind === "task" && selected.id === task.id}
                      onSelect={onSelect}
                    />
                  ))}
                </div>
              </section>
            </div>
          )}
        </>
      )}
    </section>
  );
}
