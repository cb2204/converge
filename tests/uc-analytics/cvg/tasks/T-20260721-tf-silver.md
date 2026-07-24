---
id: T-20260721-tf-silver
title: "Transform — silver conform (dedup max-_lsn, UTC)"
status: ready
format_version: 3
profile: lite
effort: M
budget_iterations: 12
agent: any
depends_on: [T-20260721-cap-alldomains]
touches_paths: []
creates_paths:
  - cvg/transform/models/silver/orders.sql
  - cvg/transform/models/silver/schema.yml
  - cvg/transform/tests/unique_business_key.sql
source_note: "R5.R — Pass 5B tasking of the backbone (Fork B, task-driven)"
created: 2026-07-21T00:00:00Z
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-24T14:26:42Z
signed_off_sig: hmac-sha256-v1:1f197c76:9b953a3bbd3e65738dd061331c0ae123397ea346c4d3a1e5c55d48449b9ed64b
---

# Transform — silver conform (dedup max-_lsn, UTC)

## Goal
Conform `raw.*` to silver: dedup to one row per business key by keeping the max-`_lsn` change event (a `_op=delete` tombstone removes the key), pin types, set UTC grain. Per the sharpened seam contract — NOT a hash of business columns.

## Success Criteria
```bash
eval_1() { test -f cvg/transform/models/silver/orders.sql && grep -qEi "max\(_lsn\)|row_number|_lsn desc" cvg/transform/models/silver/orders.sql; }
eval_2() { test -f cvg/transform/tests/unique_business_key.sql && grep -qi unique cvg/transform/tests/unique_business_key.sql; }
eval_3() { test -f cvg/transform/models/silver/orders.sql && grep -qEi "utc|timezone" cvg/transform/models/silver/orders.sql; }
```

## Validation Card
```yaml
success_criteria:
  - {id: eval_1, description: dedup keeps max-_lsn per business key, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_2, description: a uniqueness test guards the business key, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_3, description: silver timestamps are UTC, runnable: bash, check_type: deterministic, terminal: true, expected_duration_sec: 3}
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
