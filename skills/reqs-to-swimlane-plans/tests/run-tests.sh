#!/bin/bash
# run-tests.sh — table-driven regression suite for the Pass 3 scaffold
# (new-plan.sh): plan creation + the --check lint. Every row: the command,
# the exit code it MUST produce, a pattern the output MUST contain (the
# *intended reason* — a run failing for the wrong reason is a broken test,
# not a pass), and a pattern it MUST NOT contain.
#
# Exit 0 iff every row holds. bash 3.2 safe.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../scripts/new-plan.sh"
FIX="$HERE/fixtures"

TOTAL=0
FAILED=0

report() { # <name> <rc> <want_rc> <out> <must> <must_not>
  NAME="$1"; RC="$2"; WANT_RC="$3"; OUT="$4"; MUST="$5"; MUST_NOT="$6"
  ROW_OK=1
  REASON=""
  if [ "$RC" -ne "$WANT_RC" ]; then
    ROW_OK=0; REASON="exit $RC, wanted $WANT_RC"
  fi
  if [ -n "$MUST" ] && ! printf '%s\n' "$OUT" | grep -qE "$MUST"; then
    ROW_OK=0; REASON="$REASON; missing required pattern: $MUST"
  fi
  if [ -n "$MUST_NOT" ] && printf '%s\n' "$OUT" | grep -qE "$MUST_NOT"; then
    ROW_OK=0; REASON="$REASON; forbidden pattern present: $MUST_NOT"
  fi
  if [ "$ROW_OK" -eq 1 ]; then
    printf 'ok    %-38s (exit %s)\n' "$NAME" "$RC"
  else
    printf 'FAIL  %-38s %s\n' "$NAME" "$REASON"
    printf '%s\n' "$OUT" | sed 's/^/      | /'
    FAILED=$((FAILED + 1))
  fi
}

# run_case <name> <args...> -- <expected_exit> <must_match> <must_not_match>
# Array-based: multi-word args (e.g. lane titles) survive intact. bash 3.2 ok.
run_case() {
  NAME="$1"; shift
  CMD_ARGS=()
  while [ "$1" != "--" ]; do CMD_ARGS+=("$1"); shift; done
  shift
  TOTAL=$((TOTAL + 1))
  OUT="$(bash "$SCRIPT" "${CMD_ARGS[@]}" 2>&1)"
  RC=$?
  report "$NAME" "$RC" "$1" "$OUT" "$2" "$3"
}

# assert_file <name> <file> <must_match> <must_not_match>
assert_file() {
  NAME="$1"; FILE="$2"; MUST="$3"; MUST_NOT="$4"
  TOTAL=$((TOTAL + 1))
  if [ -f "$FILE" ]; then
    OUT="$(cat "$FILE")"
    report "$NAME" 0 0 "$OUT" "$MUST" "$MUST_NOT"
  else
    printf 'FAIL  %-38s file missing: %s\n' "$NAME" "$FILE"
    FAILED=$((FAILED + 1))
  fi
}

echo "== --check on fixture sets =="
run_case good-set-ok            --check --dir "$FIX/good"          -- 0 '^CHECK: OK' ''
run_case drift-sql              --check --dir "$FIX/drift-sql"     -- 1 'DRIFT.*SQL'       '^CHECK: OK'
run_case drift-task-eval        --check --dir "$FIX/drift-task"    -- 1 'DRIFT.*task'      '^CHECK: OK'
run_case no-legs-section        --check --dir "$FIX/no-legs"       -- 1 'no populated.*Legs'    '^CHECK: OK'
run_case legs-present-noids     --check --dir "$FIX/legs-noids"    -- 1 'no leg-NN identifiers' '^CHECK: OK'
run_case no-lanemeta            --check --dir "$FIX/no-lanemeta"   -- 1 "no 'lane-meta:'"  '^CHECK: OK'
run_case no-thread-set          --check --dir "$FIX/no-thread"     -- 1 'THREAD.*steel-thread' '^CHECK: OK'
run_case no-evolution           --check --dir "$FIX/no-evolution"  -- 1 'SEAM.*evolution'  '^CHECK: OK'
run_case empty-dir              --check --dir "$FIX/empty"         -- 2 'no plans found'   ''
run_case leg-gap                --check --dir "$FIX/leg-gap"       -- 1 'LEGS.*no gap'     '^CHECK: OK'
run_case no-mermaid             --check --dir "$FIX/no-mermaid"    -- 1 'VISUAL.*mermaid'  '^CHECK: OK'

echo "== machine token (agents-first) =="
run_case token-ok               --check --dir "$FIX/good"          -- 0 'CHECK_PLAN=OK'    ''
run_case token-fail             --check --dir "$FIX/no-legs"       -- 1 'CHECK_PLAN=FAIL'  ''
run_case token-empty            --check --dir "$FIX/empty"         -- 2 'CHECK_PLAN=EMPTY' ''
run_case token-usage-error      --check --bogus --dir "$FIX/good"  -- 1 'CHECK_PLAN=USAGE_ERROR' ''

echo "== scaffold =="
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

run_case scaffold-basic         --dir "$TMP_ROOT/s1" "transform lane"                          -- 0 '^Created ' ''
assert_file scaffold-leg-section   "$TMP_ROOT/s1/transform-lane.plan.md" '^## Legs$' ''
assert_file scaffold-lanemeta      "$TMP_ROOT/s1/transform-lane.plan.md" '^lane-meta: thread=' ''
assert_file scaffold-leg-ids       "$TMP_ROOT/s1/transform-lane.plan.md" 'leg-01' ''
assert_file scaffold-mermaid       "$TMP_ROOT/s1/transform-lane.plan.md" '```mermaid' ''

run_case scaffold-component     --dir "$TMP_ROOT/s2" --component "A · Transform" "transform lane" -- 0 '^Created ' ''
assert_file scaffold-identity      "$TMP_ROOT/s2/transform-lane.plan.md" 'Component \*\*A · Transform\*\*' ''

run_case scaffold-consumes      --dir "$TMP_ROOT/s3" --consumes "gold.*" "serve lane"          -- 0 '^Created ' ''
assert_file scaffold-consumed      "$TMP_ROOT/s3/serve-lane.plan.md" 'interface this lane consumes' ''
assert_file scaffold-evolution     "$TMP_ROOT/s3/serve-lane.plan.md" 'Seam evolution' ''

run_case scaffold-no-clobber    --dir "$TMP_ROOT/s1" "transform lane"                          -- 1 'already exists' ''
run_case scaffold-no-title      --dir "$TMP_ROOT/s5"                                           -- 1 'title required' ''

# the unfilled scaffold MUST fail --check (placeholders are not real values) —
# the discriminating proof that the lint has teeth.
TOTAL=$((TOTAL + 1))
bash "$SCRIPT" --dir "$TMP_ROOT/s6" "alpha lane" >/dev/null 2>&1
OUT="$(bash "$SCRIPT" --check --dir "$TMP_ROOT/s6" 2>&1)"
RC=$?
report scaffold-unfilled-fails-check "$RC" 1 "$OUT" 'META|WEAK|THREAD' '^CHECK: OK'

echo
if [ "$FAILED" -eq 0 ]; then
  echo "PASS — all $TOTAL rows green."
  exit 0
else
  echo "FAIL — $FAILED of $TOTAL rows red." >&2
  exit 1
fi
