import {
  BaseEdge,
  EdgeLabelRenderer,
  getBezierPath,
  type Edge,
  type EdgeProps,
} from "@xyflow/react";

export type CinematicFlowEdge = Edge<
  {
    kind: "complete" | "active" | "waiting" | "optional" | "return";
    label?: string;
  },
  "cinematic"
>;

export function CinematicEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
}: EdgeProps<CinematicFlowEdge>) {
  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
    curvature: data?.kind === "return" ? 0.58 : 0.28,
  });
  const kind = data?.kind ?? "waiting";

  return (
    <>
      <BaseEdge
        id={id}
        path={edgePath}
        className={`cinematic-edge cinematic-edge--${kind}`}
      />
      {kind === "complete" || kind === "active" ? (
        <path
          d={edgePath}
          className={`cinematic-edge__flow cinematic-edge__flow--${kind}`}
          aria-hidden="true"
        />
      ) : null}
      {data?.label ? (
        <EdgeLabelRenderer>
          <span
            className="cinematic-edge__label"
            style={{
              transform: `translate(-50%, -50%) translate(${labelX}px, ${labelY}px)`,
            }}
          >
            {data.label}
          </span>
        </EdgeLabelRenderer>
      ) : null}
    </>
  );
}
