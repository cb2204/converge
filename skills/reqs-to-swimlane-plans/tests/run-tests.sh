#!/bin/bash
# run-tests.sh — reqs-to-swimlane-plans v0.4.0 seam-economics gate regression.
# Proves new-plan.sh --check discriminates: a good plan set (steel thread + filled
# lane-meta + downstream seam-evolution, plan altitude) passes; a set that violates
# the hardening (no thread=yes, unfilled risk/owner, downstream w/o evolution) fails
# for those reasons. Non-data domain (web checkout) for rule-9 universality.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NP="$HERE/../scripts/new-plan.sh"
FX="$HERE/fixtures"
rows=0; failed=0

expect() { # <label> <expected-exit> <sketch-dir>
  rows=$((rows + 1))
  local rc=0
  bash "$NP" --check --dir "$1" >/dev/null 2>&1 || rc=$?
  shift
  if [ "$rc" -eq "$1" ]; then printf 'ok   %s (exit %s)\n' "$2" "$rc"
  else printf 'FAIL %s (want %s, got %s)\n' "$2" "$1" "$rc"; failed=$((failed + 1)); fi
}

expect "$FX/good-set" 0 "good set passes (steel thread + seam economics)"
expect "$FX/bad-set"  1 "bad set fails (no thread / unfilled meta / no evolution)"

# the bad set must fail specifically on the hardening checks
OUT="$(bash "$NP" --check --dir "$FX/bad-set" 2>&1 || true)"
for MARK in "THREAD" "META" "SEAM"; do
  rows=$((rows + 1))
  if printf '%s\n' "$OUT" | grep -q "$MARK"; then printf 'ok   bad set flags %s\n' "$MARK"
  else printf 'FAIL bad set did not flag %s\n' "$MARK"; failed=$((failed + 1)); fi
done

printf 'rows: %s  failed: %s\n' "$rows" "$failed"
[ "$failed" -eq 0 ]
