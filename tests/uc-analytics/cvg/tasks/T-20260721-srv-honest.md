---
id: T-20260721-srv-honest
title: "Serve — honest answers (as-of, staleness alert, audit)"
status: ready
format_version: 3
profile: lite
effort: M
budget_iterations: 12
agent: any
depends_on: [T-20260721-srv-core]
touches_paths: []
creates_paths:
  - cvg/serve/api/answers.py
  - cvg/serve/api/staleness_alert.py
  - cvg/serve/tests/test_freshness.py
source_note: "R5.R — Pass 5B tasking of the backbone (Fork B, task-driven)"
created: 2026-07-21T00:00:00Z
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-25T08:17:47Z
tracker_ref: linear:CVG-28
projection:
  milestone: Serve
signed_off_sig: hmac-sha256-v2:1f197c76:53d9950fffee1c64a300af86876a516b68174894565ab3fcf8cad76fd0586381
---

# Serve — honest answers (as-of, staleness alert, audit)

## Goal
Every answer carries its as-of freshness; a feed stoppage past 15 min fires an alert no later than 20 min after the last update (R-4); a staleness event beyond the 5-min floor records its start, duration, and domains (R-10). A late feed is visible, never fabricated.

## Success Criteria
```bash
# Every check asserts DATABASE STATE or EXECUTES the artifact — never file
# shape. A stub file cannot create a table, populate a column, or revoke a
# privilege. `make up` must be running (uc-analytics-postgres).
PG="docker exec uc-analytics-postgres psql -U postgres -d ecommerce -tAc"

# B-1: every answer carries an as_of the WAREHOUSE agrees with — the API cannot
# invent a freshness stamp that gold does not support.
eval_1() {
  test -f cvg/serve/api/answers.py || return 1
  stamp=$(python3 cvg/serve/api/answers.py --as-of 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  [ -n "$stamp" ] || return 1
  known=$($PG "select count(*) from gold.revenue where as_of::date = '$stamp'::date" 2>/dev/null)
  [ "${known:-0}" -gt 0 ]
}

# B-2: the staleness alert FIRES when data is stale — asserted by running it
# against the live warehouse, not by grepping for the number 20.
eval_2() {
  test -f cvg/serve/api/staleness_alert.py || return 1
  python3 cvg/serve/api/staleness_alert.py --selftest >/dev/null 2>&1
}

# B-3: the freshness audit records durations that actually exist.
eval_3() {
  test -f cvg/serve/tests/test_freshness.py || return 1
  python3 cvg/serve/tests/test_freshness.py >/dev/null 2>&1
}
```

## Validation Card
```yaml
success_criteria:
  - {id: eval_1, description: every answer carries its as-of, runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_2, description: staleness alert fires within 20 min (R-4), runnable: bash, check_type: deterministic, terminal: false, expected_duration_sec: 3}
  - {id: eval_3, description: staleness events are audited (R-10), runnable: bash, check_type: deterministic, terminal: true, expected_duration_sec: 3}
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
