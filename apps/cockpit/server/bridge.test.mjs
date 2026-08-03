import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import {
  chmod,
  mkdir,
  mkdtemp,
  realpath,
  rm,
  symlink,
  writeFile,
} from "node:fs/promises";
import { createServer, request as httpRequest } from "node:http";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { createRequestHandler } from "./app.mjs";
import { ArtifactStore } from "./artifact-store.mjs";
import { resolveServerConfig } from "./config.mjs";
import { createCvgRunner } from "./cvg.mjs";
import {
  createWorkspaceSnapshotValidator,
  validateJsonSchema,
} from "./schema.mjs";
import { SnapshotService } from "./service.mjs";
import {
  buildWorkspaceSnapshot,
  extractSnapshotEnvelope,
} from "./snapshot.mjs";

const APP_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const REPOSITORY_ROOT = path.resolve(APP_ROOT, "../..");

async function withTempDirectory(t) {
  const directory = await mkdtemp(path.join(tmpdir(), "cvg-cockpit-test-"));
  t.after(() => rm(directory, { force: true, recursive: true }));
  return directory;
}

function sha256(contents) {
  return createHash("sha256").update(contents).digest("hex");
}

function artifactRef({
  id = "artifact-proof",
  artifactPath = "docs/proof.md",
  digest = sha256("proof"),
} = {}) {
  return {
    id,
    label: "Proof",
    path: artifactPath,
    kind: "artifact",
    sha256: digest,
    entity: { kind: "pass", id: "pass-0" },
    provenance: {
      sourceKind: "file",
      sourceRef: artifactPath,
      observedAt: "2026-08-03T12:00:00.000Z",
      truthClass: "canonical",
    },
  };
}

function workspaceSnapshot({
  snapshotId = "ws_1234567890abcdef",
  artifacts = [artifactRef()],
} = {}) {
  return {
    schemaVersion: "2.0",
    snapshotId,
    observedAt: "2026-08-03T12:00:00.000Z",
    source: "workspace",
    project: {},
    method: {},
    review: null,
    work: {},
    execution: {},
    receipts: [],
    health: [],
    signals: [],
    issues: [],
    authorization: {},
    artifacts,
  };
}

function cliEnvelope(snapshot, overrides = {}) {
  return {
    ok: true,
    command: "snapshot",
    token: null,
    verdict: null,
    exit_code: 0,
    changed: false,
    dry_run: false,
    data: { snapshot },
    error: null,
    warnings: [],
    meta: {
      schema_version: "1.0",
      tool: "cvg",
      cvg_version: "0.1.0",
    },
    ...overrides,
  };
}

function transportEnvelope(snapshot, {
  stale = false,
  servedAt = "2026-08-03T12:00:01.000Z",
  error,
} = {}) {
  return {
    snapshot,
    transport: {
      stale,
      servedAt,
      ...(error ? { error } : {}),
    },
  };
}

async function listen(t, handler) {
  const server = createServer(handler);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(
    () =>
      new Promise((resolve) => {
        server.closeAllConnections();
        server.close(resolve);
      }),
  );
  const address = server.address();
  return `http://127.0.0.1:${address.port}`;
}

async function getWithHost(origin, requestPath, host) {
  const target = new URL(origin);
  return new Promise((resolve, reject) => {
    const request = httpRequest(
      {
        hostname: target.hostname,
        port: target.port,
        path: requestPath,
        method: "GET",
        headers: { Host: host },
      },
      (response) => {
        const chunks = [];
        response.on("data", (chunk) => chunks.push(chunk));
        response.on("end", () => {
          resolve({
            status: response.statusCode,
            document: JSON.parse(Buffer.concat(chunks).toString("utf8")),
          });
        });
      },
    );
    request.on("error", reject);
    request.end();
  });
}

test("server config requires explicit roots and only binds Cockpit to loopback", async (t) => {
  await assert.rejects(
    resolveServerConfig({ env: {}, argv: [] }),
    /CVG_HOME and CVG_PROJECT_ROOT are required/,
  );

  const root = await withTempDirectory(t);
  const cvgHome = path.join(root, "converge");
  const projectRoot = path.join(root, "project");
  await mkdir(path.join(cvgHome, "bin"), { recursive: true });
  await mkdir(projectRoot);
  await writeFile(path.join(cvgHome, "bin", "cvg"), "#!/bin/sh\n");
  await chmod(path.join(cvgHome, "bin", "cvg"), 0o755);

  const config = await resolveServerConfig({
    env: { CVG_HOME: cvgHome, CVG_PROJECT_ROOT: projectRoot },
    argv: ["--port", "4321"],
  });
  assert.equal(config.cvgHome, await realpath(cvgHome));
  assert.equal(config.projectRoot, await realpath(projectRoot));
  assert.equal(config.host, "127.0.0.1");
  assert.equal(config.port, 4321);

  await assert.rejects(
    resolveServerConfig({
      env: { CVG_HOME: cvgHome, CVG_PROJECT_ROOT: projectRoot },
      argv: ["--host", "0.0.0.0"],
    }),
    /Converge Cockpit bridge is local-only/,
  );
});

test("runner invokes only cvg snapshot --json with no shell or credential forwarding", async () => {
  let invocation;
  const snapshot = workspaceSnapshot();
  const execFileImpl = (file, args, options, callback) => {
    invocation = { file, args, options };
    callback(null, JSON.stringify(cliEnvelope(snapshot)), "");
  };
  const config = {
    cvgBin: "/tool/bin/cvg",
    cvgHome: "/tool",
    projectRoot: "/workspace",
  };
  const runner = createCvgRunner({
    config,
    execFileImpl,
    baseEnvironment: {
      PATH: "/usr/bin",
      HOME: "/home/person",
      GITHUB_TOKEN: "do-not-forward",
      OPENAI_API_KEY: "do-not-forward",
    },
  });

  const result = await runner.run("snapshot");
  assert.deepEqual(invocation.args, ["snapshot", "--json"]);
  assert.equal(invocation.file, "/tool/bin/cvg");
  assert.equal(invocation.options.cwd, "/workspace");
  assert.equal(invocation.options.shell, undefined);
  assert.equal(invocation.options.env.CVG_HOME, "/tool");
  assert.equal(invocation.options.env.CVG_PROJECT_ROOT, "/workspace");
  assert.equal(invocation.options.env.GITHUB_TOKEN, undefined);
  assert.equal(invocation.options.env.OPENAI_API_KEY, undefined);
  assert.deepEqual(result.document.data.snapshot, snapshot);

  await assert.rejects(runner.run("next"), /undeclared read-only/);
  await assert.rejects(runner.run("snapshot --json; rm -rf project"), /undeclared read-only/);
});

test("snapshot transport accepts only a successful cvg envelope and preserves CLI semantics", async () => {
  const snapshot = workspaceSnapshot();
  const allowed = [];
  const artifactStore = {
    setAllowedArtifacts(records, snapshotId) {
      allowed.push({ records, snapshotId });
    },
  };
  const runner = {
    async run(name) {
      assert.equal(name, "snapshot");
      return {
        parsed: true,
        exitCode: 0,
        timedOut: false,
        document: cliEnvelope(snapshot),
      };
    },
  };

  const received = await buildWorkspaceSnapshot({
    runner,
    artifactStore,
    validateSnapshot(candidate) {
      assert.equal(candidate, snapshot);
    },
  });
  assert.equal(received, snapshot);
  assert.deepEqual(allowed, [
    { records: snapshot.artifacts, snapshotId: snapshot.snapshotId },
  ]);
  assert.equal(Object.hasOwn(received, "transport"), false);

  assert.throws(
    () => extractSnapshotEnvelope({
      parsed: true,
      exitCode: 0,
      document: snapshot,
    }),
    { code: "CLI_SNAPSHOT_REJECTED" },
  );
  assert.throws(
    () => extractSnapshotEnvelope({
      parsed: true,
      exitCode: 1,
      document: cliEnvelope(snapshot, { ok: false, exit_code: 1 }),
    }),
    { code: "CLI_SNAPSHOT_REJECTED" },
  );
  assert.throws(
    () => extractSnapshotEnvelope({
      parsed: false,
      exitCode: 0,
      document: null,
    }),
    { code: "CLI_SNAPSHOT_INVALID" },
  );
  assert.throws(
    () => extractSnapshotEnvelope({
      parsed: false,
      exitCode: 2,
      document: null,
      timedOut: true,
    }),
    { code: "CLI_SNAPSHOT_TIMEOUT" },
  );
});

test("WorkspaceSnapshot validator rejects documents outside schema version 2.0", async (t) => {
  const root = await withTempDirectory(t);
  const schemaPath = path.join(root, "workspace-snapshot.schema.json");
  await writeFile(
    schemaPath,
    JSON.stringify({
      type: "object",
      required: ["schemaVersion", "snapshotId", "observedAt", "artifacts"],
      properties: {
        schemaVersion: { const: "2.0" },
        snapshotId: { type: "string", minLength: 12 },
        observedAt: { type: "string", format: "date-time" },
        artifacts: {
          type: "array",
          items: { $ref: "#/$defs/artifact" },
        },
      },
      additionalProperties: true,
      $defs: {
        artifact: {
          type: "object",
          required: ["id", "path", "sha256"],
          properties: {
            id: { type: "string" },
            path: { type: "string" },
            sha256: { type: "string", pattern: "^[a-f0-9]{64}$" },
          },
          additionalProperties: true,
        },
      },
    }),
  );
  const validate = await createWorkspaceSnapshotValidator({
    config: { cvgHome: root },
    schemaPath,
  });

  assert.equal(validate(workspaceSnapshot()).schemaVersion, "2.0");
  assert.throws(
    () => validate({ ...workspaceSnapshot(), schemaVersion: "1.0" }),
    { code: "SNAPSHOT_SCHEMA_INVALID" },
  );
  assert.throws(
    () => validate({ ...workspaceSnapshot(), artifacts: undefined }),
    { code: "SNAPSHOT_SCHEMA_INVALID" },
  );

  assert.deepEqual(
    validateJsonSchema(
      { state: "ok", extra: true },
      {
        type: "object",
        required: ["state"],
        properties: { state: { enum: ["ok"] } },
        additionalProperties: false,
      },
    ),
    ["$.extra is not allowed"],
  );
});

test("real CLI snapshot satisfies the complete WorkspaceSnapshot 2.0 bridge contract", async () => {
  const config = {
    cvgBin: path.join(REPOSITORY_ROOT, "bin", "cvg"),
    cvgHome: REPOSITORY_ROOT,
    projectRoot: path.join(APP_ROOT, "e2e", "fixtures", "workspace"),
  };
  const runner = createCvgRunner({ config });
  const validateSnapshot = await createWorkspaceSnapshotValidator({ config });
  const allowed = [];

  const snapshot = await buildWorkspaceSnapshot({
    runner,
    validateSnapshot,
    artifactStore: {
      setAllowedArtifacts(records, snapshotId) {
        allowed.push({ records, snapshotId });
      },
    },
  });

  assert.equal(snapshot.schemaVersion, "2.0");
  assert.equal(snapshot.source, "workspace");
  assert.match(snapshot.snapshotId, /^ws2_[0-9a-f]{32}$/);
  assert.equal(snapshot.method.activePassId, "pass-0");
  assert.equal(snapshot.work.availability, "empty");
  assert.equal(snapshot.execution.availability, "empty");
  assert.equal(snapshot.receipts.availability, "empty");
  assert.deepEqual(allowed, [
    {
      records: snapshot.artifacts,
      snapshotId: snapshot.snapshotId,
    },
  ]);
  assert.equal(JSON.stringify(snapshot).includes('"position"'), false);

  const invalidKind = structuredClone(snapshot);
  invalidKind.issues.push({
    id: "issue_11111111111111111111",
    code: "INVALID_ENTITY_KIND",
    severity: "warning",
    domain: "work",
    message: "test",
    entity: { kind: "invented", id: "pass-0" },
    artifactIds: [],
  });
  assert.throws(() => validateSnapshot(invalidKind), {
    code: "SNAPSHOT_SCHEMA_INVALID",
  });

  const danglingReference = structuredClone(snapshot);
  danglingReference.issues.push({
    id: "issue_22222222222222222222",
    code: "DANGLING_ENTITY_REFERENCE",
    severity: "warning",
    domain: "work",
    message: "test",
    entity: { kind: "task", id: "missing-task" },
    artifactIds: [],
  });
  assert.throws(() => validateSnapshot(danglingReference), {
    code: "SNAPSHOT_SCHEMA_INVALID",
  });
});

test("SnapshotService serves immutable last-good data with stale transport metadata", async () => {
  const first = workspaceSnapshot({ snapshotId: "ws_first_snapshot_123" });
  const second = workspaceSnapshot({ snapshotId: "ws_second_snapshot_45" });
  let clock = Date.parse("2026-08-03T12:00:00.000Z");
  let call = 0;
  const service = new SnapshotService({
    cacheMs: 1_000,
    now: () => clock,
    async build() {
      call += 1;
      if (call === 1) return first;
      if (call === 2) {
        const error = new Error("contains private diagnostic details");
        error.code = "SNAPSHOT_SCHEMA_INVALID";
        throw error;
      }
      return second;
    },
  });

  const live = await service.getSnapshot();
  assert.equal(live.snapshot, first);
  assert.deepEqual(live.transport, {
    stale: false,
    servedAt: "2026-08-03T12:00:00.000Z",
  });

  clock += 2_000;
  const stale = await service.getSnapshot({ fresh: true });
  assert.equal(stale.snapshot, first);
  assert.equal(stale.snapshot.snapshotId, live.snapshot.snapshotId);
  assert.equal(Object.hasOwn(stale.snapshot, "transport"), false);
  assert.deepEqual(stale.transport, {
    stale: true,
    servedAt: "2026-08-03T12:00:02.000Z",
    error: {
      code: "SNAPSHOT_SCHEMA_INVALID",
      message: "The CLI snapshot does not match WorkspaceSnapshot 2.0.",
    },
  });
  assert.equal(JSON.stringify(stale).includes("private diagnostic"), false);

  clock += 2_000;
  const recovered = await service.getSnapshot({ fresh: true });
  assert.equal(recovered.snapshot, second);
  assert.equal(recovered.transport.stale, false);

  const unavailable = new SnapshotService({
    async build() {
      throw new Error("no snapshot");
    },
  });
  await assert.rejects(unavailable.getSnapshot(), /no snapshot/);
});

test("artifact allowlist is snapshot+sha bound and blocks traversal, symlinks, binary data, and credentials", async (t) => {
  const projectRoot = await withTempDirectory(t);
  const outsideRoot = await withTempDirectory(t);
  await mkdir(path.join(projectRoot, "docs"), { recursive: true });
  const safeContents = [
    "# Evidence",
    "API_KEY=super-secret-value",
    "Authorization: Bearer bearer-secret-value",
    "github_pat_abcdefghijklmnopqrstuvwxyz0123456789",
  ].join("\n");
  const largeContents = "x".repeat(64);
  await writeFile(path.join(projectRoot, "docs", "safe.md"), safeContents);
  await writeFile(path.join(projectRoot, "docs", "large.md"), largeContents);
  await writeFile(path.join(projectRoot, "docs", "binary.log"), Buffer.from([0, 1, 2]));
  await writeFile(path.join(outsideRoot, "outside.md"), "not allowed");
  await symlink(
    path.join(outsideRoot, "outside.md"),
    path.join(projectRoot, "docs", "escape.md"),
  );

  const store = new ArtifactStore({ projectRoot, maxBytes: 32 });
  const records = [
    artifactRef({
      id: "safe",
      artifactPath: "docs/safe.md",
      digest: sha256(safeContents),
    }),
    artifactRef({
      id: "large",
      artifactPath: "docs/large.md",
      digest: sha256(largeContents),
    }),
    artifactRef({
      id: "binary",
      artifactPath: "docs/binary.log",
      digest: sha256(Buffer.from([0, 1, 2])),
    }),
    artifactRef({
      id: "escape",
      artifactPath: "docs/escape.md",
      digest: sha256("not allowed"),
    }),
  ];
  store.setAllowedArtifacts(records, "ws_snapshot_one");

  const safe = await store.read("docs/safe.md", {
    snapshotId: "ws_snapshot_one",
    expectedSha256: sha256(safeContents),
  });
  assert.equal(safe.id, "safe");
  assert.equal(safe.content.includes("super-secret-value"), false);
  assert.equal(safe.content.includes("[REDACTED]"), true);
  assert.equal(safe.sha256, sha256(safeContents));
  assert.equal(safe.snapshotId, "ws_snapshot_one");
  assert.deepEqual(safe.entity, { kind: "pass", id: "pass-0" });
  assert.equal(safe.provenance.truthClass, "canonical");

  const large = await store.read("docs/large.md", {
    snapshotId: "ws_snapshot_one",
    expectedSha256: sha256(largeContents),
  });
  assert.equal(large.truncated, true);
  assert.equal(Buffer.byteLength(large.content) <= 32, true);

  await assert.rejects(
    store.read("../outside.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256("not allowed"),
    }),
    { code: "ARTIFACT_NOT_ALLOWED" },
  );
  await assert.rejects(
    store.read("docs/escape.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256("not allowed"),
    }),
    { code: "ARTIFACT_NOT_ALLOWED" },
  );
  await assert.rejects(
    store.read("docs/not-allowlisted.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256("missing"),
    }),
    { code: "ARTIFACT_NOT_ALLOWED" },
  );
  await assert.rejects(
    store.read("docs/safe.md", {
      snapshotId: "ws_old_snapshot",
      expectedSha256: sha256(safeContents),
    }),
    { code: "SNAPSHOT_STALE" },
  );
  await assert.rejects(
    store.read("docs/safe.md", { snapshotId: "ws_snapshot_one" }),
    { code: "EVIDENCE_HASH_REQUIRED" },
  );
  await assert.rejects(
    store.read("docs/safe.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256("different"),
    }),
    { code: "EVIDENCE_STALE" },
  );
  await assert.rejects(
    store.read("docs/binary.log", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256(Buffer.from([0, 1, 2])),
    }),
    { code: "ARTIFACT_NOT_ALLOWED" },
  );

  await writeFile(path.join(projectRoot, "docs", "safe.md"), "changed after capture");
  await assert.rejects(
    store.read("docs/safe.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256(safeContents),
    }),
    { code: "EVIDENCE_STALE" },
  );

  assert.throws(
    () =>
      store.setAllowedArtifacts(
        [
          artifactRef({ artifactPath: "docs/same.md" }),
          artifactRef({ id: "duplicate", artifactPath: "docs/same.md" }),
        ],
        "ws_invalid",
      ),
    { code: "SNAPSHOT_SCHEMA_INVALID" },
  );
});

test("artifact endpoint rejects missing hashes and stale snapshots before reading", async (t) => {
  const snapshot = workspaceSnapshot();
  const service = {
    async getSnapshot() {
      return transportEnvelope(snapshot);
    },
  };
  let artifactReads = 0;
  const artifactStore = {
    async read() {
      artifactReads += 1;
      return {};
    },
  };
  const origin = await listen(
    t,
    createRequestHandler({
      config: {
        projectRoot: "/workspace/use-case",
        serveDist: false,
        distRoot: "/unused",
      },
      service,
      artifactStore,
    }),
  );

  const missingHash = await fetch(
    `${origin}/api/artifact?path=docs%2Fproof.md&snapshotId=${snapshot.snapshotId}`,
  );
  assert.equal(missingHash.status, 400);
  assert.equal(
    (await missingHash.json()).error.code,
    "ARTIFACT_SHA256_REQUIRED",
  );

  const stale = await fetch(
    `${origin}/api/artifact?path=docs%2Fproof.md&snapshotId=ws_old&sha256=${snapshot.artifacts[0].sha256}`,
  );
  assert.equal(stale.status, 409);
  assert.equal((await stale.json()).error.code, "SNAPSHOT_STALE");
  assert.equal(artifactReads, 0);
});

test("serve-dist mode serves the Cockpit client and SPA routes", async (t) => {
  const distRoot = await withTempDirectory(t);
  await mkdir(path.join(distRoot, "assets"));
  await writeFile(
    path.join(distRoot, "index.html"),
    "<!doctype html><title>Converge Cockpit</title>",
  );
  await writeFile(path.join(distRoot, "assets", "app.js"), "export {};\n");

  const origin = await listen(
    t,
    createRequestHandler({
      config: {
        projectRoot: "/workspace/use-case",
        serveDist: true,
        distRoot,
      },
      service: { async getSnapshot() {} },
      artifactStore: { async read() {} },
    }),
  );

  const rootResponse = await fetch(`${origin}/`);
  assert.equal(rootResponse.status, 200);
  assert.match(await rootResponse.text(), /Converge Cockpit/);

  const routeResponse = await fetch(`${origin}/passes/4`);
  assert.equal(routeResponse.status, 200);
  assert.match(await routeResponse.text(), /Converge Cockpit/);

  const assetResponse = await fetch(`${origin}/assets/app.js`);
  assert.equal(assetResponse.status, 200);
  assert.equal(
    assetResponse.headers.get("content-type"),
    "text/javascript; charset=utf-8",
  );
});

test("HTTP API exposes GET-only health, snapshot, events, and snapshot-bound artifacts", async (t) => {
  const snapshot = workspaceSnapshot();
  const envelope = transportEnvelope(snapshot);
  const service = {
    async getSnapshot() {
      return envelope;
    },
  };
  const artifactStore = {
    async read(requestedPath, { snapshotId, expectedSha256 }) {
      assert.equal(requestedPath, "docs/proof.md");
      assert.equal(snapshotId, snapshot.snapshotId);
      assert.equal(expectedSha256, snapshot.artifacts[0].sha256);
      return {
        ...snapshot.artifacts[0],
        content: "proof",
        truncated: false,
        snapshotId,
      };
    },
  };
  const origin = await listen(
    t,
    createRequestHandler({
      config: {
        projectRoot: "/workspace/use-case",
        serveDist: false,
        distRoot: "/does/not/matter",
      },
      service,
      artifactStore,
      pollMs: 20,
    }),
  );

  const health = await fetch(`${origin}/api/health`);
  assert.equal(health.status, 200);
  const healthDocument = await health.json();
  assert.equal(healthDocument.service, "converge-cockpit");
  assert.equal(healthDocument.mode, "read-only");

  const rebound = await getWithHost(
    origin,
    "/api/snapshot",
    "cockpit.attacker.example",
  );
  assert.equal(rebound.status, 403);
  assert.equal(rebound.document.error.code, "HOST_NOT_ALLOWED");

  for (const method of ["POST", "PUT", "PATCH", "DELETE", "HEAD"]) {
    const mutation = await fetch(`${origin}/api/snapshot`, { method });
    assert.equal(mutation.status, 405);
    if (method !== "HEAD") {
      assert.equal((await mutation.json()).error.code, "METHOD_NOT_ALLOWED");
    }
    assert.equal(mutation.headers.get("allow"), "GET");
  }

  const snapshotResponse = await fetch(`${origin}/api/snapshot`);
  assert.deepEqual(await snapshotResponse.json(), envelope);

  const artifact = await fetch(
    `${origin}/api/artifact?path=${encodeURIComponent("docs/proof.md")}` +
      `&snapshotId=${snapshot.snapshotId}&sha256=${snapshot.artifacts[0].sha256}`,
  );
  assert.equal(artifact.status, 200);
  const artifactDocument = await artifact.json();
  assert.equal(artifactDocument.content, "proof");
  assert.equal(artifactDocument.snapshotId, snapshot.snapshotId);

  const unknown = await fetch(`${origin}/api/command`);
  assert.equal(unknown.status, 404);
});

test("SSE emits semantic changes and stale transport transitions", async (t) => {
  const first = workspaceSnapshot({ snapshotId: "ws_first_snapshot_123" });
  const second = workspaceSnapshot({ snapshotId: "ws_second_snapshot_45" });
  let freshCalls = 0;
  const service = {
    async getSnapshot({ fresh = false } = {}) {
      if (!fresh) {
        return transportEnvelope(first);
      }
      freshCalls += 1;
      if (freshCalls < 3) {
        return transportEnvelope(first, {
          stale: freshCalls === 2,
          error:
            freshCalls === 2
              ? { code: "SNAPSHOT_REFRESH_FAILED", message: "stale" }
              : undefined,
        });
      }
      return transportEnvelope(second);
    },
  };
  const origin = await listen(
    t,
    createRequestHandler({
      config: {
        projectRoot: "/workspace/use-case",
        serveDist: false,
        distRoot: "/unused",
      },
      service,
      artifactStore: { async read() {} },
      pollMs: 10,
    }),
  );

  const controller = new AbortController();
  const events = await fetch(`${origin}/api/events`, {
    signal: controller.signal,
  });
  assert.equal(
    events.headers.get("content-type"),
    "text/event-stream; charset=utf-8",
  );
  const reader = events.body.getReader();
  const decoder = new TextDecoder();
  let eventText = "";
  while (!eventText.includes(`id: ${second.snapshotId}`)) {
    const { value, done } = await reader.read();
    if (done) break;
    eventText += decoder.decode(value, { stream: true });
  }
  controller.abort();

  assert.equal(
    eventText.match(/^event: snapshot$/gm)?.length,
    3,
    eventText,
  );
  assert.equal(
    eventText.match(new RegExp(`^id: ${first.snapshotId}$`, "gm"))?.length,
    2,
    eventText,
  );
  assert.match(eventText, new RegExp(`id: ${second.snapshotId}`));
  assert.match(eventText, /"stale":true/);
});
