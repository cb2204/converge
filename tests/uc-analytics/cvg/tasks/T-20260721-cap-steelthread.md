---
id: T-20260721-cap-steelthread
title: "Capture steel thread — one domain (orders) end-to-end off the WAL"
status: ready
format_version: 3
profile: standard
effort: L
budget_iterations: 15
agent: any
depends_on: []
touches_paths: []
creates_paths:
  - cvg/capture/principal.sql
  - cvg/capture/pipelines/orders.py
  - cvg/capture/probe_commit_to_answer.py
  - cvg/capture/tests/test_steelthread.py
source_note: "R5.R — Pass 5B tasking of swimlane-capture-leg-01 (steel thread); Fork B (task-driven)"
created: 2026-07-21T00:00:00Z
parent: ../sketch/swimlane-capture/swimlane-capture-leg-01-dlt.md
execution_backend: claude
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-23T18:17:08Z
signed_off_sig: hmac-sha256-v1:1f197c76:48829ec3f603bfb7460685c122022e77a2960bd0e6d745ded559ca85c5948e91
tracker_ref: linear:CVG-1
---

# Capture steel thread — one domain (orders) end-to-end off the WAL

> **Why:** The razor-thin vertical slice that de-risks the whole backbone before any
> lane fattens: provision the dedicated capture principal, land `orders` off the
> Postgres WAL into `raw.orders`, and prove a fresh source commit reaches a served
> answer. **Effort L** — it spans provision → land → probe but resolves to ONE
> coherent done-condition (the thread runs end-to-end), so it is a single long-horizon
> leaf, not a decomposition node. Accepted only on `execution_backend: glm`.

## Goal

Prove the capture steel thread end-to-end: provision the dedicated read-only capture
principal, land `orders` off the Postgres WAL into `raw.orders` in the frozen change-record
shape (`order_id` · `_lsn` · `_op` · `_captured_at` · `_source_committed_at`), and a probe
that inserts a source order and asserts it reaches a served answer within the R-1 freshness
budget — ONE coherent done-condition for the whole thin slice.

## Context

Decomposes `swimlane-capture-leg-01-dlt` (Fork B). Honors the sharpened `raw.*`
change-record seam contract: one row per change event; business key `order_id`;
total order `_lsn` (WAL LSN); `_op ∈ {insert,update,delete}` with delete-as-tombstone;
`_captured_at` + `_source_committed_at` carried; replay from a WAL checkpoint. Grounded
in ADR-0002 (log-based capture) and ADR-0003 (distinct capture principal). The `_control`
schema is fenced (ADR-0001) — never read.

## Behavior

- **B-1** — GIVEN a committed change to `orders`, WHEN the feed runs, THEN it lands in
  `raw.orders` (change-record shape) and surfaces in a served answer within the R-1
  freshness budget (the one coherent done-condition).
- **B-2** — GIVEN the capture read, WHEN the source connection log is inspected, THEN
  the read is attributed to the **dedicated capture principal**, not the operational app.
- **B-3** — GIVEN any capture run, WHEN the pipeline is audited, THEN nothing from the
  `_control` schema is ever read (the fence holds).

## Success Criteria

```bash
eval_1() { test -f cvg/capture/probe_commit_to_answer.py && grep -qEi 'assert|fresh|visible' cvg/capture/probe_commit_to_answer.py; }
eval_2() { test -f cvg/capture/principal.sql && grep -qiE 'capture.?principal|create role|create user' cvg/capture/principal.sql; }
eval_3() { test -f cvg/capture/pipelines/orders.py && ! grep -q '_control' cvg/capture/pipelines/orders.py; }
```

## Validation Card

```yaml
success_criteria:
  - id: eval_1
    description: the end-to-end probe asserts a fresh source commit is visible (B-1, the coherent done-condition)
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 60
  - id: eval_2
    description: the capture read runs as the dedicated principal (B-2)
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: false
    expected_duration_sec: 5
  - id: eval_3
    description: the pipeline never reads the _control fence (B-3)
    runnable: bash
    check_type: deterministic
    verifies: [B-3]
    terminal: false
    expected_duration_sec: 5

retry_policy:
  max_iterations: 15
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context

agent_contract:
  version: 2
  read: [intent, contract, guardrails, operations]
  produce: [code, test]
  required_tools: [bash, python, docker]
  timeout_minutes: 90
  sandbox_type: host
  output_artifacts: []
  mcp_dependencies: []
  emit: [pass, fail, retry_with_reason, parked_with_context]
  backend_metadata: {}
```

## Exit Check

```bash
eval_1 && eval_2 && eval_3
```

## Anti-Patterns

- **Don't fatten the thread.** One domain (`orders`), one thin path, one answer — leg-02
  adds the other domains, not this task.
- **Don't invent seam fields.** The `raw.*` contract is frozen at Pass 4 — carry
  `order_id`/`_lsn`/`_op`/`_captured_at`/`_source_committed_at` exactly.
- **Don't read below the seam.** No `_control`, no operational-app credentials.

## Do-Not-Touch

- `_control` schema (the chaos ledger — ADR-0001 fence).
- `public.*` beyond a read-only grant to the capture principal.

## Open Questions

- The by-principal seam (ADR-0003) may not exist on the source yet — provision it here or
  park with `blocked_reason` (owner: data-platform).
