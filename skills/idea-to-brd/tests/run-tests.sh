#!/bin/bash
# run-tests.sh — table-driven regression suite for the Pass 0 gate
# (check-brd.sh). Every row: fixture + mode, the exit code it MUST produce,
# a pattern the output MUST contain (the *intended reason* — a fixture
# failing for the wrong reason is a broken test, not a pass), and a pattern
# the output MUST NOT contain (the handoff verdict guarding rule: only a
# canonical brief may be handed to Pass 1).
#
# Exit 0 iff every row holds. bash 3.2 safe.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../scripts/check-brd.sh"
FIX="$HERE/fixtures"

TOTAL=0
FAILED=0

# run_case <name> <args...> -- <expected_exit> <must_match> <must_not_match>
run_case() {
  NAME="$1"; shift
  ARGS=""
  while [ "$1" != "--" ]; do ARGS="$ARGS $1"; shift; done
  shift
  WANT_RC="$1"; MUST="$2"; MUST_NOT="$3"

  TOTAL=$((TOTAL + 1))
  # shellcheck disable=SC2086  # ARGS is a deliberate word-split flag list
  OUT="$(bash "$CHECK" $ARGS 2>&1)"
  RC=$?

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

# --- canonical briefs must pass, in more than one domain (universality) ----
run_case canonical-data          "$FIX/brd-canonical.md"        -- 0 '^CHECK_BRD=PASS$' ''
run_case canonical-devops        "$FIX/brd-canonical-devops.md" -- 0 '^CHECK_BRD=PASS$' ''

# --- the exit contract: a draft can NEVER reach Pass 1 ---------------------
run_case pending-signoff-blocks  "$FIX/brd-pending-signoff.md"  -- 1 "FAIL  Sign-off: owner verdict 'canonical' missing" 'hand off to Pass 1'
run_case pending-signoff-draftok --draft "$FIX/brd-pending-signoff.md" -- 0 '^CHECK_BRD=DRAFT_OK$' 'hand off to Pass 1'
run_case draft-never-authorizes  --draft "$FIX/brd-canonical.md" -- 0 '^CHECK_BRD=DRAFT_OK$' 'hand off to Pass 1'

# --- each negative fails for its INTENDED reason ---------------------------
run_case empty-scope             "$FIX/brd-empty-scope.md"      -- 1 'FAIL  Scope: In has no entries' ''
run_case blank-owner             "$FIX/brd-blank-owner.md"      -- 1 'FAIL  Open questions: .*owner'  ''
run_case no-provenance           "$FIX/brd-no-provenance.md"    -- 1 'FAIL  numbers in Problem/Goals carry no provenance tag' ''
run_case no-provenance-draft     --draft "$FIX/brd-no-provenance.md" -- 0 'WARN  numbers in Problem/Goals carry no provenance tag' 'hand off to Pass 1'
run_case guessed-without-oq      "$FIX/brd-guessed-no-oq.md"    -- 1 'FAIL  \(guessed\) number\(s\) with no open question' ''

# --- semantic judgment stays human: altitude only WARNS --------------------
run_case altitude-warns-only     "$FIX/brd-altitude-warn.md"    -- 0 'WARN  possible solution-shape leak' ''
run_case altitude-still-passes   "$FIX/brd-altitude-warn.md"    -- 0 '^CHECK_BRD=PASS$' ''

# --- the no-go exit has a validator too ------------------------------------
run_case nogo-valid              --no-go "$FIX/nogo-valid.md"   -- 0 '^CHECK_BRD=NOGO_OK$' ''
run_case nogo-invalid            --no-go "$FIX/nogo-invalid.md" -- 1 'reopen' ''
run_case nogo-invalid-token      --no-go "$FIX/nogo-invalid.md" -- 1 '^CHECK_BRD=NOGO_INVALID$' ''

# --- PDF policy: text in, or no verdict at all ------------------------------
PDF_TMP="${TMPDIR:-/tmp}/check-brd-test-$$.pdf"
: > "$PDF_TMP"
run_case pdf-refused             "$PDF_TMP"                     -- 2 '[Cc]onvert' 'CHECK_BRD='
rm -f "$PDF_TMP"

# --- the true positive: the signed proving-ground BRD stays green ----------
REPO_BRD="$HERE/../../../tests/uc-analytics/cvg/docs/brd-analytical-backbone.md"
if [ -f "$REPO_BRD" ]; then
  run_case proving-ground-brd    "$REPO_BRD"                    -- 0 '^CHECK_BRD=PASS$' ''
else
  printf 'skip  %-38s (proving-ground BRD not present)\n' proving-ground-brd
fi

echo "────────────────────────────────────────────"
echo "rows: $TOTAL  failed: $FAILED"
[ "$FAILED" -eq 0 ]
