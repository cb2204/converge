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
signed_off_at: 2026-07-24T14:26:38Z
signed_off_sig: hmac-sha256-v1:1f197c76:c92d8eaff6a95d62bf5303d22530e9589a7a297fa49d18260cdc84336cbd4b0f
---

# Serve — honest answers (as-of, staleness alert, audit)

## Goal
Every answer carries its as-of freshness; a feed stoppage past 15 min fires an alert no later than 20 min after the last update (R-4); a staleness event beyond the 5-min floor records its start, duration, and domains (R-10). A late feed is visible, never fabricated.

## Success Criteria
```bash
eval_1() { test -f cvg/serve/api/answers.py && grep -qEi "as.?of|freshness|gold_as_of" cvg/serve/api/answers.py; }
eval_2() { test -f cvg/serve/api/staleness_alert.py && grep -qEi "20|1200|alert|staleness" cvg/serve/api/staleness_alert.py; }
eval_3() { test -f cvg/serve/tests/test_freshness.py && grep -qEi "audit|duration|record" cvg/serve/tests/test_freshness.py; }
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
