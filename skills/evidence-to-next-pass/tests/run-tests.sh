#!/usr/bin/env bash
# run-tests.sh — evidence-to-next-pass: the sequence engine, proven hermetically.
#
# Builds a throwaway workspace with the real `cvg init`, then fabricates each
# pass's evidence in order and asserts the conductor derives position, refuses
# early starts (pre), and verifies artifacts (post) — all from the floor, no
# stored state. No engine, no network, no credentials.
#
# Token: NEXT_PASS_TESTS=PASS | NEXT_PASS_TESTS=FAIL
# bash 3.2 safe.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../../.." && pwd)"
ENGINE="$REPO/skills/evidence-to-next-pass/scripts/next-pass.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL — %s\n' "$1"; }

echo "=================================================================="
echo "evidence-to-next-pass — the descent, in order, every time"
echo "=================================================================="

T="$(mktemp -d -t conductor-tests.XXXXXX)"
trap 'rm -rf "$T"' EXIT
git -C "$T" init --quiet
( cd "$T" && CVG_PROJECT_ROOT="$T" bash "$REPO/bin/cvg" init >/dev/null )

run() {  # run <expected-exit> <args...> — captures OUT, returns 0 if exit matches
  local want="$1"; shift
  local rc=0
  OUT="$(cd "$T" && bash "$ENGINE" "$@" 2>&1)" || rc=$?
  [ "$rc" = "$want" ]
}

# --- empty workspace ---------------------------------------------------------
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=0$' \
  && ok "fresh workspace: next is pass 0" || bad "fresh workspace should point at pass 0 ($OUT)"

run 0 pre 0 && printf '%s' "$OUT" | grep -q '^PASS_PRE=OK$' \
  && ok "pass 0 has no doors before it" || bad "pre 0 should be OK on a fresh floor"

run 1 pre 5 && printf '%s' "$OUT" | grep -q '^PASS_PRE=MISSING$' \
  && printf '%s' "$OUT" | grep -q 'pass 0' \
  && ok "pre 5 refuses and names the missing passes" || bad "pre 5 must refuse on an empty floor"

run 1 post 0 && printf '%s' "$OUT" | grep -q '^PASS_POST=INCOMPLETE$' \
  && ok "post 0 reports no artifact yet" || bad "post 0 must be INCOMPLETE before the BRD exists"

# --- the descent, one artifact at a time ------------------------------------
touch "$T/cvg/docs/brd/shop.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=1$' \
  && ok "BRD in the typed folder: next is pass 1" || bad "after BRD, next should be 1 ($OUT)"
run 0 post 0 && printf '%s' "$OUT" | grep -q '^PASS_POST=OK$' \
  && printf '%s' "$OUT" | grep -q 'cvg capture' \
  && ok "post 0 sees the artifact and names the authoritative gate" || bad "post 0 should be OK now"

touch "$T/cvg/docs/tech-spec/shop.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=2$' \
  && ok "tech-spec: next is pass 2" || bad "after tech-spec, next should be 2"

touch "$T/cvg/docs/adrs/adr-001-storage.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=3$' \
  && ok "ADRs: next is pass 3" || bad "after ADRs, next should be 3"

mkdir -p "$T/cvg/sketch/swimlane-core" && touch "$T/cvg/sketch/swimlane-core/leg-1.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=4$' \
  && ok "swimlanes: next is pass 4 — the barrier" || bad "after swimlanes, next should be 4"

mkdir -p "$T/cvg/sketch/.consensus" && echo '{}' > "$T/cvg/sketch/.consensus/objection-log.json"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=5$' \
  && ok "objection log: next is pass 5 — the cornerstone" || bad "after the barrier, next should be 5"
run 0 pre 5 && printf '%s' "$OUT" | grep -q '^PASS_PRE=OK$' \
  && ok "pre 5 opens once the barrier evidence exists" || bad "pre 5 should be OK now"

printf -- '---\nstatus: ready\n---\n' > "$T/cvg/tasks/T-20260730-first.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=5$' \
  && ok "an UNSIGNED spec does not close pass 5" || bad "unsigned spec must not advance the descent"

printf -- '---\nstatus: ready\nsigned_off: true\n---\n' > "$T/cvg/tasks/T-20260730-first.md"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=7$' \
  && ok "a SIGNED spec closes 5: next is pass 7 (6 is opt-in)" || bad "after a signed spec, next should be 7"

touch "$T/cvg/execution/T-20260730-first.profile.yaml"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=8$' \
  && ok "execution profile: next is pass 8 — the loop" || bad "after bind evidence, next should be 8"

echo '{}' > "$T/cvg/receipts/T-20260730-first.json"
run 0 next && printf '%s' "$OUT" | grep -q '^NEXT_PASS=DONE$' \
  && ok "receipt on the floor: the lane is DONE" || bad "after a receipt, next should be DONE"

# --- lanes, opt-in register, contracts ---------------------------------------
T2="$(mktemp -d -t conductor-tests2.XXXXXX)"
git -C "$T2" init --quiet
( cd "$T2" && CVG_PROJECT_ROOT="$T2" bash "$REPO/bin/cvg" init >/dev/null )
OUT="$(cd "$T2" && bash "$ENGINE" next --lane FAST 2>&1)"
printf '%s' "$OUT" | grep -q '^NEXT_PASS=5$' \
  && ok "FAST lane skips the design half: next is 5 on a fresh floor" \
  || bad "FAST lane should start at pass 5 ($OUT)"
rm -rf "$T2"

BEFORE="$(find "$T/cvg" -type f | wc -l | tr -d ' ')"
run 0 next || true
AFTER="$(find "$T/cvg" -type f | wc -l | tr -d ' ')"
[ "$BEFORE" = "$AFTER" ] && ok "the conductor is read-only — it wrote nothing" \
  || bad "the conductor mutated the workspace ($BEFORE -> $AFTER files)"

# The legacy flat layout must still read as complete — no workspace gets
# stranded by the folder change.
T4="$(mktemp -d -t conductor-tests4.XXXXXX)"
git -C "$T4" init --quiet
( cd "$T4" && CVG_PROJECT_ROOT="$T4" bash "$REPO/bin/cvg" init >/dev/null )
touch "$T4/cvg/docs/brd-legacy.md" "$T4/cvg/docs/tech-spec-legacy.md"
OUT="$(cd "$T4" && bash "$ENGINE" next 2>&1)"
printf '%s' "$OUT" | grep -q '^NEXT_PASS=2$' \
  && ok "legacy flat brd-*/tech-spec-*.md still count as done" \
  || bad "the flat layout was stranded by the folder change ($OUT)"
rm -rf "$T4"

run 2 bogus && printf '%s' "$OUT" | grep -q '^NEXT_PASS=USAGE_ERROR$' \
  && ok "unknown verb is a usage error (exit 2)" || bad "unknown verb must exit 2"
run 2 next --lane WARP && printf '%s' "$OUT" | grep -q '^NEXT_PASS=USAGE_ERROR$' \
  && ok "unknown lane is a usage error (exit 2)" || bad "unknown lane must exit 2"

echo "------------------------------------------------------------------"
echo "RESULTS: $PASS passed, $FAIL failed"
if [ "$FAIL" -eq 0 ]; then
  echo "NEXT_PASS_TESTS=PASS"
else
  echo "NEXT_PASS_TESTS=FAIL"; exit 1
fi
