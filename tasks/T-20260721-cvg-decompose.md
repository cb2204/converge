---
id: T-20260721-cvg-decompose
title: R3.I — cvg decompose subcommand (Pass 3 swimlane gate wrapper) + R3.P golden parity
status: ready
format_version: 3
profile: standard
effort: S
budget_iterations: 12
agent: claude
parent: (none)
depends_on: []
touches_paths:
  - bin/cvg
  - bin/README.md
  - cvg-todo.md
creates_paths: []
source_note: R3.I (cvg-todo, Track R) — the Pass 3 CLI beat; wraps new-plan.sh --check proven at R3.U/R3.R
created: 2026-07-21T18:00:00Z
tags: ["cvg", "pass-3", "gate", "decompose", "R3.I", "R3.P"]
owner: (none)
priority: P1
severity: feature
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
linear_ref: (none)
tracker_ref: linear:CVG-5
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-21T14:21:55Z
accepted: false
accepted_by: (none)
accepted_at: (none)
signed_off_sig: hmac-sha256-v1:1f197c76:814f96af82dba33ced7f2adbffe62282c4c760e929afa3d3bed9f84b59831d26
---

# R3.I — cvg decompose subcommand (Pass 3 swimlane gate wrapper) + R3.P golden parity

> **Why:** Pass 3 (`reqs-to-swimlane-plans`, v0.7.0) gates the sketch/ swimlane
> tree with `new-plan.sh --check`. The CLI must expose that gate as
> `cvg decompose` — the referee framing/discovery around an *exact* pass-through
> to the proven checker, exactly as `cvg structure` wraps scaffold-adr. Byte
> parity is the R3.P proof.

---

## Goal

**(a) `cvg decompose` — the R3.I subcommand.** Mirrors `structure`: an explicit
`--dir <sketch>` (or bare positional) is an exact `exec` pass-through to
`new-plan.sh --check --dir <dir>`; no target = workspace discovery
(`cvg/sketch/` then `sketch/`, qualifying only if it holds `swimlane-*/`; 0 →
exit 2 + token, >1 → exit 2 naming each + token, never guesses). Unknown flags
refused with the token. The gate path is undecorated `exec` — verdict and exit
code byte-identical to a direct run. `cvg` bumps 0.4.0 → 0.5.0; `help` +
`bin/README.md` gain the decompose row.
**(b) R3.P rides on acceptance:** `cvg decompose` on the proving ground is
byte-identical (same exit) to the direct `new-plan.sh --check --dir sketch` run
(golden diff EMPTY).

---

## Context

R3.I in cvg-todo.md (Track R). Precedent: R2.I (`cvg structure`) — the subcommand
is a thin locate-then-exec around an already-proven gate (rule 3: wrap, don't
rewrite). `new-plan.sh` was hardened to v0.7.0 (dir-per-swimlane) and its verdict
run on the proving ground at R3.R; this task does NOT touch it. The gate path
stays an undecorated `exec` (byte-parity is the R3.P proof). The swimlane set is
a validation subject, never edited.

For the feature-level design this decomposes from, see `parent:` — referenced,
never copied. Zone 1 carries only the distillation needed to execute this unit.

---

## Behavior

- **B-1** — GIVEN the proving-ground workspace WHEN `cvg decompose` runs with no
  target THEN it discovers `sketch/` and its output + exit code are byte-identical
  to the direct `new-plan.sh --check --dir sketch` run (R3.P golden diff EMPTY,
  `CHECK_PLAN=OK`).
- **B-2** — GIVEN no swimlane tree is discoverable THEN `cvg decompose` exits 2
  ending in `CHECK_PLAN=USAGE_ERROR`; GIVEN an unknown flag THEN exit 2 + the same
  token.
- **B-3** — GIVEN a failing swimlane set WHEN `cvg decompose` runs THEN it passes
  the failure through unmasked: exit 1 with `CHECK_PLAN=FAIL`; `cvg help` lists
  decompose and `cvg version` reports 0.5.0.
- **B-4** — GIVEN the changed CLI WHEN linted THEN `shellcheck -x bin/cvg
  bin/_ui.sh` and `/bin/bash -n bin/cvg` (bash 3.2) are clean.

---

## Success Criteria

```bash
# eval-1: R3.P golden byte-parity + FAIL passthrough (gate never masked)
eval_1() {
  ROOT=$(pwd)
  RCA=0; A=$(cd tests/uc-analytics/cvg && "$ROOT/bin/cvg" decompose 2>&1) || RCA=$?
  RCB=0; B=$(cd tests/uc-analytics/cvg && bash "$ROOT/skills/reqs-to-swimlane-plans/scripts/new-plan.sh" --check --dir sketch 2>&1) || RCB=$?
  [ "$RCA" -eq 0 ] || return 1
  [ "$RCA" -eq "$RCB" ] || return 1
  [ "$A" = "$B" ] || return 1
  printf '%s\n' "$A" | grep -q '^CHECK_PLAN=OK$' || return 1
  RC=0; out=$(cd tests/uc-analytics/cvg && "$ROOT/bin/cvg" decompose --dir "$ROOT/skills/reqs-to-swimlane-plans/tests/fixtures/no-thread" 2>&1) || RC=$?
  [ "$RC" -eq 1 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_PLAN=FAIL$'
}

# eval-2: discovery/flag exit-2 contract — every path ends in CHECK_PLAN=USAGE_ERROR
eval_2() {
  ROOT=$(pwd)
  T=$(mktemp -d); RC=0; out=$(cd "$T" && CVG_HOME="$ROOT" bash "$ROOT/bin/cvg" decompose 2>&1) || RC=$?; rm -rf "$T"
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_PLAN=USAGE_ERROR$' || return 1
  RC=0; out=$(cd tests/uc-analytics/cvg && "$ROOT/bin/cvg" decompose --bogus 2>&1) || RC=$?
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_PLAN=USAGE_ERROR$'
}

# eval-3: surface + hygiene
eval_3() {
  out=$(bash bin/cvg help 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'decompose' || return 1
  out=$(bash bin/cvg version 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'cvg 0.5.0' || return 1
  shellcheck -x bin/cvg bin/_ui.sh || return 1
  /bin/bash -n bin/cvg
}
```

---

## Validation Card

```yaml
success_criteria:
  - id: eval_1
    description: R3.P golden byte-parity with the direct gate + FAIL passthrough unmasked
    runnable: bash
    check_type: deterministic
    verifies: [B-1, B-3]
    terminal: true
    expected_duration_sec: 10
  - id: eval_2
    description: discovery/flag exit-2 contract — 0-found + unknown-flag end in CHECK_PLAN=USAGE_ERROR
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 10
  - id: eval_3
    description: help lists decompose, version 0.5.0, shellcheck + bash 3.2 clean
    runnable: bash
    check_type: deterministic
    verifies: [B-3, B-4]
    terminal: true
    expected_duration_sec: 10

retry_policy:
  max_iterations: 12
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context

agent_contract:
  version: 2
  read: [intent, behavior, contract, guardrails, operations]
  produce:
    - code
    - docs
  required_tools: [git, bash]
  timeout_minutes: 20
  sandbox_type: host
  output_artifacts: []
  mcp_dependencies: []
  emit:
    - pass
    - fail
    - retry_with_reason
    - parked_with_context
  backend_metadata: {}
```

---

## Exit Check

```bash
eval_1 && eval_2 && eval_3
```

---

## Rollback Plan

If execution fails mid-task, revert to the pre-task state:

1. **Git revert** — `git revert --no-commit HEAD` (if commits were made)
2. **File restore** — `git checkout -- bin/cvg bin/README.md cvg-todo.md`
3. **State reset** — set task status to `parked`, record `blocked_reason`

(Concrete: `git checkout -- bin/cvg bin/README.md cvg-todo.md` restores cvg 0.4.0
exactly; the swimlane set and new-plan.sh are untouched by this task.)

---

## Observability Hooks

- **Expected duration:** under 30 minutes build; evals < 30 s total
- **Key metric:** the golden diff line count (must be zero) and exit-code parity
- **Alert condition:** the golden diff going non-empty, or a FAIL swimlane set
  exiting 0 through the wrapper — the referee is decorating or masking the gate;
  stop and surface, never patch the swimlane set
- **Log tail:** eval_1 prints the shared verdict on parity failure

---

## Anti-Patterns

- **Don't decorate the gate path** — `cvg decompose`'s pass-through is an exact
  `exec`; cvg chrome/tokens live only on its own exit-2 surfaces. Byte-parity is
  the R3.P proof and it must survive.
- **Don't mask a FAIL** — a failing swimlane set must exit 1 with
  `CHECK_PLAN=FAIL` through the wrapper, never be swallowed to OK.
- **Don't rewrite new-plan.sh** — it was hardened at R3.U; this task wraps it
  (rule 3). A change to the gate needs its own task + a written reason.
- **Don't guess on ambiguity** — two candidate sketch trees is an exit-2 error
  that names both, never a silent pick.

---

## Do-Not-Touch

- tests/uc-analytics/cvg/sketch/** (the R3.R swimlane set — a validation subject)
- skills/reqs-to-swimlane-plans/scripts/new-plan.sh (the gate, hardened at R3.U)
- skills/task-spec/scripts/* (different skill, different task)

---

## Open Questions

1. **Discovery precedence** — recommendation: mirror `structure`/`intent` exactly
   (`cvg/sketch` then `sketch`; 0 → error, 1 → use, >1 → name-and-refuse). If a
   workspace legitimately needs both, that surfaces here as a request to revisit.
