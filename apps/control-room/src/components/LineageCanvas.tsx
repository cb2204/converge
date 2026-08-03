import { useCallback, useEffect, useMemo, useRef } from "react";
import {
  Background,
  BackgroundVariant,
  ControlButton,
  Controls,
  Panel,
  ReactFlow,
  ReactFlowProvider,
  Position,
  useNodesState,
  useReactFlow,
  type Edge,
  type FitViewOptions,
} from "@xyflow/react";
import {
  ArrowsOutCardinal,
  ArrowsOutSimple,
  CursorClick,
  SquaresFour,
} from "@phosphor-icons/react";
import type { PassState, WorkspaceSnapshot } from "../types";
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

const FIT_OPTIONS: FitViewOptions = {
  padding: 0.12,
  minZoom: 0.34,
  maxZoom: 1.08,
  duration: 420,
};

function arrangedPosition(order: number) {
  if (order <= 4) {
    return { x: order * 270, y: 36 };
  }

  if (order === 6) {
    return { x: 810, y: 454 };
  }

  return {
    x: order === 5 ? 1080 : order === 7 ? 540 : 270,
    y: 316,
  };
}

function buildNodes(
  passes: PassState[],
  selectedPassId: string,
): PassFlowNode[] {
  return passes.map((pass) => {
    const isLowerReturn = pass.order >= 5;
    return {
      id: pass.id,
      type: "pass",
      position: arrangedPosition(pass.order),
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
      draggable: true,
      selectable: true,
      focusable: true,
      ariaRole: "button",
      domAttributes: {
        "aria-pressed": pass.id === selectedPassId,
        "aria-current": pass.status === "active" ? "step" : undefined,
      },
      zIndex: pass.id === selectedPassId ? 5 : 1,
      ariaLabel: `${pass.label}, ${pass.status}. Click to inspect or drag to reposition.`,
    };
  });
}

function Flow({
  snapshot,
  selectedPassId,
  onSelectPass,
}: LineageCanvasProps) {
  const hasFit = useRef(false);
  const [nodes, setNodes, onNodesChange] = useNodesState<PassFlowNode>(
    buildNodes(snapshot.method.passes, selectedPassId),
  );
  const { fitView } = useReactFlow<PassFlowNode, CinematicFlowEdge>();

  useEffect(() => {
    setNodes((current) => {
      const positions = new Map(
        current.map((node) => [node.id, node.position] as const),
      );
      return buildNodes(snapshot.method.passes, selectedPassId).map((node) => ({
        ...node,
        position: positions.get(node.id) ?? node.position,
      }));
    });
  }, [selectedPassId, setNodes, snapshot.method.passes]);

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

  const arrangeNodes = useCallback(() => {
    setNodes((current) =>
      current.map((node) => ({
        ...node,
        position: arrangedPosition(node.data.pass.order),
      })),
    );
    window.requestAnimationFrame(() => {
      void fitView(FIT_OPTIONS);
    });
  }, [fitView, setNodes]);

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      nodeTypes={nodeTypes}
      edgeTypes={edgeTypes}
      onNodesChange={onNodesChange}
      onNodeClick={(_, node) => onSelectPass(node.id)}
      onSelectionChange={({ nodes: selectedNodes }) => {
        if (selectedNodes.length === 1) {
          onSelectPass(selectedNodes[0].id);
        }
      }}
      onInit={(instance) => {
        if (!hasFit.current) {
          void instance.fitView(FIT_OPTIONS);
          hasFit.current = true;
        }
      }}
      minZoom={0.3}
      maxZoom={1.6}
      nodesDraggable
      nodesConnectable={false}
      elementsSelectable
      panOnScroll
      panOnDrag
      zoomOnScroll
      zoomOnPinch
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
        orientation="horizontal"
        fitViewOptions={FIT_OPTIONS}
        aria-label="Lineage viewport controls"
      >
        <ControlButton
          onClick={arrangeNodes}
          aria-label="Arrange nodes"
          title="Arrange nodes"
        >
          <SquaresFour aria-hidden="true" />
        </ControlButton>
      </Controls>
      <Panel position="top-left" className="canvas-hint">
        <CursorClick size={16} aria-hidden="true" />
        Click a pass to inspect its proof
      </Panel>
      <Panel position="bottom-right" className="canvas-hint canvas-hint--quiet">
        <ArrowsOutCardinal size={16} aria-hidden="true" />
        Drag nodes · pan canvas
      </Panel>
      <Panel position="top-right" className="canvas-hint canvas-hint--quiet">
        <ArrowsOutSimple size={16} aria-hidden="true" />
        Zoom + / − · fit
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
