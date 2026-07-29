---
id: T-20260729-obs-fence
title: Add a schema-fence checker for the analytical capture surfaces
status: ready
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: XS  # LEAF: XS|S|M → Kimi ; L → GLM (execution_backend: glm) . NODE: XL|XXL → add a children: block, decompose (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: kimi
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
creates_paths:
  - cvg/capture/schema_fence.py
touches_paths: []
source_note: (none)
created: 2026-07-29T19:13:49Z
tags: [observability, guardrail]
owner: (none)
priority: P2
severity: feature  # cosmetic | refactor | feature | bugfix | security | financial-critical
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
tracker_ref: linear:CVG-30
execution_backend: kimi  # OPEN STRING — names the canonical executor (any|claude|codex|kimi|glm|gemini|<your-harness>). Adapters live in runbooks/dispatch-recipes/ (non-normative). Required to be 'glm' for effort: L.
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-29T19:17:09Z
accepted: false  # flipped true by accept-task.sh AFTER execution — closes the loop (evals re-run from clean checkout + blast-radius + envelope)
accepted_by: (none)
accepted_at: (none)
signed_off_sig: hmac-sha256-v2:1f197c76:752ad286af396c0021c059568af7243a8bc0d35f5b94ff3cfc4ef9fd3563f4a3
---

# Add a schema-fence checker for the analytical capture surfaces

> **Why:** ADR-0001 fences analytical reads to the `public` schema, but nothing
> enforces the fence — a `_control` reference could land in a pipeline today and
> nothing would object until an audit.

---

## Goal

A stdlib-only script `cvg/capture/schema_fence.py` that statically scans the
ANALYTICAL capture surfaces — `cvg/capture/pipelines/` and
`cvg/capture/dagster/` — for any reference to the `_control` schema. Clean scan:
print `FENCE=OK`, exit 0. Breach: print each offender as `file:line`, exit 1.
A `--self-test` mode proves the detector can actually detect (against a
temporary directory it creates itself), printing `SELF_TEST=OK` and exiting 0.

---

## Context

The `_control` schema is the chaos ledger — fenced ground truth that
business/analytical consumers must never read (ADR-0001,
`cvg/docs/adrs/0001-analytical-reads-fenced-to-public.md`). The ground-truth
surfaces — `cvg/capture/tests/` and `cvg/capture/principal.sql` — legitimately
read `_control` to verify capture correctness, so the fence deliberately scans
ONLY the two analytical directories. Capture-lane code is Python stdlib only.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN the analytical surfaces are clean WHEN
  `python3 cvg/capture/schema_fence.py` runs THEN it prints `FENCE=OK` and
  exits 0
- **B-2** — GIVEN a scanned file references `_control` WHEN the fence runs THEN
  it prints the offender as `file:line` and exits 1 — proven by `--self-test`,
  which creates its own temporary scan target, asserts detection, prints
  `SELF_TEST=OK`, and exits 0 without touching the repository

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: clean surfaces scan green
eval_1() {
  out=$(python3 cvg/capture/schema_fence.py) && printf '%s\n' "$out" | grep -q "FENCE=OK"
}

# eval-2: the detector detects — self-test in a temp dir, repo untouched
eval_2() {
  out=$(python3 cvg/capture/schema_fence.py --self-test) \
    && printf '%s\n' "$out" | grep -q "SELF_TEST=OK" \
    && [ -z "$(git status --porcelain cvg/capture)" ]
}

# eval-3: the fence's claim is independently true — the analytical dirs really are clean
eval_3() {
  ! grep -rn "_control" cvg/capture/pipelines cvg/capture/dagster
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
    description: clean analytical surfaces scan green with FENCE=OK, exit 0
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 2
  - id: eval_2
    description: self-test proves detection in a temp dir and leaves the repo untouched
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 2
  - id: eval_3
    description: independent grep confirms the analytical dirs are actually clean
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 1

retry_policy:
  max_iterations: 15
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context

agent_contract:
  version: 2
  read: [intent, behavior, contract, guardrails, operations]
  produce:
    - code
  required_tools: [git, bash]
  timeout_minutes: 30
  sandbox_type: host  # host | isolated | ephemeral
  output_artifacts: [cvg/capture/schema_fence.py]
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

## Holdout

Assertions the implementer never sees — graded only by the tier-2 judge.

- The exemption of the ground-truth surfaces (`tests/`, `principal.sql`) is a
  deliberate, named decision in the code (an explicit scan list or documented
  exclusion), not an accident of which directories happened to be walked.
- The self-test writes ONLY inside a `tempfile`-created directory and cleans up
  after itself — nothing lands in the repository, even on failure.
- The exit-code contract is exact: 0 clean, 1 breach, and any operational
  error (unreadable dir) is distinguishable from a breach.
- The scan matches `_control` as a schema reference, not merely as a substring
  of an unrelated word — a file containing only `pre_control_flag` must not be
  flagged.

---

## Rollback Plan

If execution fails mid-task, revert to the pre-task state:

1. **Git revert** — `git revert --no-commit HEAD` (if commits were made)
2. **File restore** — `git checkout -- <paths>` for any modified files not yet committed
3. **State reset** — update task status to `parked` and record `blocked_reason`

(none — this task is append-only or additive with no destructive changes)

---

## Observability Hooks

What to watch during execution and after deployment:

- **Expected duration:** under 5 seconds per invocation
- **Key metric:** offender count (0 when green)
- **Alert condition:** exit 1 — a `_control` reference reached an analytical surface
- **Log tail:** offenders printed one per line as `file:line`

---

## Anti-Patterns

- **Don't scan the ground-truth surfaces** — `cvg/capture/tests/` and
  `cvg/capture/principal.sql` read `_control` BY DESIGN; flagging them makes
  the fence cry wolf and get deleted.
- **Don't shell out to grep** — the checker is stdlib Python so its behavior is
  identical on every host; use `pathlib` + line iteration.
- **Don't let the self-test touch the repo** — a guardrail that mutates what it
  guards is worse than no guardrail. `tempfile.TemporaryDirectory` only.

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- cvg/capture/tests/ (ground-truth probes)
- cvg/capture/principal.sql
- cvg/capture/pipelines/orders.py
- src/ (the product's schema, seed, and generator)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

(none — this task is fully specified)
