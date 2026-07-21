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
#   new-plan.sh "transform lane"                   Create sketch/<slug>.plan (a lane)
#   new-plan.sh --component "A · Transform" "..."  Set the identity line's component
#   new-plan.sh --consumes <seam> "serve lane"     Mark a DOWNSTREAM lane + its seam
#   new-plan.sh --dir path/to/sketch "..."         Override the sketch directory
#   new-plan.sh --check                            Lint sketch/*.plan for altitude-drift
#   new-plan.sh --help
#
# Produces: sketch/<slug>.plan  (templated skeleton: lane-meta / Identity /
#           Features / Consumed-interface + Seam-evolution / Dependencies /
#           Build-order / Proving-tests / Open-questions / Spec-traceability)
#
# --check also enforces the Pass 3 "seam economics" hardening (v0.4.0): every
#   lane carries lane-meta (thread=<yes|no> · risk=<low|med|high> · owner=<stream>);
#   the SET has exactly one steel-thread lane (thread=yes) that exercises every seam
#   end-to-end first (walking skeleton); a downstream lane names its seam-evolution
#   rule (additive-safe vs breaking). Cycles that fail the one-way seam test are
#   recorded as blocks-build open questions with the breaking technique named.
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
  local rc=0 hits f thread_seen=0
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

    # H1/H2/H3 — every lane declares its seam economics on a lane-meta line,
    # with real values (an unfilled <yes|no> placeholder does not count).
    if ! grep -qiE 'lane-meta:' "$f"; then
      echo "WEAK   $f — no 'lane-meta:' line (need thread=<yes|no> · risk=<low|med|high> · owner=<stream>)."
      rc=1
    else
      grep -qiE 'thread=(yes|no)' "$f" || { echo "META   $f — lane-meta missing a real thread=yes|no (H1 steel-thread marker)."; rc=1; }
      grep -qiE 'risk=(low|med|high)' "$f" || { echo "META   $f — lane-meta missing a real risk=low|med|high (H2 risk-first order)."; rc=1; }
      grep -qiE 'owner=[^[:space:]<]' "$f" || { echo "META   $f — lane-meta missing a real owner=<stream> (H3 Conway ownership)."; rc=1; }
    fi
    if grep -qiE 'thread=yes' "$f"; then thread_seen=1; fi

    # H4 — a downstream lane (one that consumes a seam) states how the contract evolves.
    if grep -qiE 'interface this lane consumes|## +.*consumes' "$f"; then
      grep -qiE 'seam evolution|additive|breaking' "$f" || { echo "SEAM   $f — downstream lane names a consumed seam but no evolution rule (H4: additive-safe vs breaking + coexistence window)."; rc=1; }
    fi
  done

  # H1 (set level) — the plan set must contain exactly one steel-thread lane.
  if [ "$thread_seen" -eq 0 ]; then
    echo "THREAD $SKETCH_DIR/ — no steel-thread lane (no plan carries thread=yes); one lane must exercise every seam end-to-end first (H1 walking skeleton)."
    rc=1
  fi

  if [ "$rc" -eq 0 ]; then
    echo "CHECK: OK — plan altitude held (features/deps/order/tests, no SQL/tasks); seam economics present (steel-thread, risk, owner, evolution)."
  else
    echo "CHECK: FAIL — fix the flagged plans; push SQL/tasks to Pass 5, and complete the seam economics (lane-meta / steel-thread / evolution)." >&2
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
    --consumes)  CONSUMES="${2:?--consumes needs an upstream seam, e.g. the output/contract layer}"; shift 2 ;;
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
  echo "Error: lane title required (e.g. \"transform lane\")." >&2
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

This lane reads **only the \`$CONSUMES\` contract**, and never reaches below it. Name
the exact upstream fields each piece consumes, so the seam is explicit. If an answer
needs something not in \`$CONSUMES\`, the fix is a **new addition to the upstream
contract**, never a deeper read here.

| upstream unit | fields consumed | read by (this lane's piece) |
|---|---|---|
| \`$CONSUMES\` <unit> | <field, field, …> | <endpoint / tool / model> |

<!-- One row per upstream unit this lane reads (e.g. a published table, an API
     resource, an event topic). Never list a field the upstream lane has not
     committed to producing (its schema/contract). A missing field is a new
     upstream-contract request, not a deeper read. -->

**Seam evolution:** the frozen contract will change — say how safely. Additive
changes (a new column/field/endpoint) are non-breaking; renames, removals, and
newly-required fields are BREAKING and need a coexistence window before this lane
cuts over. <State the evolution rule for \`$CONSUMES\`, and how this lane learns of
a change — e.g. a consumer-driven contract test the upstream must keep green.>

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

lane-meta: thread=<yes|no> · risk=<low|med|high> · owner=<owning stream/team>

<!-- lane-meta is the greppable seam economics of this lane (Pass 3 hardening):
     · thread=yes marks THE steel-thread lane — the thin vertical path that
       exercises EVERY seam end-to-end (build+prove) before the component lanes
       fatten (walking skeleton). Exactly one lane in the set carries thread=yes.
     · risk = confidence the frozen contract / hard constraint is RIGHT
       (low|med|high risk of being wrong). A high-risk seam is spiked FIRST,
       ahead of pure dependency order.
     · owner = the single stream/team that owns this lane (one owner, or mark
       it shared/platform). A seam that splits one owner or fuses two is a
       Conway smell — flag it. -->

$IDENTITY Input contract: \`<upstream>.*\`. Output contract:
\`<downstream>.*\` (the seam the next lane consumes — name it).

Plan altitude: features, responsibilities, dependencies, build order, tests. No
model SQL, no handler code, no atomic tasks.

---

## Features / components

<!-- The pieces INSIDE this lane and what each is responsible for — component
     level, never the SQL or the handler body. For example: staged transform
     layers in a warehouse project, or query-core / API transport / MCP transport
     in a serving lane. State each piece's RESPONSIBILITY in prose (e.g. "dedup
     duplicate records by business signature, quarantine the rest"), not its
     implementation. -->

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

<!-- A sane sequence. Call out the GATING input explicitly — the frozen decision or
     upstream contract that nothing downstream can finish until it is settled (for
     example, a frozen requirement set gating the output layer and serving surface). -->

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
     the plan. Owner + blocks-build flag per row.
     CYCLE NOTE (H5): if this lane and another genuinely co-depend (the one-way
     seam test fails), do NOT smear the boundary — record HERE how the cycle was
     broken: dependency inversion (both depend on an extracted shared contract),
     an async/event boundary (one sync cycle → two one-way flows), or a promoted
     shared kernel. Flag it blocks-build until the technique is chosen. -->

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
