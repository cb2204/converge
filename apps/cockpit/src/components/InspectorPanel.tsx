import {
  ArrowSquareOut,
  CaretDoubleLeft,
  CaretDoubleRight,
  ClockCounterClockwise,
  FileCode,
  Info,
  ShieldCheck,
} from "@phosphor-icons/react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import {
  artifactsByIds,
  relatedSignals,
  resolveEntity,
} from "../lib/entities";
import type {
  ArtifactRef,
  EntityRef,
  InspectorTab,
  WorkspaceSnapshot,
} from "../types";

interface InspectorPanelProps {
  snapshot: WorkspaceSnapshot;
  selected: EntityRef | null;
  tab: InspectorTab;
  expanded: boolean;
  onTabChange: (tab: InspectorTab) => void;
  onToggle: () => void;
  onOpenArtifact: (artifact: ArtifactRef) => void;
}

const TABS: Array<{
  id: InspectorTab;
  label: string;
  icon: typeof Info;
}> = [
  { id: "details", label: "Details", icon: Info },
  { id: "proof", label: "Proof", icon: ShieldCheck },
  { id: "history", label: "History", icon: ClockCounterClockwise },
];

export function InspectorPanel({
  snapshot,
  selected,
  tab,
  expanded,
  onTabChange,
  onToggle,
  onOpenArtifact,
}: InspectorPanelProps) {
  const reduceMotion = useReducedMotion();
  const entity = resolveEntity(snapshot, selected);
  const artifacts = entity
    ? artifactsByIds(snapshot, entity.artifactIds)
    : [];
  const history = entity ? relatedSignals(snapshot, entity.ref) : [];

  return (
    <aside
      id="cockpit-inspector"
      className={`inspector ${expanded ? "inspector--expanded" : "inspector--collapsed"}`}
      aria-label="Selection inspector"
    >
      <header className="inspector__top">
        <button
          type="button"
          className="rail-toggle"
          onClick={onToggle}
          aria-expanded={expanded}
          aria-controls="cockpit-inspector"
          aria-label={expanded ? "Collapse inspector" : "Expand inspector"}
          title={expanded ? "Collapse inspector" : "Expand inspector"}
        >
          {expanded ? (
            <CaretDoubleRight aria-hidden="true" />
          ) : (
            <CaretDoubleLeft aria-hidden="true" />
          )}
        </button>
        <span>Inspector</span>
      </header>

      {!expanded ? (
        <button
          type="button"
          className="inspector-peek"
          onClick={onToggle}
          aria-label="Expand selection inspector"
        >
          <span className={`status-beacon status-beacon--${entity?.status ?? "empty"}`} />
          <span>{entity?.title ?? "No selection"}</span>
          <small>{artifacts.length}</small>
        </button>
      ) : (
        <>
          <div className="inspector__identity">
            {entity ? (
              <>
                <span>{entity.eyebrow}</span>
                <h2>{entity.title}</h2>
                <p>{entity.summary}</p>
                <div className="inspector__status">
                  <span className={`status-beacon status-beacon--${entity.status}`} />
                  {entity.status.replaceAll("_", " ")}
                </div>
              </>
            ) : (
              <>
                <span>Nothing selected</span>
                <h2>Choose an observed entity</h2>
                <p>Select a pass, task, run, receipt, artifact, check, or issue.</p>
              </>
            )}
          </div>

          <div className="inspector-tabs" role="tablist" aria-label="Inspector views">
            {TABS.map((item) => {
              const Icon = item.icon;
              return (
                <button
                  type="button"
                  key={item.id}
                  id={`inspector-tab-${item.id}`}
                  role="tab"
                  aria-selected={tab === item.id}
                  aria-controls="inspector-tabpanel"
                  className={tab === item.id ? "is-active" : ""}
                  onClick={() => onTabChange(item.id)}
                >
                  <Icon aria-hidden="true" />
                  {item.label}
                </button>
              );
            })}
          </div>

          <div
            id="inspector-tabpanel"
            className="inspector__content"
            role="tabpanel"
            aria-labelledby={`inspector-tab-${tab}`}
            tabIndex={0}
          >
            <AnimatePresence mode="wait" initial={false}>
              <motion.div
                key={`${selected?.kind ?? "none"}:${selected?.id ?? "none"}:${tab}`}
                initial={reduceMotion ? false : { opacity: 0, x: 8 }}
                animate={{ opacity: 1, x: 0 }}
                exit={reduceMotion ? undefined : { opacity: 0, x: -5 }}
                transition={{ duration: 0.16 }}
              >
                {tab === "details" ? (
                  entity ? (
                    <dl className="detail-list">
                      {entity.details.map((detail) => (
                        <div key={detail.label}>
                          <dt>{detail.label}</dt>
                          <dd>{detail.value}</dd>
                        </div>
                      ))}
                    </dl>
                  ) : (
                    <InspectorEmpty copy="Details appear after an entity is selected." />
                  )
                ) : null}

                {tab === "proof" ? (
                  artifacts.length > 0 ? (
                    <div className="inspector-proof-list">
                      {artifacts.map((artifact) => (
                        <button
                          type="button"
                          key={artifact.id}
                          onClick={() => onOpenArtifact(artifact)}
                        >
                          <FileCode aria-hidden="true" />
                          <span>
                            <strong>{artifact.label}</strong>
                            <small>{artifact.path}</small>
                            <code>{artifact.sha256.slice(0, 12)}</code>
                          </span>
                          <ArrowSquareOut aria-hidden="true" />
                        </button>
                      ))}
                    </div>
                  ) : (
                    <InspectorEmpty copy="No hash-bound proof is attached to this entity." />
                  )
                ) : null}

                {tab === "history" ? (
                  history.length > 0 ? (
                    <ol className="inspector-history">
                      {history.map((signal) => (
                        <li key={signal.id}>
                          <span
                            className={`status-beacon status-beacon--${signal.severity}`}
                            aria-hidden="true"
                          />
                          <div>
                            <strong>{signal.summary}</strong>
                            <small>
                              {signal.kind} /{" "}
                              {signal.occurredAt ? (
                                <time dateTime={signal.occurredAt}>
                                  {new Date(signal.occurredAt).toLocaleString()}
                                </time>
                              ) : (
                                "time unavailable"
                              )}
                            </small>
                          </div>
                        </li>
                      ))}
                    </ol>
                  ) : (
                    <InspectorEmpty copy="No signals reference this entity in the current snapshot." />
                  )
                ) : null}
              </motion.div>
            </AnimatePresence>
          </div>
        </>
      )}
    </aside>
  );
}

function InspectorEmpty({ copy }: { copy: string }) {
  return (
    <div className="inspector-empty">
      <Info aria-hidden="true" />
      <p>{copy}</p>
    </div>
  );
}
