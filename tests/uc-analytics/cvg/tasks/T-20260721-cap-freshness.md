---
id: T-20260721-cap-freshness
title: "Capture — freshness + by-principal instrumentation (Dagster)"
status: ready
format_version: 3
profile: lite
effort: M
budget_iterations: 12
agent: any
depends_on: [T-20260721-cap-alldomains]
touches_paths: []
creates_paths:
  - cvg/capture/dagster/freshness_check.py
  - cvg/capture/dagster/principal_count_check.py
  - cvg/capture/dagster/overhead_probe.py
source_note: "R5.R — Pass 5B tasking of the backbone (Fork B, task-driven)"
created: 2026-07-21T00:00:00Z
parent: ../sketch/swimlane-capture/swimlane-capture-leg-03-dagster.md
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-28T15:49:32Z
tracker_ref: linear:CVG-23
projection:
  milestone: Capture
signed_off_sig: hmac-sha256-v2:1f197c76:ce9a8fa3a76a5e7d94273f42e83d2fedaa54e7b72de358f78368d8e1f1266d03
---

# Capture — freshness + by-principal instrumentation (Dagster)

## Goal
Make R-1 and R-2 observable: p99 write->queryable freshness (<=5min), the by-principal analytical-query count on the source (non-capture principals = 0), and the feed overhead (<=20%, D6), via Dagster asset checks + sensors.

## Success Criteria
```bash
# Every check asserts DATABASE STATE or EXECUTES the artifact — never file
# shape. A stub file cannot create a table, populate a column, or revoke a
# privilege. `make up` must be running (uc-analytics-postgres).
PG="docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc"

# B-1: freshness is MEASURED in the database, not asserted in a comment. The
# newest change record must be inside the R-1 budget (300s).
eval_1() {
  test -f cvg/capture/dagster/freshness_check.py || return 1
  python3 cvg/capture/dagster/freshness_check.py >/dev/null 2>&1 || return 1
  lag=$($PG "select coalesce(ceil(extract(epoch from now() - max(_captured_at))), 999999) from raw.orders" 2>/dev/null)
  [ "${lag:-999999}" -lt 300 ]
}

# B-2: exactly ONE dedicated capture principal exists — the check is only
# meaningful if the cluster really has a single distinct role.
eval_2() {
  test -f cvg/capture/dagster/principal_count_check.py || return 1
  python3 cvg/capture/dagster/principal_count_check.py >/dev/null 2>&1 || return 1
  n=$($PG "select count(*) from pg_roles where rolname like '%capture%' and rolname <> 'postgres'" 2>/dev/null)
  [ "${n:-0}" -eq 1 ]
}

# B-3: the overhead probe runs against the live source and reports a bounded
# number it measured itself.
eval_3() {
  test -f cvg/capture/dagster/overhead_probe.py || return 1
  out=$(python3 cvg/capture/dagster/overhead_probe.py 2>/dev/null)
  printf '%s' "$out" | grep -qE '[0-9]' || return 1
  pct=$(printf '%s' "$out" | grep -oE '[0-9]+' | head -1)
  [ "${pct:-100}" -le 20 ]
}
```

## Validation Card
```yaml
success_criteria:
  - {id: eval_1, description: p99 write-to-queryable freshness check exists, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_2, description: by-principal query-count check, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_3, description: feed overhead measured (<=20%), runnable: bash, check_type: deterministic, terminal: true, expected_duration_sec: 3}
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
