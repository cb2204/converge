import { createHash } from "node:crypto";
import { createReadStream } from "node:fs";
import { lstat, realpath, stat } from "node:fs/promises";
import path from "node:path";

import { redactSensitiveText } from "./security.mjs";

const DEFAULT_MAX_BYTES = 256 * 1024;

function normalizeRequestedPath(requestedPath) {
  if (
    typeof requestedPath !== "string" ||
    requestedPath.length === 0 ||
    requestedPath.includes("\0") ||
    requestedPath.includes("\\") ||
    path.posix.isAbsolute(requestedPath)
  ) {
    return null;
  }

  const normalized = path.posix.normalize(requestedPath);
  if (
    normalized !== requestedPath ||
    normalized === "." ||
    normalized === ".." ||
    normalized.startsWith("../")
  ) {
    return null;
  }
  return normalized;
}

export class ArtifactStore {
  constructor({ projectRoot, maxBytes = DEFAULT_MAX_BYTES }) {
    this.projectRoot = projectRoot;
    this.maxBytes = maxBytes;
    this.allowed = new Map();
    this.snapshotId = null;
    this.projectRealPath = null;
  }

  setAllowedArtifacts(records, snapshotId) {
    if (!Array.isArray(records) || typeof snapshotId !== "string") {
      const error = new Error("snapshot artifact references are malformed");
      error.code = "SNAPSHOT_SCHEMA_INVALID";
      throw error;
    }
    const nextAllowed = new Map();
    for (const record of records) {
      const relativePath = normalizeRequestedPath(record?.path);
      if (
        !relativePath ||
        typeof record?.id !== "string" ||
        typeof record?.label !== "string" ||
        typeof record?.kind !== "string" ||
        typeof record?.sha256 !== "string" ||
        !/^[a-f0-9]{64}$/i.test(record.sha256) ||
        typeof record?.provenance !== "object" ||
        record.provenance === null ||
        nextAllowed.has(relativePath)
      ) {
        const error = new Error(
          "snapshot contains an unsafe or duplicate artifact reference",
        );
        error.code = "SNAPSHOT_SCHEMA_INVALID";
        throw error;
      }
      nextAllowed.set(relativePath, {
        id: record.id,
        label: record.label,
        kind: record.kind,
        sha256: record.sha256.toLowerCase(),
        ...(record.entity ? { entity: record.entity } : {}),
        provenance: record.provenance,
      });
    }
    this.allowed = nextAllowed;
    this.snapshotId = snapshotId;
  }

  async read(requestedPath, { snapshotId, expectedSha256 } = {}) {
    const relativePath = normalizeRequestedPath(requestedPath);
    const metadata = relativePath ? this.allowed.get(relativePath) : null;
    if (!relativePath || !metadata) {
      const error = new Error("artifact is not in the workspace evidence allowlist");
      error.code = "ARTIFACT_NOT_ALLOWED";
      throw error;
    }
    if (!snapshotId || snapshotId !== this.snapshotId) {
      const error = new Error(
        "artifact request is not bound to the current workspace snapshot",
      );
      error.code = "SNAPSHOT_STALE";
      throw error;
    }
    if (typeof expectedSha256 !== "string") {
      const error = new Error(
        "artifact request is missing the captured evidence hash",
      );
      error.code = "EVIDENCE_HASH_REQUIRED";
      throw error;
    }
    if (expectedSha256.toLowerCase() !== metadata.sha256) {
      const error = new Error(
        "artifact request hash does not match the captured evidence reference",
      );
      error.code = "EVIDENCE_STALE";
      throw error;
    }

    const projectRealPath =
      this.projectRealPath ?? (this.projectRealPath = await realpath(this.projectRoot));
    const absolutePath = path.resolve(projectRealPath, relativePath);
    const unresolvedInfo = await lstat(absolutePath);
    if (unresolvedInfo.isSymbolicLink()) {
      const error = new Error("symbolic-link artifacts are not exposed");
      error.code = "ARTIFACT_NOT_ALLOWED";
      throw error;
    }
    const resolvedPath = await realpath(absolutePath);
    if (
      resolvedPath !== projectRealPath &&
      !resolvedPath.startsWith(`${projectRealPath}${path.sep}`)
    ) {
      const error = new Error("artifact resolves outside the observed workspace");
      error.code = "ARTIFACT_NOT_ALLOWED";
      throw error;
    }

    const info = await stat(resolvedPath);
    if (!info.isFile()) {
      const error = new Error("artifact is not a regular file");
      error.code = "ARTIFACT_NOT_ALLOWED";
      throw error;
    }

    const digest = createHash("sha256");
    const previewChunks = [];
    let previewBytes = 0;
    for await (const chunk of createReadStream(resolvedPath)) {
      digest.update(chunk);
      if (previewBytes < this.maxBytes) {
        const remaining = this.maxBytes - previewBytes;
        const previewChunk = chunk.subarray(0, remaining);
        previewChunks.push(previewChunk);
        previewBytes += previewChunk.byteLength;
      }
    }
    const actualSha256 = digest.digest("hex");
    if (actualSha256 !== metadata.sha256) {
      const error = new Error(
        "artifact bytes changed after the workspace snapshot was captured",
      );
      error.code = "EVIDENCE_STALE";
      throw error;
    }

    let content = Buffer.concat(previewChunks).toString("utf8");
    if (content.includes("\0")) {
      const error = new Error("binary artifacts are not exposed by the bridge");
      error.code = "ARTIFACT_NOT_ALLOWED";
      throw error;
    }
    content = redactSensitiveText(content);

    return {
      id: metadata.id,
      path: relativePath,
      label: metadata.label,
      kind: metadata.kind,
      content,
      truncated: info.size > this.maxBytes,
      sha256: actualSha256,
      snapshotId,
      ...(metadata.entity ? { entity: metadata.entity } : {}),
      provenance: metadata.provenance,
    };
  }
}

export { normalizeRequestedPath };
