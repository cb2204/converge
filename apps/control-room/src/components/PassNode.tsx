import { Handle, Position, type Node, type NodeProps } from "@xyflow/react";
import { motion, useReducedMotion } from "motion/react";
import { FileText, ShieldCheck } from "@phosphor-icons/react";
import type { PassState } from "../types";
import { StatusGlyph } from "./StatusGlyph";

export type PassFlowNode = Node<
  {
    pass: PassState;
    isSelected: boolean;
  },
  "pass"
>;

export function PassNode({
  data,
  sourcePosition = Position.Right,
  targetPosition = Position.Left,
}: NodeProps<PassFlowNode>) {
  const reduceMotion = useReducedMotion();
  const { pass, isSelected } = data;

  return (
    <motion.div
      layout={!reduceMotion}
      className={`pass-node pass-node--${pass.status} ${
        isSelected ? "pass-node--selected" : ""
      }`}
      transition={{
        type: "spring",
        stiffness: 310,
        damping: 30,
        mass: 0.8,
      }}
      aria-label={`${pass.label}. ${pass.status}. ${pass.gate.token ?? "No gate token yet"}`}
    >
      <Handle
        type="target"
        position={targetPosition}
        className="pass-node__handle"
        isConnectable={false}
      />
      <div className="pass-node__header">
        <span className="pass-node__order">{pass.order}</span>
        <span className="pass-node__title">{pass.shortLabel}</span>
        <span className="pass-node__status" aria-label={pass.status}>
          <StatusGlyph status={pass.status} />
        </span>
      </div>

      <p className="pass-node__summary">{pass.summary}</p>

      <div className="pass-node__footer">
        <span>
          <FileText size={14} aria-hidden="true" />
          {pass.evidence.length} evidence
        </span>
        {pass.blockerCount > 0 ? (
          <span className="pass-node__blockers">
            <ShieldCheck size={14} aria-hidden="true" />
            {pass.blockerCount} flagged
          </span>
        ) : (
          <span className="pass-node__token">
            {pass.gate.verdict ?? (pass.optional ? "OPT-IN" : "WAITING")}
          </span>
        )}
      </div>

      {isSelected ? (
        <motion.div
          className="pass-node__expanded"
          initial={reduceMotion ? false : { opacity: 0, y: 5 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: reduceMotion ? 0 : 0.08, duration: 0.2 }}
        >
          <span>{pass.gate.command}</span>
          <strong>{pass.gate.token ?? "NO_TOKEN_YET"}</strong>
        </motion.div>
      ) : null}

      <Handle
        type="source"
        position={sourcePosition}
        className="pass-node__handle"
        isConnectable={false}
      />
    </motion.div>
  );
}
