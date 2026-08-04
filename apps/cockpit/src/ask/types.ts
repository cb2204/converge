export type AskAgentAvailability =
  | "available"
  | "ready"
  | "not_configured"
  | "authentication_required"
  | "unavailable"
  | "blocked";

export interface AskAgent {
  id: "codex" | "claude";
  label: string;
  adapter: string;
  availability: AskAgentAvailability;
  reason: string | null;
  authenticationMethods?: Array<{ id: string; label: string }>;
}

export interface AskCapabilities {
  agents: AskAgent[];
  requestToken: string;
  policy: {
    transport: "ACP";
    workspaceAccess: "enforced-safe-mode";
    persistence: "cockpit-ephemeral";
    evidenceBoundary: string;
  };
}

export interface AskActivity {
  id: string;
  kind: "plan" | "read" | "search" | "think" | "permission" | "status";
  label: string;
  status: "pending" | "active" | "complete" | "denied";
  detail?: string;
}

export interface AskTurnResponse {
  turnId: string;
  agentId: AskAgent["id"];
  snapshotId: string;
  grounding: {
    snapshotId: string;
    observedAt: string;
    methodology: {
      tool: "cvg";
      version: string;
      digest: string;
    };
    entity: EntityRef | null;
    artifacts: Array<{
      id: string;
      label: string;
      path: string;
      sha256: string;
      truncated: boolean;
    }>;
  };
  answer: string;
  steps: string[];
  activity: AskActivity[];
  stopReason: string;
  elapsedMs: number;
}
import type { EntityRef } from "../types";
