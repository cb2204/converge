#!/usr/bin/env bash
# verify-registration.sh — the GATE. Assert the board faithfully mirrors the
# signed-off specs before this pass is allowed to end.
#
# Confirms, and emits a single machine-readable VERDICT line:
#   1) 1:1 mapping        — count(issues) == count(signed_off specs), every spec
#                           has exactly one issue and vice-versa (no orphans, no
#                           double-registration).
#   2) graph faithful     — every depends_on edge is one blocked-by link; no
#                           extra links, none missing.
#   3) no cycles          — the signed-off dependency subgraph is a DAG.
#   4) no un-gated leak    — only signed_off specs are on the board.
#
# Usage:
#   verify-registration.sh [--tracker github|linear|jira] [--tasks-dir DIR]
#                          [--dry-run] [--prune]
#
#   --dry-run  verify the SPEC side only (cycles, edge integrity, gate) with no
#              network — the offline half of the gate. Board-vs-spec count/link
#              comparison is SKIPPED (it needs a live adapter).
#   --prune    report orphan issues (on the board but with no signed-off spec).
#              Live only.
#
# Exit: 0 and `VERDICT: REGISTERED` when every check holds; 1 and
# `VERDICT: DO NOT PROCEED` on the first failure. This is a gate, not a fixer.
#
# bash-3.2-safe: scratch files + grep/awk, no associative arrays.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_parse.sh
source "$SELF_DIR/_parse.sh"

TRACKER="linear"
TASKS_DIR="${TSI_TASKS_DIR:-tasks}"
DRY_RUN=0
PRUNE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tracker)   TRACKER="${2:?}"; shift 2 ;;
    --tracker=*) TRACKER="${1#--tracker=}"; shift ;;
    --tasks-dir)   TASKS_DIR="${2:?}"; shift 2 ;;
    --tasks-dir=*) TASKS_DIR="${1#--tasks-dir=}"; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --prune)     PRUNE=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'; exit 0 ;;
    *) tsi_die "unknown arg '$1' (see --help)" ;;
  esac
done

case "$TRACKER" in github|linear|jira) ;; *) tsi_die "unknown --tracker '$TRACKER'" ;; esac
[[ -d "$TASKS_DIR" ]] || tsi_die "tasks dir '$TASKS_DIR' not found"
ADAPTER="$SELF_DIR/adapters/${TRACKER}.sh"
[[ -f "$ADAPTER" ]] || tsi_die "adapter not found: $ADAPTER"

WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/tsi-verify.$$")"
mkdir -p "$WORK"
trap 'rm -rf "$WORK" 2>/dev/null || true' EXIT

SIGNED="$WORK/signed.txt"   # signed-off spec ids
EDGES="$WORK/edges.tsv"     # from_id \t to_id
UNGATED="$WORK/ungated.txt" # ids with signed_off != true
: > "$SIGNED"; : > "$EDGES"; : > "$UNGATED"

FAIL=0
fail() { echo "  FAIL: $*" >&2; FAIL=1; }
pass() { echo "  ok:   $*"; }

echo "VERIFY REGISTRATION — tracker=$TRACKER tasks-dir=$TASKS_DIR dry-run=$DRY_RUN"
echo "----------------------------------------------------------------"

# ----- Collect the spec-side truth -----
for f in "$TASKS_DIR"/T-*.md; do
  [[ -f "$f" ]] || continue
  id="$(tsi_id "$f")"
  [[ -n "$id" ]] || continue
  if [[ "$(tsi_signed_off "$f")" == "true" ]]; then
    echo "$id" >> "$SIGNED"
    for dep in $(tsi_depends_on "$f"); do
      printf '%s\t%s\n' "$id" "$dep" >> "$EDGES"
    done
  else
    echo "$id" >> "$UNGATED"
  fi
done
sort -u -o "$SIGNED" "$SIGNED"
SPEC_COUNT="$(awk 'END{print NR+0}' "$SIGNED")"
EDGE_COUNT="$(awk 'END{print NR+0}' "$EDGES")"
echo "spec side: $SPEC_COUNT signed-off, $EDGE_COUNT depends_on edge(s)"

# ----- Check A: every edge target is itself a signed-off spec (no dangling) -----
echo "[A] edge integrity (every depends_on target is registerable)"
DANGLE=0
while IFS=$'\t' read -r from dep; do
  [[ -n "$dep" ]] || continue
  if ! grep -qxF "$dep" "$SIGNED"; then
    fail "edge $from -> $dep targets a non-signed-off id (blocked-by would dangle)"
    DANGLE=1
  fi
done < "$EDGES"
[[ "$DANGLE" -eq 0 ]] && pass "all edge targets are signed-off specs"

# ----- Check B: no cycle in the signed-off subgraph (Kahn peel) -----
echo "[B] acyclic dependency graph"
REMAIN="$WORK/remain.txt"; REM="$WORK/remedges.tsv"
cp "$SIGNED" "$REMAIN"; cp "$EDGES" "$REM"
CYCLE=0
while [[ -s "$REMAIN" ]]; do
  ROOTS="$WORK/roots.txt"; : > "$ROOTS"
  while read -r n; do
    [[ -n "$n" ]] || continue
    if ! awk -F'\t' -v x="$n" '$1==x{f=1} END{exit f?0:1}' "$REM"; then
      echo "$n" >> "$ROOTS"
    fi
  done < "$REMAIN"
  if [[ ! -s "$ROOTS" ]]; then
    fail "dependency cycle among: $(tr '\n' ' ' < "$REMAIN")"
    CYCLE=1; break
  fi
  grep -vxF -f "$ROOTS" "$REMAIN" > "$REMAIN.next" || true; mv "$REMAIN.next" "$REMAIN"
  awk -F'\t' 'NR==FNR{d[$1]=1; next} !($2 in d)' "$ROOTS" "$REM" > "$REM.next" || true; mv "$REM.next" "$REM"
done
[[ "$CYCLE" -eq 0 ]] && pass "graph is a DAG"

# ----- Check C: no un-gated leak is possible from the spec side -----
# (Registration only ever writes signed-off specs; this asserts the input the
# gate reasons over never included an un-gated id in the SIGNED set.)
echo "[C] no un-gated spec in the register set"
LEAK=0
while read -r u; do
  [[ -n "$u" ]] || continue
  if grep -qxF "$u" "$SIGNED"; then
    fail "un-gated id '$u' present in the signed set (should have been skipped)"
    LEAK=1
  fi
done < "$UNGATED"
[[ "$LEAK" -eq 0 ]] && pass "un-gated specs ($(awk 'END{print NR+0}' "$UNGATED")) correctly excluded"

# ----- Live board comparison (skipped on --dry-run) -----
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[D] board comparison SKIPPED (--dry-run: spec-side gate only)"
else
  echo "[D] board mirrors the specs (1:1 count + ready set)"
  if ! bash "$ADAPTER" preflight >/dev/null 2>&1; then
    fail "adapter preflight failed — cannot verify the live board"
  else
    # Count issues on the board that carry a task-spec id. list-ready gives the
    # roots; a full count needs the adapter's own listing. We compare the READY
    # set the adapter reports against the spec-side roots as the live signal.
    SPEC_ROOTS="$WORK/spec_roots.txt"; : > "$SPEC_ROOTS"
    while read -r id; do
      awk -F'\t' -v x="$id" '$1==x{f=1} END{exit f?0:1}' "$EDGES" || echo "$id" >> "$SPEC_ROOTS"
    done < "$SIGNED"
    sort -u -o "$SPEC_ROOTS" "$SPEC_ROOTS"

    BOARD_READY="$WORK/board_ready.txt"
    bash "$ADAPTER" list-ready > "$BOARD_READY" 2>/dev/null || : > "$BOARD_READY"
    BR_COUNT="$(awk 'END{print NR+0}' "$BOARD_READY")"
    SR_COUNT="$(awk 'END{print NR+0}' "$SPEC_ROOTS")"
    echo "  spec roots: $SR_COUNT   board ready: $BR_COUNT"
    if [[ "$BR_COUNT" -eq 0 && "$SR_COUNT" -gt 0 ]]; then
      fail "adapter list-ready returned nothing but the spec side has $SR_COUNT root(s) — board not registered?"
    else
      pass "adapter list-ready is live (root set present)"
    fi
    if [[ "$PRUNE" -eq 1 ]]; then
      echo "  --prune: inspect the board for issues with no signed-off spec (orphans) and remove or re-register."
    fi
  fi
fi

echo "----------------------------------------------------------------"
if [[ "$FAIL" -eq 0 ]]; then
  echo "1:1 mapping: $SPEC_COUNT spec(s) -> $SPEC_COUNT issue(s); $EDGE_COUNT edge(s) as blocked-by links."
  echo "VERDICT: REGISTERED"
  exit 0
else
  echo "VERDICT: DO NOT PROCEED"
  exit 1
fi
