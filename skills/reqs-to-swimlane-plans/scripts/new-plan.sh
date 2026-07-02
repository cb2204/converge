#!/usr/bin/env bash
# new-plan.sh — Converge Pass 3 (DECOMPOSE): scaffold one swimlane plan per seam,
# or check the existing sketch/*.plan set for altitude-drift (SQL / tasks / code).
#
# A swimlane plan describes WHAT a lane contains and IN WHAT ORDER it is built —
# nothing lower. The moment a plan holds a SELECT, a handler body, or an atomic
# task with an eval, it has left Pass 3 and skipped the adversarial review that is
# meant to harden the plan first. That altitude boundary is the one invariant this
# pass enforces; --check is its deterministic guard.
#
# Usage:
#   new-plan.sh "duckdb dbt med arch"              Create sketch/<slug>.plan (a lane)
#   new-plan.sh --component "A · Transform" "..."  Set the identity line's component
#   new-plan.sh --consumes gold "fast api mcp"     Mark a DOWNSTREAM lane + its seam
#   new-plan.sh --dir path/to/sketch "..."         Override the sketch directory
#   new-plan.sh --check                            Lint sketch/*.plan for altitude-drift
#   new-plan.sh --help
#
# Produces: sketch/<slug>.plan  (templated skeleton: Identity / Features /
#           Consumed-interface / Dependencies / Build-order / Proving-tests /
#           Open-questions / Spec-traceability)
# Exit:     0 = ok; 1 = drift/usage error; 2 = nothing to check
#
# bash 3.2-safe (runs on macOS system /bin/bash). No associative arrays, no mapfile.

set -euo pipefail

SKETCH_DIR="sketch"
COMPONENT=""
CONSUMES=""

usage() { sed -n '11,17p' "$0"; }

# ── Altitude-drift guards ─────────────────────────────────────────────────────
# A plan that carries SQL, an atomic task, or a handler body has dropped below
# plan altitude into Pass 5 territory. Match at the head of a line / bullet so
# ordinary prose (a "select few marts", "the create step") never trips the check.
#
# SQL_RE — a SQL statement opening a line (the SELECT/handler-body leak).
SQL_RE='^[[:space:]]*(SELECT|INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM|CREATE[[:space:]]+(TABLE|VIEW|OR[[:space:]]+REPLACE)|WITH[[:space:]]+[A-Za-z_].*[[:space:]]+AS[[:space:]]*\(|MERGE[[:space:]]+INTO)[[:space:]]'
# TASK_RE — an atomic task id or an eval block; tasks live at tasks/T-*.md (Pass 5).
TASK_RE='(^[[:space:]]*[-*>]?[[:space:]]*(Task|T-[0-9]{6,})[-: ]|^[[:space:]]*(eval|acceptance[_-]?eval|bash[_-]?eval)[[:space:]]*:)'

# Structural sections a lane plan must carry (Step 2 of the SKILL). Kept to the
# headings the canonical plans share; identity + features are expressed in prose or
# under varying heading names (Layers / Components), so they are not grep-required —
# the altitude guards above are the hard gate, this is a nudge.
#
# One grep -E pattern per line (newline-delimited, NOT space-delimited: the patterns
# contain spaces, so a space-split for-loop would shred them). '|' inside a pattern
# covers wording variants a real plan uses (e.g. "Build order" vs. "Build-order").
REQUIRED_SECTIONS='Dependenc(y|ies)
Build[ -]order
Tests +that +prove
Open +question'

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

check_drift() {
  local rc=0 hits f
  if [ ! -d "$SKETCH_DIR" ] || ! ls "$SKETCH_DIR"/*.plan >/dev/null 2>&1; then
    echo "CHECK: no plans found in $SKETCH_DIR/ — scaffold a lane first." >&2
    return 2
  fi
  for f in "$SKETCH_DIR"/*.plan; do
    [ -e "$f" ] || continue

    # 1) SQL leak — a SELECT / DDL statement at a line head.
    hits=$(grep -nEi "$SQL_RE" "$f" || true)
    if [ -n "$hits" ]; then
      echo "DRIFT  $f — SQL at a line head (that is Pass 5 / task-spec, not a plan):"
      printf '%s\n' "$hits" | sed 's/^/         /'
      rc=1
    fi

    # 2) Atomic-task / eval leak — a task id or an eval block.
    hits=$(grep -nEi "$TASK_RE" "$f" || true)
    if [ -n "$hits" ]; then
      echo "DRIFT  $f — atomic task / eval block (that is Pass 5 / task-spec, not a plan):"
      printf '%s\n' "$hits" | sed 's/^/         /'
      rc=1
    fi

    # 3) A plan missing a required structural section is not skimmable / not
    #    attackable. Iterate the newline-delimited patterns without word-splitting
    #    on spaces (bash 3.2-safe: set IFS to newline for just this loop).
    local sec oldifs="$IFS"
    IFS='
'
    for sec in $REQUIRED_SECTIONS; do
      IFS="$oldifs"
      if ! grep -qiE "$sec" "$f"; then
        echo "WEAK   $f — no section matching /$sec/; a lane plan needs Dependencies, Build order, Tests-that-prove, and Open-questions."
        rc=1
      fi
      IFS='
'
    done
    IFS="$oldifs"
  done
  if [ "$rc" -eq 0 ]; then
    echo "CHECK: OK — every plan reads at plan altitude (features/deps/order/tests), no SQL or tasks."
  else
    echo "CHECK: FAIL — push each flagged SQL/task down to Pass 5 (task-spec); the plan keeps the responsibility in prose." >&2
  fi
  return "$rc"
}

# ── Parse args ────────────────────────────────────────────────────────────────
TITLE=""
DO_CHECK=false
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)   usage; exit 0 ;;
    --check)     DO_CHECK=true; shift ;;
    --dir)       SKETCH_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --component) COMPONENT="${2:?--component needs a label, e.g. \"A · Transform\"}"; shift 2 ;;
    --consumes)  CONSUMES="${2:?--consumes needs an upstream seam, e.g. gold}"; shift 2 ;;
    --)          shift; TITLE="${1:-}"; break ;;
    -*)          echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)           TITLE="$1"; shift ;;
  esac
done

if [ "$DO_CHECK" = true ]; then
  check_drift
  exit $?
fi

if [ -z "$TITLE" ]; then
  echo "Error: lane title required (e.g. \"duckdb dbt med arch\")." >&2
  usage >&2
  exit 1
fi

SLUG="$(slugify "$TITLE")"
[ -n "$SLUG" ] || { echo "Error: title slugified to empty." >&2; exit 1; }

mkdir -p "$SKETCH_DIR"
OUT="$SKETCH_DIR/$SLUG.plan"
[ -e "$OUT" ] && { echo "Error: $OUT already exists — edit it, don't re-scaffold." >&2; exit 1; }

# Identity line — component label if given, else a placeholder to fill in.
if [ -n "$COMPONENT" ]; then
  IDENTITY="Component **$COMPONENT** from the decomposition."
else
  IDENTITY="Component **<A · Transform | B · Serve>** from the decomposition."
fi

# The consumed-interface block only exists for a DOWNSTREAM lane (one with --consumes).
CONSUMED_BLOCK=""
if [ -n "$CONSUMES" ]; then
  CONSUMED_BLOCK="## The interface this lane consumes (the seam — hard boundary)

This lane reads **only \`$CONSUMES.*\`**, and never reaches below it. Name the exact
upstream tables and columns each piece consumes, so the seam is explicit. If an
answer needs data not in \`$CONSUMES\`, the fix is a **new mart upstream**, never a
deeper read here.

| upstream table | columns consumed | read by (this lane's piece) |
|---|---|---|
| \`$CONSUMES.<table>\` | <col, col, …> | <endpoint / tool / model> |

<!-- One row per table this lane reads. Never list a column the upstream lane has
     not committed to producing (its schema/contract). A missing column is a new
     upstream mart request, not a deeper read. -->

---

"
fi

TODAY="$(date +%Y-%m-%d)"

cat > "$OUT" <<EOF
# Plan · $TITLE

<!-- Pass 3 (DECOMPOSE) · scaffolded $TODAY · PLAN ALTITUDE ONLY.
     Describe WHAT this lane contains and IN WHAT ORDER it is built. No model SQL,
     no handler bodies, no atomic tasks with evals — those are Pass 5 (task-spec).
     This plan is meant to be ATTACKED in Pass 4, so leave the soft spots visible;
     do not pre-empt objections. -->

$IDENTITY Input contract: \`<upstream>.*\`. Output contract:
\`<downstream>.*\` (the seam the next lane consumes — name it).

Plan altitude: features, responsibilities, dependencies, build order, tests. No
model SQL, no handler code, no atomic tasks.

---

## Features / components

<!-- The pieces INSIDE this lane and what each is responsible for — component
     level, never the SQL or the handler body. e.g. bronze/silver/gold layers, or
     query-core / FastAPI transport / MCP transport. State each piece's
     RESPONSIBILITY in prose (e.g. "dedup duplicate_order by business signature,
     quarantine the rest"), not its implementation. -->

- **<piece>** — <what it does / what it is responsible for>.
- **<piece>** — <what it does / what it is responsible for>.

---

${CONSUMED_BLOCK}## Dependencies

<!-- A small DAG: the build order between this lane's own pieces AND its inbound
     seam. One direction; no piece reads above itself. -->

\`\`\`
<upstream seam>  ->  <piece>  ->  <piece>
\`\`\`

- <the dependency edges in words; call out the single inbound seam>.

---

## Build order

<!-- A sane sequence. Call out the GATING input explicitly (in this repo the
     frozen E4 question set gates gold and the final serving surface). -->

1. <first buildable piece — why it unblocks the rest>.
2. <next>.
3. <…>.

<!-- Name the gating edge: what cannot finish until <gating input> is frozen. -->

---

## Tests that prove each piece

<!-- Plan altitude: WHAT each test asserts, not the test code. -->

| Piece | Tests (what they prove) |
|---|---|
| **<piece>** | <invariant this piece must satisfy>. Proves: <property>. |
| **<piece>** | <invariant>. Proves: <property>. |

---

## Open questions

<!-- Anything the ADRs do NOT cover. Surface it — do NOT invent the answer inside
     the plan. Owner + blocks-build flag per row. -->

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | <question the ADRs don't settle> | <owner> | <Yes/No — and which piece> |

---

## Spec traceability

<!-- Trace each piece back to the ADR (docs/adrs/NNNN-*.md) or tech requirement it
     satisfies. A plan that CONTRADICTS an ADR fails the gate — cite it, never
     re-decide it here. -->

- **<ADR / requirement id>** — <how this lane honors it>.
EOF

echo "Created $OUT"
