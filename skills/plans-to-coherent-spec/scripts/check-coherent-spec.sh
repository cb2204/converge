#!/usr/bin/env bash
# check-coherent-spec.sh — Converge Pass 5A (Specify, Fork A): the deterministic
# gate for the coherent spec + its single end-to-end eval.
#
# This checks only the STRUCTURAL items on the SKILL.md gate — the ones a machine
# can verify. The judgment items (spec reads as ONE narrative not two stapled
# plans; the boundary truly wraps the whole system; every Pass-4 risk carried
# forward verbatim; done means "eval green") are marked ⊙ in SKILL.md and stay a
# human's call — this script prints them as reminders, it does not grade them.
#
# It is deliberately STACK-AGNOSTIC. It validates the SHAPE of the end-to-end
# eval — does it drive prep -> transform -> assert-output -> serve and assert the
# far end? — without assuming any particular stack (no grep for make/dbt/gold or
# any tool). A dbt/DuckDB warehouse, a plain API+DB, a CLI, a pipeline all pass so
# long as the eval drives their real flow end to end and asserts the far end.
#
# What it enforces:
#   1. A coherent spec exists under --specs-dir (framework-native filename).
#   2. Exactly ONE end-to-end eval exists at <specs-dir>/e2e-eval.sh.
#   3. That eval is executable AND syntactically valid bash (bash -n).
#   4. The eval drives the REAL flow: it exhibits all four stages of the generic
#      spine — PREP/SEED -> TRANSFORM -> ASSERT-OUTPUT -> SERVE — and asserts the
#      far end (an output-contract check AND a serving-layer call).
#   5. The one-way dependency (source -> transform -> output -> serving, a
#      read-only crossing that nothing writes back down) is stated as an
#      invariant somewhere in the spec.
#   6. No Fork-B drift: no tracker binding and no per-task atomic spec files were
#      written by this pass (Fork A has nothing to fan out).
#
# Usage:
#   check-coherent-spec.sh                      Check ./specs
#   check-coherent-spec.sh --specs-dir specs/   Override the specs directory
#   check-coherent-spec.sh --help
#
# Exit: 0 = gate PASS (structural items hold); 1 = FAIL; 2 = usage error.
#
# bash 3.2-safe (runs on macOS system /bin/bash). No associative arrays, no
# mapfile. Mirrors the style of the task-spec skill scripts.

set -uo pipefail

SPECS_DIR="specs"

usage() { sed -n '2,37p' "$0"; }

RC=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1" >&2; RC=1; }
info() { printf '  ....  %s\n' "$1"; }

# ── Parse args ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)   usage; exit 0 ;;
    --specs-dir) SPECS_DIR="${2:?--specs-dir needs a path}"; shift 2 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)  echo "Unexpected argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SPECS_DIR="${SPECS_DIR%/}"
[ -n "$SPECS_DIR" ] || { echo "ERROR: --specs-dir resolved to empty." >&2; exit 2; }

echo "== check-coherent-spec — Converge Pass 5A gate =="
echo "specs dir: $SPECS_DIR/"

if [ ! -d "$SPECS_DIR" ]; then
  bad "specs dir '$SPECS_DIR' does not exist — run Step 1 (LIFT) to write the coherent spec."
  echo "" >&2
  echo "GATE: FAIL — no specs directory." >&2
  exit 1
fi

# ── 1. A coherent spec document exists (framework-native filename) ────────────
# Accept any of the framework-native shapes named in SKILL.md's framework table:
#   speckit -> spec.md (+ plan.md) ; kiro -> requirements.md/design.md ;
#   openspec -> a change proposal (proposal.md / spec deltas) ; bmad -> a PRD doc.
# The invariant is "one spec document lands here", not a fixed name — so we look
# for any of the known spec filenames rather than hardcoding one framework.
SPEC_FILE=""
for cand in spec.md requirements.md design.md proposal.md prd.md plan.md; do
  if [ -f "$SPECS_DIR/$cand" ]; then
    SPEC_FILE="$SPECS_DIR/$cand"
    break
  fi
done
# Fall back to any non-eval .md in the specs dir (e.g. a change-proposal subdir).
if [ -z "$SPEC_FILE" ]; then
  SPEC_FILE="$(ls "$SPECS_DIR"/*.md 2>/dev/null | grep -v 'e2e-eval' | head -1 || true)"
fi
if [ -z "$SPEC_FILE" ]; then
  SPEC_FILE="$(find "$SPECS_DIR" -type f -name '*.md' 2>/dev/null | grep -v 'e2e-eval' | head -1 || true)"
fi

if [ -n "$SPEC_FILE" ]; then
  ok "coherent spec present: $SPEC_FILE"
else
  bad "no coherent spec (spec.md / requirements.md / proposal.md / PRD) found under $SPECS_DIR/ — run Step 1 (LIFT)."
fi

# ── 2. Exactly ONE end-to-end eval at <specs-dir>/e2e-eval.sh ─────────────────
EVAL="$SPECS_DIR/e2e-eval.sh"
if [ -f "$EVAL" ]; then
  ok "single end-to-end eval present: $EVAL"
else
  bad "missing $EVAL — run scripts/scaffold-e2e-eval.sh --specs-dir $SPECS_DIR then fill the assertions."
fi

# Guard against Fork-B shape: a set of per-task eval files here means the author
# sharded the system instead of binding ONE eval. Count *eval*.sh other than the
# single canonical one.
EXTRA_EVALS="$(ls "$SPECS_DIR"/*eval*.sh 2>/dev/null | grep -v "e2e-eval.sh" | wc -l | tr -d ' ')"
if [ "${EXTRA_EVALS:-0}" != "0" ]; then
  bad "found $EXTRA_EVALS extra *eval*.sh beside e2e-eval.sh — Fork A binds ONE eval, not per-task evals."
else
  info "no per-task eval files beside the single e2e-eval (Fork A shape holds)"
fi

# ── 3. The eval is executable AND valid bash ─────────────────────────────────
if [ -f "$EVAL" ]; then
  if [ -x "$EVAL" ]; then
    ok "$EVAL is executable"
  else
    bad "$EVAL is not executable — run: chmod +x $EVAL"
  fi
  if bash -n "$EVAL" 2>/dev/null; then
    ok "$EVAL is syntactically valid bash (bash -n)"
  else
    bad "$EVAL failed 'bash -n' — fix the syntax (run: bash -n $EVAL)"
  fi

  # ── 4. The eval drives the REAL flow (the generic four-stage spine) ─────────
  # Fork A's unit of trust is the WHOLE system, so the one eval must drive the
  # full spine and assert the far end. We validate the SHAPE, not any stack:
  #
  #     PREP/SEED  ->  TRANSFORM  ->  ASSERT-OUTPUT  ->  SERVE
  #
  # The scaffold stamps each stage with a labeled marker (STAGE 1 — SEED/PREP,
  # STAGE 2 — TRANSFORM, STAGE 3 — ASSERT-OUTPUT, STAGE 4 — SERVE). We accept
  # those markers OR generic wording, so a hand-written eval also passes as long
  # as it names all four stages. No tool name (make/dbt/duckdb/gold) is required.
  #
  # $1 = human label for the stage, $2 = extended-regex that recognizes it.
  stage_present() {
    if grep -Eqi "$2" "$EVAL"; then
      ok "eval drives the $1 stage"
    else
      bad "eval has no $1 stage — the end-to-end eval must drive prep -> transform -> assert-output -> serve; add a clearly-labeled $1 stage."
    fi
  }

  stage_present "PREP/SEED (establish a known input)" \
    'seed|prep|fixture|arrange|known[ -]?input|given|setup|bootstrap|ingest'
  stage_present "TRANSFORM (build the system's output from the input)" \
    'transform|build|compile|migrate|process|pipeline|generate|render|run'
  stage_present "ASSERT-OUTPUT (check the output/contract layer)" \
    'assert|expect|output|contract|published|verify|equals?|must[ -]?(be|equal)'
  stage_present "SERVE (exercise the serving layer end to end)" \
    'serve|serving|endpoint|api|handler|mcp|route|query|request|response|answer'

  # The far end must be ASSERTED, not merely invoked — a coherent Fork-A eval
  # asserts that a known input produces the expected output AND the expected
  # served answer. Require at least one explicit assertion verb anywhere.
  if grep -Eqi '\b(assert|expect|\[\[?|-eq|=|fail|pass)\b|\[ ' "$EVAL"; then
    ok "eval asserts the far end (contains explicit checks, not just invocations)"
  else
    bad "eval invokes stages but never asserts an expected result — it must assert the far end (known input -> expected output AND expected served answer)."
  fi
fi

# ── 5. One-way dependency invariant is stated in the spec ─────────────────────
if [ -n "$SPEC_FILE" ]; then
  # The spine must be stated as a DIRECTED, one-way chain: source flows toward
  # the served answer and nothing writes back down. We check the SHAPE of the
  # invariant (a direction + a one-way/read-only crossing), not any stack name.
  # Accept either arrow style and either wording, but require the direction.
  HAS_CHAIN=0
  # A directed chain: some stage -> some stage (arrow, or the word "to"/"then").
  if grep -Eqi '(source|raw|input|ingest|prep).*(->|→|then|to|feeds?|flows?).*(transform|build|output|serv|api|contract)' "$SPEC_FILE" \
     || grep -Eqi '(transform|build).*(->|→|then|to|feeds?|flows?).*(output|serv|api|contract)' "$SPEC_FILE"; then
    HAS_CHAIN=1
  fi
  HAS_ONEWAY=0
  if grep -Eqi 'read[- ]?only|one[- ]?way|nothing writes back|does not write back|single (writer|crossing)|invariant' "$SPEC_FILE"; then
    HAS_ONEWAY=1
  fi
  if [ "$HAS_CHAIN" -eq 1 ] && [ "$HAS_ONEWAY" -eq 1 ]; then
    ok "one-way source -> transform -> output -> serving dependency stated as an invariant"
  else
    bad "the spec does not clearly state the one-way source -> transform -> output -> serving invariant (a directed chain plus a read-only / one-way crossing that nothing writes back down)."
  fi

  # The output/contract interface must be named as the internal seam both halves
  # agree on. We check that an interface/contract/seam is named — not that it is
  # a specific stack's artifact.
  if grep -Eqi '(contract|interface|seam|schema|published (tables?|outputs?)|output layer)' "$SPEC_FILE"; then
    ok "the output/contract interface is named as the internal seam"
  else
    bad "the spec does not name the output/contract interface (the seam — e.g. a schema, published-tables contract, or API contract) that both halves agree on."
  fi
fi

# ── 6. No Fork-B drift (no tracker, no atomic per-task spec files) ────────────
if [ -n "$SPEC_FILE" ] || [ -f "$EVAL" ]; then
  DRIFT=0
  # A tracker binding here is Fork-B territory — Fork A has no backlog to fan out.
  if [ -n "$SPEC_FILE" ] && grep -Eqi '(^|[^a-z])--?tracker\b|linear|jira|github issues?' "$SPEC_FILE"; then
    bad "spec mentions a tracker (--tracker/Linear/Jira/GitHub issues) — Fork A registers no backlog; that is Fork B."
    DRIFT=1
  fi
  # Atomic per-unit task-spec files under specs/ mean the author took Fork B.
  if ls "$SPECS_DIR"/T-*.md >/dev/null 2>&1; then
    bad "atomic T-*.md task files found under $SPECS_DIR/ — Fork A is one coupled spec, not per-task specs (that is Fork B / task-spec)."
    DRIFT=1
  fi
  [ "$DRIFT" -eq 0 ] && ok "no Fork-B drift (no tracker binding, no atomic task files in the specs dir)"
fi

# ── Judgment reminders (⊙ — not machine-graded) ──────────────────────────────
echo ""
echo "Confirm by eye (SKILL.md ⊙ items this script cannot grade):"
echo "  ⊙ the spec reads as ONE narrative — plans resolved, not stapled side by side"
echo "  ⊙ the boundary wraps the WHOLE system (source -> transform -> output -> serving), not one layer"
echo "  ⊙ every served answer maps to an output the transform step actually produces"
echo "  ⊙ every Pass-4 accepted risk / open question carried forward verbatim"
echo "  ⊙ done is defined as 'the e2e eval is green', never 'looks done'"

# ── Verdict ──────────────────────────────────────────────────────────────────
echo ""
if [ "$RC" -eq 0 ]; then
  echo "GATE: PASS — structural items hold. Confirm the ⊙ items, then enter Execution (Pass 8)."
else
  echo "GATE: FAIL — fix the items above before leaving Pass 5A." >&2
fi
exit "$RC"
