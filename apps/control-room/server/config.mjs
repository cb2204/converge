import { constants } from "node:fs";
import { access, realpath, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SERVER_DIR = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(SERVER_DIR, "..");

function takeValue(argv, index, flag) {
  const value = argv[index + 1];
  if (!value || value.startsWith("--")) {
    throw new Error(`${flag} requires a value`);
  }
  return value;
}

export function parseServerArgs(argv = []) {
  const parsed = {
    cvgHome: undefined,
    projectRoot: undefined,
    host: "127.0.0.1",
    port: 4174,
    serveDist: false,
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];

    if (argument === "--cvg-home") {
      parsed.cvgHome = takeValue(argv, index, argument);
      index += 1;
    } else if (argument.startsWith("--cvg-home=")) {
      parsed.cvgHome = argument.slice("--cvg-home=".length);
    } else if (argument === "--project-root") {
      parsed.projectRoot = takeValue(argv, index, argument);
      index += 1;
    } else if (argument.startsWith("--project-root=")) {
      parsed.projectRoot = argument.slice("--project-root=".length);
    } else if (argument === "--host") {
      parsed.host = takeValue(argv, index, argument);
      index += 1;
    } else if (argument.startsWith("--host=")) {
      parsed.host = argument.slice("--host=".length);
    } else if (argument === "--port") {
      parsed.port = Number(takeValue(argv, index, argument));
      index += 1;
    } else if (argument.startsWith("--port=")) {
      parsed.port = Number(argument.slice("--port=".length));
    } else if (argument === "--serve-dist") {
      parsed.serveDist = true;
    } else if (argument === "--help" || argument === "-h") {
      parsed.help = true;
    } else {
      throw new Error(`unknown option: ${argument}`);
    }
  }

  return parsed;
}

async function requireDirectory(candidate, label) {
  const absolute = path.resolve(candidate);
  let info;
  try {
    info = await stat(absolute);
  } catch {
    throw new Error(`${label} does not exist: ${absolute}`);
  }
  if (!info.isDirectory()) {
    throw new Error(`${label} is not a directory: ${absolute}`);
  }
  return realpath(absolute);
}

export async function resolveServerConfig({
  argv = [],
  env = process.env,
} = {}) {
  const args = parseServerArgs(argv);
  if (args.help) {
    return { help: true };
  }

  const cvgHomeInput = args.cvgHome ?? env.CVG_HOME;
  const projectRootInput = args.projectRoot ?? env.CVG_PROJECT_ROOT;

  if (!cvgHomeInput || !projectRootInput) {
    throw new Error(
      "CVG_HOME and CVG_PROJECT_ROOT are required; pass --cvg-home and --project-root or set both environment variables",
    );
  }

  if (!["127.0.0.1", "localhost", "::1"].includes(args.host)) {
    throw new Error(
      "the Control Room bridge is local-only; --host must be 127.0.0.1, localhost, or ::1",
    );
  }
  if (!Number.isInteger(args.port) || args.port < 1 || args.port > 65_535) {
    throw new Error("--port must be an integer between 1 and 65535");
  }

  const [cvgHome, projectRoot] = await Promise.all([
    requireDirectory(cvgHomeInput, "CVG_HOME"),
    requireDirectory(projectRootInput, "CVG_PROJECT_ROOT"),
  ]);
  const cvgBin = path.join(cvgHome, "bin", "cvg");

  try {
    await access(cvgBin, constants.X_OK);
  } catch {
    throw new Error(`Converge executable is missing or not executable: ${cvgBin}`);
  }

  return {
    help: false,
    cvgHome,
    projectRoot,
    cvgBin,
    host: args.host,
    port: args.port,
    serveDist: args.serveDist,
    distRoot: path.join(APP_ROOT, "dist"),
    appRoot: APP_ROOT,
  };
}

export const SERVER_USAGE = `Converge Control Room (read-only)

Usage:
  node server/index.mjs --cvg-home <path> --project-root <path> [options]

Required:
  --cvg-home <path>      Converge checkout containing bin/cvg
  --project-root <path>  Consuming workspace to observe

Options:
  --host <loopback>      127.0.0.1 (default), localhost, or ::1
  --port <number>        4174 by default
  --serve-dist           Serve the built client from dist/
`;
