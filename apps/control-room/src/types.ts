export type PassStatus =
  | "complete"
  | "active"
  | "attention"
  | "blocked"
  | "waiting"
  | "optional"
  | "skipped";

export type EvidenceKind =
  | "brief"
  | "spec"
  | "decision"
  | "plan"
  | "review"
  | "task"
  | "contract"
  | "event"
  | "receipt"
  | "artifact";

export interface GateState {
  command: string;
  token: string | null;
  verdict: string | null;
  exitCode: number | null;
  ok: boolean | null;
}

export interface EvidenceRef {
  id: string;
  label: string;
  path: string;
  kind: EvidenceKind;
  sha256?: string;
}

export interface PassState {
  id: string;
  order: number;
  label: string;
  shortLabel: string;
  summary: string;
  status: PassStatus;
  optional?: boolean;
  gate: GateState;
  evidence: EvidenceRef[];
  blockerCount: number;
  position: {
    x: number;
    y: number;
  };
}

export interface MethodEdge {
  id: string;
  source: string;
  target: string;
  kind: "complete" | "active" | "waiting" | "optional" | "return";
  label?: string;
}

export interface ReviewObjection {
  id: string;
  title: string;
  severity: "critical" | "high" | "medium" | "low" | string;
  confidence?: number;
  body?: string;
  disposition?: string;
  residualRisk?: string;
  planPath?: string;
}

export interface OpenQuestion {
  question: string;
  owner: string;
  blocksBuild: boolean;
}

export interface ReviewState {
  round: number;
  verdict: string;
  adversary: {
    engine: string;
    family: string;
    version?: string;
  };
  authorFamily?: string;
  objections: ReviewObjection[];
  openQuestions: OpenQuestion[];
  promptSha256?: string;
}

export interface ActivityItem {
  id: string;
  time: string;
  label: string;
  detail: string;
  tone: "proven" | "active" | "attention" | "neutral";
  source: "gate" | "git" | "artifact" | "fixture";
}

export interface WorkspaceSnapshot {
  schemaVersion: "1.0";
  snapshotId: string;
  generatedAt: string;
  source: "live" | "fixture";
  project: {
    name: string;
    root: string;
    lane: "FULL" | "NORMAL" | "FAST";
    branch: string;
    commit: string;
    dirty: boolean;
  };
  cli: {
    version: string;
    role: string;
    commandCount: number;
  };
  method: {
    name: string;
    version: string;
    activePassId: string;
    passes: PassState[];
    edges: MethodEdge[];
  };
  review: ReviewState | null;
  authorization: {
    state: "allowed" | "blocked" | "attention" | "unknown";
    nextPassId: string | null;
    command: string | null;
    rationale: string;
  };
  activity: ActivityItem[];
  warnings: string[];
}

export interface ArtifactDocument {
  path: string;
  label: string;
  kind: EvidenceKind;
  content: string;
  truncated: boolean;
  sha256: string;
  snapshotId: string;
}
