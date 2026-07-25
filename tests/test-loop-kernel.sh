#!/usr/bin/env bash
# test-loop-kernel.sh — Pass 8's loop, and specifically its BRAKES.
#
# The loop's value is not that it iterates; a `while true` iterates. The value is
# that it always lands in a named terminal state, that an error or an exhausted
# budget is never reported as success, and that it stops as soon as more
# iterations cannot help. Those are the properties tested here.
#
# Every row uses a STUB engine, so the suite is hermetic: no model is called, no
# token is spent, and the result does not depend on how a real engine happens to
# behave today.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
KERNEL="$SRC/skills/task-loop/scripts/loop-kernel.sh"
FIXTURE="$SRC/skills/task-spec/tests/fixtures/T-20260602-golden.md"
SAFE="$SRC/skills/task-spec/scripts/safe-to-delegate.sh"
CVG="$SRC/bin/cvg"
PASS=0; FAIL=0
ok()  { printf '  ok   — %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  FAIL — %s\n' "$1"; FAIL=$((FAIL + 1)); }

KEY="$(mktemp -t cvg-loopkey.XXXXXX)"; head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$KEY"
# Stub engines live HERE, never in the shipped adapter directory.
STUBS="$(mktemp -d -t cvg-loopstubs.XXXXXX)"

echo "=================================================================="
echo "Pass 8 · the loop kernel"
echo "=================================================================="

# A workspace whose task is RED, in a repo of its own.
new_ws() {
  W="$(mktemp -d -t cvg-loopws.XXXXXX)"
  git -C "$W" init --quiet
  git -C "$W" config user.email loop@test.local
  git -C "$W" config user.name "loop test"
  mkdir -p "$W/cvg/tasks" "$W/engines"
  cp "$FIXTURE" "$W/cvg/tasks/T-20260602-golden.md"
  printf '# readme\n' > "$W/README.md"
  ( cd "$W" && TASKSPEC_SIGNING_KEY="$KEY" bash "$SAFE" --stamp --stamp-by loop cvg/tasks/T-20260602-golden.md >/dev/null 2>&1
    TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" "$CVG" bind --task cvg/tasks/T-20260602-golden.md >/dev/null 2>&1 ) || true
  git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m base >/dev/null 2>&1
  # Make the eval RED: the golden fixture asserts NEVERMATCH is absent, so
  # putting it in the file it inspects is a deterministic red.
  printf 'NEVERMATCH\n' >> "$W/README.md"
  printf '%s\n' "$W"
}

# A stub engine directory the kernel can be pointed at via --agent.
stub_engine() {  # stub_engine <_unused> <name> <body>
  { printf '#!/usr/bin/env bash\nset -uo pipefail\ncase "${1:-}" in --available) exit 0 ;; esac\n'
    printf '%s\n' "$3"; } > "$STUBS/$2.sh"
}
# NO `trap ... EXIT` here. Bash fires an inherited EXIT trap when a `( )`
# SUBSHELL exits, and run_kernel uses one — so a cleanup trap would delete the
# stubs and the signing key partway through the suite, and the later rows would
# fail for reasons that have nothing to do with the loop.

run_kernel() {  # run_kernel <ws> <args...>  -> output; sets RK_RC
  _w="$1"; shift
  RK_OUT="$( (cd "$_w" && TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" \
    CVG_ENGINES_DIR="$STUBS" bash "$KERNEL" --issue T-20260602-golden "$@" 2>&1) )"
  RK_RC=$?
}

# An engine that always succeeds and never fixes anything — the shape of a loop
# that would otherwise burn its whole budget.
stub_engine "" tstnoop 'echo "stub: changed nothing"; echo "ENGINE_TOKENS=100"; exit 0'
# An engine that actually satisfies the eval on its first attempt.
stub_engine "" tstfix 'sed -i.bak "/NEVERMATCH/d" README.md 2>/dev/null || true; rm -f README.md.bak; echo "stub: fixed it"; exit 0'

# ---------------------------------------------------------------- STALLED
W="$(new_ws)"
run_kernel "$W" --agent tstnoop
if grep -q '^TASK_LOOP=STALLED$' <<<"$RK_OUT" && [ "$RK_RC" -eq 1 ]; then
  ok "an ineffective engine lands STALLED (not SETTLED, not a hang)"
else
  bad "no stagnation landing: $(tail -2 <<<"$RK_OUT" | head -1)"
fi
# It must stop AT the circuit breaker, not run the full budget.
_att="$(grep -c '── attempt ' <<<"$RK_OUT" || true)"
if [ "${_att//[^0-9]/}" -le 4 ] 2>/dev/null; then
  ok "it stops at the circuit breaker (${_att} attempts, not the full 15)"
else
  bad "it burned $_att attempts before stopping"
fi
rm -rf "$W"

# ---------------------------------------------------------------- EXHAUSTED
W="$(new_ws)"
run_kernel "$W" --agent tstnoop --max-iterations 2
if grep -q '^TASK_LOOP=EXHAUSTED$' <<<"$RK_OUT" && [ "$RK_RC" -eq 1 ]; then
  ok "the iteration ceiling lands EXHAUSTED — never SETTLED"
else
  bad "the iteration ceiling did not land EXHAUSTED"
fi
if [ -f "$W/cvg/loop/T-20260602-golden/HANDOFF.md" ]; then
  ok "budget exhaustion is a PLANNED landing — a handoff note is on disk"
else
  bad "no handoff note: exhaustion was a crash, not a landing"
fi
# The checkpoint must be durable, or a restart silently redoes the work.
if grep -q '^ITER=2$' "$W/cvg/loop/T-20260602-golden/state.env" 2>/dev/null; then
  ok "the loop's position is checkpointed on disk (resumable)"
else
  bad "the loop position was not persisted"
fi
rm -rf "$W"

# ---------------------------------------------------------------- flags tighten only
W="$(new_ws)"
run_kernel "$W" --agent tstnoop --max-iterations 999
_att="$(grep -c '── attempt ' <<<"$RK_OUT" || true)"
if [ "${_att//[^0-9]/}" -le 4 ] 2>/dev/null; then
  ok "a flag cannot RAISE the spec's ceiling, only tighten it"
else
  bad "--max-iterations 999 overrode the spec budget ($_att attempts)"
fi
rm -rf "$W"

# ---------------------------------------------------------------- CANCELLED
W="$(new_ws)"
mkdir -p "$W/cvg/loop/T-20260602-golden"; touch "$W/cvg/loop/T-20260602-golden/STOP"
run_kernel "$W" --agent tstnoop
if grep -q '^TASK_LOOP=CANCELLED$' <<<"$RK_OUT" && [ "$RK_RC" -eq 3 ]; then
  ok "an external stop signal lands CANCELLED before spending anything"
else
  bad "the kill switch was ignored"
fi
rm -rf "$W"

# ---------------------------------------------------------------- NO_OP
W="$(new_ws)"
git -C "$W" checkout -- README.md 2>/dev/null || true   # already green
run_kernel "$W" --agent tstnoop
if grep -q '^TASK_LOOP=NO_OP$' <<<"$RK_OUT" && [ "$RK_RC" -eq 0 ]; then
  ok "an already-green task is a clean NO_OP, not a manufactured success"
else
  bad "an already-green task did not report NO_OP"
fi
rm -rf "$W"

# ---------------------------------------------------------------- green path
W="$(new_ws)"
run_kernel "$W" --agent tstfix
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT" && [ "$RK_RC" -eq 0 ]; then
  ok "an effective engine reaches a real green and settles"
else
  bad "the green path did not settle: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
rm -rf "$W"

# ---------------------------------------------------------------- gate-only
W="$(new_ws)"
run_kernel "$W" --no-agent
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT"; then
  ok "--no-agent is honest: RED with no attempt is BLOCKED, not STALLED"
else
  bad "--no-agent did not report BLOCKED"
fi
rm -rf "$W"

# ---------------------------------------------------------------- unknown engine
W="$(new_ws)"
run_kernel "$W" --agent doesnotexist
if grep -q '^TASK_LOOP=ERROR$' <<<"$RK_OUT" && [ "$RK_RC" -eq 4 ]; then
  ok "a missing engine is an ERROR, never a silent pass"
else
  bad "a missing engine did not fail closed"
fi
rm -rf "$W"

# ------------------------------------------------ engines must not inherit stdin
# An engine handed an open-but-never-closing stdin can finish its work and then
# BLOCK waiting for an EOF that never arrives. The watchdog eventually kills it,
# the attempt is recorded as a timeout, and the transcript hides the fact that
# the model was done minutes earlier. This cost a 25-minute run to learn once.
# Each adapter honours CVG_<ENGINE>_CMD, so point it at a stub that READS stdin:
# with a closed stdin the stub returns at once, with an inherited one it hangs.
STDIN_PROBE="$STUBS/stdin-probe.sh"
printf '#!/usr/bin/env bash\ncat >/dev/null\necho probe-returned\n' > "$STDIN_PROBE"
chmod +x "$STDIN_PROBE"
printf 'prompt\n' > "$STUBS/probe-prompt.md"
for _eng in claude codex kimi; do
  _var="CVG_$(echo "$_eng" | tr '[:lower:]' '[:upper:]')_CMD"
  _out="$( ( echo "an open pipe that never closes" | \
      env "$_var=$STDIN_PROBE" ENGINE_TIMEOUT=10 \
      bash "$SRC/skills/task-loop/scripts/engines/$_eng.sh" \
        --prompt-file "$STUBS/probe-prompt.md" --workdir "$STUBS" 2>&1 ) )"
  if printf '%s' "$_out" | grep -q 'probe-returned' \
     && ! printf '%s' "$_out" | grep -q 'engine timed out'; then
    ok "$_eng passes the engine a CLOSED stdin (returns, does not hang)"
  else
    bad "$_eng leaves stdin open — the engine can block after finishing"
  fi
done

# ------------------------------------------------- checkpoint before the pause
# An engine call can run for many minutes. If the checkpoint is written only on
# the way OUT, a process killed mid-attempt leaves --resume nothing to resume
# from and the attempt is silently redone. The checkpoint must already exist
# while the loop is paused inside the engine.
W="$(new_ws)"
stub_engine "" tstslow 'sleep 30; echo "slow"; exit 0'
( cd "$W" && TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" CVG_ENGINES_DIR="$STUBS" \
  bash "$KERNEL" --issue T-20260602-golden --agent tstslow >/dev/null 2>&1 ) &
_kpid=$!
sleep 8   # long enough to be inside the engine call, nowhere near its return
if grep -q '^ITER=1$' "$W/cvg/loop/T-20260602-golden/state.env" 2>/dev/null; then
  ok "the checkpoint exists WHILE the loop is paused inside an attempt"
else
  bad "no checkpoint mid-attempt — a kill here would silently redo the work"
fi
kill "$_kpid" 2>/dev/null; wait "$_kpid" 2>/dev/null
pkill -f 'sleep 30' 2>/dev/null || true
rm -rf "$W"

# ---------------------------------------------------------- tracker authority
# Posting to a board is an external write. The envelope grants tracker.write its
# own scope and policy.external_writes defaults to deny, so a loop that narrated
# anyway would be quietly exceeding its contract — the exact defect class the
# envelope exists to prevent.
W="$(new_ws)"
run_kernel "$W" --agent tstnoop
if grep -q 'tracker: not authorized' <<<"$RK_OUT"; then
  ok "a deny-by-default contract suppresses tracker writes, and says so"
else
  bad "the loop did not report its tracker authority"
fi
if ! grep -qE 'tracker: .* → (in progress|done)' <<<"$RK_OUT"; then
  ok "no board mutation happens without tracker.write authority"
else
  bad "the loop wrote to the board it was not authorized to touch"
fi
# This row must run against a REAL stalled loop, so prove the run it inspects
# actually happened. Both assertions above are satisfiable by a loop that never
# attempted anything — one greps for a suppression notice the ERROR landing also
# prints, the other is a negative. When the stub cleanup sat above this block,
# the engine adapter was already deleted: the loop landed ERROR with zero
# attempts and both rows passed for the wrong reason.
if grep -q '^TASK_LOOP=STALLED$' <<<"$RK_OUT" && [ "$(grep -c '── attempt ' <<<"$RK_OUT")" -gt 0 ]; then
  ok "…and it proved that on a loop that really ran (STALLED, attempts > 0)"
else
  ok_state="$(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
  bad "the tracker rows inspected a loop that never ran (${ok_state:-no terminal state})"
fi
rm -rf "$W"

# Cleanup belongs AFTER the last row that needs the stubs and the signing key.
# (Still no `trap ... EXIT`: bash fires an inherited EXIT trap when a `( )`
# subshell exits, and run_kernel uses one.)
rm -rf "$STUBS"; rm -f "$KEY"

echo "------------------------------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  printf 'PASS — %d loop-kernel checks green.\n' "$PASS"; exit 0
fi
printf 'FAIL — %d of %d loop-kernel checks red.\n' "$FAIL" "$((PASS + FAIL))"; exit 1
