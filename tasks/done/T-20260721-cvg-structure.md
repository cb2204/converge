---
id: T-20260721-cvg-structure
title: R2.I — cvg structure subcommand (Pass 2 ADR gate wrapper) + R2.P golden parity
status: done
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
source_note: R2.I (cvg-todo, Track R) — the Pass 2 CLI beat; wraps the canonical scaffold-adr.sh --check gate proven at R2.C
created: 2026-07-21T16:00:00Z
tags: ["cvg", "pass-2", "gate", "structure", "R2.I", "R2.P"]
owner: (none)
priority: P1
severity: feature
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
linear_ref: (none)
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-21T11:25:14Z
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-21T11:26:20Z
signed_off_sig: hmac-sha256-v1:1f197c76:77a078b9cb64e0b936ad90605826de8ccbce6dbca9ffa38f364d5768514d6110
---

# R2.I — cvg structure subcommand (Pass 2 ADR gate wrapper) + R2.P golden parity

> **Why:** Pass 2 (`tech-req-to-adrs`) closed at R2.C with a canonical ADR set
> gated by `scaffold-adr.sh --check`. The CLI must expose that gate as
> `cvg structure` — the referee framing/discovery around an *exact* pass-through
> to the proven checker, exactly as `cvg intent` wraps check-tech-spec. The
> subcommand adds nothing to the gate's verdict; it locates the ADR set and
> execs the gate byte-for-byte (R2.P proves the parity).

---

## Goal

**(a) `cvg structure` — the R2.I subcommand.** Mirrors `intent`/`capture`: an
explicit `--dir <adr-dir>` (or a bare positional) is an exact `exec`
pass-through to `scaffold-adr.sh --check --dir <dir>`; no target = workspace
discovery (`cvg/docs/adrs/` then `docs/adrs/`, each qualifying only if it holds
`NNNN-*.md`; 0 found → exit 2 + token, >1 → exit 2 naming each + token, never
guesses). `--final` passes through (pass-close: nothing `proposed`). Unknown
flags refused with the token. The gate path is undecorated `exec` — no cvg
chrome — so the verdict and exit code are byte-identical to a direct run.
`cvg` bumps 0.3.0 → 0.4.0; `help` + `bin/README.md` gain the structure row.
**(b) R2.P rides on acceptance:** `cvg structure --final` on the proving ground
is byte-identical (same exit) to the direct `scaffold-adr.sh --check --final
--dir cvg/docs/adrs` run (golden diff EMPTY).

---

## Context

R2.I in cvg-todo.md (Track R). Precedent: R1.I (`T-20260719-cvg-intent`) — the
subcommand is a thin locate-then-exec around an already-proven gate (rule 3:
wrap, don't rewrite). The gate `scaffold-adr.sh` was hardened at R2.U (v0.4.0)
and its verdict canonized at R2.C; this task does NOT touch it. The UX contract
(stage-visible `_ui`) applies only to cvg's own exit-2 surfaces — the gate path
stays an undecorated `exec` (byte-parity is the R2.P proof). The signed ADR set
on the proving ground is a validation subject, never edited.

For the feature-level design this decomposes from, see `parent:` — referenced,
never copied. Zone 1 carries only the distillation needed to execute this unit.

---

## Behavior

- **B-1** — GIVEN the proving-ground workspace WHEN `cvg structure --final`
  runs with no target THEN it discovers `cvg/docs/adrs/` and its output +
  exit code are byte-identical to the direct `scaffold-adr.sh --check --final
  --dir cvg/docs/adrs` run (R2.P golden diff EMPTY, `CHECK_ADR=OK`).
- **B-2** — GIVEN no ADR set is discoverable THEN `cvg structure` exits 2
  ending in `CHECK_ADR=USAGE_ERROR`; GIVEN an unknown flag THEN exit 2 + the
  same token; GIVEN both `cvg/docs/adrs/` and `docs/adrs/` hold ADRs THEN
  exit 2 (ambiguous) + the token; GIVEN an explicit `--dir` THEN discovery is
  skipped and the gate runs on it.
- **B-3** — GIVEN a failing (unfilled) ADR set WHEN `cvg structure` runs THEN
  it passes the failure through unmasked: exit 1 with `CHECK_ADR=FAIL`;
  `cvg help` lists structure and `cvg version` reports 0.4.0.
- **B-4** — GIVEN the changed CLI WHEN linted THEN `shellcheck -x bin/cvg
  bin/_ui.sh` and `/bin/bash -n bin/cvg` (bash 3.2) are clean.

---

## Success Criteria

```bash
# eval-1: R2.P golden byte-parity + FAIL passthrough (the gate is never masked)
eval_1() {
  ROOT=$(pwd)
  RCA=0; A=$(cd tests/uc-analytics && "$ROOT/bin/cvg" structure --final 2>&1) || RCA=$?
  RCB=0; B=$(cd tests/uc-analytics && bash "$ROOT/skills/tech-req-to-adrs/scripts/scaffold-adr.sh" --check --final --dir cvg/docs/adrs 2>&1) || RCB=$?
  [ "$RCA" -eq 0 ] || return 1
  [ "$RCA" -eq "$RCB" ] || return 1
  [ "$A" = "$B" ] || return 1
  printf '%s\n' "$A" | grep -q '^CHECK_ADR=OK$' || return 1
  T=$(mktemp -d)
  bash skills/tech-req-to-adrs/scripts/scaffold-adr.sh --dir "$T/adrs" --context >/dev/null 2>&1
  bash skills/tech-req-to-adrs/scripts/scaffold-adr.sh --dir "$T/adrs" "unfilled placeholder fact" >/dev/null 2>&1
  RC=0; out=$(cd "$T" && CVG_HOME="$ROOT" bash "$ROOT/bin/cvg" structure --dir adrs 2>&1) || RC=$?
  rm -rf "$T"
  [ "$RC" -eq 1 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_ADR=FAIL$'
}

# eval-2: discovery + flag contract — every exit-2 path ends in the machine token
eval_2() {
  ROOT=$(pwd)
  T=$(mktemp -d); RC=0; out=$(cd "$T" && CVG_HOME="$ROOT" bash "$ROOT/bin/cvg" structure 2>&1) || RC=$?; rm -rf "$T"
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_ADR=USAGE_ERROR$' || return 1
  RC=0; out=$(cd tests/uc-analytics && "$ROOT/bin/cvg" structure --bogus 2>&1) || RC=$?
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_ADR=USAGE_ERROR$' || return 1
  T=$(mktemp -d)
  bash skills/tech-req-to-adrs/scripts/scaffold-adr.sh --dir "$T/cvg/docs/adrs" --context >/dev/null 2>&1
  bash skills/tech-req-to-adrs/scripts/scaffold-adr.sh --dir "$T/docs/adrs" --context >/dev/null 2>&1
  RC=0; out=$(cd "$T" && CVG_HOME="$ROOT" bash "$ROOT/bin/cvg" structure 2>&1) || RC=$?; rm -rf "$T"
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_ADR=USAGE_ERROR$'
}

# eval-3: surface + hygiene
eval_3() {
  out=$(bash bin/cvg help 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'structure' || return 1
  out=$(bash bin/cvg version 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'cvg 0.4.0' || return 1
  shellcheck -x bin/cvg bin/_ui.sh || return 1
  /bin/bash -n bin/cvg
}
```

---

## Validation Card

```yaml
success_criteria:
  - id: eval_1
    description: R2.P golden byte-parity with the direct gate run + FAIL passthrough unmasked
    runnable: bash
    check_type: deterministic
    verifies: [B-1, B-3]
    terminal: true
    expected_duration_sec: 10
  - id: eval_2
    description: discovery/flag exit-2 contract — 0-found, unknown-flag, ambiguous all end in CHECK_ADR=USAGE_ERROR
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 10
  - id: eval_3
    description: help lists structure, version 0.4.0, shellcheck + bash 3.2 clean
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

(Concrete: `git checkout -- bin/cvg bin/README.md cvg-todo.md` restores cvg
0.3.0 exactly; the ADR set and scaffold-adr.sh are untouched by this task.)

---

## Observability Hooks

- **Expected duration:** under 30 minutes build; evals < 30 s total
- **Key metric:** the golden diff line count (must be zero) and exit-code parity
- **Alert condition:** the golden diff going non-empty, or a FAIL set exiting 0
  through the wrapper — the referee is decorating or masking the gate; stop and
  surface, never patch the ADR set
- **Log tail:** eval_1 prints the shared verdict on parity failure

---

## Anti-Patterns

- **Don't decorate the gate path** — `cvg structure`'s pass-through is an exact
  `exec`; cvg chrome/tokens live only on its own exit-2 surfaces. Byte-parity
  is the R2.P proof and it must survive.
- **Don't mask a FAIL** — a failing ADR set must exit 1 with `CHECK_ADR=FAIL`
  through the wrapper, never be swallowed to OK.
- **Don't rewrite scaffold-adr.sh** — it was canonized at R2.C; this task wraps
  it (rule 3). A change to the gate needs its own task + a written reason.
- **Don't guess on ambiguity** — two candidate ADR dirs is an exit-2 error that
  names both, never a silent pick.

---

## Do-Not-Touch

- tests/uc-analytics/cvg/docs/adrs/* (the canonical Pass 2 ADR set — a
  validation subject, immutable/accepted)
- skills/tech-req-to-adrs/scripts/scaffold-adr.sh (the gate, canonized at R2.C)
- skills/task-spec/scripts/* (different skill, different task)

---

## Open Questions

1. **Ambiguity policy** — recommendation: mirror `intent` exactly (0 → error,
   1 → use, >1 → name-and-refuse). If a workspace legitimately needs both a
   `cvg/docs/adrs` and a root `docs/adrs`, that surfaces here as a request to
   revisit, not a silent precedence rule.
