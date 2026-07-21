#!/bin/bash
# run-tests.sh — pass-to-lesson v0.2.0 teaching-modes gate regression.
# Proves check-lesson.sh discriminates: the good modes fixture passes, the bad
# one fails for its intended (mode) reasons, and back-compat holds. bash 3.2 safe.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CL="$HERE/../scripts/check-lesson.sh"
FX="$HERE/fixtures"
rows=0; failed=0

expect() { # <label> <expected-exit> <file>
  rows=$((rows + 1))
  local rc=0
  bash "$CL" "$3" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq "$2" ]; then
    printf 'ok   %s (exit %s)\n' "$1" "$rc"
  else
    printf 'FAIL %s (want exit %s, got %s)\n' "$1" "$2" "$rc"; failed=$((failed + 1))
  fi
}

# emitter-mode discrimination
expect "good-modes fixture passes"  0 "$FX/lesson-good-modes.md"
expect "bad-modes fixture fails"    1 "$FX/lesson-bad-modes.md"

# the bad fixture must fail ONLY on modes — its base sections stay valid
BASE=$(bash "$CL" "$FX/lesson-bad-modes.md" 2>&1 | grep -c '^PASS  section present' || true)
rows=$((rows + 1))
if [ "$BASE" -eq 7 ]; then printf 'ok   bad fixture keeps 7 base sections (fails on modes only)\n'
else printf 'FAIL bad fixture base sections = %s (want 7)\n' "$BASE"; failed=$((failed + 1)); fi

printf 'rows: %s  failed: %s\n' "$rows" "$failed"
[ "$failed" -eq 0 ]
