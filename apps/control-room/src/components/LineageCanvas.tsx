import { useMemo, useRef } from "react";
import {
  Background,
  BackgroundVariant,
  Controls,
  Panel,
  ReactFlow,
  ReactFlowProvider,
  Position,
  type Edge,
} from "@xyflow/react";
import { ArrowsOutSimple, CursorClick } from "@phosphor-icons/react";
import type { WorkspaceSnapshot } from "../types";
import { CinematicEdge, type CinematicFlowEdge } from "./CinematicEdge";
import { PassNode, type PassFlowNode } from "./PassNode";
import { MobilePassList } from "./MobilePassList";

interface LineageCanvasProps {
  snapshot: WorkspaceSnapshot;
  selectedPassId: string;
  onSelectPass: (passId: string) => void;
}

const nodeTypes = {
  pass: PassNode,
};

const edgeTypes = {
  cinematic: CinematicEdge,
};

function Flow({
  snapshot,
  selectedPassId,
  onSelectPass,
}: LineageCanvasProps) {
  const hasFit = useRef(false);

  const nodes = useMemo<PassFlowNode[]>(
    () =>
      snapshot.method.passes.map((pass) => {
        const isLowerReturn = pass.order >= 5;
        return {
          id: pass.id,
          type: "pass",
          position: pass.position,
          sourcePosition:
            pass.order === 4
              ? Position.Bottom
              : isLowerReturn
                ? Position.Left
                : Position.Right,
          targetPosition:
            pass.order === 5
              ? Position.Top
              : isLowerReturn
                ? Position.Right
                : Position.Left,
          data: {
            pass,
            isSelected: pass.id === selectedPassId,
          },
          draggable: false,
          selectable: true,
          focusable: true,
          zIndex: pass.id === selectedPassId ? 5 : 1,
          ariaLabel: `${pass.label}, ${pass.status}`,
        };
      }),
    [snapshot.method.passes, selectedPassId],
  );

  const edges = useMemo<CinematicFlowEdge[]>(
    () =>
      snapshot.method.edges.map((edge) => ({
        id: edge.id,
        source: edge.source,
        target: edge.target,
        type: "cinematic",
        data: {
          kind: edge.kind,
          label: edge.label,
        },
        selectable: false,
        focusable: false,
      })) as Edge[] as CinematicFlowEdge[],
    [snapshot.method.edges],
  );

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      nodeTypes={nodeTypes}
      edgeTypes={edgeTypes}
      onNodeClick={(_, node) => onSelectPass(node.id)}
      onInit={(instance) => {
        if (!hasFit.current) {
          void instance.fitView({ padding: 0.12, duration: 460 });
          hasFit.current = true;
        }
      }}
      fitView
      fitViewOptions={{ padding: 0.14, minZoom: 0.48, maxZoom: 1.05 }}
      minZoom={0.4}
      maxZoom={1.35}
      nodesDraggable={false}
      nodesConnectable={false}
      elementsSelectable
      panOnScroll
      panOnDrag
      zoomOnDoubleClick={false}
      proOptions={{ hideAttribution: true }}
      colorMode="dark"
      aria-label="Converge method lineage"
    >
      <Background
        variant={BackgroundVariant.Dots}
        gap={29}
        size={1}
        color="rgba(176, 205, 192, 0.13)"
      />
      <Controls
        className="lineage-controls"
        showInteractive={false}
        aria-label="Lineage viewport controls"
      />
      <Panel position="top-left" className="canvas-hint">
        <CursorClick size={16} aria-hidden="true" />
        Select a pass to inspect its proof
      </Panel>
      <Panel position="bottom-right" className="canvas-hint canvas-hint--quiet">
        <ArrowsOutSimple size={16} aria-hidden="true" />
        Pan and zoom
      </Panel>
    </ReactFlow>
  );
}

export function LineageCanvas(props: LineageCanvasProps) {
  return (
    <section className="lineage-surface" aria-label="Method lineage">
      <div className="lineage-surface__desktop">
        <ReactFlowProvider>
          <Flow {...props} />
        </ReactFlowProvider>
      </div>
      <MobilePassList
        passes={props.snapshot.method.passes}
        selectedPassId={props.selectedPassId}
        onSelectPass={props.onSelectPass}
      />
    </section>
  );
}
