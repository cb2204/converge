import type {
  ActivityItem,
  EvidenceRef,
  MethodEdge,
  PassState,
  ReviewState,
  WorkspaceSnapshot,
} from "../types";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasString(value: Record<string, unknown>, key: string) {
  return typeof value[key] === "string";
}

function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === "string";
}

function isEvidence(value: unknown): value is EvidenceRef {
  if (!isRecord(value)) return false;
  return (
    hasString(value, "id") &&
    hasString(value, "label") &&
    hasString(value, "path") &&
    hasString(value, "kind") &&
    (value.sha256 === undefined || typeof value.sha256 === "string")
  );
}

function isPass(value: unknown): value is PassState {
  if (!isRecord(value) || !isRecord(value.gate) || !isRecord(value.position)) {
    return false;
  }
  return (
    hasString(value, "id") &&
    typeof value.order === "number" &&
    Number.isFinite(value.order) &&
    hasString(value, "label") &&
    hasString(value, "shortLabel") &&
    hasString(value, "summary") &&
    hasString(value, "status") &&
    Array.isArray(value.evidence) &&
    value.evidence.every(isEvidence) &&
    typeof value.blockerCount === "number" &&
    Number.isFinite(value.blockerCount) &&
    hasString(value.gate, "command") &&
    isNullableString(value.gate.token) &&
    isNullableString(value.gate.verdict) &&
    (value.gate.exitCode === null ||
      (typeof value.gate.exitCode === "number" &&
        Number.isFinite(value.gate.exitCode))) &&
    (value.gate.ok === null || typeof value.gate.ok === "boolean") &&
    typeof value.position.x === "number" &&
    Number.isFinite(value.position.x) &&
    typeof value.position.y === "number" &&
    Number.isFinite(value.position.y)
  );
}

function isEdge(value: unknown): value is MethodEdge {
  return (
    isRecord(value) &&
    hasString(value, "id") &&
    hasString(value, "source") &&
    hasString(value, "target") &&
    hasString(value, "kind") &&
    (value.label === undefined || typeof value.label === "string")
  );
}

function isReview(value: unknown): value is ReviewState | null {
  if (value === null) return true;
  if (!isRecord(value) || !isRecord(value.adversary)) return false;
  return (
    typeof value.round === "number" &&
    Number.isFinite(value.round) &&
    hasString(value, "verdict") &&
    hasString(value.adversary, "engine") &&
    hasString(value.adversary, "family") &&
    Array.isArray(value.objections) &&
    value.objections.every(
      (objection) =>
        isRecord(objection) &&
        hasString(objection, "id") &&
        hasString(objection, "title") &&
        hasString(objection, "severity"),
    ) &&
    Array.isArray(value.openQuestions) &&
    value.openQuestions.every(
      (question) =>
        isRecord(question) &&
        hasString(question, "question") &&
        hasString(question, "owner") &&
        typeof question.blocksBuild === "boolean",
    )
  );
}

function isActivity(value: unknown): value is ActivityItem {
  return (
    isRecord(value) &&
    hasString(value, "id") &&
    hasString(value, "time") &&
    !Number.isNaN(Date.parse(value.time as string)) &&
    hasString(value, "label") &&
    hasString(value, "detail") &&
    hasString(value, "tone") &&
    hasString(value, "source")
  );
}

export function isWorkspaceSnapshot(
  value: unknown,
): value is WorkspaceSnapshot {
  if (
    !isRecord(value) ||
    !isRecord(value.project) ||
    !isRecord(value.cli) ||
    !isRecord(value.method) ||
    !isRecord(value.authorization)
  ) {
    return false;
  }

  if (!Array.isArray(value.method.passes) || value.method.passes.length === 0) {
    return false;
  }

  const passes = value.method.passes;
  if (!passes.every(isPass)) return false;
  const passIds = new Set(passes.map((pass) => pass.id));

  return (
    value.schemaVersion === "1.0" &&
    hasString(value, "snapshotId") &&
    hasString(value, "generatedAt") &&
    !Number.isNaN(Date.parse(value.generatedAt as string)) &&
    (value.source === "live" || value.source === "fixture") &&
    hasString(value.project, "name") &&
    hasString(value.project, "root") &&
    hasString(value.project, "lane") &&
    hasString(value.project, "branch") &&
    hasString(value.project, "commit") &&
    typeof value.project.dirty === "boolean" &&
    hasString(value.cli, "version") &&
    hasString(value.cli, "role") &&
    typeof value.cli.commandCount === "number" &&
    Number.isFinite(value.cli.commandCount) &&
    hasString(value.method, "name") &&
    hasString(value.method, "version") &&
    hasString(value.method, "activePassId") &&
    passIds.has(value.method.activePassId as string) &&
    Array.isArray(value.method.edges) &&
    value.method.edges.every(
      (edge) =>
        isEdge(edge) &&
        passIds.has(edge.source) &&
        passIds.has(edge.target),
    ) &&
    isReview(value.review) &&
    hasString(value.authorization, "state") &&
    isNullableString(value.authorization.nextPassId) &&
    (value.authorization.nextPassId === null ||
      passIds.has(value.authorization.nextPassId)) &&
    isNullableString(value.authorization.command) &&
    hasString(value.authorization, "rationale") &&
    Array.isArray(value.activity) &&
    value.activity.every(isActivity) &&
    Array.isArray(value.warnings) &&
    value.warnings.every((warning) => typeof warning === "string")
  );
}
