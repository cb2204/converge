#!/usr/bin/env bash
# check-tech-spec.sh — Converge Pass 1 gate verifier.
#
# The bundled checklist verifier that SKILL.md Step 4 invokes. Given a
# tech-spec path it asserts the six required sections are present, that the
# spec restates the problem, that requirements read as falsifiable, that
# success metrics are expressed current -> target, that the source data is
# named, and that open assumptions carry owners. It also WARNS on any
# technology/stack leak (dbt, duckdb, postgres, MCP, FastAPI, a schema, ...)
# because Pass 1 must stay above the stack — the engine is decided in Pass 3.
#
# Usage:
#   bash check-tech-spec.sh docs/tech-spec-analytical-engine.md
#   bash check-tech-spec.sh --version
#
# Exit codes:
#   0   PASS — every required box is checked (warnings do not fail the gate)
#   1   FAIL — one or more required checks failed, or the file is missing
#   2   usage error
#
# Portability: macOS system bash 3.2 safe. No mapfile, no `declare -A`, no
# process substitution into arrays. grep/sed/awk only, like the task-spec
# skill scripts.

set -euo pipefail

CHECK_TECH_SPEC_VERSION="0.2.0"

# ---------------------------------------------------------------------------
# Error / warning helpers (arrays + explicit counters so `set -u` stays happy
# on bash 3.2, where ${#arr[@]} on a never-assigned array can trip up).
# ---------------------------------------------------------------------------
ERRORS=()
WARNINGS=()
PASSES=()
NERR=0
NWARN=0
NPASS=0

err()  { ERRORS+=("$1");   NERR=$((NERR + 1)); }
warn() { WARNINGS+=("$1"); NWARN=$((NWARN + 1)); }
ok()   { PASSES+=("$1");   NPASS=$((NPASS + 1)); }

die() {
  echo "ERROR: $*" >&2
  exit 2
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--version" ]]; then
  echo "check-tech-spec v$CHECK_TECH_SPEC_VERSION"
  exit 0
fi

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "usage: bash check-tech-spec.sh <tech-spec.md>" >&2
  echo "       bash check-tech-spec.sh --version" >&2
  exit 2
fi

SPEC="$1"

[[ -f "$SPEC" ]] || die "tech-spec not found: $SPEC"

case "$SPEC" in
  *.md) : ;;
  *.pdf)
    die "this verifier reads text (.md); a .pdf is a consensus object — emit --out-format md once the spec is locked, then re-run the gate on it"
    ;;
  *)
    warn "unexpected extension on '$SPEC' — expected a .md tech-spec"
    ;;
esac

# Lower-cased copy of the body for case-insensitive presence checks. Keep the
# original around for line-accurate leak reporting.
BODY_LC="$(tr '[:upper:]' '[:lower:]' < "$SPEC")"

# has_any <pattern...> — return 0 if ANY extended-regex matches the body.
# Runs case-insensitively against the lower-cased body. Patterns are passed
# with `-e` so a pattern that starts with '<' or '>' (a comparator) is never
# mistaken for a grep option by BSD/macOS grep.
has_any() {
  local pat
  for pat in "$@"; do
    if printf '%s\n' "$BODY_LC" | grep -Eq -e "$pat"; then
      return 0
    fi
  done
  return 1
}

# count_matches <pattern> — count body lines matching an extended regex.
# Prints an integer. `-e` guards comparator patterns as above.
count_matches() {
  printf '%s\n' "$BODY_LC" | grep -Ec -e "$1" || true
}

# ---------------------------------------------------------------------------
# Check 1 — Problem restated (one paragraph, from the client's seat)
# ---------------------------------------------------------------------------
if has_any '^#+.*problem[[:space:]-]*(restat|statement)' 'problem restated' 'problem statement'; then
  ok "Problem restated section present"
else
  err "Missing a 'Problem restated' (or 'Problem statement') section — the one-paragraph restatement is half the gate"
fi

# ---------------------------------------------------------------------------
# Check 2 — Scope: in AND out, explicit
# ---------------------------------------------------------------------------
HAS_SCOPE=0
has_any '^#+.*scope' '\bscope\b' && HAS_SCOPE=1
HAS_IN=0
has_any 'in[[:space:]-]*scope' '\bin\b[[:space:]]*:' '^[[:space:]]*[-*].*\bin\b' && HAS_IN=1
HAS_OUT=0
has_any 'out[[:space:]-]*of[[:space:]-]*scope' 'out[[:space:]-]*scope' 'explicitly out' 'not[[:space:]]+in[[:space:]]+scope' && HAS_OUT=1

if [[ $HAS_SCOPE -eq 1 && $HAS_OUT -eq 1 ]]; then
  ok "Scope section present with an explicit out-of-scope boundary"
elif [[ $HAS_SCOPE -eq 1 && $HAS_OUT -eq 0 ]]; then
  err "Scope section present but no explicit OUT-of-scope boundary — say what the engine does NOT do"
else
  err "Missing a Scope section (in / out) at the problem level"
fi

# ---------------------------------------------------------------------------
# Check 3 — Requirements, and whether they read as verifiable/falsifiable
# ---------------------------------------------------------------------------
if has_any '^#+.*requirement' '\brequirements\b'; then
  ok "Requirements section present"
else
  err "Missing a Requirements section"
fi

# Falsifiability heuristic: a spec whose requirements can be eval'd carries
# measurable language — numbers, thresholds, comparators, time/percent units.
# Vague-only specs carry wish words with no numbers to pin them.
NNUM=$(count_matches '[0-9]+([.][0-9]+)?[[:space:]]*(%|percent|s\b|sec|second|minute|min\b|hour|hr\b|ms\b|day|row|record|byte|kb|mb|gb)')
NCOMPARE=$(count_matches '(<=|>=|<|>|within|at least|at most|no more than|no less than|fewer than|greater than|less than|up to)')
NWISH=$(count_matches '\b(fast|quick|reliable|robust|accurate|scalable|performant|user[- ]?friendly|seamless|efficient|snappy|responsive)\b')

if [[ "$NNUM" -eq 0 && "$NCOMPARE" -eq 0 ]]; then
  err "Requirements are not falsifiable — no measurable thresholds found (no numbers with units, no comparators). Rewrite each as current -> target; see references/falsifiable-requirements.md"
else
  ok "Requirements carry measurable thresholds ($NNUM quantified line(s), $NCOMPARE comparator(s))"
fi

if [[ "$NWISH" -gt 0 && "$NNUM" -eq 0 ]]; then
  warn "Wish words present with no numbers to anchor them (e.g. fast/reliable/accurate) — make each measurable or move it to open assumptions"
fi

# ---------------------------------------------------------------------------
# Check 4 — Success metrics expressed as current -> target
# ---------------------------------------------------------------------------
HAS_METRICS=0
has_any '^#+.*success[[:space:]]*metric' 'success metrics' '\bkpi' '\bmetric' && HAS_METRICS=1
HAS_C2T=0
# Accept ASCII '->' and the unicode arrow '→'; also accept a 'current ... target'
# pairing on the same line.
has_any '->' '→' 'current[[:space:]].*target' 'baseline[[:space:]].*target' 'from[[:space:]].*to[[:space:]]' && HAS_C2T=1

if [[ $HAS_METRICS -eq 1 && $HAS_C2T -eq 1 ]]; then
  ok "Success metrics present and expressed current -> target"
elif [[ $HAS_METRICS -eq 1 && $HAS_C2T -eq 0 ]]; then
  err "Success metrics present but not expressed as current -> target — every metric needs a baseline and a target traced to a BRD KPI"
else
  err "Missing a Success metrics section (each metric current -> target, traced to a BRD KPI)"
fi

# ---------------------------------------------------------------------------
# Check 5 — Data named (the source records the engine consumes)
# ---------------------------------------------------------------------------
if has_any '^#+.*data' '\bdata named\b' '\bsource\b.*\brecord' 'raw\.' '\border' '\bpayment' '\bcustomer' '\bproduct'; then
  ok "Source data named (the records the engine acts on)"
else
  err "The data the engine acts on is not named — name the source records at the problem level (order, payment, customer, product ...)"
fi

# ---------------------------------------------------------------------------
# Check 6 — Open assumptions, each with a named owner
# ---------------------------------------------------------------------------
HAS_ASSUMP=0
has_any '^#+.*assumption' 'open assumptions' '\bassumption' && HAS_ASSUMP=1
HAS_OWNER=0
has_any '\bowner\b' 'owned by' 'owner:' '@[a-z]' && HAS_OWNER=1

if [[ $HAS_ASSUMP -eq 1 && $HAS_OWNER -eq 1 ]]; then
  ok "Open assumptions recorded, each with a named owner"
elif [[ $HAS_ASSUMP -eq 1 && $HAS_OWNER -eq 0 ]]; then
  err "Open assumptions listed but no owner named — every assumption needs a named owner (a client stakeholder)"
else
  err "Missing an Open assumptions section (each with a named owner)"
fi

# ---------------------------------------------------------------------------
# Leak scan — WARN on premature technology / stack (Pass 1 stays above it).
# We scan word-boundaried, case-insensitively, and report the first hit line
# per term against the ORIGINAL body so the author can find it.
# ---------------------------------------------------------------------------
# Terms are extended-regex fragments matched with word boundaries where useful.
LEAK_TERMS="dbt duckdb postgres postgresql fastapi mcp airflow snowflake spark \
kafka redshift bigquery star[- ]schema snowflake[- ]schema create[[:space:]]+table \
[.]sql\b schema\.sql sqlmesh dagster prefect parquet iceberg pandas polars"

LEAKS_FOUND=0
for term in $LEAK_TERMS; do
  # Case-insensitive match against the original file for accurate line numbers.
  hit="$(grep -nEi -e "$term" "$SPEC" 2>/dev/null | head -1 || true)"
  if [[ -n "$hit" ]]; then
    warn "possible stack leak ('$term') — Pass 1 stays above the stack; defer to Pass 3: $hit"
    LEAKS_FOUND=$((LEAKS_FOUND + 1))
  fi
done
if [[ $LEAKS_FOUND -eq 0 ]]; then
  ok "No premature technology named (stays above the stack)"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "check-tech-spec.sh — $SPEC"
echo "════════════════════════════════════════════════════════════"
if [[ $NPASS -gt 0 ]]; then
  echo "Passed:"
  i=0
  while [[ $i -lt $NPASS ]]; do echo "  [x] ${PASSES[$i]}"; i=$((i + 1)); done
fi
if [[ $NWARN -gt 0 ]]; then
  echo "Warnings ($NWARN):"
  i=0
  while [[ $i -lt $NWARN ]]; do echo "  [!] ${WARNINGS[$i]}"; i=$((i + 1)); done
fi
if [[ $NERR -gt 0 ]]; then
  echo "Failed ($NERR):"
  i=0
  while [[ $i -lt $NERR ]]; do echo "  [ ] ${ERRORS[$i]}"; i=$((i + 1)); done
  echo "────────────────────────────────────────────────────────────"
  echo "FAIL: $NERR required check(s) failed — do not descend to Pass 2"
  exit 1
fi
echo "────────────────────────────────────────────────────────────"
if [[ $NWARN -gt 0 ]]; then
  echo "PASS: gate met with $NWARN warning(s) — review the stack leaks above before sign-off"
else
  echo "PASS: gate met — the tech-spec is ready to hand to Pass 2 (tech-req-to-adrs)"
fi
exit 0
