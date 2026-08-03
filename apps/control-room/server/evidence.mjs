import { createHash } from "node:crypto";
import { lstat, readFile, readdir } from "node:fs/promises";
import path from "node:path";

import { redactSensitiveText } from "./security.mjs";

const TEXT_EXTENSIONS = new Set([
  ".json",
  ".jsonl",
  ".log",
  ".md",
  ".txt",
  ".yaml",
  ".yml",
]);

const PASS_SOURCES = Object.freeze({
  "pass-0": [
    { path: "cvg/docs/brd", recursive: true, kind: "brief" },
    { path: "BRIEF.md", recursive: false, kind: "brief" },
    {
      path: "cvg/brain/transcripts",
      recursive: true,
      kind: "artifact",
      filenameIncludes: "pass-0",
    },
    {
      path: "cvg/brain/decisions",
      recursive: true,
      kind: "decision",
      filenameIncludes: "pass-0",
    },
  ],
  "pass-1": [
    { path: "cvg/docs/tech-spec", recursive: true, kind: "spec" },
  ],
  "pass-2": [{ path: "cvg/docs/adrs", recursive: true, kind: "decision" }],
  "pass-3": [
    {
      path: "cvg/swimlanes",
      recursive: true,
      kind: "plan",
      excludeSegments: [".consensus"],
    },
    {
      path: "cvg/brain/decisions",
      recursive: true,
      kind: "decision",
      filenameIncludes: "pass-3",
    },
  ],
  "pass-4": [
    {
      path: "cvg/swimlanes/.consensus/objection-log.json",
      recursive: false,
      kind: "review",
    },
  ],
  "pass-5": [
    {
      path: "cvg/tasks",
      recursive: true,
      kind: "task",
      excludeBasenames: ["README.md", "_state.yaml", "_metrics.jsonl"],
    },
  ],
  "pass-6": [],
  "pass-7": [
    { path: "cvg/execution", recursive: true, kind: "contract" },
  ],
  "pass-8": [
    { path: "cvg/loop", recursive: true, kind: "event" },
    {
      path: "cvg/receipts",
      recursive: true,
      kind: "receipt",
      excludeBasenames: ["README.md"],
    },
  ],
});

function toPosix(relativePath) {
  return relativePath.split(path.sep).join("/");
}

function evidenceId(relativePath) {
  return `ev_${createHash("sha256").update(relativePath).digest("hex").slice(0, 12)}`;
}

async function markdownLabel(absolutePath, fallback) {
  if (path.extname(absolutePath).toLowerCase() !== ".md") {
    return fallback;
  }
  try {
    const contents = await readFile(absolutePath, "utf8");
    const heading = contents.match(/^#\s+(.+)$/m)?.[1]?.trim();
    return redactSensitiveText(heading || fallback).slice(0, 100);
  } catch {
    return fallback;
  }
}

function fallbackLabel(relativePath) {
  const basename = path.basename(relativePath, path.extname(relativePath));
  return basename
    .replace(/[-_]+/g, " ")
    .replace(/\b\w/g, (character) => character.toUpperCase());
}

function sourceAccepts(relativePath, source) {
  const segments = toPosix(relativePath).split("/");
  if (
    source.excludeSegments?.some((excluded) => segments.includes(excluded))
  ) {
    return false;
  }
  if (
    source.filenameIncludes &&
    !path.basename(relativePath).includes(source.filenameIncludes)
  ) {
    return false;
  }
  if (source.excludeBasenames?.includes(path.basename(relativePath))) {
    return false;
  }
  return TEXT_EXTENSIONS.has(path.extname(relativePath).toLowerCase());
}

async function collectSource(projectRoot, source) {
  const sourceAbsolute = path.resolve(projectRoot, source.path);
  const sourceRelative = toPosix(path.relative(projectRoot, sourceAbsolute));
  if (
    sourceRelative === ".." ||
    sourceRelative.startsWith("../") ||
    path.isAbsolute(sourceRelative)
  ) {
    return [];
  }

  let sourceInfo;
  try {
    sourceInfo = await lstat(sourceAbsolute);
  } catch {
    return [];
  }
  if (sourceInfo.isSymbolicLink()) {
    return [];
  }

  const candidates = [];
  if (sourceInfo.isFile()) {
    candidates.push({ absolute: sourceAbsolute, relative: sourceRelative });
  } else if (sourceInfo.isDirectory()) {
    const visit = async (absoluteDirectory, relativeDirectory) => {
      const entries = await readdir(absoluteDirectory, { withFileTypes: true });
      entries.sort((left, right) => left.name.localeCompare(right.name));

      for (const entry of entries) {
        if (entry.isSymbolicLink() || entry.name === ".gitkeep") {
          continue;
        }
        const absolute = path.join(absoluteDirectory, entry.name);
        const relative = toPosix(path.join(relativeDirectory, entry.name));
        if (entry.isDirectory() && source.recursive) {
          await visit(absolute, relative);
        } else if (entry.isFile()) {
          candidates.push({ absolute, relative });
        }
      }
    };
    await visit(sourceAbsolute, sourceRelative);
  }

  const records = [];
  for (const candidate of candidates) {
    if (!sourceAccepts(candidate.relative, source)) {
      continue;
    }
    const [contents, info] = await Promise.all([
      readFile(candidate.absolute),
      lstat(candidate.absolute),
    ]);
    if (!info.isFile() || info.isSymbolicLink()) {
      continue;
    }
    const fallback = fallbackLabel(candidate.relative);
    records.push({
      id: evidenceId(candidate.relative),
      label: await markdownLabel(candidate.absolute, fallback),
      path: candidate.relative,
      kind: source.kind,
      sha256: createHash("sha256").update(contents).digest("hex"),
      modifiedAt: info.mtime.toISOString(),
    });
  }

  return records;
}

export async function collectWorkspaceEvidence(projectRoot) {
  const byPass = {};
  const allByPath = new Map();

  for (const [passId, sources] of Object.entries(PASS_SOURCES)) {
    const sourceResults = await Promise.all(
      sources.map((source) => collectSource(projectRoot, source)),
    );
    const records = sourceResults
      .flat()
      .filter((record) => {
        if (allByPath.has(record.path)) {
          return false;
        }
        allByPath.set(record.path, record);
        return true;
      })
      .sort((left, right) => left.path.localeCompare(right.path));
    byPass[passId] = records;
  }

  return {
    byPass,
    artifacts: [...allByPath.values()],
  };
}

export function latestEvidenceTime(records, fallback) {
  const latest = records
    .map((record) => Date.parse(record.modifiedAt))
    .filter(Number.isFinite)
    .sort((left, right) => right - left)[0];
  return Number.isFinite(latest) ? new Date(latest).toISOString() : fallback;
}
