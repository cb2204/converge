#!/bin/bash
# check-brd.sh — Converge Pass 0 gate checker.
# Verifies a BRD produced by idea-to-brd is structurally gate-ready:
#   1. all required sections present
#   2. the Problem section carries at least one number (quantified pain)
#   3. the Goals section names at least one KPI-looking line
#   4. Scope has both In and Out entries
#   5. every Open-questions record names an owner
# Warns (never fails) on likely solution-shape leaks — judgment stays human.
# bash 3.2 safe (macOS system bash).

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "usage: check-brd.sh docs/brd-<slug>.md" >&2
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
for SEC in "Executive summary" "Problem" "Goals" "Scope" "Definition of success" "Stakeholders" "Risks" "Constraints" "Open questions" "Source" "Sign-off"; do
  if grep -qiE "^## +.*${SEC}" "$FILE"; then
    pass "section present: $SEC"
  else
    fail "section missing: $SEC"
  fi
done

# 2 — quantified pain: at least one digit in the Problem section
if section "Problem" | grep -qE '[0-9]'; then
  pass "Problem is quantified (carries at least one number)"
else
  fail "Problem carries no number — cost, count, or frequency required ('a lot' is not a cost)"
fi

# 3 — at least one KPI line under Goals (a line with a digit or an arrow)
if section "Goals" | grep -qE '([0-9]|->|→)'; then
  pass "Goals name at least one KPI-shaped line"
else
  fail "Goals section has no KPI — need at least one owner-metric, ideally current → target"
fi

# 4 — scope has both sides
SCOPE_BODY="$(section "Scope")"
if printf '%s\n' "$SCOPE_BODY" | grep -qiE '\*\*In:?\*\*|^In:'; then
  pass "Scope: In present"
else
  fail "Scope: no explicit In entry"
fi
if printf '%s\n' "$SCOPE_BODY" | grep -qiE '\*\*Out:?\*\*|^Out:'; then
  pass "Scope: Out present"
else
  fail "Scope: no explicit Out entry — ask 'what are we explicitly NOT doing?'"
fi

# 5 — every open question owned
OQ_BODY="$(section "Open questions")"
Q_COUNT=$(printf '%s\n' "$OQ_BODY" | grep -cE '^- *question:' || true)
O_COUNT=$(printf '%s\n' "$OQ_BODY" | grep -cE '^ *owner:' || true)
if [ "$Q_COUNT" -eq 0 ]; then
  pass "Open questions: none recorded (explicitly empty is allowed)"
elif [ "$O_COUNT" -ge "$Q_COUNT" ]; then
  pass "Open questions: all $Q_COUNT record(s) carry an owner"
else
  fail "Open questions: $Q_COUNT record(s) but only $O_COUNT owner line(s) — every question needs a named owner"
fi

# 6 — number provenance (advisory: tags keep Pass 1 honest about traceability)
PG_BODY="$(section "Problem"; section "Goals")"
if printf '%s\n' "$PG_BODY" | grep -qE '[0-9]'; then
  if printf '%s\n' "$PG_BODY" | grep -qE '\((measured|estimated|guessed)\)'; then
    pass "numbers carry provenance tags ((measured)/(estimated)/(guessed))"
  else
    warn "numbers in Problem/Goals carry no provenance tag — tag each (measured), (estimated), or (guessed)"
  fi
fi
if grep -qE '\(guessed\)' "$FILE"; then
  warn "(guessed) number(s) present — each needs a matching open question to verify it"
fi

# 7 — sign-off state (advisory: structure is gated, the verdict is the owner's)
if section "Sign-off" | grep -qiE '\bcanonical\b'; then
  pass "Sign-off: owner has marked the brief canonical"
else
  warn "Sign-off pending — the brief is a draft until the owner writes 'canonical' (Pass 1 must not consume it)"
fi

# 8 — altitude warnings (advisory only; the human judges)
if grep -qiE '\b(the system shall|must implement|architecture|schema|database|endpoint|framework)\b' "$FILE"; then
  warn "possible solution-shape leak (requirement/tech language found) — keep the BRD in the owner's voice"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "GATE: PASS — the BRD is capture-complete; hand off to Pass 1 (brd-docs-to-tech-req)."
  exit 0
else
  echo "GATE: FAIL — fix the items above; the brief is not yet gate-ready."
  exit 1
fi
