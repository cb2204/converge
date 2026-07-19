#!/bin/bash
# check-brd.sh — Converge Pass 0 gate checker (the exit contract).
#
# Three modes:
#   canonical (default)  The handoff gate. Structure AND authorization: the
#                        owner's sign-off must say 'canonical' on the verdict
#                        line itself (a verdict carrying 'pending'/'draft'
#                        never authorizes) with a VALID ISO date on a
#                        Date/Signed line, scope In/Out must carry real
#                        entries, every open question a nonblank owner in the
#                        record shape, numbers provenance-tagged, (guessed)
#                        numbers linked to an open question.
#                        ONLY this mode may print the Pass 1 handoff verdict.
#   --draft              Validation while writing. Same structural checks;
#                        ownership/provenance/sign-off items downgrade to
#                        warnings. NEVER authorizes handoff, no matter how
#                        complete the brief.
#   --no-go <file>       Validates a no-go record (the pass's other honest
#                        exit): a no-go marker, an ISO date, why it didn't
#                        clear, and what would reopen it.
#
# All checks run on the file with fenced code blocks stripped — an example
# inside ``` fences can neither satisfy nor trip a check (v0.3.1).
#
# Semantic judgment (owner voice, altitude leaks) stays WARN in every mode —
# the human judges voice; this script mechanizes only the provable.
#
# Agent contract: the LAST line is always a stable machine token —
#   CHECK_BRD=PASS | FAIL | DRAFT_OK | DRAFT_INCOMPLETE | NOGO_OK
#             | NOGO_INVALID | USAGE_ERROR
# so a harness greps one line and never parses prose. Usage errors exit 2
# AND still end in CHECK_BRD=USAGE_ERROR (v0.3.1 — agents are users too).
#
# PDF policy: this verifier reads text (.md). A .pdf brief is a consensus
# object — convert it (or emit --out-format md) and gate the .md.
#
# bash 3.2 safe (macOS system bash).

set -euo pipefail

CHECK_BRD_VERSION="0.3.1"

# A valid ISO date: month 01-12, day 01-31 (2026-13-45 is not a date).
ISO_RE='[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'

usage_error() {
  printf 'ERROR: %s\n' "$1" >&2
  printf 'usage: check-brd.sh [--draft] docs/brd-<slug>.md\n' >&2
  printf '       check-brd.sh --no-go docs/no-go-<slug>.md\n' >&2
  printf '       check-brd.sh --version\n' >&2
  echo "CHECK_BRD=USAGE_ERROR"
  exit 2
}

MODE="canonical"
FILE=""
DRAFT_SET=0
NOGO_SET=0

for ARG in "$@"; do
  case "$ARG" in
    --version) echo "check-brd v$CHECK_BRD_VERSION"; exit 0 ;;
    --draft)   MODE="draft"; DRAFT_SET=1 ;;
    --no-go)   MODE="nogo";  NOGO_SET=1 ;;
    -h|--help)
      echo "usage: check-brd.sh [--draft] docs/brd-<slug>.md" >&2
      echo "       check-brd.sh --no-go docs/no-go-<slug>.md" >&2
      echo "       check-brd.sh --version" >&2
      echo "CHECK_BRD=USAGE_ERROR"
      exit 2
      ;;
    -*)
      usage_error "unknown flag '$ARG' — expected --draft, --no-go, --version, or a file path"
      ;;
    *)
      if [ -n "$FILE" ]; then
        usage_error "more than one file argument ('$FILE', '$ARG') — gate one brief per run"
      fi
      FILE="$ARG"
      ;;
  esac
done

if [ "$DRAFT_SET" -eq 1 ] && [ "$NOGO_SET" -eq 1 ]; then
  usage_error "--draft and --no-go conflict — a record is a BRD draft or a no-go, never both"
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  usage_error "file missing: '$FILE'"
fi

case "$FILE" in
  *.pdf)
    echo "ERROR: this verifier reads text (.md) — a .pdf is a consensus object." >&2
    echo "Convert it (or re-emit with --out-format md), then gate the .md." >&2
    echo "CHECK_BRD=USAGE_ERROR"
    exit 2
    ;;
esac

# BODY: the file with fenced code blocks stripped. Every check below reads
# BODY, never the raw file — an example inside ``` fences proves nothing.
BODY="$(awk '/^[[:space:]]*```/ { fence = !fence; next } !fence { print }' "$FILE")"

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
  printf '%s\n' "$BODY" | awk -v want="$1" '
    /^##[^#]/ {
      inside = (tolower($0) ~ tolower(want)) ? 1 : 0
      next
    }
    inside { print }
  '
}

# ===========================================================================
# --no-go mode — validate the pass's other honest exit, then leave.
# ===========================================================================
if [ "$MODE" = "nogo" ]; then
  if printf '%s\n' "$BODY" | grep -qiE 'no-go'; then
    pass "no-go: record identifies itself as a no-go"
  else
    fail "no-go: no 'no-go' marker found — say what this record is"
  fi
  if printf '%s\n' "$BODY" | grep -qE "$ISO_RE"; then
    pass "no-go: dated (valid ISO YYYY-MM-DD)"
  else
    fail "no-go: no valid ISO date — a parked idea needs its parking date"
  fi
  if printf '%s\n' "$BODY" | grep -qiE '(^|[[:space:]#*-])why([^a-z]|$)'; then
    pass "no-go: states why it didn't clear"
  else
    fail "no-go: no 'why' — record why the pain didn't justify a build"
  fi
  if printf '%s\n' "$BODY" | grep -qiE 'reopen'; then
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
  if printf '%s\n' "$BODY" | grep -qiE "^## +.*${SEC}"; then
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

# 5 — every open question owned, in the record shape; unrecognized
#     question-shaped content FAILS CLOSED (the gate cannot verify what it
#     cannot parse — v0.3.1)
OQ_BODY="$(section "Open questions")"
Q_COUNT=$(printf '%s\n' "$OQ_BODY" | grep -cE '^- *question:' || true)
O_TOTAL=$(printf '%s\n' "$OQ_BODY" | grep -cE '^[[:space:]]*owner:' || true)
O_FILLED=$(printf '%s\n' "$OQ_BODY" | grep -cE '^[[:space:]]*owner:[[:space:]]*[^[:space:]]' || true)
if [ "$Q_COUNT" -eq 0 ]; then
  if printf '%s\n' "$OQ_BODY" | grep -qiE '(\?|question)'; then
    own "Open questions: content present but not in the record shape ('- question:' / 'owner:') — the gate cannot verify ownership of what it cannot parse"
  else
    pass "Open questions: none recorded (explicitly empty is allowed)"
  fi
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
if printf '%s\n' "$BODY" | grep -qE '\(guessed\)'; then
  if [ "$Q_COUNT" -ge 1 ]; then
    pass "(guessed) number(s) are linked: open question(s) exist to verify them"
  else
    own "(guessed) number(s) with no open question to verify them — a guess without a verification owner is a fabrication waiting to load-bear"
  fi
fi

# 7 — sign-off: the authorization boundary between draft and canonical.
#     Anchored to the VERDICT LINE (v0.3.1): 'canonical' anywhere else in the
#     section — a guidance sentence, an example — authorizes nothing.
SO_BODY="$(section "Sign-off")"
VERDICT_LINE="$(printf '%s\n' "$SO_BODY" | grep -iE 'verdict' | head -1 || true)"
VERDICT_CANONICAL=0
if printf '%s\n' "$VERDICT_LINE" | grep -qiE '\bcanonical\b'; then
  if ! printf '%s\n' "$VERDICT_LINE" | grep -qiE '\b(pending|draft)\b'; then
    VERDICT_CANONICAL=1
  fi
fi
DATE_LINES="$(printf '%s\n' "$SO_BODY" | grep -iE '(date|signed)' || true)"
if [ "$MODE" = "canonical" ]; then
  if [ "$VERDICT_CANONICAL" -eq 1 ]; then
    pass "Sign-off: owner has marked the brief canonical"
  else
    fail "Sign-off: owner verdict 'canonical' missing — a draft cannot pass the canonical gate (validate work-in-progress with --draft)"
  fi
  if printf '%s\n' "$DATE_LINES" | grep -qE "$ISO_RE"; then
    pass "Sign-off: dated (ISO YYYY-MM-DD)"
  else
    fail "Sign-off: no valid ISO date (YYYY-MM-DD) on a Date/Signed line — an undated sign-off cannot anchor the descent"
  fi
else
  if [ "$VERDICT_CANONICAL" -eq 1 ]; then
    warn "Sign-off already reads canonical — run the default (canonical) mode for the handoff verdict"
  else
    warn "Sign-off pending — the brief is a draft until the owner writes 'canonical' (Pass 1 must not consume it)"
  fi
fi

# 8 — altitude warnings (advisory in EVERY mode; the human judges voice)
if printf '%s\n' "$BODY" | grep -qiE '\b(the system shall|must implement|architecture|schema|database|endpoint|framework)\b'; then
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
