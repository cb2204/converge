import { execFile as nodeExecFile } from "node:child_process";

import { createReadOnlyEnvironment } from "./security.mjs";

const GIT_READS = Object.freeze({
  branch: Object.freeze(["rev-parse", "--abbrev-ref", "HEAD"]),
  commit: Object.freeze(["rev-parse", "HEAD"]),
  dirty: Object.freeze([
    "status",
    "--porcelain",
    "--untracked-files=normal",
    "--",
    ".",
  ]),
  committedAt: Object.freeze(["log", "-1", "--format=%cI"]),
});

export function createGitReader({
  config,
  execFileImpl = nodeExecFile,
  baseEnvironment = process.env,
} = {}) {
  const environment = createReadOnlyEnvironment(baseEnvironment, config);

  function read(name) {
    const args = GIT_READS[name];
    if (!args) {
      return Promise.reject(new Error(`undeclared git read: ${name}`));
    }

    return new Promise((resolve) => {
      execFileImpl(
        "git",
        [...args],
        {
          cwd: config.projectRoot,
          env: environment,
          encoding: "utf8",
          maxBuffer: 512 * 1024,
          timeout: 5_000,
          windowsHide: true,
        },
        (error, stdout = "") => {
          resolve(error ? null : stdout.trim());
        },
      );
    });
  }

  return Object.freeze({
    async readState() {
      const [branch, commit, dirtyOutput, committedAt] = await Promise.all([
        read("branch"),
        read("commit"),
        read("dirty"),
        read("committedAt"),
      ]);
      return {
        branch: branch || "detached",
        commit: commit || "unknown",
        dirty: dirtyOutput === null ? false : dirtyOutput.length > 0,
        committedAt:
          committedAt && !Number.isNaN(Date.parse(committedAt))
            ? committedAt
            : null,
      };
    },
  });
}
