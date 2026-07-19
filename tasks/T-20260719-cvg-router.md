---
id: T-20260719-cvg-router
title: Create the bin/cvg router — one name over the task-spec toolchain
status: ready
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: S  # XS | S | M → Kimi ; L → GLM (requires execution_backend: glm) ; XL → route to SDD (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: claude
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
touches_paths:
  - bin/cvg
  - bin/_ui.sh
creates_paths:
  - bin/cvg
  - bin/_ui.sh
source_note: cvg-todo.md Milestone 1.1 — owner pivot 2026-07-19: bin/cvg born at R0.I
created: 2026-07-19T14:03:17Z
tags: ["cvg", "cli", "router", "milestone-1.1"]
owner: (none)
priority: P1
severity: feature
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
linear_ref: (none)  # off-repo Intent crossing — Linear issue id/url this task traces to
execution_backend: any  # OPEN STRING — names the canonical executor (any|claude|codex|kimi|glm|gemini|<your-harness>). Adapters live in runbooks/dispatch-recipes/ (non-normative). Required to be 'glm' for effort: L.
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-19T14:06:11Z
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-19T14:09:59Z
signed_off_sig: hmac-sha256-v1:1f197c76:c647cdd87a3f7967ba9fb004294edc08903ea2e3107076f3f7f8a56adef09c67
---

# Create the bin/cvg router — one name over the task-spec toolchain

> **Why:** Every Converge operation today means remembering a script path
> under `skills/task-spec/scripts/`. Milestone 1.1 gives the chain ONE name:
> `cvg <verb>` routes to the proven scripts unchanged — referee, never player.

---

## Goal

A bash-3.2-safe `bin/cvg` entrypoint that maps subcommands onto the existing,
untouched task-spec scripts: `cvg tasks validate|gate|accept`, `cvg eval`,
`cvg lint`, `cvg transition`, `cvg ready`, plus `cvg help` and `cvg version`.
Wrapped commands are byte-exact pass-throughs (same stdout, same exit code)
so every already-proven gate stays proven. Repo-local resolution: locate
`skills/task-spec/scripts/` by walking up from the working directory to the
git root, with a `CVG_HOME` override. A minimal shared `bin/_ui.sh` layer is
born alongside (colors only in `help`/`version`/error surfaces — NEVER in
wrapped-command output) honoring the verified degradation contract: no ANSI
when stdout is not a TTY, when `NO_COLOR` is set non-empty, or when
`CVG_COLOR=0`.

---

## Context

`cvg-todo.md` Milestone 1.1 (absorbed into R0.I by the owner's 2026-07-19
pivot: Pass 0 closes end-to-end now, so the entrypoint is born now). The UX
contract and its field research live at `cvg-todo.md` R1.I bullet and
`temp/cli-ux-research-2026-07-19.md` — this task implements only the
degradation floor; the stage-strip aesthetics arrive with `cvg capture`.
Wrap-don't-rewrite is rule 3; the fixture floor is `tests/e2e-test-engine/`
with its 6-spec backlog under `tasks/`.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN the fixture backlog WHEN `cvg tasks gate <spec>` runs THEN
  stdout and exit code are byte-identical to invoking
  `skills/task-spec/scripts/safe-to-delegate.sh <spec>` directly.
- **B-2** — GIVEN a user asking for orientation WHEN `cvg help` runs THEN it
  exits 0 and lists every subcommand: tasks (validate, gate, accept), eval,
  lint, transition, ready, help, version.
- **B-3** — GIVEN piped/non-TTY output or `NO_COLOR=1` WHEN any `cvg`
  command runs THEN the output contains zero ANSI escape bytes (the
  degradation contract from the CLI-UX research).

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: pass-through parity — cvg tasks gate === safe-to-delegate.sh (bytes + exit)
eval_1() {
  SPEC=tasks/T-20260716-build-daily-totals.md
  bash skills/task-spec/scripts/safe-to-delegate.sh "$SPEC" > /tmp/cvg_e1_direct.txt 2>&1
  d=$?
  ./bin/cvg tasks gate "$SPEC" > /tmp/cvg_e1_routed.txt 2>&1
  r=$?
  [ "$d" -eq "$r" ] && diff -q /tmp/cvg_e1_direct.txt /tmp/cvg_e1_routed.txt >/dev/null
}

# eval-2: cvg help exits 0 and names every subcommand
eval_2() {
  out=$(./bin/cvg help 2>&1) || return 1
  for w in tasks validate gate accept eval lint transition ready help version; do
    printf '%s\n' "$out" | grep -qw "$w" || return 1
  done
}

# eval-3: degradation contract — commands SUCCEED and piped output carries zero ANSI escape bytes
eval_3() {
  out=$(./bin/cvg help 2>&1) || return 1
  printf '%s\n' "$out" | LC_ALL=C grep -q $'\033' && return 1
  out=$(NO_COLOR=1 ./bin/cvg version 2>&1) || return 1
  printf '%s\n' "$out" | LC_ALL=C grep -q $'\033' && return 1
  out=$(./bin/cvg tasks gate tasks/T-20260716-build-daily-totals.md 2>&1) || return 1
  printf '%s\n' "$out" | LC_ALL=C grep -q $'\033' && return 1
  return 0
}
```

---

## Validation Card

```yaml
success_criteria:
  # check_type: deterministic (default, bash-checked, preferred) | llm_judge
  # (subjective criteria graded by a fast LLM via judge_prompt — deterministic-first).
  # verifies: the behavior id(s) this eval proves. Standard/full profiles require
  # every B-N to be covered by >=1 eval and every eval to map to a behavior.
  - id: eval_1
    description: pass-through parity — cvg tasks gate === safe-to-delegate.sh (bytes + exit)
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 10
  - id: eval_2
    description: cvg help exits 0 and names every subcommand
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 2
  - id: eval_3
    description: piped/NO_COLOR output carries zero ANSI escape bytes
    runnable: bash
    check_type: deterministic
    verifies: [B-3]
    terminal: true
    expected_duration_sec: 12

retry_policy:
  max_iterations: 15
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context

agent_contract:
  version: 2
  read: [intent, behavior, contract, guardrails, operations]
  produce:
    - code
    - docs
    - config
    - tests
  required_tools: [git, bash]
  timeout_minutes: 30
  sandbox_type: host  # host | isolated | ephemeral
  output_artifacts: []
  mcp_dependencies: []
  emit:
    - pass
    - fail
    - retry_with_reason
    - parked_with_context
  backend_metadata: {}  # optional executor-specific key/value map (the backend names itself); replaces the old codex_metadata/kimi_metadata
```

---

## Exit Check

```bash
# Final proof-of-done. Returns 0 only when ALL evals pass.
eval_1 && eval_2 && eval_3
```

---

## Rollback Plan

If execution fails mid-task, revert to the pre-task state:

1. **Git revert** — `git revert --no-commit HEAD` (if commits were made)
2. **File restore** — `git checkout -- <paths>` for any modified files not yet committed
3. **State reset** — update task status to `parked` and record `blocked_reason`

(none beyond the above — this task is additive: it creates `bin/cvg` and
`bin/_ui.sh` and modifies nothing else; deleting `bin/` restores the world.)

---

## Observability Hooks

What to watch during execution and after deployment:

- **Expected duration:** under 30 minutes of build time; evals complete in < 30 s total
- **Key metric:** eval_1 parity diff — any byte of drift between routed and direct output
- **Alert condition:** a wrapped command's exit code differs from its script's
- **Log tail:** /tmp/cvg_e1_*.txt on eval_1 failure

---

## Anti-Patterns

- **Don't rewrite or "improve" any wrapped script** — rule 3 (wrap, don't
  rewrite); a rewrite needs a written reason in cvg-todo.md. Route to the
  scripts unchanged.
- **Don't decorate wrapped-command output** — eval_1's byte-parity is the
  contract that keeps every proven gate proven. Beauty lives only in
  help/version/error surfaces.
- **Don't use bash-4+ features (mapfile, declare -A, ${var,,})** — rule 5:
  macOS system bash 3.2 is the floor, matching the task-spec scripts.

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- skills/task-spec/scripts/* (route to them, never edit them)
- tasks/T-20260716-*.md (the fixture backlog is sealed — HMAC envelopes)
- tests/e2e-test-engine/* (the proven floor)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

1. **`cvg eval` default flags** — `run-task-spec.sh` supports `--ci`; the
   router passes flags through verbatim, so decide only whether bare
   `cvg eval <spec>` implies `--ci` (recommendation: no — pass-through
   purity; Milestone 2.1 owns the `--ci` contract).
2. **`cvg version` composition** — recommendation: print the cvg version
   plus the wrapped `TASKSPEC_VERSION` from `_lib.sh` so one command names
   the whole toolchain.
