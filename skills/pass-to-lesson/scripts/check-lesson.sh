#!/bin/bash
# check-lesson.sh — Converge teaching-companion gate checker.
# Verifies a lesson produced by pass-to-lesson is structurally gate-ready:
#   1. all required sections present
#   2. the component walkthrough has at least one four-part component
#   3. the Decisions table has at least one row naming an alternative
#   4. Check yourself carries 3-5 numbered questions
# Warns (never fails) where judgment stays human (coverage vs. the pass's
# real inventory can only be checked against git, not the file alone).
# bash 3.2 safe (macOS system bash).

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "usage: check-lesson.sh docs/lessons/lesson-<pass-slug>-<topic>.md" >&2
  exit 2
fi

FAIL=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAIL=1; }
warn() { printf 'WARN  %s\n' "$1"; }

# --- extract a section body: lines after "## <name>" until the next "## " ---
section() {
  awk -v want="$1" '
    /^##[^#]/ {
      inside = (tolower($0) ~ tolower(want)) ? 1 : 0
      next
    }
    inside { print }
  ' "$FILE"
}

# 1 — required sections
for SEC in "TL;DR" "Why this pass exists" "component by component" "roads not taken" "Vocabulary" "What to watch" "Check yourself"; do
  if grep -qiE "^## +.*${SEC}" "$FILE"; then
    pass "section present: $SEC"
  else
    fail "section missing: $SEC"
  fi
done

# 2 — at least one component with the four-part treatment
CW_BODY="$(section "component by component")"
C_COUNT=$(printf '%s\n' "$CW_BODY" | grep -cE '^### ' || true)
B_COUNT=$(printf '%s\n' "$CW_BODY" | grep -ciE 'breaks downstream' || true)
if [ "$C_COUNT" -ge 1 ] && [ "$B_COUNT" -ge "$C_COUNT" ]; then
  pass "walkthrough: $C_COUNT component(s), each with 'what breaks downstream'"
elif [ "$C_COUNT" -ge 1 ]; then
  fail "walkthrough: $C_COUNT component(s) but only $B_COUNT carry 'what breaks downstream' — the fourth part is the test of understanding"
else
  fail "walkthrough has no components (need at least one '### <component>' block)"
fi

# 3 — decisions carry alternatives
D_BODY="$(section "roads not taken")"
D_ROWS=$(printf '%s\n' "$D_BODY" | grep -cE '^\|' || true)
if [ "$D_ROWS" -ge 3 ]; then   # header + separator + >=1 row
  pass "decisions table has at least one row (decision + rejected alternative)"
else
  fail "decisions table empty — every locked decision needs a rejected alternative and why it lost"
fi

# 4 — check-yourself question count
Q_COUNT=$(section "Check yourself" | grep -cE '^[0-9]+\.' || true)
if [ "$Q_COUNT" -ge 3 ] && [ "$Q_COUNT" -le 5 ]; then
  pass "Check yourself: $Q_COUNT question(s) (3-5 required)"
else
  fail "Check yourself: $Q_COUNT question(s) — need 3-5 numbered questions"
fi

# 5 — advisory: unresolved rationale markers
if grep -qiE 'alternative unrecorded' "$FILE"; then
  warn "'alternative unrecorded' marker(s) present — confirm each is flagged under What to watch"
fi

# 6 — teaching modes (v0.2.0). A lesson declares its modes on a `modes:` line;
# emitter modes (adept/review/map) are gate-checkable, reshape modes are
# behavioral (advisory). No modes: line → nothing here runs (full back-compat).
MODES_LINE="$(grep -iE '^>?[[:space:]]*modes:' "$FILE" | head -1 | sed -E 's/^[^:]*://; s/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
if [ -n "$MODES_LINE" ]; then
  pass "modes declared: $MODES_LINE"
  has_mode() { printf '%s' "$MODES_LINE" | grep -qiw "$1"; }

  if has_mode adept; then
    AB="$(section "ADEPT explanations")"
    if [ -z "$AB" ]; then
      fail "mode 'adept' declared but no '## ADEPT explanations' section"
    else
      miss=""
      for L in "Analogy" "Diagram" "Example" "Plain-English" "Technical"; do
        printf '%s\n' "$AB" | grep -qE "[*]{2}$L:" || miss="$miss $L"
      done
      if [ -n "$miss" ]; then fail "adept: ADEPT block missing label(s):$miss"; else pass "adept: all five ADEPT labels present"; fi
    fi
  fi

  if has_mode review; then
    RB="$(section "Review schedule")"
    if [ -z "$RB" ]; then
      fail "mode 'review' declared but no '## Review schedule' section"
    else
      QN=$(printf '%s\n' "$RB" | grep -cE '^Q:' || true)
      DN=$(printf '%s\n' "$RB" | grep -ciE 'day [0-9]+' || true)
      if [ "$QN" -ge 3 ] && [ "$DN" -ge 2 ]; then
        pass "review: $QN flashcard(s) + $DN dated checkpoint(s)"
      else
        fail "review: need >=3 'Q:' cards (have $QN) and >=2 'day N' checkpoints (have $DN) — spacing is the point"
      fi
    fi
  fi

  if has_mode map; then
    MB="$(section "Concept map")"
    if [ -z "$MB" ]; then
      fail "mode 'map' declared but no '## Concept map' section"
    else
      if printf '%s\n' "$MB" | grep -v '<!--' | grep -qE -- '-->'; then
        pass "map: concept map carries edges"
      else
        fail "map: '## Concept map' has no edges (expected 'A --> B' lines below the answer marker)"
      fi
    fi
  fi

  for M in teachback socratic why mix; do
    if has_mode "$M"; then
      warn "mode '$M' is behavioral (reshapes quiz/walkthrough) — not script-verifiable; confirm it was honored"
    fi
  done
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "GATE: PASS — the lesson is teach-ready; walk it, then quiz (unless --quiz off)."
  exit 0
else
  echo "GATE: FAIL — fix the items above; the lesson is not yet gate-ready."
  exit 1
fi
