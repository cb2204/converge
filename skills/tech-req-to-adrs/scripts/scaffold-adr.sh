#!/usr/bin/env bash
# scaffold-adr.sh — Converge Pass 2 (Structure): scaffold a numbered grounding ADR,
# or check the existing ADR set for design-drift.
#
# Grounding ADRs record a FACT or CONSTRAINT about the terrain (what IS / what MUST
# hold) with its evidence — never a "build X" instruction. That boundary is the one
# invariant this pass enforces; --check is its deterministic guard.
#
# Usage:
#   scaffold-adr.sh "orders join events on user_id"  Create docs/adrs/NNNN-<slug>.md
#   scaffold-adr.sh --ground brownfield "context"   Set the Ground type in the record
#   scaffold-adr.sh --status proposed "title"       Set the Status field (default: accepted)
#   scaffold-adr.sh --dir path/to/adrs "title"      Override the ADR directory
#   scaffold-adr.sh --check                          Lint docs/adrs/* for design-drift
#   scaffold-adr.sh --help
#
# Produces: docs/adrs/NNNN-<slug>.md  (auto-numbered, dated, templated skeleton)
# Exit:     0 = ok; 1 = drift/usage error; 2 = nothing to check
#
# bash 3.2-safe (runs on macOS system /bin/bash). No associative arrays.

set -euo pipefail

ADR_DIR="docs/adrs"
GROUND="brownfield"
STATUS="accepted"

usage() { sed -n '2,18p' "$0"; }

# ── Build-verb drift guard ────────────────────────────────────────────────────
# A grounding ADR that starts a Decision line with an imperative build-verb has
# drifted into Pass 3 (planning). Match verbs only at the head of a line / bullet
# so prose like "the build surface" or "created_at" never trips the check.
DRIFT_RE='^[[:space:]]*[-*>]?[[:space:]]*(Build|Create|Implement|Add|Introduce|Design|Refactor|Migrate|Scaffold|Wire up|Set up)[[:space:]]'

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

next_number() {
  # Highest existing NNNN in ADR_DIR, plus one, zero-padded to 4.
  local max=0 n f
  if [ -d "$ADR_DIR" ]; then
    for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
      [ -e "$f" ] || continue
      n=$(basename "$f" | cut -c1-4)
      n=$((10#$n))
      [ "$n" -gt "$max" ] && max="$n"
    done
  fi
  printf '%04d' "$((max + 1))"
}

check_drift() {
  local rc=0 hits f
  if [ ! -d "$ADR_DIR" ] || ! ls "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md >/dev/null 2>&1; then
    echo "CHECK: no ADRs found in $ADR_DIR/ — run Step 3 first." >&2
    return 2
  fi
  for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
    [ -e "$f" ] || continue
    hits=$(grep -nEi "$DRIFT_RE" "$f" || true)
    if [ -n "$hits" ]; then
      echo "DRIFT  $f — build-verb at line head (this is Pass 3 design, not Pass 2 grounding):"
      printf '%s\n' "$hits" | sed 's/^/         /'
      rc=1
    fi
    # An ADR with no Evidence line is unfalsifiable grounding.
    if ! grep -qiE '^\#*[[:space:]]*Evidence' "$f"; then
      echo "WEAK   $f — no Evidence section; a grounding fact must cite its source."
      rc=1
    fi
  done
  if [ "$rc" -eq 0 ]; then
    echo "CHECK: OK — every ADR reads as terrain (fact/constraint) with evidence, no design-drift."
  else
    echo "CHECK: FAIL — split each flagged fact from its build clause; the fact stays, the design goes to Pass 3." >&2
  fi
  return "$rc"
}

# ── Parse args ────────────────────────────────────────────────────────────────
TITLE=""
DO_CHECK=false
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --check)   DO_CHECK=true; shift ;;
    --dir)     ADR_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --ground)  GROUND="${2:?--ground needs greenfield|brownfield}"; shift 2 ;;
    --status)  STATUS="${2:?--status needs a value (e.g. proposed|accepted)}"; shift 2 ;;
    --) shift; TITLE="${1:-}"; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)  TITLE="$1"; shift ;;
  esac
done

if [ "$DO_CHECK" = true ]; then
  check_drift
  exit $?
fi

if [ -z "$TITLE" ]; then
  echo "Error: ADR title required." >&2
  usage >&2
  exit 1
fi

SLUG="$(slugify "$TITLE")"
[ -n "$SLUG" ] || { echo "Error: title slugified to empty." >&2; exit 1; }

mkdir -p "$ADR_DIR"
NUM="$(next_number)"
OUT="$ADR_DIR/$NUM-$SLUG.md"
[ -e "$OUT" ] && { echo "Error: $OUT already exists." >&2; exit 1; }
TODAY="$(date +%Y-%m-%d)"

cat > "$OUT" <<EOF
# $NUM — $TITLE

- **Status:** $STATUS
- **Date:** $TODAY
- **Ground type:** $GROUND
- **Converge pass:** 2 (Structure)

## Context

<!-- What part of the terrain does this record pin down? Reference the Pass 1
     tech-spec claim it grounds. State the question a Pass 3 planner would
     otherwise get wrong. -->

## Decision

<!-- A FACT or CONSTRAINT about the terrain — what IS, or what MUST hold.
     NOT a build instruction. If this line starts with Build/Create/Implement/
     Add/Design, it belongs in Pass 3, not here. -->

## Evidence

<!-- The exact source line / row count / command output that makes this true.
     Cite whatever your stack exposes — a schema definition, a config value, a
     migration, a build/ingest command's result, an API contract.
     e.g. <source schema file>:  child.parent_id <TYPE> NOT NULL REFERENCES parent(id)
     e.g. <your build/ingest step> → output row count == source row count -->

## Consequences

<!-- What downstream passes must respect. e.g. "Pass 3 plans must join
     A↔B on <key> only; no other key exists." -->
EOF

echo "Created $OUT"
