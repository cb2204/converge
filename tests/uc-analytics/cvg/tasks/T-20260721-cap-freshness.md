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
execution_backend: any
---

# Capture — freshness + by-principal instrumentation (Dagster)

## Goal
Make R-1 and R-2 observable: p99 write->queryable freshness (<=5min), the by-principal analytical-query count on the source (non-capture principals = 0), and the feed overhead (<=20%, D6), via Dagster asset checks + sensors.

## Success Criteria
```bash
eval_1() { test -f cvg/capture/dagster/freshness_check.py && grep -qEi "p99|300|5 ?min" cvg/capture/dagster/freshness_check.py; }
eval_2() { test -f cvg/capture/dagster/principal_count_check.py && grep -qEi "principal|connection.?log" cvg/capture/dagster/principal_count_check.py; }
eval_3() { test -f cvg/capture/dagster/overhead_probe.py && grep -qEi "overhead|feed.?off|20" cvg/capture/dagster/overhead_probe.py; }
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
