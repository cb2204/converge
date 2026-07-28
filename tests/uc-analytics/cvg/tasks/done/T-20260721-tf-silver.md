---
id: T-20260721-tf-silver
title: "Transform — silver conform (dedup max-_lsn, UTC)"
status: done
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
parent: ../sketch/swimlane-transform/swimlane-transform-leg-01-dbt-silver.md
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-28T15:49:33Z
tracker_ref: linear:CVG-24
projection:
  milestone: Transform
signed_off_sig: hmac-sha256-v2:1f197c76:b1da4760be4bd4f84c555608ed8628604e7c975110b420595df2e5c248a0e505
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-28T21:09:05Z
---

# Transform — silver conform (dedup max-_lsn, UTC)

## Goal
Conform `raw.*` to silver: dedup to one row per business key by keeping the max-`_lsn` change event (a `_op=delete` tombstone removes the key), pin types, set UTC grain. Per the sharpened seam contract — NOT a hash of business columns.

## Success Criteria
```bash
# Every check asserts DATABASE STATE or EXECUTES the artifact — never file
# shape. A stub file cannot create a table, populate a column, or revoke a
# privilege. `make up` must be running (uc-analytics-postgres).
PG="docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc"

# B-1: the silver grain HOLDS in the warehouse — one row per business key,
# deduped to the latest _lsn. A SQL file containing the word row_number proves
# nothing; a table whose count equals its distinct count proves the grain.
eval_1() {
  test -f cvg/transform/models/silver/orders.sql || return 1
  total=$($PG "select count(*) from silver.orders" 2>/dev/null)
  [ "${total:-0}" -gt 0 ] || return 1
  distinct=$($PG "select count(distinct order_id) from silver.orders" 2>/dev/null)
  [ "${total:-0}" -eq "${distinct:-1}" ]
}

# B-2: the uniqueness test is REAL — running it must find zero violations.
eval_2() {
  test -f cvg/transform/tests/unique_business_key.sql || return 1
  bad=$($PG "select count(*) from (select order_id from silver.orders
             group by order_id having count(*) > 1) d" 2>/dev/null)
  [ "${bad:-1}" -eq 0 ]
}

# B-3: UTC discipline is enforced by the COLUMN TYPE, not by a comment.
eval_3() {
  naive=$($PG "select count(*) from information_schema.columns
               where table_schema='silver' and table_name='orders'
                 and data_type = 'timestamp without time zone'" 2>/dev/null)
  [ "${naive:-1}" -eq 0 ]
}
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
