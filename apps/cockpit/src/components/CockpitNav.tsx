import {
  CaretDoubleLeft,
  CaretDoubleRight,
  FlowArrow,
  Heartbeat,
  Kanban,
  Pulse,
  SealCheck,
} from "@phosphor-icons/react";
import type { ComponentType } from "react";
import type { CockpitSurface, WorkspaceSnapshot } from "../types";

interface CockpitNavProps {
  snapshot: WorkspaceSnapshot;
  surface: CockpitSurface;
  expanded: boolean;
  onToggle: () => void;
  onSelect: (surface: CockpitSurface) => void;
}

interface NavItem {
  id: CockpitSurface;
  label: string;
  description: string;
  icon: ComponentType<{ size?: number; weight?: "regular" | "bold" | "fill" }>;
  count: (snapshot: WorkspaceSnapshot) => number | null;
}

const NAV_ITEMS: NavItem[] = [
  {
    id: "journey",
    label: "Journey",
    description: "Method and gates",
    icon: FlowArrow,
    count: (snapshot) => snapshot.method.passes.length,
  },
  {
    id: "work",
    label: "Work",
    description: "Tasks and frontier",
    icon: Kanban,
    count: (snapshot) => snapshot.work.stats.total,
  },
  {
    id: "runs",
    label: "Runs",
    description: "Attempts and outcomes",
    icon: Pulse,
    count: (snapshot) =>
      snapshot.execution.availability === "available"
        ? snapshot.execution.runs.length
        : null,
  },
  {
    id: "proof",
    label: "Proof",
    description: "Artifacts and receipts",
    icon: SealCheck,
    count: (snapshot) => snapshot.artifacts.length,
  },
  {
    id: "health",
    label: "Health",
    description: "Operational checks",
    icon: Heartbeat,
    count: (snapshot) => snapshot.health.checks.length,
  },
];

export function CockpitNav({
  snapshot,
  surface,
  expanded,
  onToggle,
  onSelect,
}: CockpitNavProps) {
  return (
    <aside
      id="cockpit-navigation"
      className={`cockpit-nav ${expanded ? "cockpit-nav--expanded" : "cockpit-nav--collapsed"}`}
      aria-label="Cockpit views"
    >
      <div className="cockpit-nav__heading">
        <span>Observe</span>
        <button
          type="button"
          className="rail-toggle"
          onClick={onToggle}
          aria-expanded={expanded}
          aria-controls="cockpit-navigation"
          aria-label={expanded ? "Collapse navigation" : "Expand navigation"}
          title={expanded ? "Collapse navigation" : "Expand navigation"}
        >
          {expanded ? (
            <CaretDoubleLeft aria-hidden="true" />
          ) : (
            <CaretDoubleRight aria-hidden="true" />
          )}
        </button>
      </div>

      <nav className="cockpit-nav__items">
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const count = item.count(snapshot);
          const active = item.id === surface;
          return (
            <button
              type="button"
              key={item.id}
              className={`nav-item ${active ? "nav-item--active" : ""}`}
              onClick={() => onSelect(item.id)}
              aria-current={active ? "page" : undefined}
              title={expanded ? undefined : item.label}
            >
              <span className="nav-item__icon">
                <Icon size={20} weight={active ? "fill" : "regular"} />
              </span>
              <span className="nav-item__copy">
                <strong>{item.label}</strong>
                <small>{item.description}</small>
              </span>
              {count !== null ? <span className="nav-item__count">{count}</span> : null}
            </button>
          );
        })}
      </nav>

      <div className="cockpit-nav__status">
        <span
          className={`health-beacon health-beacon--${snapshot.health.overall}`}
          aria-hidden="true"
        />
        <span>
          <strong>{snapshot.health.overall}</strong>
          <small>
            {snapshot.issues.length} issue{snapshot.issues.length === 1 ? "" : "s"}
          </small>
        </span>
      </div>
    </aside>
  );
}
