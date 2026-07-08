#!/usr/bin/env bash
# scaffold-e2e-eval.sh — Converge Pass 5A (Specify, Fork A): stamp the ONE
# end-to-end eval that governs the whole coherent spec.
#
# Fork A's unit of trust is the WHOLE system, not a task. So this pass produces
# exactly ONE eval, at specs/e2e-eval.sh, that drives the real flow end to end:
#     prep/seed  →  transform  →  assert output/contract  →  hit serving
# and asserts the FAR END: a known input yields the expected output shape AND the
# expected served answer. This script writes a runnable, stack-agnostic skeleton
# of that eval — a generic PREP → TRANSFORM → ASSERT-OUTPUT → SERVE spine with
# clearly-marked TODO(author) stages. The author wires each stage to THEIR stack
# (whatever build/ingest command, transform pipeline, output store, and serving
# layer the project uses) and fills the concrete assertions once the output
# contract is frozen.
#
# The skeleton is deliberately RED until each stage is wired and the transform
# and serving layers exist — that is correct for Fork A: the eval is the single
# artifact Execution (Pass 8 · The Loop) drives to GREEN. Each stage prints a
# precise, actionable reason when it is not yet wired, so a RED run names the gap.
#
# Usage:
#   scaffold-e2e-eval.sh                       Write specs/e2e-eval.sh
#   scaffold-e2e-eval.sh --specs-dir specs/    Override the specs directory
#   scaffold-e2e-eval.sh --force               Overwrite an existing eval
#   scaffold-e2e-eval.sh --help
#
# Produces: <specs-dir>/e2e-eval.sh  (chmod +x, runnable, bash -n clean)
# Exit:     0 = written; 1 = usage error / refused to clobber
#
# bash 3.2-safe (runs on macOS system /bin/bash). No associative arrays, no
# mapfile. Mirrors the style of the task-spec skill's scripts/_lib.sh.

set -euo pipefail

SPECS_DIR="specs"
FORCE=false

usage() { sed -n '2,29p' "$0"; }

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# ── Parse args ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)    usage; exit 0 ;;
    --specs-dir)  SPECS_DIR="${2:?--specs-dir needs a path}"; shift 2 ;;
    --force)      FORCE=true; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)  echo "Unexpected argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Strip a trailing slash so the path composes cleanly.
SPECS_DIR="${SPECS_DIR%/}"
[ -n "$SPECS_DIR" ] || die "--specs-dir resolved to empty."

OUT="$SPECS_DIR/e2e-eval.sh"

mkdir -p "$SPECS_DIR"
if [ -e "$OUT" ] && [ "$FORCE" != true ]; then
  die "$OUT already exists. Re-run with --force to overwrite (you will lose filled-in assertions)."
fi

# ── Emit the eval skeleton ────────────────────────────────────────────────────
# Heredoc is quoted ('EOF') so nothing here is expanded now — the generated
# script keeps its own $VARS, $(...) and "$@" verbatim.
cat > "$OUT" <<'EOF'
#!/usr/bin/env bash
# e2e-eval.sh — THE single end-to-end eval for the coherent spec (Converge 5A).
#
# The unit of trust is the WHOLE system: source input -> transform -> output
# contract -> serving answers. This eval drives the REAL flow and asserts the
# FAR END. Done = this is GREEN.
#
# Generic spine (wire each stage to YOUR stack):
#   PREP     -> establish a known, deterministic input (your build/ingest step)
#   TRANSFORM-> run the project's transform pipeline over that input
#   ASSERT   -> the transform emitted the expected OUTPUT/contract shape
#   SERVE    -> the serving layer (API, MCP tool, CLI, etc.) returns the expected
#               answer, and that answer matches the output shape asserted above
#
# One eval, end to end, unambiguous pass/fail. It is RED until each stage is
# wired and the transform + serving layers are built — that is by design:
# Execution (Pass 8) drives it to GREEN. Each stage below prints a precise reason
# when it is not yet wired or its layer is not yet built.
#
# Run from the repo root:  bash specs/e2e-eval.sh
# bash 3.2-safe. No associative arrays, no mapfile.

set -uo pipefail   # NB: not -e — we want to run every stage and report all gaps.

# ── Repo grounding (single sources of truth) ─────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# TODO(author): point these at YOUR stack. These are placeholders, not defaults
# for any particular tool. Prefer env overrides so CI and local runs agree.
#   DATA_STORE  — where the transform writes its output (a db file, a schema, a
#                 directory of artifacts, an API base URL, ...). Your read path.
#   PREP_CMD    — the project's data-prep / ingest command (produces known input).
#   TRANSFORM_CMD — the project's transform step (input -> output/contract layer).
DATA_STORE="${DATA_STORE:-}"       # e.g. the project's warehouse / output store
PREP_CMD="${PREP_CMD:-}"           # e.g. "make seed" or your ingest script
TRANSFORM_CMD="${TRANSFORM_CMD:-}" # e.g. your transformation pipeline command

# Deterministic input knobs — a KNOWN input is what makes the far-end assertion
# meaningful. Keep whatever knobs your prep step takes fixed so the expected
# output shape is reproducible. SEED is the canonical example of such a knob.
SEED="${SEED:-42}"

FAILS=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1" >&2; FAILS=$((FAILS + 1)); }
note() { printf '  ....  %s\n' "$1"; }
stage() { printf '\n== %s ==\n' "$1"; }

# read_output — read one scalar fact from the output/contract layer; echo the
# value or "" on error. This is the eval's single READ PATH: implement it ONCE
# against your output store (a SQL query, a jq over a JSON artifact, an HTTP GET,
# a file read, ...) so every assertion below reads the far end the same way and
# honors the SAME read invariant (e.g. read-only) your serving layer must.
read_output() {
  # $1 = a query/selector meaningful to YOUR output store; echo one scalar.
  # TODO(author): implement your read path. Examples (pick/replace, don't keep):
  #   - SQL warehouse:  your_sql_client --scalar "$1"
  #   - JSON artifact:  jq -r "$1" path/to/output.json 2>/dev/null
  #   - HTTP endpoint:  curl -fsS "$DATA_STORE/$1" 2>/dev/null
  :
}

# ── Stage 1 — PREP (known, deterministic input) ──────────────────────────────
# Establish a KNOWN input so the far-end output is reproducible. Wire PREP_CMD to
# the project's data-prep/ingest step (for example, in a Make-based project this
# might be a `make seed`-style target that generates a fixed dataset).
stage "prep — deterministic known input"
if [ -z "$PREP_CMD" ]; then
  fail "PREP_CMD not set — wire the project's data-prep/ingest step (produces a known input). \
Cannot establish a known input, so the far-end assertion has no meaning yet."
elif ( eval "$PREP_CMD" ) >/dev/null 2>&1; then
  pass "prep step ($PREP_CMD, seed=$SEED)"
else
  fail "prep step failed ($PREP_CMD) — is its backing service up? — cannot establish a known input"
fi

# ── Stage 2 — TRANSFORM (input -> output/contract layer) ─────────────────────
# Run the project's transform pipeline. It is the component that turns the known
# input into the published output/contract layer the serving half binds to. It
# is not scaffolded until Execution builds it; until TRANSFORM_CMD is wired and
# succeeds, this stage reports the gap precisely (RED), which is the correct
# Fork-A signal, not a false green.
# (For example, in a dbt/warehouse project the transform step is `dbt build` over
# a medallion of models; wire TRANSFORM_CMD to whatever YOUR project uses.)
stage "transform — project transform pipeline (input -> output layer)"
if [ -z "$TRANSFORM_CMD" ]; then
  fail "TRANSFORM_CMD not set — the transform pipeline is not wired/built yet. \
Execution must build the transform layer and wire this command; then this stage runs it."
elif ( eval "$TRANSFORM_CMD" ) >/dev/null 2>&1; then
  pass "transform step ($TRANSFORM_CMD) succeeded (models + tests green)"
else
  fail "transform step failed ($TRANSFORM_CMD) — a model or data test is RED (run it directly to see which)"
fi

# ── Stage 3 — ASSERT OUTPUT (the internal contract) ──────────────────────────
# Assert the OUTPUT/contract shape the serving half binds to, for the known
# input. This is the frozen contract between the transform half and the serving
# half. Fill in the exact facts (existence of published tables/artifacts, row
# counts, totals, ...) once the output contract is pinned.
stage "output — the internal contract (published output shape for the known input)"
# TODO(author): assert each published output your contract promises. For each
# one, check it exists AND assert its FAR-END shape for the known input. Example
# skeleton (replace the selectors/expected values with YOURS):
#   for name in <your published output names>; do
#     EXISTS="$(read_output "<exists-check for $name>")"
#     if [ "$EXISTS" = "1" ]; then
#       pass "output '$name' present"
#       VAL="$(read_output "<a scalar fact about $name for the known input>")"
#       [ "$VAL" = "<expected-for-seed-$SEED>" ] && pass "$name value" || fail "$name value ($VAL)"
#     else
#       fail "output '$name' missing — the transform half has not emitted this (frozen contract)"
#     fi
#   done
# Atomic-publish invariant: if your contract promises all outputs come from ONE
# generation, assert a single generation id is visible across them, e.g.:
#   GENS="$(read_output "<count of distinct publish/run ids across all outputs>")"
#   [ "$GENS" = "1" ] && pass "single publish generation" || fail "half-published output ($GENS ids)"
fail "output-contract assertions not yet filled — spec is not converged until they are"

# ── Stage 4 — SERVE (the far end: the served answer) ─────────────────────────
# The serving layer is read-only over the output/contract layer. Assert that the
# frozen question is answered as expected, and — if more than one surface serves
# it (e.g. an API endpoint AND an MCP tool over the same core) — that every
# surface returns the SAME answer, and that answer matches the output shape
# asserted above.
stage "serve — the serving layer answers the frozen question"
# TODO(author): detect that YOUR serving layer exists (a source dir, a running
# process, an importable module, ...), then invoke it and assert the answer.
# Replace this presence check with one meaningful to your stack:
SERVING_PRESENT=false   # e.g. [ -d src/serving ] && SERVING_PRESENT=true
if [ "$SERVING_PRESENT" = true ]; then
  pass "serving layer present"
  # TODO(author): invoke the serving layer (start the API / import the query
  # core / run the CLI) and assert the answer for the known input. If multiple
  # surfaces serve the same core, assert they return the SAME value (parity), and
  # that the value equals the output shape asserted in Stage 3. Example:
  #   ANS="$(<invoke your serving layer for the frozen question> 2>/dev/null || true)"
  #   [ -n "$ANS" ] && pass "frozen question answered" || fail "no serving answer"
  note "fill the serving answer assertions (must equal the output shape above)"
  fail "serving answer assertions not yet filled — spec is not converged until they are"
else
  fail "serving layer not present/detected — the serving layer is not built yet. \
Execution must add the read-only serving layer (API, MCP tool, CLI, etc.) over the output layer, \
then wire the presence check above."
fi

# ── Verdict ──────────────────────────────────────────────────────────────────
stage "verdict"
if [ "$FAILS" -eq 0 ]; then
  echo "GREEN — the whole system is converged: prep -> transform -> output -> serve all pass."
  exit 0
else
  echo "RED — $FAILS check(s) failed. The coherent spec is not yet done." >&2
  echo "Feed the first failing stage back into the loop and revise; done = this eval is GREEN." >&2
  exit 1
fi
EOF

chmod +x "$OUT"

echo "Created $OUT (executable)."
echo "Next: wire each stage to your stack (PREP_CMD, TRANSFORM_CMD, read path, serving check),"
echo "freeze the output contract, then fill the FAR-END assertions marked TODO(author)."
echo "Syntax check: bash -n $OUT"
