import { GitCommit, ShieldCheck, Sparkle, Warning } from "@phosphor-icons/react";
import { motion, useReducedMotion } from "motion/react";
import type { ActivityItem } from "../types";

interface ActivityRailProps {
  items: ActivityItem[];
}

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

export function ActivityRail({ items }: ActivityRailProps) {
  const reduceMotion = useReducedMotion();
  const formatter = new Intl.DateTimeFormat("en", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <section className="activity-rail" aria-labelledby="activity-title">
      <div className="activity-rail__label">
        <span id="activity-title">Evidence stream</span>
        <span>{items.length} signals</span>
      </div>
      <div className="activity-rail__track" tabIndex={0}>
        {items.map((item, index) => (
          <motion.article
            key={item.id}
            className={`activity-item activity-item--${item.tone}`}
            initial={reduceMotion ? false : { opacity: 0, x: 10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: reduceMotion ? 0 : index * 0.035 }}
          >
            <span className="activity-item__icon">
              <ActivityIcon tone={item.tone} />
            </span>
              <span className="activity-item__copy">
                <strong>{item.label}</strong>
                <span>{item.detail}</span>
                <small>{item.source}</small>
              </span>
              <time dateTime={item.time}>
                {formatter.format(new Date(item.time))}
              </time>
          </motion.article>
        ))}
      </div>
    </section>
  );
}
