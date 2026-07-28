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

# Remove a workspace AND any isolated worktree it still owns.
#
# Rows that land EXHAUSTED, STALLED or BLOCKED deliberately KEEP their worktree
# — the handoff note is useless without the work it describes. Deleting only the
# parent repo therefore orphans that checkout in $TMPDIR: two per suite run,
# forever, and the suite that asserts "a failed run leaves no orphaned worktree
# behind" was itself the thing leaking them. `cvg-wt-` is the kernel's own
# prefix, so it can never match the `cvg-loopws-` workspace being removed.
drop_ws() {
  _dw="$1"
  git -C "$_dw" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{print $2}' | grep '/cvg-wt-' \
    | while IFS= read -r _wt; do
        git -C "$_dw" worktree remove --force "$_wt" >/dev/null 2>&1 || rm -rf "$_wt"
      done
  rm -rf "$_dw"
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
  # Rows that are not ABOUT isolation run in-place, so they assert loop
  # behaviour rather than git-worktree behaviour. The default itself is pinned
  # by its own row below.
  _w="$1"; shift
  case " $* " in *" --isolation "*) : ;; *) set -- "$@" --isolation inplace ;; esac
  RK_OUT="$( (cd "$_w" && TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" \
    CVG_ENGINES_DIR="$STUBS" CVG_VERIFIER="${RK_VERIFIER:-$STUBS/verify-uphold.sh}" \
    bash "$KERNEL" --issue T-20260602-golden "$@" 2>&1) )"
  RK_RC=$?
}

# Stub JUDGES. Tier-2 dispatches a real engine and takes minutes; a hermetic
# suite must be able to pin the kernel's REACTION to each verdict without that.
stub_verifier() {  # stub_verifier <name> <body>
  { printf '#!/usr/bin/env bash\nset -uo pipefail\n'; printf '%s\n' "$2"; } > "$STUBS/$1.sh"
}
stub_verifier verify-uphold 'echo "CHECK_VERIFY=UPHELD"; exit 0'
stub_verifier verify-refute 'echo "  - hardcoded lookup table satisfies the assertion"; echo "CHECK_VERIFY=REFUTED"; exit 1'
stub_verifier verify-unavail 'echo "CHECK_VERIFY=UNAVAILABLE"; exit 0'
# Neither a verdict nor a token — the shape of a judge that died mid-sentence.
stub_verifier verify-broken 'echo "judge exploded"; exit 1'

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
drop_ws "$W"

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
# A handoff that lost its numbers is a handoff nobody can act on. `printf '- x'`
# makes bash read the FORMAT as an option, which silently emptied these lines.
if grep -q '^- iterations:' "$W/cvg/loop/T-20260602-golden/HANDOFF.md" 2>/dev/null \
  && grep -q '^- elapsed:' "$W/cvg/loop/T-20260602-golden/HANDOFF.md" 2>/dev/null; then
  ok "the handoff actually carries the numbers it exists to report"
else
  bad "the handoff note is missing its iteration/elapsed lines"
fi
# The checkpoint must be durable, or a restart silently redoes the work.
if grep -q '^ITER=2$' "$W/cvg/loop/T-20260602-golden/state.env" 2>/dev/null; then
  ok "the loop's position is checkpointed on disk (resumable)"
else
  bad "the loop position was not persisted"
fi
drop_ws "$W"

# ---------------------------------------------------------------- flags tighten only
W="$(new_ws)"
run_kernel "$W" --agent tstnoop --max-iterations 999
_att="$(grep -c '── attempt ' <<<"$RK_OUT" || true)"
if [ "${_att//[^0-9]/}" -le 4 ] 2>/dev/null; then
  ok "a flag cannot RAISE the spec's ceiling, only tighten it"
else
  bad "--max-iterations 999 overrode the spec budget ($_att attempts)"
fi
drop_ws "$W"

# ---------------------------------------------------------------- CANCELLED
W="$(new_ws)"
mkdir -p "$W/cvg/loop/T-20260602-golden"; touch "$W/cvg/loop/T-20260602-golden/STOP"
run_kernel "$W" --agent tstnoop
if grep -q '^TASK_LOOP=CANCELLED$' <<<"$RK_OUT" && [ "$RK_RC" -eq 3 ]; then
  ok "an external stop signal lands CANCELLED before spending anything"
else
  bad "the kill switch was ignored"
fi
drop_ws "$W"

# ---------------------------------------------------------------- NO_OP
W="$(new_ws)"
git -C "$W" checkout -- README.md 2>/dev/null || true   # already green
run_kernel "$W" --agent tstnoop
if grep -q '^TASK_LOOP=NO_OP$' <<<"$RK_OUT" && [ "$RK_RC" -eq 0 ]; then
  ok "an already-green task is a clean NO_OP, not a manufactured success"
else
  bad "an already-green task did not report NO_OP"
fi
drop_ws "$W"

# ---------------------------------------------------------------- green path
W="$(new_ws)"
run_kernel "$W" --agent tstfix
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT" && [ "$RK_RC" -eq 0 ]; then
  ok "an effective engine reaches a real green and settles"
else
  bad "the green path did not settle: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
drop_ws "$W"

# ------------------------------------------------------ tier 2 · the gate
# A green eval is necessary, not sufficient. Tier 1 cannot tell a real
# implementation from a lookup table that satisfies the same assertion, so a
# refutation from an engine that did not do the work must STOP settlement.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix --verify
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT" && [ "$RK_RC" -eq 1 ]; then
  ok "tier-2 REFUTED blocks settlement even though the eval went green"
else
  bad "a refuted diff still settled: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
# The refusal has to be legible, or the operator cannot act on it.
if grep -q 'lookup table' <<<"$RK_OUT"; then
  ok "the judge's findings reach the operator, not just the verdict"
else
  bad "tier-2 findings were swallowed"
fi
drop_ws "$W"

# A judge that dies mid-sentence returns no verdict. That is not a pass.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-broken.sh" run_kernel "$W" --agent tstfix --verify
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT"; then
  ok "tier-2 FAILS CLOSED — an unobtainable verdict never settles"
else
  bad "a broken judge was treated as approval"
fi
drop_ws "$W"

# UNAVAILABLE is the one verdict that proceeds: verify-work.py itself permits it
# only for low blast radius, and that judgement belongs to the verifier.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-unavail.sh" run_kernel "$W" --agent tstfix --verify
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT"; then
  ok "UNAVAILABLE proceeds — absence of a judge is not a refutation"
else
  bad "UNAVAILABLE was treated as a block"
fi
drop_ws "$W"

# Tier 2 is OPT-IN. A judge that would refute must not even be consulted unless
# asked for: it costs a full extra engine dispatch, and making it the default
# meant a judge timing out could block a task whose evals had all passed.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT" \
  && grep -q 'tier 2 ── not requested' <<<"$RK_OUT"; then
  ok "tier 2 is OPT-IN — a refuting judge is not consulted without --verify"
else
  bad "tier 2 ran (or was silent) without being asked: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
drop_ws "$W"

# Naming a judge is asking for the check. A --judge that needed --verify beside
# it would be a flag that silently does nothing.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix --judge codex
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT"; then
  ok "--judge implies --verify (a flag that did nothing would be worse)"
else
  bad "--judge did not enable tier 2"
fi
drop_ws "$W"

# The explicit opt-out still wins, so a profile that turns tier 2 on can be
# overridden from the command line.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix --verify --no-verify
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT"; then
  ok "--no-verify overrides an earlier --verify (last flag wins)"
else
  bad "--no-verify could not turn tier 2 back off"
fi
drop_ws "$W"

# ------------------------------------------- evidence lands in the REAL repo
# The settler writes the receipt relative to ITS workspace, which under isolation
# is a temp worktree. So a run that genuinely settled wrote `result: pass` into
# $TMPDIR while the repository kept a STALE receipt — the durable proof of
# success living in a directory `git worktree prune` deletes, next to a repo
# asserting the opposite. STATE.md went to the real workspace and the receipt did
# not: one run, two evidence artifacts, two different roots.
W="$(new_ws)"
# The worktree checks out COMMITTED state, so the red marker has to be committed
# or the isolated run starts green and lands NO_OP.
git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m red >/dev/null 2>&1
run_kernel "$W" --agent tstfix --isolation worktree
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT"; then
  _rcp="$W/cvg/receipts/T-20260602-golden.json"
  if [ -f "$_rcp" ] && grep -q '"result": *"pass"' "$_rcp"; then
    ok "a settled run's receipt lands in the real workspace, not the worktree"
  else
    bad "the receipt never left the worktree (repo has $( [ -f "$_rcp" ] && grep -o '"result": *"[a-z]*"' "$_rcp" || echo 'no receipt' ))"
  fi
else
  bad "the isolated run did not settle: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
drop_ws "$W"

# ------------------------------------------------------ the cost dial (lane)
# One setting for every task is what made a four-file build cost $7.91: bare
# `claude -p`, top model, flat 900s. `cvg lane` classified the work and the
# verdict reached nothing. These rows pin that it now reaches the engine.
W="$(new_ws)"
run_kernel "$W" --agent tstfix --lane FAST --estimate
if grep -q 'model haiku' <<<"$RK_OUT" && grep -q 'lane FAST' <<<"$RK_OUT"; then
  ok "the lane picks the model tier — FAST does not draw the top engine"
else
  bad "the lane did not reach the model: $(grep -i 'lane\|model' <<<"$RK_OUT" | head -2)"
fi
# attempt_seconds = lane base x effort multiplier, so a long-horizon leaf is not
# guillotined on a cheap lane and a typo fix is not handed 15 minutes.
if grep -qE 'per attempt *: up to (150|225|300|450)s' <<<"$RK_OUT"; then
  ok "the per-attempt cap scales with effort, not a flat 900s"
else
  bad "the attempt cap ignored the dial: $(grep 'per attempt' <<<"$RK_OUT")"
fi
drop_ws "$W"

# A lane may LOWER a ceiling and never RAISE one — the same invariant --max-*
# already obeys, because a routing hint must never widen an authorization.
#
# FULL's table value (15) equals the golden fixture's own budget_iterations, so
# comparing those two proves nothing either way. Pin it against a TIGHTENED
# ceiling instead: --max-iterations 2 with the most generous lane must stay 2.
W="$(new_ws)"
run_kernel "$W" --agent tstfix --lane FULL --max-iterations 2 --estimate
_fullit="$(grep -oE 'attempts *: up to [0-9]+' <<<"$RK_OUT" | grep -oE '[0-9]+$')"
if [ "${_fullit:-999}" -eq 2 ] 2>/dev/null; then
  ok "the most generous lane cannot widen a tightened ceiling (still 2)"
else
  bad "the lane widened a tightened budget to $_fullit"
fi
drop_ws "$W"

# FULL earns tier 2 by default, because high blast radius is where a green eval
# is least sufficient — but the operator still outranks the table.
W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix --lane FULL
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT"; then
  ok "FULL turns tier 2 on without being asked twice"
else
  bad "FULL did not enable tier 2"
fi
drop_ws "$W"

W="$(new_ws)"
RK_VERIFIER="$STUBS/verify-refute.sh" run_kernel "$W" --agent tstfix --lane FULL --no-verify
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT"; then
  ok "an explicit --no-verify outranks the lane's default"
else
  bad "the operator could not decline the lane's verifier"
fi
drop_ws "$W"

# ------------------------------------------------- settlement base reference
# The guard must be asked about the work THIS RUN produced. Cutting the loop
# branch from a non-default branch used to make `main...HEAD` sweep in every
# commit on it — 135 paths judged against a scope of 4 — and settlement was
# refused on work that was entirely in scope.
W="$(new_ws)"
git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m red >/dev/null 2>&1
git -C "$W" checkout --quiet -b feature/somewhere-else 2>/dev/null
printf 'unrelated\n' > "$W/UNRELATED.md"
git -C "$W" add -A >/dev/null 2>&1
git -C "$W" commit --quiet -m "work that predates the loop" >/dev/null 2>&1
run_kernel "$W" --agent tstfix --isolation worktree
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT" && [ "$RK_RC" -eq 0 ]; then
  ok "a loop branch cut from a FEATURE branch still settles (base is the fork point)"
else
  bad "settlement refused on in-scope work: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
# Prove the mechanism, not just the outcome: pre-existing commits on the feature
# branch must never appear in the guard's diff.
if ! grep -q 'UNRELATED.md' <<<"$RK_OUT"; then
  ok "commits that predate the run are not attributed to it"
else
  bad "the guard was shown work the loop did not do"
fi
drop_ws "$W"

# ------------------------------------------------- resume · the wall clock
# The budget bounds what the loop DOES. Persisting a start timestamp made it
# bound wall time instead: pick a run up the next morning and `now - STARTED_AT`
# already exceeds any budget, so it lands EXHAUSTED without making one attempt —
# a spent budget reported on a run that spent nothing.
W="$(new_ws)"
run_kernel "$W" --agent tstnoop --max-iterations 1
_st="$W/cvg/loop/T-20260602-golden/state.env"
# Backdate the run to 1970 — the state a long pause leaves behind.
sed -i.bak 's/^STARTED_AT=.*/STARTED_AT=1/; s/^ELAPSED_PRIOR=.*/ELAPSED_PRIOR=3/' "$_st" && rm -f "$_st.bak"
run_kernel "$W" --agent tstfix --resume --max-iterations 5
if grep -qE '^TASK_LOOP=(SETTLED|LOCAL_SETTLED)$' <<<"$RK_OUT"; then
  ok "--resume continues the BUDGET, not the clock (a long pause is not a spend)"
else
  bad "resume after a pause was killed by wall-clock: $(grep -E '^TASK_LOOP=' <<<"$RK_OUT" | tail -1)"
fi
drop_ws "$W"

# ---------------------------------------------------------------- gate-only
W="$(new_ws)"
run_kernel "$W" --no-agent
if grep -q '^TASK_LOOP=BLOCKED$' <<<"$RK_OUT"; then
  ok "--no-agent is honest: RED with no attempt is BLOCKED, not STALLED"
else
  bad "--no-agent did not report BLOCKED"
fi
drop_ws "$W"

# ---------------------------------------------------------------- unknown engine
W="$(new_ws)"
run_kernel "$W" --agent doesnotexist
if grep -q '^TASK_LOOP=ERROR$' <<<"$RK_OUT" && [ "$RK_RC" -eq 4 ]; then
  ok "a missing engine is an ERROR, never a silent pass"
else
  bad "a missing engine did not fail closed"
fi
drop_ws "$W"

# ------------------------------- evals must run in the WORKSPACE, not git root
# A spec's relative paths are written against its own workspace. When the runner
# cd'd to the git root instead, every `test -f` failed in 0s without reaching the
# work — a RED indistinguishable from a real failure except by the suspiciously
# round duration. It cost a full engine run to find, because the fix had been
# applied to the inline fallback and NOT to the delegated path that actually runs.
# Build the nested workspace from scratch: copying a BOUND workspace would
# carry an execution profile whose paths point at the old root, which fails for
# a reason that has nothing to do with the working directory.
NEST="$(mktemp -d -t cvg-evalcwd.XXXXXX)"
git -C "$NEST" init --quiet
git -C "$NEST" config user.email cwd@test.local
git -C "$NEST" config user.name "cwd test"
mkdir -p "$NEST/projects/demo/cvg/tasks"
cp "$FIXTURE" "$NEST/projects/demo/cvg/tasks/T-20260602-golden.md"
printf '# readme\n' > "$NEST/projects/demo/README.md"
printf '# root readme\n' > "$NEST/README.md"
(
  cd "$NEST/projects/demo"
  TASKSPEC_SIGNING_KEY="$KEY" bash "$SAFE" --stamp --stamp-by cwd cvg/tasks/T-20260602-golden.md >/dev/null 2>&1
  TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" "$CVG" bind --task cvg/tasks/T-20260602-golden.md >/dev/null 2>&1
) || true
git -C "$NEST" add -A >/dev/null 2>&1; git -C "$NEST" commit --quiet -m base >/dev/null 2>&1
CWD_OUT="$( (cd "$NEST/projects/demo" && env -u TASKSPEC_WORKSPACE_ROOT TASKSPEC_SIGNING_KEY="$KEY" \
  bash "$SRC/skills/task-loop/scripts/run-issue-eval.sh" --issue T-20260602-golden 2>&1) || true )"
if grep -q '^GREEN$' <<<"$CWD_OUT"; then
  ok "evals run in the WORKSPACE, so a nested project verifies its own files"
else
  bad "evals ran in the wrong directory: $(grep -E '^\[(pass|fail)\]' <<<"$CWD_OUT" | head -1)"
fi
rm -rf "$NEST"

# --------------------------------- the signing key must survive a worktree
# Inside a linked worktree `git rev-parse --git-dir` is <main>/.git/worktrees/<n>,
# which has no info/ of its own. The signing key was therefore invisible, the
# spec silently degraded Tier 1 -> Tier 2 ("no key"), and that read as trust-tier
# DRIFT against a profile bound at Tier 1 — so every worktree run died on a
# contract error that had nothing to do with the task. Now that worktree is the
# DEFAULT, this is the difference between the loop working and not.
W="$(new_ws)"
mkdir -p "$W/.git/info"
cp "$KEY" "$W/.git/info/taskspec-signing-key"
git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m keyed >/dev/null 2>&1
WT="$(mktemp -d -t cvg-keywt.XXXXXX)"; rm -rf "$WT"
git -C "$W" worktree add --quiet -b probe/key "$WT" >/dev/null 2>&1
TIER_OUT="$( (cd "$WT" && env -u TASKSPEC_SIGNING_KEY \
  bash "$SRC/skills/task-spec/scripts/validate-task-spec.sh" cvg/tasks/T-20260602-golden.md 2>&1) || true )"
if grep -q 'Tier 1' <<<"$TIER_OUT"; then
  ok "the signing key resolves inside a worktree (Tier 1 survives isolation)"
else
  bad "a worktree cannot see the signing key: $(head -1 <<<"$TIER_OUT")"
fi
git -C "$W" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
drop_ws "$W"

# ------------------------------------------------- isolation is the DEFAULT
# An unattended agent must not be able to touch the tree a human is reading,
# and that has to be true when nobody passes a flag.
W="$(new_ws)"
git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m red >/dev/null 2>&1
DEF_OUT="$( (cd "$W" && TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" CVG_ENGINES_DIR="$STUBS" \
  bash "$KERNEL" --issue T-20260602-golden --agent tstnoop --max-iterations 1 2>&1) )"
if grep -q 'isolation: worktree' <<<"$DEF_OUT"; then
  ok "isolation defaults to worktree — safety is not opt-in"
else
  bad "the default is still in-place"
fi
drop_ws "$W"

# ----------------------------------------------------- worktree isolation
# In-place, a failed attempt leaves wreckage the NEXT attempt inherits. A
# worktree makes the cost of a bad run exactly zero and keeps an unattended
# agent out of the tree the human is reading.
W="$(new_ws)"
# A worktree is a checkout of COMMITTED state — uncommitted work in the main
# tree is invisible to it. Commit the red-making change or the isolated run
# starts green and reports a NO_OP that means nothing.
git -C "$W" add -A >/dev/null 2>&1; git -C "$W" commit --quiet -m red >/dev/null 2>&1
run_kernel "$W" --agent tstnoop --isolation worktree --max-iterations 1
if grep -q 'isolation: worktree' <<<"$RK_OUT"; then
  ok "the run happens in an isolated worktree, not the live tree"
else
  bad "--isolation worktree did not take effect"
fi
# EXHAUSTED keeps the worktree: a handoff note is useless without the work.
if grep -q 'worktree KEPT' <<<"$RK_OUT"; then
  ok "a landing with work to inspect KEEPS its worktree (resumable)"
else
  bad "the worktree was discarded even though there was work to keep"
fi
drop_ws "$W"

# A run the agent could not even start must leave NOTHING behind.
W="$(new_ws)"
_wt_before="$(git -C "$W" worktree list | wc -l | tr -d ' ')"
run_kernel "$W" --agent doesnotexist --isolation worktree
_wt_after="$(git -C "$W" worktree list | wc -l | tr -d ' ')"
if [ "$_wt_before" = "$_wt_after" ]; then
  ok "a failed run leaves no orphaned worktree behind"
else
  bad "an orphaned worktree survived a failed run"
fi
drop_ws "$W"

# ------------------------------------------- the fence a spec cannot widen
# The contract answers "may THIS task write here?"; the gate answers "may ANY
# task ever write here?". Before the gate, a spec that scoped fs.write to
# auth/ was not a violation — it was an instruction, and everything downstream
# worked perfectly to let an agent edit the auth code.
GW="$(new_ws)"
mkdir -p "$GW/.cvg" "$GW/auth"
printf 'version: 1\ndenylist:\n  - "auth/**"\n  - ".env"\nmax_files: 2\n' > "$GW/.cvg/gate.yaml"
# A contract that explicitly authorizes the forbidden path.
python3 - "$GW/cvg/execution/T-20260602-golden/execution-profile.yaml" <<'PYEOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
for g in d.get("authority", {}).get("grants", []):
    if g.get("capability") in ("fs.write", "vcs.commit"):
        g["scope"] = ["auth/**", "README.md"]
json.dump(d, open(p, "w"), indent=2)
PYEOF
printf 'secret\n' > "$GW/auth/login.py"
GATE_OUT="$( (cd "$GW" && python3 "$SRC/skills/task-to-runtime-contract/scripts/check-path-policy.py" \
  --profile cvg/execution/T-20260602-golden/execution-profile.yaml --repo "$GW" 2>&1) || true )"
if grep -q 'CHECK_PATH_POLICY=FAIL' <<<"$GATE_OUT" && grep -q 'no spec may widen' <<<"$GATE_OUT"; then
  ok "the repo gate refuses a path the CONTRACT authorized"
else
  bad "a spec widened the repo fence: $(tail -2 <<<"$GATE_OUT" | head -1)"
fi

# Blast radius is orthogonal to paths: all-legal, still too many.
for i in 1 2 3 4; do printf 'x\n' > "$GW/f$i.md"; done
python3 - "$GW/cvg/execution/T-20260602-golden/execution-profile.yaml" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
for g in d.get("authority", {}).get("grants", []):
    if g.get("capability") in ("fs.write", "vcs.commit"):
        g["scope"] = ["**"]
json.dump(d, open(sys.argv[1], "w"), indent=2)
PYEOF
rm -f "$GW/auth/login.py"
BR_OUT="$( (cd "$GW" && python3 "$SRC/skills/task-to-runtime-contract/scripts/check-path-policy.py" \
  --profile cvg/execution/T-20260602-golden/execution-profile.yaml --repo "$GW" 2>&1) || true )"
if grep -q 'exceeds max_files' <<<"$BR_OUT"; then
  ok "blast radius is capped even when every path is in scope"
else
  bad "max_files did not fire"
fi

# A gate that cannot be parsed must FAIL, never be skipped.
printf 'version: 1\nnonsense-key: yes\n' > "$GW/.cvg/gate.yaml"
BAD_OUT="$( (cd "$GW" && python3 "$SRC/skills/task-to-runtime-contract/scripts/check-path-policy.py" \
  --profile cvg/execution/T-20260602-golden/execution-profile.yaml --repo "$GW" 2>&1) || true )"
if grep -q 'Gate policy unreadable' <<<"$BAD_OUT"; then
  ok "an unparseable gate FAILS closed — not silently skipped"
else
  bad "a broken gate was treated as no gate"
fi

# Dotfiles must not be mangled. lstrip("./") turned ".env" into "env" and
# quietly exempted exactly the files most worth guarding.
if python3 -c "
import sys; sys.path.insert(0, '$SRC/skills/task-to-runtime-contract/scripts')
from _gate_policy import parse_gate
g = parse_gate('version: 1\ndenylist:\n  - \".env\"\n  - \".github/workflows/**\"\n')
assert g.forbids('.env'), '.env not matched'
assert g.forbids('.github/workflows/ci.yml'), 'workflow not matched'
" 2>/dev/null; then
  ok "dotfile paths are matched, not silently renamed"
else
  bad "dotfile paths are still being mangled"
fi
rm -rf "$GW"

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
# in-place: this row is about the CHECKPOINT, not about isolation, and a
# worktree would put state.env somewhere this assertion is not looking.
( cd "$W" && TASKSPEC_SIGNING_KEY="$KEY" CVG_HOME="$SRC" CVG_ENGINES_DIR="$STUBS" \
  bash "$KERNEL" --issue T-20260602-golden --agent tstslow --isolation inplace >/dev/null 2>&1 ) &
_kpid=$!
sleep 8   # long enough to be inside the engine call, nowhere near its return
if grep -q '^ITER=1$' "$W/cvg/loop/T-20260602-golden/state.env" 2>/dev/null; then
  ok "the checkpoint exists WHILE the loop is paused inside an attempt"
else
  bad "no checkpoint mid-attempt — a kill here would silently redo the work"
fi
kill "$_kpid" 2>/dev/null; wait "$_kpid" 2>/dev/null
pkill -f 'sleep 30' 2>/dev/null || true
drop_ws "$W"

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
drop_ws "$W"

# Cleanup belongs AFTER the last row that needs the stubs and the signing key.
# (Still no `trap ... EXIT`: bash fires an inherited EXIT trap when a `( )`
# subshell exits, and run_kernel uses one.)
rm -rf "$STUBS"; rm -f "$KEY"

echo "------------------------------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  printf 'PASS — %d loop-kernel checks green.\n' "$PASS"; exit 0
fi
printf 'FAIL — %d of %d loop-kernel checks red.\n' "$FAIL" "$((PASS + FAIL))"; exit 1
