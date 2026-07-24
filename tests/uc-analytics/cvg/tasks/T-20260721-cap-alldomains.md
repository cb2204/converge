---
id: T-20260721-cap-alldomains
title: "Capture — land all four domains into raw.*"
status: ready
format_version: 3
profile: lite
effort: M
budget_iterations: 12
agent: any
depends_on: [T-20260721-cap-steelthread]
touches_paths: []
creates_paths:
  - cvg/capture/pipelines/customers.py
  - cvg/capture/pipelines/products.py
  - cvg/capture/pipelines/payments.py
  - cvg/capture/tests/test_alldomains.py
source_note: "R5.R — Pass 5B tasking of the backbone (Fork B, task-driven)"
created: 2026-07-21T00:00:00Z
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-24T14:26:34Z
signed_off_sig: hmac-sha256-v1:1f197c76:68e4b2fa60875d0e4bf11415894245bb4b59f9d79ce61a830f6daa4e62a435d5
tracker_ref: linear:CVG-13
---

# Capture — land all four domains into raw.*

## Goal
Fatten the thread: land customers, products, orders, payments into `raw.*` as change records, each row carrying its capture as-of + measured lag. Honors the frozen `raw.*` seam contract; `_control` never captured (ADR-0001 fence).

## Success Criteria
```bash
eval_1() { for d in customers products orders payments; do test -f "cvg/capture/pipelines/$d.py" || return 1; done; }
eval_2() { test -f cvg/capture/pipelines/customers.py && grep -qEi "_captured_at|as.?of|lag" cvg/capture/pipelines/customers.py; }
eval_3() { test -f cvg/capture/pipelines/customers.py && ! grep -rq "_control" cvg/capture/pipelines/; }
```

## Validation Card
```yaml
success_criteria:
  - {id: eval_1, description: all four domain pipelines exist, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_2, description: landed rows carry capture as-of + lag, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_3, description: the _control fence holds, runnable: bash, check_type: deterministic, terminal: true, expected_duration_sec: 3}
retry_policy:
  max_iterations: 12
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context
agent_contract:
  version: 2
  read: [intent, contract]
  produce: [code, test]
  required_tools: [bash]
  timeout_minutes: 30
  sandbox_type: host
  output_artifacts: []
  mcp_dependencies: []
  emit: [pass, fail]
  backend_metadata: {}
```

## Exit Check
```bash
eval_1 && eval_2 && eval_3
```
