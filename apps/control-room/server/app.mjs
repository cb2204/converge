import { readFile, stat } from "node:fs/promises";
import path from "node:path";

import { publicError } from "./security.mjs";

const CONTENT_TYPES = Object.freeze({
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
});

function setSecurityHeaders(response) {
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Referrer-Policy", "no-referrer");
  response.setHeader("X-Frame-Options", "DENY");
  response.setHeader(
    "Content-Security-Policy",
    "default-src 'self'; connect-src 'self'; font-src 'self' data:; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  );
}

function sendJson(response, statusCode, document) {
  const body = JSON.stringify(document);
  response.writeHead(statusCode, {
    "Cache-Control": "no-store",
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
  });
  response.end(body);
}

async function serveStatic(response, pathname, distRoot, headOnly) {
  let decoded;
  try {
    decoded = decodeURIComponent(pathname);
  } catch {
    return false;
  }
  if (decoded.includes("\0") || decoded.includes("\\")) {
    return false;
  }

  const relative = decoded.replace(/^\/+/, "");
  const candidate = path.resolve(distRoot, relative || "index.html");
  if (
    candidate !== distRoot &&
    !candidate.startsWith(`${path.resolve(distRoot)}${path.sep}`)
  ) {
    return false;
  }

  let selected = candidate;
  try {
    const info = await stat(selected);
    if (!info.isFile()) {
      selected = path.join(distRoot, "index.html");
    }
  } catch {
    if (path.extname(relative)) {
      return false;
    }
    selected = path.join(distRoot, "index.html");
  }

  try {
    const contents = await readFile(selected);
    response.writeHead(200, {
      "Cache-Control":
        path.basename(selected) === "index.html"
          ? "no-cache"
          : "public, max-age=31536000, immutable",
      "Content-Type":
        CONTENT_TYPES[path.extname(selected).toLowerCase()] ??
        "application/octet-stream",
      "Content-Length": contents.byteLength,
    });
    response.end(headOnly ? undefined : contents);
    return true;
  } catch {
    return false;
  }
}

function beginEventStream(request, response, service, pollMs) {
  response.writeHead(200, {
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive",
    "Content-Type": "text/event-stream; charset=utf-8",
    "X-Accel-Buffering": "no",
  });
  response.write("retry: 4000\n\n");

  let closed = false;
  let lastSnapshotId = null;
  let polling = false;

  const emitSnapshot = async (fresh) => {
    if (closed || polling) {
      return;
    }
    polling = true;
    try {
      const snapshot = await service.getSnapshot({ fresh });
      if (!closed && snapshot.snapshotId !== lastSnapshotId) {
        lastSnapshotId = snapshot.snapshotId;
        response.write(`id: ${snapshot.snapshotId}\n`);
        response.write("event: snapshot\n");
        response.write(`data: ${JSON.stringify(snapshot)}\n\n`);
      }
    } catch {
      if (!closed) {
        response.write("event: bridge-error\n");
        response.write(
          `data: ${JSON.stringify({ code: "SNAPSHOT_UNAVAILABLE", message: "The read-only snapshot could not be refreshed." })}\n\n`,
        );
      }
    } finally {
      polling = false;
    }
  };

  void emitSnapshot(false);
  const pollTimer = setInterval(() => void emitSnapshot(true), pollMs);
  const heartbeatTimer = setInterval(() => {
    if (!closed) {
      response.write(`: heartbeat ${Date.now()}\n\n`);
    }
  }, 15_000);
  pollTimer.unref();
  heartbeatTimer.unref();

  request.on("close", () => {
    closed = true;
    clearInterval(pollTimer);
    clearInterval(heartbeatTimer);
  });
}

export function createRequestHandler({
  config,
  service,
  artifactStore,
  pollMs = 5_000,
}) {
  return (request, response) => {
    setSecurityHeaders(response);

    void (async () => {
      const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
      const isGet = request.method === "GET";
      const isHead = request.method === "HEAD";

      if (url.pathname.startsWith("/api/") && !isGet) {
        response.setHeader("Allow", "GET");
        sendJson(
          response,
          405,
          publicError("METHOD_NOT_ALLOWED", "The bridge exposes read-only GET endpoints."),
        );
        return;
      }

      if (url.pathname === "/api/health") {
        sendJson(response, 200, {
          ok: true,
          service: "converge-control-room",
          mode: "read-only",
          project: path.basename(config.projectRoot),
        });
        return;
      }

      if (url.pathname === "/api/snapshot") {
        try {
          sendJson(response, 200, await service.getSnapshot());
        } catch {
          sendJson(
            response,
            503,
            publicError(
              "SNAPSHOT_UNAVAILABLE",
              "The read-only workspace snapshot is unavailable.",
            ),
          );
        }
        return;
      }

      if (url.pathname === "/api/events") {
        beginEventStream(request, response, service, pollMs);
        return;
      }

      if (url.pathname === "/api/artifact") {
        const requestedPath = url.searchParams.get("path");
        const requestedSnapshotId = url.searchParams.get("snapshotId");
        const expectedSha256 = url.searchParams.get("sha256") ?? undefined;
        if (!requestedPath) {
          sendJson(
            response,
            400,
            publicError("ARTIFACT_PATH_REQUIRED", "A single artifact path is required."),
          );
          return;
        }
        if (!requestedSnapshotId) {
          sendJson(
            response,
            400,
            publicError(
              "SNAPSHOT_ID_REQUIRED",
              "Artifact reads must be bound to a workspace snapshot.",
            ),
          );
          return;
        }
        try {
          const snapshot = await service.getSnapshot();
          if (snapshot.snapshotId !== requestedSnapshotId) {
            const error = new Error("the requested snapshot is no longer current");
            error.code = "SNAPSHOT_STALE";
            throw error;
          }
          sendJson(
            response,
            200,
            await artifactStore.read(requestedPath, {
              snapshotId: requestedSnapshotId,
              expectedSha256,
            }),
          );
        } catch (error) {
          const notAllowed = error?.code === "ARTIFACT_NOT_ALLOWED";
          const stale =
            error?.code === "SNAPSHOT_STALE" ||
            error?.code === "EVIDENCE_STALE";
          sendJson(
            response,
            stale ? 409 : notAllowed ? 403 : 404,
            publicError(
              stale
                ? error.code
                : notAllowed
                  ? "ARTIFACT_NOT_ALLOWED"
                  : "ARTIFACT_NOT_FOUND",
              stale
                ? "The artifact no longer matches the captured workspace snapshot. Refresh before inspecting it."
                : notAllowed
                ? "The requested artifact is not in the workspace evidence allowlist."
                : "The requested artifact is unavailable.",
            ),
          );
        }
        return;
      }

      if (url.pathname.startsWith("/api/")) {
        sendJson(
          response,
          404,
          publicError("NOT_FOUND", "No read-only endpoint exists at this path."),
        );
        return;
      }

      if (
        config.serveDist &&
        (isGet || isHead) &&
        (await serveStatic(response, url.pathname, config.distRoot, isHead))
      ) {
        return;
      }

      sendJson(
        response,
        404,
        publicError(
          "NOT_FOUND",
          config.serveDist
            ? "The requested resource was not found."
            : "The client is served separately in development mode.",
        ),
      );
    })().catch(() => {
      if (!response.headersSent) {
        sendJson(
          response,
          500,
          publicError("BRIDGE_ERROR", "The read-only bridge could not complete the request."),
        );
      } else {
        response.end();
      }
    });
  };
}

export { beginEventStream, serveStatic };
