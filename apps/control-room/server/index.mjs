#!/usr/bin/env node

import { createServer } from "node:http";

import { createRequestHandler } from "./app.mjs";
import { ArtifactStore } from "./artifact-store.mjs";
import {
  resolveServerConfig,
  SERVER_USAGE,
} from "./config.mjs";
import { createCvgRunner } from "./cvg.mjs";
import { createGitReader } from "./git.mjs";
import { SnapshotService } from "./service.mjs";
import { buildWorkspaceSnapshot } from "./snapshot.mjs";

async function main() {
  let config;
  try {
    config = await resolveServerConfig({ argv: process.argv.slice(2) });
  } catch (error) {
    process.stderr.write(`control-room: ${error.message}\n\n${SERVER_USAGE}`);
    process.exitCode = 2;
    return;
  }
  if (config.help) {
    process.stdout.write(SERVER_USAGE);
    return;
  }

  const runner = createCvgRunner({ config });
  const gitReader = createGitReader({ config });
  const artifactStore = new ArtifactStore({
    projectRoot: config.projectRoot,
  });
  const service = new SnapshotService({
    build: () =>
      buildWorkspaceSnapshot({
        config,
        runner,
        gitReader,
        artifactStore,
      }),
  });
  const handler = createRequestHandler({
    config,
    service,
    artifactStore,
  });
  const server = createServer(handler);

  server.on("clientError", (_error, socket) => {
    socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(config.port, config.host, resolve);
  });

  const displayHost = config.host === "::1" ? "[::1]" : config.host;
  process.stdout.write(
    `Converge Control Room bridge\n` +
      `  mode    read-only\n` +
      `  project ${config.projectRoot}\n` +
      `  api     http://${displayHost}:${config.port}/api/health\n`,
  );

  const shutdown = () => {
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(0), 2_000).unref();
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

await main();
