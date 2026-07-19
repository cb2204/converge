#!/bin/bash
# check-brd.sh — Converge Pass 0 gate checker (the exit contract).
#
# Three modes:
#   canonical (default)  The handoff gate. Structure AND authorization: the
#                        owner's sign-off must say 'canonical' with an ISO
#                        date, scope In/Out must carry real entries, every
#                        open question a nonblank owner, numbers provenance-
#                        tagged, (guessed) numbers linked to an open question.
#                        ONLY this mode may print the Pass 1 handoff verdict.
#   --draft              Validation while writing. Same structural checks;
#                        ownership/provenance/sign-off items downgrade to
#                        warnings. NEVER authorizes handoff, no matter how
#                        complete the brief.
#   --no-go <file>       Validates a no-go record (the pass's other honest
#                        exit): a no-go marker, an ISO date, why it didn't
#                        clear, and what would reopen it.
#
# Semantic judgment (owner voice, altitude leaks) stays WARN in every mode —
# the human judges voice; this script mechanizes only the provable.
#
# Agent contract: the LAST line is always a stable machine token —
#   CHECK_BRD=PASS | FAIL | DRAFT_OK | DRAFT_INCOMPLETE | NOGO_OK | NOGO_INVALID
# so a harness greps one line and never parses prose. Usage errors exit 2.
#
# PDF policy: this verifier reads text (.md). A .pdf brief is a consensus
# object — convert it (or emit --out-format md) and gate the .md.
#
# bash 3.2 safe (macOS system bash).

set -euo pipefail

CHECK_BRD_VERSION="0.3.0"

MODE="canonical"
FILE=""

for ARG in "$@"; do
  case "$ARG" in
    --version) echo "check-brd v$CHECK_BRD_VERSION"; exit 0 ;;
    --draft)   MODE="draft" ;;
    --no-go)   MODE="nogo" ;;
    -h|--help)
      echo "usage: check-brd.sh [--draft] docs/brd-<slug>.md" >&2
      echo "       check-brd.sh --no-go docs/no-go-<slug>.md" >&2
      echo "       check-brd.sh --version" >&2
      exit 2
      ;;
    *) FILE="$ARG" ;;
  esac
done

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "usage: check-brd.sh [--draft|--no-go] <file.md>  (file missing: '$FILE')" >&2
  exit 2
fi

case "$FILE" in
  *.pdf)
    echo "ERROR: this verifier reads text (.md) — a .pdf is a consensus object." >&2
    echo "Convert it (or re-emit with --out-format md), then gate the .md." >&2
    exit 2
    ;;
esac

FAIL=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAIL=1; }
warn() { printf 'WARN  %s\n' "$1"; }

# own() — an ownership/authorization check: hard in canonical, advisory in draft.
own() {
  if [ "$MODE" = "canonical" ]; then
    fail "$1"
  else
    warn "$1 (draft: advisory)"
  fi
}

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

# ===========================================================================
# --no-go mode — validate the pass's other honest exit, then leave.
# ===========================================================================
if [ "$MODE" = "nogo" ]; then
  if grep -qiE 'no-go' "$FILE"; then
    pass "no-go: record identifies itself as a no-go"
  else
    fail "no-go: no 'no-go' marker found — say what this record is"
  fi
  if grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$FILE"; then
    pass "no-go: dated (ISO YYYY-MM-DD)"
  else
    fail "no-go: no ISO date — a parked idea needs its parking date"
  fi
  if grep -qiE '(^|[[:space:]#*-])why([^a-z]|$)' "$FILE"; then
    pass "no-go: states why it didn't clear"
  else
    fail "no-go: no 'why' — record why the pain didn't justify a build"
  fi
  if grep -qiE 'reopen' "$FILE"; then
    pass "no-go: states what would reopen it"
  else
    fail "no-go: nothing would reopen it? — a no-go is parked, not deleted; name the reopen condition"
  fi
  echo
  if [ "$FAIL" -eq 0 ]; then
    echo "NO-GO RECORD: valid — the idea is parked honestly."
    echo "CHECK_BRD=NOGO_OK"
    exit 0
  else
    echo "NO-GO RECORD: invalid — fix the items above."
    echo "CHECK_BRD=NOGO_INVALID"
    exit 1
  fi
fi

# ===========================================================================
# BRD modes (canonical | draft)
# ===========================================================================

# 1 — required sections (structural: hard in every mode)
for SEC in "Executive summary" "Problem" "Goals" "Scope" "Definition of success" "Stakeholders" "Risks" "Constraints" "Open questions" "Source" "Sign-off"; do
  if grep -qiE "^## +.*${SEC}" "$FILE"; then
    pass "section present: $SEC"
  else
    fail "section missing: $SEC"
  fi
done

# 2 — quantified pain: at least one digit in the Problem section (structural)
if section "Problem" | grep -qE '[0-9]'; then
  pass "Problem is quantified (carries at least one number)"
else
  fail "Problem carries no number — cost, count, or frequency required ('a lot' is not a cost)"
fi

# 3 — at least one KPI line under Goals (structural)
if section "Goals" | grep -qE '([0-9]|->|→)'; then
  pass "Goals name at least one KPI-shaped line"
else
  fail "Goals section has no KPI — need at least one owner-metric, ideally current → target"
fi

# 4 — scope has both sides, and each side has real entries
SCOPE_BODY="$(section "Scope")"

scope_entries() {
  # count non-empty entry lines inside the In or Out zone, including
  # same-line content after the marker ("**In:** everything" counts as 1)
  printf '%s\n' "$SCOPE_BODY" | awk -v which="$1" '
    BEGIN { zone = 0; n = 0 }
    {
      low = tolower($0)
      if (low ~ /(\*\*|^)(in|out|undecided):?(\*\*|[[:space:]]|$)/) {
        zone = (low ~ ("(\\*\\*|^)" which ":?")) ? 1 : 0
        if (zone) {
          line = $0
          sub(/.*\*\*[A-Za-z]+:?\*\*/, "", line)
          sub(/^[A-Za-z]+:/, "", line)
          if (line ~ /[^[:space:]]/) n++
        }
        next
      }
      if (zone && $0 ~ /[^[:space:]]/) n++
    }
    END { print n }'
}

if printf '%s\n' "$SCOPE_BODY" | grep -qiE '\*\*In:?\*\*|^In:'; then
  IN_N="$(scope_entries in)"
  if [ "$IN_N" -ge 1 ]; then
    pass "Scope: In present with $IN_N entr(y/ies)"
  else
    fail "Scope: In has no entries — an empty In is not a scope decision"
  fi
else
  fail "Scope: no explicit In entry"
fi
if printf '%s\n' "$SCOPE_BODY" | grep -qiE '\*\*Out:?\*\*|^Out:'; then
  OUT_N="$(scope_entries out)"
  if [ "$OUT_N" -ge 1 ]; then
    pass "Scope: Out present with $OUT_N entr(y/ies)"
  else
    fail "Scope: Out has no entries — ask 'what are we explicitly NOT doing?'"
  fi
else
  fail "Scope: no explicit Out entry — ask 'what are we explicitly NOT doing?'"
fi

# 5 — every open question owned, and every owner nonblank
OQ_BODY="$(section "Open questions")"
Q_COUNT=$(printf '%s\n' "$OQ_BODY" | grep -cE '^- *question:' || true)
O_TOTAL=$(printf '%s\n' "$OQ_BODY" | grep -cE '^[[:space:]]*owner:' || true)
O_FILLED=$(printf '%s\n' "$OQ_BODY" | grep -cE '^[[:space:]]*owner:[[:space:]]*[^[:space:]]' || true)
if [ "$Q_COUNT" -eq 0 ]; then
  pass "Open questions: none recorded (explicitly empty is allowed)"
else
  if [ "$O_TOTAL" -gt "$O_FILLED" ]; then
    own "Open questions: blank owner value(s) — every owner must be a name, not an empty field"
  fi
  if [ "$O_FILLED" -ge "$Q_COUNT" ]; then
    pass "Open questions: all $Q_COUNT record(s) carry a nonblank owner"
  else
    own "Open questions: $Q_COUNT record(s) but only $O_FILLED nonblank owner line(s) — every question needs a named owner"
  fi
fi

# 6 — number provenance (mechanically provable → hard in canonical)
PG_BODY="$(section "Problem"; section "Goals")"
if printf '%s\n' "$PG_BODY" | grep -qE '[0-9]'; then
  if printf '%s\n' "$PG_BODY" | grep -qE '\((measured|estimated|guessed)\)'; then
    pass "numbers carry provenance tags ((measured)/(estimated)/(guessed))"
  else
    own "numbers in Problem/Goals carry no provenance tag — tag each (measured), (estimated), or (guessed)"
  fi
fi
if grep -qE '\(guessed\)' "$FILE"; then
  if [ "$Q_COUNT" -ge 1 ]; then
    pass "(guessed) number(s) are linked: open question(s) exist to verify them"
  else
    own "(guessed) number(s) with no open question to verify them — a guess without a verification owner is a fabrication waiting to load-bear"
  fi
fi

# 7 — sign-off: the authorization boundary between draft and canonical
SO_BODY="$(section "Sign-off")"
if [ "$MODE" = "canonical" ]; then
  if printf '%s\n' "$SO_BODY" | grep -qiE '\bcanonical\b'; then
    pass "Sign-off: owner has marked the brief canonical"
  else
    fail "Sign-off: owner verdict 'canonical' missing — a draft cannot pass the canonical gate (validate work-in-progress with --draft)"
  fi
  if printf '%s\n' "$SO_BODY" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    pass "Sign-off: dated (ISO YYYY-MM-DD)"
  else
    fail "Sign-off: no ISO date (YYYY-MM-DD) — an undated sign-off cannot anchor the descent"
  fi
else
  if printf '%s\n' "$SO_BODY" | grep -qiE '\bcanonical\b'; then
    warn "Sign-off already reads canonical — run the default (canonical) mode for the handoff verdict"
  else
    warn "Sign-off pending — the brief is a draft until the owner writes 'canonical' (Pass 1 must not consume it)"
  fi
fi

# 8 — altitude warnings (advisory in EVERY mode; the human judges voice)
if grep -qiE '\b(the system shall|must implement|architecture|schema|database|endpoint|framework)\b' "$FILE"; then
  warn "possible solution-shape leak (requirement/tech language found) — keep the BRD in the owner's voice"
fi

# ===========================================================================
# Verdict — only the canonical gate may authorize the handoff to Pass 1.
# ===========================================================================
echo
if [ "$MODE" = "canonical" ]; then
  if [ "$FAIL" -eq 0 ]; then
    echo "GATE: PASS — canonical brief; hand off to Pass 1 (brd-docs-to-tech-req)."
    echo "CHECK_BRD=PASS"
    exit 0
  else
    echo "GATE: FAIL — fix the items above; this brief is NOT authorized for Pass 1."
    echo "CHECK_BRD=FAIL"
    exit 1
  fi
else
  if [ "$FAIL" -eq 0 ]; then
    echo "DRAFT: structure OK — validation only; a draft is never authorized for Pass 1 (owner sign-off + the canonical gate do that)."
    echo "CHECK_BRD=DRAFT_OK"
    exit 0
  else
    echo "DRAFT: incomplete — fix the structural items above, then keep drafting."
    echo "CHECK_BRD=DRAFT_INCOMPLETE"
    exit 1
  fi
fi
