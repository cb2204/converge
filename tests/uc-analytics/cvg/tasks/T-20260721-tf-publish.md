---
id: T-20260721-tf-publish
title: "Transform — publish gold as DuckLake (Q-SET-1 coverage)"
status: ready
format_version: 3
profile: lite
effort: S
budget_iterations: 8
agent: any
depends_on: [T-20260721-tf-gold]
touches_paths: []
creates_paths:
  - cvg/transform/publish/ducklake.py
  - cvg/transform/tests/qset1_coverage.py
source_note: "R5.R — Pass 5B tasking of the backbone (Fork B, task-driven)"
created: 2026-07-21T00:00:00Z
parent: ../sketch/swimlane-transform/swimlane-transform-leg-03-ducklake.md
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-28T15:49:35Z
tracker_ref: linear:CVG-26
projection:
  milestone: Transform
signed_off_sig: hmac-sha256-v2:1f197c76:9a5272714b37b8794c83bf26eb41877be91aa67275462b88de11d47544b6d474
---

# Transform — publish gold as DuckLake (Q-SET-1 coverage)

## Goal
Publish gold as serving-ready DuckLake tables shaped to the frozen Q-SET-1, via an atomic snapshot swap (per the seam contract). Every Q-SET-1 question maps to a gold table; the serve lane needs nothing below the contract.

## Success Criteria
```bash
# Every check asserts DATABASE STATE or EXECUTES the artifact — never file
# shape. A stub file cannot create a table, populate a column, or revoke a
# privilege. `make up` must be running (uc-analytics-postgres).
PG="docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc"

# B-1: the publisher RUNS and the published snapshot carries the same row count
# as the gold table it published. A stub cannot move rows.
eval_1() {
  test -f cvg/transform/publish/ducklake.py || return 1
  python3 cvg/transform/publish/ducklake.py >/dev/null 2>&1 || return 1
  published=$(python3 cvg/transform/publish/ducklake.py --count 2>/dev/null | grep -oE '[0-9]+' | head -1)
  gold=$($PG "select count(*) from gold.revenue" 2>/dev/null)
  [ -n "$published" ] && [ "${published:-0}" -eq "${gold:-1}" ]
}

# B-2: Q-set 1 coverage is EXECUTED, and every question must be answered.
eval_2() {
  test -f cvg/transform/tests/qset1_coverage.py || return 1
  python3 cvg/transform/tests/qset1_coverage.py >/dev/null 2>&1
}
```

## Validation Card
```yaml
success_criteria:
  - {id: eval_1, description: gold published via atomic DuckLake snapshot, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_2, description: every Q-SET-1 question maps to a gold table, runnable: bash, check_type: deterministic, terminal: true, expected_duration_sec: 3}
retry_policy:
  max_iterations: 8
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
eval_1 && eval_2
```
