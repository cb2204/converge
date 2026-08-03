import { useEffect, useMemo, useRef } from "react";
import {
  Background,
  BackgroundVariant,
  Controls,
  Handle,
  Position,
  ReactFlow,
  ReactFlowProvider,
  useNodesState,
  type Edge,
  type Node,
  type NodeProps,
} from "@xyflow/react";
import { CheckCircle, LockKey, RocketLaunch } from "@phosphor-icons/react";
import type { EntityRef, WorkTask } from "../types";

type WorkFlowNode = Node<
  {
    task: WorkTask;
    selected: boolean;
    frontier: boolean;
  },
  "work"
>;

interface WorkGraphProps {
  tasks: WorkTask[];
  frontierIds: string[];
  selected: EntityRef | null;
  onSelect: (selection: EntityRef) => void;
}

function WorkNode({ data }: NodeProps<WorkFlowNode>) {
  const { task, selected, frontier } = data;
  return (
    <div
      className={`work-node work-node--${task.status} ${
        selected ? "work-node--selected" : ""
      }`}
    >
      <Handle
        type="target"
        position={Position.Left}
        className="work-node__handle"
        isConnectable={false}
      />
      <div className="work-node__meta">
        <span>{task.id}</span>
        <span>{String(task.priority ?? "No priority")}</span>
      </div>
      <strong>{task.title}</strong>
      <div className="work-node__state">
        {task.status === "done" ? (
          <CheckCircle weight="fill" aria-hidden="true" />
        ) : frontier ? (
          <RocketLaunch weight="fill" aria-hidden="true" />
        ) : (
          <LockKey weight="fill" aria-hidden="true" />
        )}
        {frontier ? "frontier" : task.status.replaceAll("_", " ")}
      </div>
      <Handle
        type="source"
        position={Position.Right}
        className="work-node__handle"
        isConnectable={false}
      />
    </div>
  );
}

const nodeTypes = { work: WorkNode };

function depthFor(
  task: WorkTask,
  byId: ReadonlyMap<string, WorkTask>,
  visiting = new Set<string>(),
): number {
  if (task.dependsOn.length === 0 || visiting.has(task.id)) return 0;
  const nextVisiting = new Set(visiting);
  nextVisiting.add(task.id);
  return (
    1 +
    Math.max(
      0,
      ...task.dependsOn.map((id) => {
        const dependency = byId.get(id);
        return dependency ? depthFor(dependency, byId, nextVisiting) : 0;
      }),
    )
  );
}

function buildNodes(
  tasks: WorkTask[],
  frontier: ReadonlySet<string>,
  selected: EntityRef | null,
): WorkFlowNode[] {
  const byId = new Map(tasks.map((task) => [task.id, task] as const));
  const rowsByDepth = new Map<number, number>();
  return tasks.map((task) => {
    const depth = depthFor(task, byId);
    const row = rowsByDepth.get(depth) ?? 0;
    rowsByDepth.set(depth, row + 1);
    return {
      id: task.id,
      type: "work",
      position: { x: depth * 278 + 54, y: row * 164 + 76 },
      data: {
        task,
        frontier: frontier.has(task.id),
        selected: selected?.kind === "task" && selected.id === task.id,
      },
      draggable: true,
      focusable: true,
      ariaRole: "button",
      ariaLabel: `${task.id}, ${task.title}, ${task.status}`,
      zIndex: selected?.kind === "task" && selected.id === task.id ? 2 : 1,
    };
  });
}

function Graph(props: WorkGraphProps) {
  const didFit = useRef(false);
  const frontier = useMemo(
    () => new Set(props.frontierIds),
    [props.frontierIds],
  );
  const [nodes, setNodes, onNodesChange] = useNodesState<WorkFlowNode>(
    buildNodes(props.tasks, frontier, props.selected),
  );

  useEffect(() => {
    setNodes((current) => {
      const positions = new Map(
        current.map((node) => [node.id, node.position] as const),
      );
      return buildNodes(props.tasks, frontier, props.selected).map((node) => ({
        ...node,
        position: positions.get(node.id) ?? node.position,
      }));
    });
  }, [frontier, props.selected, props.tasks, setNodes]);

  const edges = useMemo<Edge[]>(
    () =>
      props.tasks.flatMap((task) =>
        task.dependsOn.map((dependency) => ({
          id: `${dependency}-${task.id}`,
          source: dependency,
          target: task.id,
          type: "smoothstep",
          animated: frontier.has(task.id),
          className: frontier.has(task.id)
            ? "work-edge work-edge--frontier"
            : "work-edge",
          selectable: false,
          focusable: false,
        })),
      ),
    [frontier, props.tasks],
  );

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      nodeTypes={nodeTypes}
      onNodesChange={onNodesChange}
      onNodeClick={(_, node) =>
        props.onSelect({ kind: "task", id: node.id })
      }
      onInit={(instance) => {
        if (!didFit.current) {
          void instance.fitView({
            padding: 0.18,
            minZoom: 0.45,
            maxZoom: 1,
            duration: 360,
          });
          didFit.current = true;
        }
      }}
      nodesConnectable={false}
      minZoom={0.35}
      maxZoom={1.5}
      panOnScroll
      fitView
      proOptions={{ hideAttribution: true }}
      colorMode="dark"
      aria-label="Work dependency graph"
    >
      <Background
        variant={BackgroundVariant.Dots}
        gap={28}
        size={1}
        color="rgba(162, 177, 191, 0.11)"
      />
      <Controls
        className="lineage-controls"
        showInteractive={false}
        orientation="horizontal"
        aria-label="Work graph viewport controls"
      />
    </ReactFlow>
  );
}

export function WorkGraph(props: WorkGraphProps) {
  return (
    <div className="work-graph">
      <ReactFlowProvider>
        <Graph {...props} />
      </ReactFlowProvider>
    </div>
  );
}
