#!/usr/bin/env bash
# check-consensus-gate.sh — Converge Pass 4 (Consensus): the falsifiable exit gate.
#
# The pass is done only when the swimlane plans have been ATTACKED by a different
# model, GROUNDED against the spec + ADRs, every objection is FIXED-or-ACCEPTED,
# the cross-lane gold-table interface survived, and THE FORK is named at the top
# of every plan. This script makes that machine-checkable — it does not sharpen
# plans, it only refuses to let a soft pass slip through.
#
# Usage:
#   check-consensus-gate.sh sketch/                 Gate every sketch/*.plan
#   check-consensus-gate.sh sketch/foo.plan ...     Gate the named plans only
#   check-consensus-gate.sh --spec docs/x.pdf DIR   Point at a specific tech-spec
#   check-consensus-gate.sh --adrs docs/adrs   DIR  Point at a specific ADR dir
#   check-consensus-gate.sh --help
#
# Exit: 0 = green (all checks hold); 1 = a check failed; 2 = nothing to gate.
#
# bash 3.2-safe (runs on macOS system /bin/bash). No mapfile, no associative
# arrays — plain grep/sed/awk over the plan text, mirroring the task-spec scripts.

set -euo pipefail

SPEC_GLOB="docs/tech-spec-*.pdf docs/tech-spec-*.md"
ADR_DIR="docs/adrs"

usage() { sed -n '2,20p' "$0"; }

err() { echo "ERROR: $*" >&2; }

# ── Parse args ────────────────────────────────────────────────────────────────
TARGETS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --spec)    SPEC_GLOB="${2:?--spec needs a path}"; shift 2 ;;
    --adrs)    ADR_DIR="${2:?--adrs needs a path}"; shift 2 ;;
    --) shift; TARGETS="$TARGETS $*"; break ;;
    -*) err "unknown option: $1"; usage >&2; exit 1 ;;
    *)  TARGETS="$TARGETS $1"; shift ;;
  esac
done

# Default target: the conventional sketch/ directory.
[ -n "${TARGETS// /}" ] || TARGETS="sketch/"

# ── Resolve the target dir/files into a flat list of *.plan paths ─────────────
PLANS=""
for t in $TARGETS; do
  if [ -d "$t" ]; then
    for f in "$t"/*.plan; do
      [ -e "$f" ] || continue
      PLANS="$PLANS $f"
    done
  elif [ -f "$t" ]; then
    PLANS="$PLANS $t"
  else
    err "no such plan or directory: $t"
    exit 1
  fi
done

if [ -z "${PLANS// /}" ]; then
  echo "GATE: no *.plan files found — run Pass 3 (reqs-to-swimlane-plans) first." >&2
  exit 2
fi

# ── Check helpers ─────────────────────────────────────────────────────────────
RC=0
pass() { echo "  ok   $*"; }
fail() { echo "  FAIL $*"; RC=1; }

# A plan's fork line: FORK A|B declared near the top. Tolerant of both the prose
# form ("**Execution model: FORK B — task-driven.**") and the terse form the
# SKILL.md prescribes ("FORK: A (plan-driven)"). Must appear in the first 15 lines.
fork_declared() {
  head -15 "$1" | grep -qiE 'FORK[:[:space:]]*[AB]\b'
}

# The fork must also carry its descriptor (plan-driven / task-driven) so the line
# is a decision, not a bare letter.
fork_has_reason() {
  head -15 "$1" | grep -qiE '(plan-driven|task-driven)'
}

echo "== Converge Pass 4 · Consensus gate =="
echo "plans:$PLANS"
echo

# ── Check 1 — a DIFFERENT engine attacked the plans (not self-review) ─────────
# The adversary leaves fingerprints: objection markers naming the engine
# (Codex C1, gemini, gpt) somewhere in the plan set. Self-review leaves none.
echo "[1] a different-model adversary attacked the plans"
ADVERSARY_HITS=$(grep -hoiE '\b(Codex|Gemini|GPT)\b' $PLANS 2>/dev/null | sort -u | tr '\n' ' ' || true)
if [ -n "${ADVERSARY_HITS// /}" ]; then
  pass "adversary fingerprints present:${ADVERSARY_HITS}"
else
  fail "no adversary named in any plan — did the author self-review? (Step 1)"
fi
echo

# ── Check 2 — plans grilled against the tech-spec AND the ADRs ────────────────
echo "[2] plans grounded vs. tech-spec + ADRs"
SPEC_FOUND=""
for g in $SPEC_GLOB; do
  [ -e "$g" ] && SPEC_FOUND="$g" && break
done
if [ -n "$SPEC_FOUND" ]; then
  pass "tech-spec present: $SPEC_FOUND"
else
  fail "no tech-spec found ($SPEC_GLOB) — Step 2 has no ground truth"
fi
# Spec traceability must be visible in the plans (E-requirement citations, §refs).
if grep -qiE '(spec|§|\bE[0-9]\b|traceab)' $PLANS 2>/dev/null; then
  pass "plans cite the spec (requirement/section references present)"
else
  fail "no spec citations in the plans — Step 2 drift check not recorded"
fi
if [ -d "$ADR_DIR" ] && ls "$ADR_DIR"/*.md >/dev/null 2>&1; then
  pass "ADRs present in $ADR_DIR/"
else
  # SKILL.md contract: absent ADRs are allowed but must be logged as an open Q.
  if grep -qiE 'ADRs? absent' $PLANS 2>/dev/null; then
    pass "ADRs absent — logged as an open question (allowed by the pass)"
  else
    fail "no ADRs in $ADR_DIR/ AND not logged as 'ADRs absent' open question"
  fi
fi
echo

# ── Check 3 — every logged objection is FIXED or ACCEPTED (no silent drop) ────
# Objections are labelled C1, C2, ... (e.g. "Codex C3"). Each id must recur in
# the plan body — the recurrence is the resolution (a FIX cites the C-id where it
# revised the plan; an ACCEPT records it with an owner). An id that appears once
# and is never referenced again is a logged-but-unresolved objection.
echo "[3] every objection FIXED or ACCEPTED (one resolution per objection)"
OBJ_IDS=$(grep -hoE '\bC[0-9]+\b' $PLANS 2>/dev/null | sort -u || true)
if [ -z "$OBJ_IDS" ]; then
  fail "no objection ids (C1, C2, ...) found — Step 1 attack not logged"
else
  UNRESOLVED=""
  for id in $OBJ_IDS; do
    # Count every occurrence of this id across all plans. A resolved objection is
    # referenced at least twice: the log entry + the place it was fixed/accepted.
    N=$(grep -hoE "\b${id}\b" $PLANS 2>/dev/null | wc -l | tr -d ' ')
    if [ "${N:-0}" -lt 2 ]; then
      UNRESOLVED="$UNRESOLVED $id"
    fi
  done
  if [ -n "${UNRESOLVED// /}" ]; then
    fail "objection(s) logged but not resolved (no FIX/ACCEPT reference):${UNRESOLVED}"
  else
    pass "all objections resolved:$(echo $OBJ_IDS | sed 's/^/ /')"
  fi
fi
# Every ACCEPTed risk must name an owner — an ACCEPT without an owner is a drop.
if grep -qiE 'Accepted risk' $PLANS 2>/dev/null; then
  if grep -qiE 'Owner:' $PLANS 2>/dev/null; then
    pass "accepted risks carry a named owner"
  else
    fail "an 'Accepted risk' block has no 'Owner:' — ACCEPT must name an owner"
  fi
fi
echo

# ── Check 4 — the cross-lane gold-table interface survived scrutiny ───────────
# The seam is the medallion->serving contract: gold.* consumed read-only, pinned
# by a per-mart schema.yml, read against a single published _gold_run_id.
echo "[4] cross-lane interface (medallion -> serving gold-table contract) survived"
SEAM_RC=0
grep -qiE 'gold\.\*|gold_[a-z]' $PLANS 2>/dev/null || { fail "no gold.* interface referenced"; SEAM_RC=1; }
grep -qiE 'schema\.yml'         $PLANS 2>/dev/null || { fail "gold contract not pinned by a schema.yml"; SEAM_RC=1; }
grep -qiE '_gold_run_id'        $PLANS 2>/dev/null || { fail "no atomic-publish generation stamp (_gold_run_id)"; SEAM_RC=1; }
[ "$SEAM_RC" -eq 0 ] && pass "gold.* + schema.yml contract + _gold_run_id all present"
echo

# ── Check 5 — THE FORK declared at the top of EVERY plan, with a reason ───────
echo "[5] the fork declared at the top of every plan (Fork A or Fork B) + reason"
for p in $PLANS; do
  if fork_declared "$p"; then
    if fork_has_reason "$p"; then
      pass "$(basename "$p"): fork declared with plan-driven/task-driven descriptor"
    else
      fail "$(basename "$p"): fork letter present but no plan-driven/task-driven reason"
    fi
  else
    fail "$(basename "$p"): no 'FORK A|B' in the first 15 lines (Step 4 skipped)"
  fi
done
echo

# ── Check 6 — an open-questions list exists; blockers are flagged ─────────────
echo "[6] open-questions list exists; blockers flagged"
if grep -qiE '^#+[[:space:]]*Open[[:space:]-]*questions|^\**[[:space:]]*Open[[:space:]-]*questions' $PLANS 2>/dev/null; then
  pass "open-questions section present"
  if grep -qiE 'Blocks? build|Yes[[:space:]—-]' $PLANS 2>/dev/null; then
    pass "blocker status recorded (Blocks build? column)"
  else
    fail "open questions present but no blocker flag (Blocks build? / Yes|No)"
  fi
else
  fail "no 'Open questions' section — the residual-risk list is missing"
fi
echo

# ── Verdict ───────────────────────────────────────────────────────────────────
if [ "$RC" -eq 0 ]; then
  echo "GATE: GREEN — consensus reached. Hand off per the fork (Pass 5A or 5B)."
else
  echo "GATE: RED — see FAILs above. Sharpen in place (Step 3) or declare the fork" >&2
  echo "      (Step 4); do NOT add scope. Re-run this gate until green." >&2
fi
exit "$RC"
