import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";

import {
  collectWorkspaceEvidence,
  latestEvidenceTime,
} from "./evidence.mjs";
import { redactSensitiveText } from "./security.mjs";

const PASSES = Object.freeze([
  {
    id: "pass-0",
    number: 0,
    label: "Capture",
    summary: "Canonical problem, boundaries, and owner sign-off.",
    command: "cvg capture --json",
    runnerKey: "pass0",
    position: { x: 0, y: 90 },
  },
  {
    id: "pass-1",
    number: 1,
    label: "Intent",
    summary: "Measurable requirements without implementation drift.",
    command: "cvg intent --json",
    runnerKey: "pass1",
    position: { x: 280, y: 220 },
  },
  {
    id: "pass-2",
    number: 2,
    label: "Structure",
    summary: "Evidence-backed constraints encoded as architectural terrain.",
    command: "cvg structure --json",
    runnerKey: "pass2",
    position: { x: 560, y: 90 },
  },
  {
    id: "pass-3",
    number: 3,
    label: "Decompose",
    summary: "A linked, seam-aware delivery plan across explicit lanes.",
    command: "cvg decompose --json",
    runnerKey: "pass3",
    position: { x: 840, y: 220 },
  },
  {
    id: "pass-4",
    number: 4,
    label: "Consensus",
    summary: "Independent adversarial review with preserved provenance.",
    command: "cvg review --check --json",
    runnerKey: "pass4",
    position: { x: 1120, y: 90 },
  },
  {
    id: "pass-5",
    number: 5,
    label: "Tasking",
    summary: "Delegable Task-Specs with bounded write surfaces.",
    command: "",
    runnerKey: null,
    position: { x: 1120, y: 390 },
  },
  {
    id: "pass-6",
    number: 6,
    label: "Register",
    summary: "Optional tracker projection from the sealed Task-Spec graph.",
    command: "cvg register --check --tracker <tracker>",
    runnerKey: null,
    optional: true,
    position: { x: 840, y: 450 },
  },
  {
    id: "pass-7",
    number: 7,
    label: "Bind",
    summary: "Fresh runtime contracts bound to evidence and policy.",
    command: "",
    runnerKey: null,
    position: { x: 560, y: 330 },
  },
  {
    id: "pass-8",
    number: 8,
    label: "Loop",
    summary: "Bounded execution settles through runnable evidence.",
    command: "",
    runnerKey: null,
    position: { x: 280, y: 450 },
  },
]);

const NEXT_COMMAND = Object.freeze({
  "pass-0": "cvg capture",
  "pass-1": "cvg intent",
  "pass-2": "cvg structure",
  "pass-3": "cvg decompose",
  "pass-4": "cvg review --check",
  "pass-5": "cvg tasks new <slug>",
  "pass-6": "cvg register --check --tracker <tracker>",
  "pass-7": "cvg bind --task <spec>",
  "pass-8": "cvg loop --gate-only --issue <id>",
});

function stableObject(value) {
  if (Array.isArray(value)) {
    return value.map(stableObject);
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([, nested]) => nested !== undefined)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, nested]) => [key, stableObject(nested)]),
    );
  }
  return value;
}

export function computeSnapshotId(snapshot) {
  const identity = structuredClone(snapshot);
  delete identity.generatedAt;
  delete identity.snapshotId;
  const digest = createHash("sha256")
    .update(JSON.stringify(stableObject(identity)))
    .digest("hex");
  return `ws_${digest.slice(0, 28)}`;
}

function gateFromResult(pass, result) {
  const document = result?.document;
  return {
    command: pass.command,
    token: typeof document?.token === "string" ? document.token : null,
    verdict: typeof document?.verdict === "string" ? document.verdict : null,
    exitCode:
      typeof document?.exit_code === "number"
        ? document.exit_code
        : typeof result?.exitCode === "number"
          ? result.exitCode
          : null,
    ok: typeof document?.ok === "boolean" ? document.ok : null,
  };
}

function emptyGate(command = "") {
  return {
    command,
    token: null,
    verdict: null,
    exitCode: null,
    ok: null,
  };
}

function parseProgress(output) {
  const progress = new Map();
  const expression = /\[([+.!x-])\]\s+pass\s+(\d+)/g;
  let match;
  while ((match = expression.exec(output)) !== null) {
    progress.set(Number(match[2]), match[1]);
  }
  return progress;
}

function parseNextPass(nextResult) {
  const document = nextResult?.document;
  const raw =
    typeof document?.verdict === "string"
      ? document.verdict
      : typeof document?.token === "string"
        ? document.token.replace(/^NEXT_PASS=/, "")
        : "";
  const numeric = raw.match(/^\d+$/) ? Number(raw) : null;
  return {
    raw,
    id: numeric === null ? null : `pass-${numeric}`,
    done: /^(?:DONE|COMPLETE|SETTLED)$/i.test(raw),
  };
}

function parseLane(nextResult) {
  const output = nextResult?.document?.data?.output;
  const lane =
    typeof output === "string"
      ? output.match(/\blane\s+(FULL|NORMAL|FAST)\b/i)?.[1]?.toUpperCase()
      : null;
  return ["FULL", "NORMAL", "FAST"].includes(lane) ? lane : "FULL";
}

function reviewFromDocument(document) {
  if (!document || typeof document !== "object") {
    return null;
  }
  const objections = Array.isArray(document.objections)
      ? document.objections.map((objection, index) => ({
        id: redactSensitiveText(
          String(objection.id ?? `objection-${index + 1}`),
        ),
        title: redactSensitiveText(
          String(objection.title ?? "Untitled objection"),
        ),
        severity: redactSensitiveText(
          String(objection.severity ?? "unknown"),
        ),
        ...(typeof objection.confidence === "number"
          ? { confidence: objection.confidence }
          : {}),
        ...(typeof objection.body === "string"
          ? { body: redactSensitiveText(objection.body) }
          : {}),
        ...(typeof objection.resolution?.disposition === "string"
          ? {
              disposition: redactSensitiveText(
                objection.resolution.disposition,
              ),
            }
          : {}),
        ...(typeof objection.resolution?.risk_residual === "string"
          ? {
              residualRisk: redactSensitiveText(
                objection.resolution.risk_residual,
              ),
            }
          : {}),
        ...(typeof objection.location?.plan_file === "string"
          ? { planPath: redactSensitiveText(objection.location.plan_file) }
          : {}),
      }))
    : [];
  const openQuestions = Array.isArray(document.open_questions)
    ? document.open_questions.map((question) => ({
        question: redactSensitiveText(
          String(question.q ?? question.question ?? "Unrecorded question"),
        ),
        owner: redactSensitiveText(String(question.owner ?? "unassigned")),
        blocksBuild: question.blocks_build === true,
      }))
    : [];

  return {
    round:
      typeof document.rounds_run === "number"
        ? document.rounds_run
        : typeof document.round === "number"
          ? document.round
          : 0,
    verdict: redactSensitiveText(String(document.verdict ?? "UNKNOWN")),
    adversary: {
      engine: redactSensitiveText(
        String(
          document.adversary?.engine_id ??
            document.adversary?.engine ??
            document.adversary?.model ??
            "unknown",
        ),
      ),
      family: redactSensitiveText(
        String(document.adversary?.family ?? "unknown"),
      ),
      ...(typeof document.adversary?.engine_version === "string"
        ? { version: redactSensitiveText(document.adversary.engine_version) }
        : {}),
    },
    ...(typeof document.author?.family === "string"
      ? { authorFamily: redactSensitiveText(document.author.family) }
      : {}),
    objections,
    openQuestions,
    ...(typeof document.prompt_sha256 === "string"
      ? { promptSha256: document.prompt_sha256 }
      : {}),
  };
}

async function readReview(projectRoot) {
  const reviewPath = path.join(
    projectRoot,
    "cvg",
    "swimlanes",
    ".consensus",
    "objection-log.json",
  );
  try {
    return reviewFromDocument(JSON.parse(await readFile(reviewPath, "utf8")));
  } catch {
    return null;
  }
}

function passStatus({
  pass,
  gate,
  activePassId,
  progress,
  blockingQuestionCount,
}) {
  if (gate.ok === false) {
    return "blocked";
  }
  if (pass.id === "pass-4" && blockingQuestionCount > 0) {
    return "attention";
  }
  if (pass.id === activePassId) {
    return "active";
  }
  const progressMark = progress.get(pass.number);
  if (progressMark === "+") {
    return "complete";
  }
  if (gate.ok === true) {
    return "complete";
  }
  if (pass.optional) {
    return "optional";
  }
  return "waiting";
}

function edgeKind(source, target) {
  if (target.status === "active") {
    return "active";
  }
  if (source.gate.ok === true && target.gate.ok === true) {
    return "complete";
  }
  if (source.status === "complete" && target.status === "complete") {
    return "complete";
  }
  return "waiting";
}

function projectNameFromEvidence(evidence, projectRoot) {
  const canonicalBrief = (evidence.byPass["pass-0"] ?? []).find((record) =>
    record.path.startsWith("cvg/docs/brd/"),
  );
  if (!canonicalBrief) {
    return path.basename(projectRoot);
  }
  return canonicalBrief.label
    .replace(/^BRD\s*[—:-]\s*/i, "")
    .trim();
}

function authorizationFromNext(nextResult, nextPass) {
  const ok = nextResult?.document?.ok;
  if (ok === false) {
    return {
      state: "blocked",
      nextPassId: null,
      command: null,
      rationale: "The cvg next command did not authorize a next pass.",
    };
  }
  if (ok === true && nextPass.id && NEXT_COMMAND[nextPass.id]) {
    return {
      state: "allowed",
      nextPassId: nextPass.id,
      command: NEXT_COMMAND[nextPass.id],
      rationale: `The read-only cvg next verdict identifies ${nextPass.id.replace("-", " ")} as the next pass.`,
    };
  }
  if (ok === true && nextPass.done) {
    return {
      state: "allowed",
      nextPassId: null,
      command: null,
      rationale: "The read-only cvg next verdict reports the descent complete.",
    };
  }
  return {
    state: "unknown",
    nextPassId: null,
    command: null,
    rationale: "The bridge could not derive an authorization from cvg next.",
  };
}

export async function buildWorkspaceSnapshot({
  config,
  runner,
  gitReader,
  artifactStore,
  now = () => new Date(),
}) {
  const gatePromises = PASSES.filter((pass) => pass.runnerKey).map(
    async (pass) => [pass.id, await runner.run(pass.runnerKey)],
  );
  const [contextResult, nextResult, gateEntries, evidence, review, git] =
    await Promise.all([
      runner.run("context"),
      runner.run("next"),
      Promise.all(gatePromises),
      collectWorkspaceEvidence(config.projectRoot),
      readReview(config.projectRoot),
      gitReader.readState(),
    ]);

  const gateResults = new Map(gateEntries);
  const nextPass = parseNextPass(nextResult);
  const activePassId =
    nextPass.id && PASSES.some((pass) => pass.id === nextPass.id)
      ? nextPass.id
      : PASSES.at(-1).id;
  const output =
    typeof nextResult?.document?.data?.output === "string"
      ? nextResult.document.data.output
      : "";
  const progress = parseProgress(output);
  const blockingQuestionCount =
    review?.openQuestions.filter((question) => question.blocksBuild).length ?? 0;

  const passes = PASSES.map((pass) => {
    const gate = pass.runnerKey
      ? gateFromResult(pass, gateResults.get(pass.id))
      : emptyGate(pass.command);
    return {
      id: pass.id,
      order: pass.number,
      label: pass.label,
      shortLabel: pass.label,
      summary: pass.summary,
      status: passStatus({
        pass,
        gate,
        activePassId,
        progress,
        blockingQuestionCount,
      }),
      ...(pass.optional ? { optional: true } : {}),
      gate,
      evidence: (evidence.byPass[pass.id] ?? []).map(
        ({ modifiedAt: _modifiedAt, ...record }) => record,
      ),
      blockerCount:
        pass.id === "pass-4"
          ? blockingQuestionCount
          : gate.ok === false
            ? 1
            : 0,
      position: pass.position,
    };
  });
  const passById = new Map(passes.map((pass) => [pass.id, pass]));
  const edgeDefinitions = [
    ["pass-0", "pass-1"],
    ["pass-1", "pass-2"],
    ["pass-2", "pass-3"],
    ["pass-3", "pass-4"],
    ["pass-4", "pass-5"],
    ["pass-5", "pass-6", "optional", "opt-in tracker"],
    ["pass-5", "pass-7", null, "repo-local queue"],
    ["pass-6", "pass-7", "optional"],
    ["pass-7", "pass-8"],
  ];
  const edges = edgeDefinitions.map(
    ([sourceId, targetId, forcedKind, label]) => {
      const source = passById.get(sourceId);
      const target = passById.get(targetId);
      return {
        id: `${sourceId}-to-${targetId}`,
        source: sourceId,
        target: targetId,
        kind: forcedKind ?? edgeKind(source, target),
        ...(label ? { label } : {}),
      };
    },
  );

  const fallbackTime =
    git.committedAt ?? "1970-01-01T00:00:00.000Z";
  const activity = passes
    .filter((pass) => pass.gate.ok !== null || pass.status === "active")
    .map((pass) => ({
      id: `activity-${pass.id}`,
      time: latestEvidenceTime(evidence.byPass[pass.id] ?? [], fallbackTime),
      label:
        pass.status === "active"
          ? `${pass.label} is next`
          : `${pass.label} gate ${pass.gate.ok ? "passed" : "needs attention"}`,
      detail:
        pass.status === "active"
          ? NEXT_COMMAND[pass.id] ?? "Awaiting a declared next command"
          : pass.gate.token ?? "No stable gate token returned",
      tone:
        pass.status === "active"
          ? "active"
          : pass.gate.ok
            ? "proven"
            : "attention",
      source: "gate",
    }))
    .sort((left, right) => left.time.localeCompare(right.time));

  const warnings = [];
  if (!contextResult.parsed) {
    warnings.push("The CLI context manifest could not be parsed.");
  }
  if (!nextResult.parsed) {
    warnings.push("The CLI next-pass response could not be parsed.");
  }
  if (git.dirty) {
    warnings.push("The observed workspace has uncommitted changes.");
  }
  if (
    passes.find((pass) => pass.id === "pass-4")?.gate.ok === true &&
    blockingQuestionCount > 0
  ) {
    warnings.push(
      `Pass 4 gate is green while ${blockingQuestionCount} review questions remain marked blocks_build; gate, review, and authorization are intentionally shown separately.`,
    );
  }

  const context = contextResult.document ?? {};
  const snapshot = {
    schemaVersion: "1.0",
    snapshotId: "",
    generatedAt: now().toISOString(),
    source: "live",
    project: {
      name: projectNameFromEvidence(evidence, config.projectRoot),
      root: config.projectRoot,
      lane: parseLane(nextResult),
      branch: git.branch,
      commit: git.commit,
      dirty: git.dirty,
    },
    cli: {
      version: String(context.version ?? "unknown"),
      role: String(context.role ?? "referee"),
      commandCount: Array.isArray(context.commands) ? context.commands.length : 0,
    },
    method: {
      name: "Converge",
      version: String(context.version ?? "unknown"),
      activePassId,
      passes,
      edges,
    },
    review,
    authorization: authorizationFromNext(nextResult, nextPass),
    activity,
    warnings,
  };
  snapshot.snapshotId = computeSnapshotId(snapshot);
  artifactStore.setAllowedArtifacts(evidence.artifacts, snapshot.snapshotId);
  return snapshot;
}

export { PASSES, parseNextPass, reviewFromDocument };
