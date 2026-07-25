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
execution_backend: any
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-25T06:07:48Z
signed_off_sig: hmac-sha256-v2:1f197c76:a3503a95c819c1e500b1c4e63cc6e852a2d16a9de0a9bc162ee489eab07ff7b2
tracker_ref: linear:CVG-26
projection:
  milestone: Transform
---

# Transform — publish gold as DuckLake (Q-SET-1 coverage)

## Goal
Publish gold as serving-ready DuckLake tables shaped to the frozen Q-SET-1, via an atomic snapshot swap (per the seam contract). Every Q-SET-1 question maps to a gold table; the serve lane needs nothing below the contract.

## Success Criteria
```bash
eval_1() { test -f cvg/transform/publish/ducklake.py && grep -qEi "snapshot|atomic|ducklake" cvg/transform/publish/ducklake.py; }
eval_2() { test -f cvg/transform/tests/qset1_coverage.py && grep -qEi "q.?set.?1|coverage|question" cvg/transform/tests/qset1_coverage.py; }
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
