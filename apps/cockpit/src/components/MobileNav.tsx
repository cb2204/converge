import {
  FlowArrow,
  Heartbeat,
  Kanban,
  Pulse,
  SealCheck,
} from "@phosphor-icons/react";
import type { CockpitSurface } from "../types";

interface MobileNavProps {
  surface: CockpitSurface;
  onSelect: (surface: CockpitSurface) => void;
}

const items = [
  { id: "journey", label: "Journey", icon: FlowArrow },
  { id: "work", label: "Work", icon: Kanban },
  { id: "runs", label: "Runs", icon: Pulse },
  { id: "proof", label: "Proof", icon: SealCheck },
  { id: "health", label: "Health", icon: Heartbeat },
] as const;

export function MobileNav({ surface, onSelect }: MobileNavProps) {
  return (
    <nav className="mobile-nav" aria-label="Cockpit views">
      {items.map((item) => {
        const Icon = item.icon;
        const active = surface === item.id;
        return (
          <button
            type="button"
            key={item.id}
            className={active ? "is-active" : ""}
            onClick={() => onSelect(item.id)}
            aria-current={active ? "page" : undefined}
          >
            <Icon weight={active ? "fill" : "regular"} aria-hidden="true" />
            <span>{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
