#!/bin/bash
# run-tests.sh — table-driven regression suite for the Pass 1 gate
# (check-tech-spec.sh). Every row: fixture + mode, the exit code it MUST
# produce, a pattern the output MUST contain (the *intended reason* — a
# fixture failing for the wrong reason is a broken test, not a pass), and a
# pattern the output MUST NOT contain (the handoff-verdict guarding rule:
# only a canonical spec may be handed to Pass 2).
#
# Exit 0 iff every row holds. bash 3.2 safe.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../scripts/check-tech-spec.sh"
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

# --- a canonical spec passes, in a NON-data domain (rule 9 universality) ---
run_case canonical-pass          "$FIX/spec-canonical.md"       -- 0 '^CHECK_TECH_SPEC=PASS$' ''
run_case canonical-draft-ok      --draft "$FIX/spec-canonical.md" -- 0 '^CHECK_TECH_SPEC=DRAFT_OK$' 'hand to Pass 2'

# --- the exit contract: a draft can NEVER reach Pass 2 ----------------------
run_case pending-signoff-blocks  "$FIX/spec-pending-signoff.md" -- 1 "Sign-off: owner verdict 'canonical' missing" 'hand to Pass 2'
run_case pending-signoff-draftok --draft "$FIX/spec-pending-signoff.md" -- 0 '^CHECK_TECH_SPEC=DRAFT_OK$' 'hand to Pass 2'
run_case unsigned-blocks         "$FIX/spec-unsigned.md"        -- 1 'Sign-off: section missing' 'hand to Pass 2'
run_case codefence-signoff-blocks "$FIX/spec-codefence-signoff.md" -- 1 "Sign-off: owner verdict 'canonical' missing" 'hand to Pass 2'
run_case bad-date-blocks         "$FIX/spec-bad-date.md"        -- 1 'no valid ISO date' 'hand to Pass 2'

# --- the register keeps its teeth in both modes -----------------------------
run_case open-blocker-fails      "$FIX/spec-open-blocker.md"    -- 1 'BLOCKER' ''
run_case open-blocker-draft-fails --draft "$FIX/spec-open-blocker.md" -- 1 '^CHECK_TECH_SPEC=DRAFT_INCOMPLETE$' 'hand to Pass 2'

# --- usage errors exit 2 AND still end in the machine token -----------------
run_case unknown-flag            -draft "$FIX/spec-canonical.md" -- 2 '^CHECK_TECH_SPEC=USAGE_ERROR$' 'CHECK_TECH_SPEC=PASS'
run_case missing-file-token      "$FIX/does-not-exist.md"       -- 2 '^CHECK_TECH_SPEC=USAGE_ERROR$' ''
run_case two-files-refused       "$FIX/spec-pending-signoff.md" "$FIX/spec-canonical.md" -- 2 '^CHECK_TECH_SPEC=USAGE_ERROR$' 'CHECK_TECH_SPEC=PASS'

# --- PDF policy: text in, or no gate verdict at all --------------------------
PDF_TMP="${TMPDIR:-/tmp}/check-tech-spec-test-$$.pdf"
: > "$PDF_TMP"
run_case pdf-refused             "$PDF_TMP"                     -- 2 'consensus object' 'CHECK_TECH_SPEC=(PASS|FAIL|DRAFT)'
run_case pdf-refused-token       "$PDF_TMP"                     -- 2 '^CHECK_TECH_SPEC=USAGE_ERROR$' ''
rm -f "$PDF_TMP"

# --- the true positive: the signed proving-ground spec stays green ----------
REPO_SPEC="$HERE/../../../tests/uc-analytics/cvg/docs/tech-spec-analytical-backbone.md"
if [ -f "$REPO_SPEC" ]; then
  run_case proving-ground-spec   "$REPO_SPEC"                   -- 0 '^CHECK_TECH_SPEC=PASS$' ''
else
  printf 'skip  %-38s (proving-ground spec not present)\n' proving-ground-spec
fi

echo "────────────────────────────────────────────"
echo "rows: $TOTAL  failed: $FAILED"
[ "$FAILED" -eq 0 ]
