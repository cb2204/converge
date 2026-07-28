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
parent: ../sketch/swimlane-capture/swimlane-capture-leg-02-dlt.md
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-28T15:49:31Z
tracker_ref: linear:CVG-22
projection:
  milestone: Capture
signed_off_sig: hmac-sha256-v2:1f197c76:ff6e3abe632a84977cf4f37d9a163df0b6b8be01a83c7fca5b9d02df9fed79a0
---

# Capture — land all four domains into raw.*

## Goal
Fatten the thread: land customers, products, orders, payments into `raw.*` as change records, each row carrying its capture as-of + measured lag. Honors the frozen `raw.*` seam contract; `_control` never captured (ADR-0001 fence).

## Success Criteria
```bash
# Every check asserts DATABASE STATE or EXECUTES the artifact — never file
# shape. A stub file cannot create a table, populate a column, or revoke a
# privilege. `make up` must be running (uc-analytics-postgres).
PG="docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc"

# B-1: all four domains land off the WAL in the frozen change-record shape.
eval_1() {
  for d in customers products orders payments; do
    test -f "cvg/capture/pipelines/$d.py" || return 1
    cols=$($PG "select count(*) from information_schema.columns
                where table_schema='raw' and table_name='$d'
                  and column_name in ('_lsn','_op','_captured_at','_source_committed_at')" 2>/dev/null)
    [ "${cols:-0}" -eq 4 ] || return 1
  done
}

# B-2: every domain actually carries rows — a landed table with no change
# records has not captured anything.
eval_2() {
  for d in customers products orders payments; do
    n=$($PG "select count(*) from raw.$d" 2>/dev/null)
    [ "${n:-0}" -gt 0 ] || return 1
  done
}

# B-3: the _control fence holds in the cluster, not merely in the source.
eval_3() {
  grep -rq '_control' cvg/capture/pipelines/ && return 1
  role=$($PG "select rolname from pg_roles where rolname like '%capture%' and rolname <> 'postgres' limit 1" 2>/dev/null)
  [ -n "$role" ] || return 1
  fenced=$($PG "select has_schema_privilege('$role','_control','USAGE')" 2>/dev/null)
  [ "$fenced" = "f" ]
}
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
