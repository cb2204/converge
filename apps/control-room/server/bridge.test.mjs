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
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { createRequestHandler } from "./app.mjs";
import { ArtifactStore } from "./artifact-store.mjs";
import { resolveServerConfig } from "./config.mjs";
import { createCvgRunner } from "./cvg.mjs";
import { buildWorkspaceSnapshot } from "./snapshot.mjs";

async function withTempDirectory(t) {
  const directory = await mkdtemp(path.join(tmpdir(), "cvg-control-room-test-"));
  t.after(() => rm(directory, { force: true, recursive: true }));
  return directory;
}

test("server config requires explicit roots and only binds to loopback", async (t) => {
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
    /local-only/,
  );
});

test("cvg runner uses an argument array, fixed read-only commands, and a credential-free environment", async () => {
  let invocation;
  const execFileImpl = (file, args, options, callback) => {
    invocation = { file, args, options };
    callback(
      null,
      JSON.stringify({
        ok: true,
        token: "CHECK_CONSENSUS=OK",
        verdict: "OK",
        exit_code: 0,
      }),
      "",
    );
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

  const result = await runner.run("pass4");
  assert.deepEqual(invocation.args, ["review", "--check", "--json"]);
  assert.equal(invocation.file, "/tool/bin/cvg");
  assert.equal(invocation.options.cwd, "/workspace");
  assert.equal(invocation.options.shell, undefined);
  assert.equal(invocation.options.env.CVG_HOME, "/tool");
  assert.equal(invocation.options.env.CVG_PROJECT_ROOT, "/workspace");
  assert.equal(invocation.options.env.GITHUB_TOKEN, undefined);
  assert.equal(invocation.options.env.OPENAI_API_KEY, undefined);
  assert.equal(result.document.verdict, "OK");

  await assert.rejects(runner.run("review-dispatch"), /undeclared read-only/);
});

function envelope({ token, verdict, ok = true, output = "" }) {
  return {
    ok,
    token,
    verdict,
    exit_code: ok ? 0 : 1,
    data: { output },
  };
}

test("snapshot keeps review, gate, blocking questions, and CLI authorization separate", async (t) => {
  const projectRoot = await withTempDirectory(t);
  await mkdir(path.join(projectRoot, "cvg", "docs", "brd"), {
    recursive: true,
  });
  await mkdir(path.join(projectRoot, "cvg", "swimlanes", ".consensus"), {
    recursive: true,
  });
  await writeFile(
    path.join(projectRoot, "cvg", "docs", "brd", "example.md"),
    "# BRD — Trusted category profitability\n",
  );
  await writeFile(
    path.join(
      projectRoot,
      "cvg",
      "swimlanes",
      ".consensus",
      "objection-log.json",
    ),
    JSON.stringify({
      verdict: "REVISE",
      rounds_run: 2,
      adversary: {
        engine_id: "codex",
        family: "openai",
        engine_version: "test",
      },
      author: { family: "anthropic" },
      objections: [
        {
          id: "C1",
          title: "Independent lineage is missing",
          severity: "critical",
          resolution: { disposition: "FIX", risk_residual: "Open" },
        },
      ],
      open_questions: [
        { q: "Who owns the evidence?", owner: "analytics", blocks_build: true },
      ],
    }),
  );

  const nextOutput = [
    "conductor — descent position (lane FULL)",
    "  [+] pass 0 · Capture",
    "  [+] pass 1 · Intent",
    "  [+] pass 2 · Structure",
    "  [+] pass 3 · Decompose",
    "  [+] pass 4 · Consensus",
    "  [.] pass 5 · Tasking",
    "  [.] pass 7 · Bind",
    "  [.] pass 8 · Loop",
  ].join("\n");
  const documents = {
    context: {
      schema_version: "1.0",
      version: "0.1.0",
      role: "referee",
      commands: [{}, {}, {}],
    },
    next: envelope({
      token: "NEXT_PASS=5",
      verdict: "5",
      output: nextOutput,
    }),
    pass0: envelope({ token: "CHECK_BRD=PASS", verdict: "PASS" }),
    pass1: envelope({ token: "CHECK_TECH_SPEC=PASS", verdict: "PASS" }),
    pass2: envelope({ token: "CHECK_ADR=OK", verdict: "OK" }),
    pass3: envelope({ token: "CHECK_PLAN=OK", verdict: "OK" }),
    pass4: envelope({ token: "CHECK_CONSENSUS=OK", verdict: "OK" }),
  };
  const runner = {
    async run(commandName) {
      return {
        parsed: true,
        exitCode: documents[commandName].exit_code ?? 0,
        document: documents[commandName],
      };
    },
  };
  const gitReader = {
    async readState() {
      return {
        branch: "main",
        commit: "abc123",
        dirty: false,
        committedAt: "2026-08-03T12:00:00.000Z",
      };
    },
  };
  const config = {
    projectRoot,
    cvgHome: "/tool",
    cvgBin: "/tool/bin/cvg",
  };
  const artifactStore = new ArtifactStore({ projectRoot });
  const first = await buildWorkspaceSnapshot({
    config,
    runner,
    gitReader,
    artifactStore,
    now: () => new Date("2026-08-03T13:00:00.000Z"),
  });
  const second = await buildWorkspaceSnapshot({
    config,
    runner,
    gitReader,
    artifactStore,
    now: () => new Date("2026-08-03T14:00:00.000Z"),
  });

  assert.equal(first.snapshotId, second.snapshotId);
  assert.notEqual(first.generatedAt, second.generatedAt);
  assert.equal(first.project.name, "Trusted category profitability");
  assert.equal(first.review.verdict, "REVISE");
  assert.equal(first.review.openQuestions[0].blocksBuild, true);
  assert.equal(first.authorization.state, "allowed");
  assert.equal(first.authorization.nextPassId, "pass-5");
  assert.equal(first.method.activePassId, "pass-5");
  const knownPassIds = new Set(first.method.passes.map((pass) => pass.id));
  assert.ok(first.activity.length > 0);
  assert.ok(
    first.activity.every(
      (activity) =>
        typeof activity.passId === "string" &&
        knownPassIds.has(activity.passId),
    ),
  );

  const consensus = first.method.passes.find((pass) => pass.id === "pass-4");
  assert.equal(consensus.gate.verdict, "OK");
  assert.equal(consensus.status, "attention");
  assert.equal(consensus.blockerCount, 1);

  const register = first.method.passes.find((pass) => pass.id === "pass-6");
  assert.equal(register.status, "optional");
  assert.equal(register.optional, true);
  assert.ok(
    first.method.edges.some(
      (edge) =>
        edge.source === "pass-5" &&
        edge.target === "pass-6" &&
        edge.kind === "optional",
    ),
  );
  assert.ok(
    first.method.edges.some(
      (edge) => edge.source === "pass-5" && edge.target === "pass-7",
    ),
  );
});

test("artifact store allowlists evidence, blocks traversal and symlink escapes, truncates, and redacts secrets", async (t) => {
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
  await writeFile(
    path.join(projectRoot, "docs", "safe.md"),
    safeContents,
  );
  await writeFile(path.join(projectRoot, "docs", "large.md"), largeContents);
  await writeFile(path.join(outsideRoot, "outside.md"), "not allowed");
  await symlink(
    path.join(outsideRoot, "outside.md"),
    path.join(projectRoot, "docs", "escape.md"),
  );

  const store = new ArtifactStore({ projectRoot, maxBytes: 32 });
  const sha256 = (contents) =>
    createHash("sha256").update(contents).digest("hex");
  store.setAllowedArtifacts(
    [
      {
        path: "docs/safe.md",
        label: "Safe",
        kind: "artifact",
        sha256: sha256(safeContents),
      },
      {
        path: "docs/large.md",
        label: "Large",
        kind: "artifact",
        sha256: sha256(largeContents),
      },
      {
        path: "docs/escape.md",
        label: "Escape",
        kind: "artifact",
        sha256: sha256("not allowed"),
      },
    ],
    "ws_snapshot_one",
  );

  const safe = await store.read("docs/safe.md", {
    snapshotId: "ws_snapshot_one",
    expectedSha256: sha256(safeContents),
  });
  assert.equal(safe.content.includes("super-secret-value"), false);
  assert.equal(safe.content.includes("[REDACTED]"), true);
  assert.equal(safe.sha256, sha256(safeContents));
  assert.equal(safe.snapshotId, "ws_snapshot_one");

  const large = await store.read("docs/large.md", {
    snapshotId: "ws_snapshot_one",
  });
  assert.equal(large.truncated, true);
  assert.equal(Buffer.byteLength(large.content) <= 32, true);

  await assert.rejects(
    store.read("../outside.md", { snapshotId: "ws_snapshot_one" }),
    {
      code: "ARTIFACT_NOT_ALLOWED",
    },
  );
  await assert.rejects(
    store.read("docs/escape.md", { snapshotId: "ws_snapshot_one" }),
    {
      code: "ARTIFACT_NOT_ALLOWED",
    },
  );
  await assert.rejects(
    store.read("docs/not-allowlisted.md", {
      snapshotId: "ws_snapshot_one",
    }),
    {
      code: "ARTIFACT_NOT_ALLOWED",
    },
  );
  await assert.rejects(
    store.read("docs/safe.md", { snapshotId: "ws_old_snapshot" }),
    {
      code: "SNAPSHOT_STALE",
    },
  );
  await assert.rejects(
    store.read("docs/safe.md", {
      snapshotId: "ws_snapshot_one",
      expectedSha256: sha256("different"),
    }),
    {
      code: "EVIDENCE_STALE",
    },
  );

  await writeFile(path.join(projectRoot, "docs", "safe.md"), "changed after capture");
  await assert.rejects(
    store.read("docs/safe.md", { snapshotId: "ws_snapshot_one" }),
    {
      code: "EVIDENCE_STALE",
    },
  );
});

test("artifact preview rejects a stale snapshot before presenting evidence", async () => {
  const snapshot = {
    schemaVersion: "1.0",
    snapshotId: "ws_current_snapshot",
  };
  const service = {
    async getSnapshot() {
      return snapshot;
    },
  };
  let artifactRead = false;
  const artifactStore = {
    async read() {
      artifactRead = true;
      return {};
    },
  };
  const server = createServer(
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
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  const response = await fetch(
    `http://127.0.0.1:${address.port}/api/artifact?path=docs%2Fevidence.md&snapshotId=ws_old_snapshot`,
  );
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));

  assert.equal(response.status, 409);
  assert.equal((await response.json()).error.code, "SNAPSHOT_STALE");
  assert.equal(artifactRead, false);
});

test("serve-dist mode serves the built client and SPA routes", async (t) => {
  const distRoot = await withTempDirectory(t);
  await mkdir(path.join(distRoot, "assets"));
  await writeFile(
    path.join(distRoot, "index.html"),
    "<!doctype html><title>Control Room</title>",
  );
  await writeFile(path.join(distRoot, "assets", "app.js"), "export {};\n");

  const server = createServer(
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
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(
    () =>
      new Promise((resolve) => {
        server.close(resolve);
        server.closeAllConnections();
      }),
  );
  const address = server.address();
  const origin = `http://127.0.0.1:${address.port}`;

  const rootResponse = await fetch(`${origin}/`);
  assert.equal(rootResponse.status, 200);
  assert.match(await rootResponse.text(), /Control Room/);

  const routeResponse = await fetch(`${origin}/passes/4`);
  assert.equal(routeResponse.status, 200);
  assert.match(await routeResponse.text(), /Control Room/);

  const assetResponse = await fetch(`${origin}/assets/app.js`);
  assert.equal(assetResponse.status, 200);
  assert.equal(assetResponse.headers.get("content-type"), "text/javascript; charset=utf-8");
});

test("HTTP bridge exposes only read-only health, snapshot, events, and allowlisted artifact routes", async (t) => {
  const snapshot = {
    schemaVersion: "1.0",
    snapshotId: "ws_1234567890123456",
  };
  const service = {
    async getSnapshot() {
      return snapshot;
    },
  };
  const artifactStore = {
    async read(requestedPath, { snapshotId }) {
      if (requestedPath !== "docs/evidence.md") {
        const error = new Error("not allowed");
        error.code = "ARTIFACT_NOT_ALLOWED";
        throw error;
      }
      return {
        path: requestedPath,
        label: "Evidence",
        kind: "artifact",
        content: "proof",
        truncated: false,
        sha256: "abc",
        snapshotId,
      };
    },
  };
  const config = {
    projectRoot: "/workspace/use-case",
    serveDist: false,
    distRoot: "/does/not/matter",
  };
  const server = createServer(
    createRequestHandler({
      config,
      service,
      artifactStore,
      pollMs: 20,
    }),
  );
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(
    () =>
      new Promise((resolve) => {
        server.close(resolve);
        server.closeAllConnections();
      }),
  );
  const address = server.address();
  const origin = `http://127.0.0.1:${address.port}`;

  const health = await fetch(`${origin}/api/health`);
  assert.equal(health.status, 200);
  assert.equal((await health.json()).mode, "read-only");

  const mutation = await fetch(`${origin}/api/snapshot`, { method: "POST" });
  assert.equal(mutation.status, 405);
  assert.equal((await mutation.json()).error.code, "METHOD_NOT_ALLOWED");

  const snapshotResponse = await fetch(`${origin}/api/snapshot`);
  assert.deepEqual(await snapshotResponse.json(), snapshot);

  const artifact = await fetch(
    `${origin}/api/artifact?path=${encodeURIComponent("docs/evidence.md")}&snapshotId=${snapshot.snapshotId}`,
  );
  const artifactDocument = await artifact.json();
  assert.equal(artifactDocument.content, "proof");
  assert.equal(artifactDocument.snapshotId, snapshot.snapshotId);

  const blockedArtifact = await fetch(
    `${origin}/api/artifact?path=${encodeURIComponent("../secret")}&snapshotId=${snapshot.snapshotId}`,
  );
  assert.equal(blockedArtifact.status, 403);

  const controller = new AbortController();
  const events = await fetch(`${origin}/api/events`, {
    signal: controller.signal,
  });
  assert.equal(events.headers.get("content-type"), "text/event-stream; charset=utf-8");
  const reader = events.body.getReader();
  let eventText = "";
  while (!eventText.includes("event: snapshot")) {
    const { value, done } = await reader.read();
    if (done) {
      break;
    }
    eventText += new TextDecoder().decode(value);
  }
  assert.match(eventText, /id: ws_1234567890123456/);
  controller.abort();
});
