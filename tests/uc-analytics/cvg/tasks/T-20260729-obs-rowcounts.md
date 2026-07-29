---
id: T-20260729-obs-rowcounts
title: Add a row-count observability probe for the four public tables
status: ready
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: XS  # LEAF: XS|S|M → Kimi ; L → GLM (execution_backend: glm) . NODE: XL|XXL → add a children: block, decompose (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: codex
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
creates_paths:
  - cvg/capture/row_counts.py
touches_paths: []
source_note: (none)
created: 2026-07-29T19:13:49Z
tags: [observability]
owner: (none)
priority: P2
severity: feature  # cosmetic | refactor | feature | bugfix | security | financial-critical
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
tracker_ref: linear:CVG-31
execution_backend: codex  # OPEN STRING — names the canonical executor (any|claude|codex|kimi|glm|gemini|<your-harness>). Adapters live in runbooks/dispatch-recipes/ (non-normative). Required to be 'glm' for effort: L.
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-29T19:17:08Z
accepted: false  # flipped true by accept-task.sh AFTER execution — closes the loop (evals re-run from clean checkout + blast-radius + envelope)
accepted_by: (none)
accepted_at: (none)
signed_off_sig: hmac-sha256-v2:1f197c76:a9c8547cbd6ee00d1fd4108ff5d9e2e3ebbe633b0ffb99fc1cfd5d91880483e9
---

# Add a row-count observability probe for the four public tables

> **Why:** The capture lane asserts freshness and principal counts but nothing
> reports the plain size of the four operational tables, so drift between runs
> has no cheap first signal.

---

## Goal

A stdlib-only script `cvg/capture/row_counts.py` that prints ONE single-line
JSON object with exactly the keys `customers`, `products`, `orders`,
`payments` — each an integer row count read from the `public` schema of the
`ecommerce` database — and exits 0. On any failure (container down, table
missing) it exits non-zero with a one-line error on stderr.

---

## Context

The proving-ground database is an operational Postgres in the
`uc-analytics-postgres` container (db `ecommerce`, user `postgres`,
deterministic seed). Capture-lane code is Python stdlib only and reaches the
database through the `docker exec … psql` transport — see
`cvg/capture/pipelines/orders.py` and `cvg/capture/dagster/freshness_check.py`
for the established pattern. Analytical reads are fenced to the `public`
schema (ADR-0001); the `_control` schema is the chaos ledger and is
off-limits to this probe.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN the `uc-analytics-postgres` container is healthy WHEN
  `python3 cvg/capture/row_counts.py` runs THEN stdout is one line of JSON with
  exactly the keys `customers`, `products`, `orders`, `payments`, every value
  an integer ≥ 1, and the exit code is 0
- **B-2** — GIVEN the script builds its queries WHEN it reads the database THEN
  it touches only the `public` schema through the stdlib + `docker exec psql`
  transport — no `_control` reference, no third-party driver import

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: the probe emits valid JSON with exactly the four public tables, all counts >= 1
eval_1() {
  python3 cvg/capture/row_counts.py | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert sorted(d) == ["customers", "orders", "payments", "products"], d
assert all(isinstance(v, int) and v >= 1 for v in d.values()), d
print("EVAL1_OK")'
}

# eval-2: the probe stays inside the fence — no _control reference, no third-party driver
eval_2() {
  ! grep -q "_control" cvg/capture/row_counts.py \
    && ! grep -Eq "^[[:space:]]*(import|from)[[:space:]]+(psycopg|sqlalchemy|pg8000|asyncpg)" cvg/capture/row_counts.py
}

# eval-3: the probe's orders count equals what psql reports directly
eval_3() {
  a=$(python3 cvg/capture/row_counts.py | python3 -c 'import json,sys; print(json.load(sys.stdin)["orders"])')
  b=$(docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc "SELECT count(*) FROM public.orders")
  [ -n "$a" ] && [ "$a" = "$b" ]
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
    description: probe emits valid JSON with exactly the four public tables, counts >= 1
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 5
  - id: eval_2
    description: probe stays inside the fence — no _control, no third-party driver
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 1
  - id: eval_3
    description: probe's orders count equals psql's answer for the same table
    runnable: bash
    check_type: deterministic
    verifies: [B-1, B-2]
    terminal: true
    expected_duration_sec: 5

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
  output_artifacts: [cvg/capture/row_counts.py]
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

- All FOUR counts (not just orders) match a direct psql query at grading time.
- The script exits non-zero with a one-line stderr message when asked about a
  table that does not exist or when the container is unreachable — the error
  path exists and is exercised, not just the happy path.
- No SQL string is built from user-controlled input (argv/env interpolated into
  a query); the four table names are a fixed allowlist in the source.
- The JSON is emitted by `json.dumps` (or equivalent), not hand-concatenated.

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

- **Expected duration:** under 10 seconds per invocation
- **Key metric:** the four row counts, one JSON line per run
- **Alert condition:** non-zero exit, or any count of 0
- **Log tail:** stderr carries the single-line failure reason

---

## Anti-Patterns

- **Don't import a Postgres driver** — the capture lane is stdlib-only by
  constraint; the transport is `docker exec … psql`. Mirror
  `cvg/capture/pipelines/orders.py`.
- **Don't read `_control`** — it is the chaos ledger, fenced from analytical
  consumers (ADR-0001). The probe reads `public` only.
- **Don't print anything but the JSON on stdout** — consumers parse stdout;
  diagnostics belong on stderr.

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- cvg/capture/pipelines/orders.py
- cvg/capture/principal.sql
- src/ (the product's schema, seed, and generator)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

(none — this task is fully specified)
