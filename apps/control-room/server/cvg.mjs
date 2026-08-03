import { execFile as nodeExecFile } from "node:child_process";

import { createReadOnlyEnvironment } from "./security.mjs";

export const READ_ONLY_CVG_COMMANDS = Object.freeze({
  context: Object.freeze(["agent-context"]),
  next: Object.freeze(["next", "--json"]),
  pass0: Object.freeze(["capture", "--json"]),
  pass1: Object.freeze(["intent", "--json"]),
  pass2: Object.freeze(["structure", "--json"]),
  pass3: Object.freeze(["decompose", "--json"]),
  pass4: Object.freeze(["review", "--check", "--json"]),
});

function parseDocument(stdout) {
  try {
    return JSON.parse(stdout);
  } catch {
    return null;
  }
}

export function createCvgRunner({
  config,
  execFileImpl = nodeExecFile,
  baseEnvironment = process.env,
  timeoutMs = 20_000,
} = {}) {
  if (!config?.cvgBin || !config?.cvgHome || !config?.projectRoot) {
    throw new Error("createCvgRunner requires cvgBin, cvgHome, and projectRoot");
  }

  const environment = createReadOnlyEnvironment(baseEnvironment, config);

  return Object.freeze({
    run(commandName) {
      const declaredArguments = READ_ONLY_CVG_COMMANDS[commandName];
      if (!declaredArguments) {
        return Promise.reject(
          new Error(`undeclared read-only cvg command: ${commandName}`),
        );
      }
      const argumentsCopy = [...declaredArguments];

      return new Promise((resolve) => {
        execFileImpl(
          config.cvgBin,
          argumentsCopy,
          {
            cwd: config.projectRoot,
            env: environment,
            encoding: "utf8",
            maxBuffer: 1024 * 1024,
            timeout: timeoutMs,
            windowsHide: true,
          },
          (error, stdout = "") => {
            const document = parseDocument(stdout);
            const errorCode =
              typeof error?.code === "number"
                ? error.code
                : typeof document?.exit_code === "number"
                  ? document.exit_code
                  : error
                    ? 2
                    : 0;

            resolve({
              commandName,
              arguments: argumentsCopy,
              exitCode: errorCode,
              document,
              parsed: document !== null,
              timedOut:
                error?.killed === true &&
                (error?.signal === "SIGTERM" || error?.code === "ETIMEDOUT"),
            });
          },
        );
      });
    },
  });
}
