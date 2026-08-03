import { useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  GitCommit,
  ShieldCheck,
  Sparkle,
  Warning,
  X,
} from "@phosphor-icons/react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import type { ActivityItem } from "../types";

interface ActivityRailProps {
  items: ActivityItem[];
  selectedPassId: string;
  onSelectPass?: (passId: string) => void;
}

const SOURCE_COPY: Record<
  ActivityItem["source"],
  { label: string; description: string }
> = {
  gate: {
    label: "CLI gate",
    description: "A deterministic result emitted by a Converge gate.",
  },
  git: {
    label: "Repository",
    description: "A signal derived from the observed Git workspace.",
  },
  artifact: {
    label: "Artifact",
    description: "A signal attached to a repository evidence artifact.",
  },
  fixture: {
    label: "Replay fixture",
    description: "A captured signal replayed without a live workspace claim.",
  },
};

function ActivityIcon({ tone }: { tone: ActivityItem["tone"] }) {
  if (tone === "proven") {
    return <ShieldCheck weight="fill" aria-hidden="true" />;
  }
  if (tone === "attention") {
    return <Warning weight="fill" aria-hidden="true" />;
  }
  if (tone === "active") {
    return <Sparkle weight="fill" aria-hidden="true" />;
  }
  return <GitCommit weight="bold" aria-hidden="true" />;
}

export function ActivityRail({
  items,
  selectedPassId,
  onSelectPass,
}: ActivityRailProps) {
  const reduceMotion = useReducedMotion();
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
  const selectedItem = useMemo(
    () => items.find((item) => item.id === selectedItemId) ?? null,
    [items, selectedItemId],
  );
  const timeFormatter = new Intl.DateTimeFormat("en", {
    hour: "2-digit",
    minute: "2-digit",
  });
  const detailFormatter = new Intl.DateTimeFormat("en", {
    dateStyle: "medium",
    timeStyle: "medium",
  });

  useEffect(() => {
    if (!selectedItem) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSelectedItemId(null);
    };
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [selectedItem]);

  useEffect(() => {
    if (selectedItem?.passId && selectedItem.passId !== selectedPassId) {
      setSelectedItemId(null);
    }
  }, [selectedItem, selectedPassId]);

  function inspectItem(item: ActivityItem) {
    setSelectedItemId(item.id);
    if (item.passId) onSelectPass?.(item.passId);
  }

  return (
    <section className="activity-rail" aria-labelledby="activity-title">
      <div className="activity-rail__label">
        <span id="activity-title">Evidence stream</span>
        <span>{items.length} signals · click to inspect</span>
      </div>

      <div className="activity-rail__track" aria-label="Workspace evidence signals">
        {items.length === 0 ? (
          <p className="activity-rail__empty">
            No evidence signals have been emitted for this workspace.
          </p>
        ) : (
          items.map((item, index) => (
            <motion.button
              type="button"
              key={item.id}
              className={`activity-item activity-item--${item.tone} ${
                selectedItemId === item.id ? "activity-item--selected" : ""
              }`}
              initial={reduceMotion ? false : { opacity: 0, x: 10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: reduceMotion ? 0 : index * 0.035 }}
              onClick={() => inspectItem(item)}
              aria-pressed={selectedItemId === item.id}
            >
              <span className="activity-item__icon">
                <ActivityIcon tone={item.tone} />
              </span>
              <span className="activity-item__copy">
                <strong>{item.label}</strong>
                <span>{item.detail}</span>
                <small>{SOURCE_COPY[item.source].label}</small>
              </span>
              <time dateTime={item.time}>
                {timeFormatter.format(new Date(item.time))}
              </time>
            </motion.button>
          ))
        )}
      </div>

      <AnimatePresence>
        {selectedItem ? (
          <motion.aside
            className="activity-detail"
            role="dialog"
            aria-modal="false"
            aria-labelledby="activity-detail-title"
            initial={reduceMotion ? false : { opacity: 0, y: 10, scale: 0.985 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? undefined : { opacity: 0, y: 7, scale: 0.99 }}
            transition={{ duration: 0.18 }}
          >
            <header>
              <span>{SOURCE_COPY[selectedItem.source].label}</span>
              <button
                type="button"
                onClick={() => setSelectedItemId(null)}
                aria-label="Close signal details"
              >
                <X aria-hidden="true" />
              </button>
            </header>
            <strong id="activity-detail-title">{selectedItem.label}</strong>
            <p>{selectedItem.detail}</p>
            <div className="activity-detail__meta">
              <span>{SOURCE_COPY[selectedItem.source].description}</span>
              <time dateTime={selectedItem.time}>
                {detailFormatter.format(new Date(selectedItem.time))}
              </time>
            </div>
            {selectedItem.passId ? (
              <div className="activity-detail__link">
                <ArrowRight aria-hidden="true" />
                Inspector synchronized to{" "}
                {selectedItem.passId.replace("pass-", "Pass ")}
              </div>
            ) : null}
          </motion.aside>
        ) : null}
      </AnimatePresence>
    </section>
  );
}
