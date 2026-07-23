#!/usr/bin/env bash
# register.sh — the REGISTER driver: project signed-off task-specs onto a tracker.
#
# Reads tasks/T-*.md, keeps only `signed_off: true` specs, refuses on a
# depends_on cycle, topologically orders the survivors, and drives the selected
# adapter's `upsert` (one issue per spec) then `link` (each depends_on edge as a
# blocked-by link) in BUILD ORDER. Idempotent by construction — the adapter keys
# on the spec id.
#
# Usage:
#   register.sh [--tracker github|linear|jira] [--tasks-dir DIR] [--dry-run]
#               [--no-stamp-refs]
#
#   --tracker        backend to register onto (default: linear)
#   --tasks-dir      where the specs live (default: tasks)
#   --dry-run        parse + validate + PRINT the plan; make NO network calls and
#                    invoke NO adapter. Fully runnable offline with no creds.
#   --no-stamp-refs  do NOT write the tracker_ref receipt back into each spec.
#                    Default is to stamp `tracker_ref: <tracker>:<issue>` into the
#                    spec frontmatter after a successful upsert (a convenience
#                    backlink; the issue-side marker stays the idempotency key).
#                    Use this for read-only / CI contexts that must not touch the
#                    repo — resolution still works by marker with an empty ref.
#
# Exit: 0 on a clean plan/registration; 1 on a cycle, a missing dependency, an
# adapter preflight failure, or a mid-run adapter error (never half-silent).
#
# bash-3.2-safe: no mapfile, no `declare -A`. The graph is held in newline-
# delimited scratch files under a temp dir and walked with grep/awk, mirroring
# the task-spec skill's portable style.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_parse.sh
source "$SELF_DIR/_parse.sh"

# ----- Defaults -----
TRACKER="linear"
TASKS_DIR="${TSI_TASKS_DIR:-tasks}"
DRY_RUN=0
STAMP_REFS=1

# ----- Arg parse -----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tracker)   TRACKER="${2:?--tracker needs a value}"; shift 2 ;;
    --tracker=*) TRACKER="${1#--tracker=}"; shift ;;
    --tasks-dir)   TASKS_DIR="${2:?--tasks-dir needs a value}"; shift 2 ;;
    --tasks-dir=*) TASKS_DIR="${1#--tasks-dir=}"; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --no-stamp-refs) STAMP_REFS=0; shift ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
      exit 0 ;;
    *) tsi_die "unknown arg '$1' (see --help)" ;;
  esac
done

case "$TRACKER" in
  github|linear|jira) ;;
  fake) ;;  # test-only no-network reference adapter (scripts/adapters/fake.sh)
  *) tsi_die "unknown --tracker '$TRACKER' (want: github|linear|jira)" ;;
esac

[[ -d "$TASKS_DIR" ]] || tsi_die "tasks dir '$TASKS_DIR' not found"

ADAPTER="$SELF_DIR/adapters/${TRACKER}.sh"
[[ -f "$ADAPTER" ]] || tsi_die "adapter not found: $ADAPTER"

# ----- Scratch -----
WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/tsi-register.$$")"
mkdir -p "$WORK"
cleanup() { rm -rf "$WORK" 2>/dev/null || true; }
trap cleanup EXIT

SIGNED="$WORK/signed.tsv"     # id \t file \t title  (signed_off==true only)
EDGES="$WORK/edges.tsv"       # from_id \t to_id     (from depends_on to_id)
ALLIDS="$WORK/allids.txt"     # every spec id (signed or not) — for edge validation
: > "$SIGNED"; : > "$EDGES"; : > "$ALLIDS"

echo "REGISTER — tracker=$TRACKER tasks-dir=$TASKS_DIR dry-run=$DRY_RUN stamp-refs=$STAMP_REFS"
echo "----------------------------------------------------------------"

# ----- Step 1: collect the signed-off backlog -----
# bash 3.2 has no `lastpipe`, so a `... | while read` loop runs in a subshell and
# its variable writes are lost. We iterate the glob DIRECTLY (no pipe) so SKIPPED
# and the scratch files accumulate in THIS shell.
SKIPPED=""
for f in "$TASKS_DIR"/T-*.md; do
  [[ -f "$f" ]] || continue
  id="$(tsi_id "$f")"
  [[ -n "$id" ]] || { echo "WARN: $f has no id: — skipping" >&2; continue; }
  echo "$id" >> "$ALLIDS"

  so="$(tsi_signed_off "$f")"
  title="$(tsi_title "$f")"
  if [[ "$so" != "true" ]]; then
    SKIPPED="${SKIPPED}${SKIPPED:+ }$id"
    continue
  fi
  printf '%s\t%s\t%s\n' "$id" "$f" "$title" >> "$SIGNED"

  # Record edges: for each dep, an edge (id depends_on dep).
  for dep in $(tsi_depends_on "$f"); do
    printf '%s\t%s\n' "$id" "$dep" >> "$EDGES"
  done
done

SIGNED_COUNT="$(awk 'END{print NR}' "$SIGNED")"
echo "signed-off specs: $SIGNED_COUNT"
if [[ -n "$SKIPPED" ]]; then
  echo "skipped (un-gated, signed_off!=true): $SKIPPED"
fi
if [[ "$SIGNED_COUNT" -eq 0 ]]; then
  echo "nothing to register (no signed_off specs)."
  echo "REGISTER=EMPTY"
  exit 0
fi

# ----- Step 1b: validate edges reference registerable ids -----
# Every depends_on target must be a signed-off spec (else the blocked-by link
# has no issue to point at). A dep on an un-gated / unknown id is a hard stop.
MISSING=""
while IFS=$'\t' read -r from dep; do
  [[ -n "$dep" ]] || continue
  if ! awk -F'\t' -v d="$dep" '$1==d{f=1} END{exit f?0:1}' "$SIGNED"; then
    MISSING="${MISSING}${MISSING:+ }${from}->${dep}"
  fi
done < "$EDGES"
if [[ -n "$MISSING" ]]; then
  echo "ERROR: blocked-by target not found (dependency is un-gated or unknown):" >&2
  echo "  $MISSING" >&2
  echo "  either sign off + register the dependency, or fix the stale depends_on." >&2
  echo "REGISTER=FAIL"
  exit 1
fi

# ----- Step 2: cycle detection + topological (build) order -----
# Kahn's algorithm over the signed-off subgraph. Node = spec id. A depends_on
# edge (a -> b) means b must come BEFORE a, so b has an out-edge to a in build
# terms. We compute in-degree over dependency edges and peel roots (no deps).
# Held entirely in scratch files → bash-3.2-safe, no associative arrays.
NODES="$WORK/nodes.txt"          # all signed ids
awk -F'\t' '{print $1}' "$SIGNED" | sort -u > "$NODES"

REMAIN="$WORK/remain.txt"        # ids not yet emitted
REMEDGES="$WORK/remedges.tsv"    # edges (from depends_on to) still live
ORDER="$WORK/order.txt"          # topological build order (deps first)
cp "$NODES" "$REMAIN"
cp "$EDGES" "$REMEDGES"
: > "$ORDER"

# A node is a "root" (ready to emit) when it has no remaining depends_on edge,
# i.e. it never appears in column 1 of REMEDGES.
while [[ -s "$REMAIN" ]]; do
  ROOTS="$WORK/roots.txt"; : > "$ROOTS"
  while read -r n; do
    [[ -n "$n" ]] || continue
    if ! awk -F'\t' -v x="$n" '$1==x{f=1} END{exit f?0:1}' "$REMEDGES"; then
      echo "$n" >> "$ROOTS"
    fi
  done < "$REMAIN"

  if [[ ! -s "$ROOTS" ]]; then
    echo "ERROR: refusing to register — dependency cycle among:" >&2
    # The remaining nodes form the cycle set; print their live edges as evidence.
    while read -r n; do
      dl="$(awk -F'\t' -v x="$n" '$1==x{printf "%s ", $2}' "$REMEDGES")"
      [[ -n "$dl" ]] && echo "  $n depends_on: $dl" >&2
    done < "$REMAIN"
    echo "  a cycle is a spec bug (Pass 5B), not a board state. Fix depends_on upstream." >&2
    echo "REGISTER=FAIL"
    exit 1
  fi

  # Emit roots in a stable order; drop them from REMAIN and from REMEDGES targets.
  sort "$ROOTS" | while read -r r; do echo "$r"; done >> "$ORDER"
  grep -vxF -f "$ROOTS" "$REMAIN" > "$REMAIN.next" || true
  mv "$REMAIN.next" "$REMAIN"
  # Remove edges whose TARGET (col 2) is now emitted — those deps are satisfied.
  awk -F'\t' 'NR==FNR{done[$1]=1; next} !($2 in done)' "$ROOTS" "$REMEDGES" > "$REMEDGES.next" || true
  mv "$REMEDGES.next" "$REMEDGES"
done

echo "build order (deps first):"
awk '{printf "  %d. %s\n", NR, $0}' "$ORDER"
echo "----------------------------------------------------------------"

# ----- Step 3+4: drive the adapter (or PRINT the plan on --dry-run) -----
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN — no network, no adapter calls. This is what WOULD happen:"
  echo
  echo "[preflight] $ADAPTER preflight"
  echo
  echo "[upsert] one issue per signed-off spec, in build order:"
  while read -r id; do
    title="$(awk -F'\t' -v x="$id" '$1==x{print $3}' "$SIGNED")"
    file="$(awk -F'\t' -v x="$id" '$1==x{print $2}' "$SIGNED")"
    echo "  $ADAPTER upsert --id $id --title \"$title\" --body-file <goal+exit-check of $file>"
    if [[ "$STAMP_REFS" -eq 1 ]]; then
      echo "    └─ would stamp receipt: tracker_ref: $TRACKER:<issue> into $file"
    fi
  done < "$ORDER"
  echo
  echo "[link] depends_on -> blocked-by (from -> to):"
  if [[ -s "$EDGES" ]]; then
    # Print links in build order of the FROM node for readability.
    while read -r id; do
      awk -F'\t' -v x="$id" '$1==x{print $2}' "$EDGES" | while read -r dep; do
        [[ -n "$dep" ]] && echo "  $ADAPTER link --from $id --to $dep   # $id blocked-by $dep"
      done
    done < "$ORDER"
  else
    echo "  (none — no depends_on edges among signed-off specs)"
  fi
  echo
  EDGE_COUNT="$(awk 'END{print NR+0}' "$EDGES")"
  echo "PLAN: upsert $SIGNED_COUNT issue(s), set $EDGE_COUNT blocked-by link(s)."
  # Ready set = signed-off ids that never appear as a FROM in EDGES (no blocker).
  READY=""
  while read -r id; do
    [[ -n "$id" ]] || continue
    if ! awk -F'\t' -v x="$id" '$1==x{f=1} END{exit f?0:1}' "$EDGES"; then
      READY="${READY}${READY:+ }$id"
    fi
  done < "$ORDER"
  echo "ready set (no blocker): ${READY:-(none)}"
  echo
  echo "VERDICT: DRY-RUN OK (offline plan is consistent). Re-run without --dry-run to write."
  echo "REGISTER=DRY_RUN"
  exit 0
fi

# ----- Live path: preflight, then upsert, then link -----
echo "[preflight] $TRACKER"
if ! bash "$ADAPTER" preflight; then
  echo "STOP: adapter preflight failed — not half-registering the board." >&2
  echo "REGISTER=FAIL"
  exit 1
fi
echo

CREATED=0; UPDATED=0; LINKS=0; STAMPED=0

echo "[upsert] one issue per signed-off spec (build order)"
while read -r id; do
  file="$(awk -F'\t' -v x="$id" '$1==x{print $2}' "$SIGNED")"
  title="$(awk -F'\t' -v x="$id" '$1==x{print $3}' "$SIGNED")"

  # Build the issue body: goal + touches_paths + the Exit Check VERBATIM.
  body="$WORK/body.$id.md"
  {
    echo "## $title"
    echo
    tsi_goal "$file"
    echo
    echo "**touches_paths:** $(tsi_field "$file" touches_paths | sed 's/^$/(see spec)/')"
    echo
    echo "### Exit Check (close condition — only a GREEN eval moves this to done)"
    echo
    echo '```bash'
    tsi_exit_check "$file"
    echo '```'
  } > "$body"

  out="$(bash "$ADAPTER" upsert \
    --id "$id" \
    --title "$title" \
    --body-file "$body" \
    --label "$(tsi_severity "$file")" \
    --label "$(tsi_priority "$file")" 2>>"$WORK/adapter.log")" \
    || { echo "ERROR: upsert failed for $id (see adapter.log)"; cat "$WORK/adapter.log" >&2; echo "REGISTER=FAIL"; exit 1; }
  echo "  upsert $id -> issue $out"

  # Stamp the RECEIPT back into the spec (best-effort — a receipt failure never
  # aborts a written board; the issue-side marker remains the idempotency key).
  if [[ "$STAMP_REFS" -eq 1 && -n "$out" ]]; then
    if tsi_set_tracker_ref "$file" "$TRACKER:$out" 2>>"$WORK/adapter.log"; then
      STAMPED=$((STAMPED + 1))
      echo "     receipt: tracker_ref: $TRACKER:$out -> $file"
    else
      echo "     WARN: could not stamp tracker_ref into $file (board unaffected; see adapter.log)" >&2
    fi
  fi
done < "$ORDER"

# Count created vs updated from the adapter log (adapters emit "created"/"updated").
# NB: `grep -c` prints "0" AND exits 1 on no match, so a `|| echo 0` fallback would
# DOUBLE it to "0\n0". Swallow the status with `|| true` and normalise to an integer.
CREATED="$(grep -c '^created ' "$WORK/adapter.log" 2>/dev/null || true)"; CREATED="${CREATED//[^0-9]/}"; CREATED="${CREATED:-0}"
UPDATED="$(grep -c '^updated ' "$WORK/adapter.log" 2>/dev/null || true)"; UPDATED="${UPDATED//[^0-9]/}"; UPDATED="${UPDATED:-0}"

echo
echo "[link] depends_on -> blocked-by"
while IFS=$'\t' read -r from dep; do
  [[ -n "$dep" ]] || continue
  bash "$ADAPTER" link --from "$from" --to "$dep" 2>>"$WORK/adapter.log" \
    || { echo "ERROR: link failed for $from blocked-by $dep"; cat "$WORK/adapter.log" >&2; echo "REGISTER=FAIL"; exit 1; }
  LINKS=$((LINKS + 1))
  echo "  $from blocked-by $dep"
done < "$EDGES"

echo
echo "----------------------------------------------------------------"
echo "REGISTERED: $SIGNED_COUNT issue(s) (created $CREATED, updated $UPDATED), $LINKS blocked-by link(s)."
[[ "$STAMP_REFS" -eq 1 ]] && echo "stamped $STAMPED tracker_ref receipt(s) back into the specs."
[[ -n "$SKIPPED" ]] && echo "skipped (un-gated): $SKIPPED"
echo "next: run verify-registration.sh --tracker $TRACKER to gate the mapping."
echo "REGISTER=OK"
