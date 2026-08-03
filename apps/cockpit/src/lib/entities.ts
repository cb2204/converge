import type {
  ArtifactRef,
  EntityRef,
  WorkspaceSnapshot,
} from "../types";

export interface ResolvedEntity {
  ref: EntityRef;
  eyebrow: string;
  title: string;
  summary: string;
  status: string;
  artifactIds: string[];
  details: Array<{ label: string; value: string }>;
}

export function sameEntity(left: EntityRef | null, right: EntityRef | null) {
  return left?.kind === right?.kind && left?.id === right?.id;
}

export function entityKey(entity: EntityRef) {
  return `${entity.kind}:${entity.id}`;
}

export function artifactsByIds(
  snapshot: WorkspaceSnapshot,
  artifactIds: readonly string[],
) {
  const ids = new Set(artifactIds);
  return snapshot.artifacts.filter((artifact) => ids.has(artifact.id));
}

export function relatedSignals(snapshot: WorkspaceSnapshot, ref: EntityRef) {
  return snapshot.signals
    .filter(
      (signal) =>
        signal.entity?.kind === ref.kind && signal.entity.id === ref.id,
    )
    .sort((left, right) => {
      const rightTime = right.occurredAt ? Date.parse(right.occurredAt) : 0;
      const leftTime = left.occurredAt ? Date.parse(left.occurredAt) : 0;
      return rightTime - leftTime;
    });
}

export function resolveEntity(
  snapshot: WorkspaceSnapshot,
  ref: EntityRef | null,
): ResolvedEntity | null {
  if (!ref) return null;

  if (ref.kind === "pass") {
    const pass = snapshot.method.passes.find((item) => item.id === ref.id);
    if (!pass) return null;
    return {
      ref,
      eyebrow: `Pass ${pass.order}`,
      title: pass.label,
      summary: pass.summary,
      status: pass.status,
      artifactIds: pass.artifactIds,
      details: [
        { label: "Gate", value: pass.gate.verdict ?? "Not evaluated" },
        { label: "Token", value: pass.gate.token ?? "No token" },
        {
          label: "Command",
          value: pass.gate.command ?? "No command recorded",
        },
        { label: "Optional", value: pass.optional ? "Yes" : "No" },
      ],
    };
  }

  if (ref.kind === "task") {
    const task = snapshot.work.tasks.find((item) => item.id === ref.id);
    if (!task) return null;
    return {
      ref,
      eyebrow: task.id,
      title: task.title,
      summary:
        task.blockingReasons[0] ??
        (task.dispatchable
          ? "Signed off and available at the current frontier."
          : "Observed in the canonical work graph."),
      status: task.status,
      artifactIds: task.artifactIds,
      details: [
        { label: "Priority", value: String(task.priority ?? "Not set") },
        { label: "Effort", value: String(task.effort ?? "Not set") },
        { label: "Agent", value: task.agent ?? "Unassigned" },
        {
          label: "Budget",
          value:
            task.budgetIterations === null
              ? "Not recorded"
              : `${task.budgetIterations} iterations`,
        },
        {
          label: "Dependencies",
          value: task.dependsOn.length > 0 ? task.dependsOn.join(", ") : "None",
        },
        { label: "Signed off", value: task.signedOff ? "Yes" : "No" },
        { label: "Dispatchable", value: task.dispatchable ? "Yes" : "No" },
      ],
    };
  }

  if (ref.kind === "run") {
    const run = snapshot.execution.runs.find((item) => item.id === ref.id);
    if (!run) return null;
    return {
      ref,
      eyebrow:
        run.attempt === null ? "Attempt not recorded" : `Attempt ${run.attempt}`,
      title: run.id,
      summary: `Observed execution for ${run.taskId}.`,
      status: run.state,
      artifactIds: run.artifactIds,
      details: [
        { label: "Task", value: run.taskId },
        {
          label: "Attempt",
          value: run.attempt === null ? "Not recorded" : String(run.attempt),
        },
        {
          label: "Budget",
          value:
            run.budgetIterations === null
              ? "Not recorded"
              : `${run.budgetIterations} iterations`,
        },
        {
          label: "Profile",
          value: run.profileArtifactId || "Not available",
        },
        {
          label: "Primary runtime",
          value: run.runtime.primaryRuntime ?? "Not recorded",
        },
        {
          label: "Assurance",
          value: run.runtime.assurance ?? "Not recorded",
        },
        {
          label: "Terminal result",
          value: run.terminal?.result ?? "Still open",
        },
      ],
    };
  }

  if (ref.kind === "receipt") {
    const receipt = snapshot.receipts.items.find((item) => item.id === ref.id);
    if (!receipt) return null;
    return {
      ref,
      eyebrow: "Settlement receipt",
      title: receipt.id,
      summary: `Durable result for ${receipt.taskId}.`,
      status: receipt.integrity,
      artifactIds: receipt.artifactIds,
      details: [
        { label: "Task", value: receipt.taskId },
        { label: "Result", value: receipt.result },
        { label: "Integrity", value: receipt.integrity },
        { label: "Freshness", value: receipt.freshness },
        {
          label: "Generated by",
          value: receipt.provenance.generatedBy ?? "Not recorded",
        },
        {
          label: "Post hoc",
          value: receipt.provenance.postHoc ? "Yes" : "No",
        },
        {
          label: "Recorded",
          value: receipt.recordedAt
            ? new Date(receipt.recordedAt).toLocaleString()
            : "Not recorded",
        },
      ],
    };
  }

  if (ref.kind === "health") {
    const check = snapshot.health.checks.find((item) => item.id === ref.id);
    if (!check) return null;
    return {
      ref,
      eyebrow: check.required ? "Required check" : "Optional check",
      title: check.component,
      summary: check.summary,
      status: check.status,
      artifactIds: check.artifactIds,
      details: [
        { label: "Check ID", value: check.id },
        { label: "Required", value: check.required ? "Yes" : "No" },
        { label: "Overall health", value: snapshot.health.overall },
      ],
    };
  }

  if (ref.kind === "signal") {
    const signal = snapshot.signals.find((item) => item.id === ref.id);
    if (!signal) return null;
    return {
      ref,
      eyebrow: `${signal.kind} signal`,
      title: signal.summary,
      summary: signal.occurredAt
        ? `Observed ${new Date(signal.occurredAt).toLocaleString()}.`
        : "The source did not provide an event timestamp.",
      status: signal.severity,
      artifactIds: signal.artifactIds,
      details: [
        { label: "Signal ID", value: signal.id },
        { label: "Kind", value: signal.kind },
        {
          label: "Linked entity",
          value: signal.entity
            ? `${signal.entity.kind}:${signal.entity.id}`
            : "None",
        },
      ],
    };
  }

  if (ref.kind === "issue") {
    const issue = snapshot.issues.find((item) => item.id === ref.id);
    if (!issue) return null;
    return {
      ref,
      eyebrow: issue.code,
      title: issue.domain,
      summary: issue.message,
      status: issue.severity,
      artifactIds: issue.artifactIds,
      details: [
        { label: "Issue ID", value: issue.id },
        {
          label: "Linked entity",
          value: issue.entity
            ? `${issue.entity.kind}:${issue.entity.id}`
            : "None",
        },
        {
          label: "Remediation",
          value: issue.remediation ?? "No remediation recorded",
        },
      ],
    };
  }

  if (ref.kind === "artifact") {
    const artifact = snapshot.artifacts.find((item) => item.id === ref.id);
    if (!artifact) return null;
    return artifactEntity(artifact);
  }

  return null;
}

function artifactEntity(artifact: ArtifactRef): ResolvedEntity {
  return {
    ref: { kind: "artifact", id: artifact.id },
    eyebrow: artifact.kind,
    title: artifact.label,
    summary: artifact.path,
    status: artifact.provenance.truthClass,
    artifactIds: [artifact.id],
    details: [
      { label: "Path", value: artifact.path },
      { label: "SHA-256", value: artifact.sha256 },
      { label: "Source", value: artifact.provenance.sourceRef },
      { label: "Truth class", value: artifact.provenance.truthClass },
      {
        label: "Observed",
        value: new Date(artifact.provenance.observedAt).toLocaleString(),
      },
    ],
  };
}

export function entityExists(
  snapshot: WorkspaceSnapshot,
  ref: EntityRef | null,
) {
  return resolveEntity(snapshot, ref) !== null;
}
