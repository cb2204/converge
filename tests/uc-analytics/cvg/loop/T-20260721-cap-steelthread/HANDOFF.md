# Handoff — T-20260721-cap-steelthread

**Why the loop stopped:** iteration budget exhausted (2)


## Last failure

```
No prompt provided via stdin.
Runtime contract ready: task hash, evidence, topology, and guards verified.
CHECK_RUNTIME_CONTRACT=PASS
issue:  /Users/luanmorenomaciel/GitHub/converge/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md
task:   T-20260721-cap-steelthread
title:  "Capture steel thread — one domain (orders) end-to-end off the WAL"
spec:   /Users/luanmorenomaciel/GitHub/converge/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md
----------------------------------------------------------------------
[fail] eval_1 (0s)
[fail] eval_2 (0s)
[fail] eval_3 (0s)
Exit Check: fail (0s)
----------------------------------------------------------------------
RED
issue: /Users/luanmorenomaciel/GitHub/converge/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md  task: T-20260721-cap-steelthread
The task's own eval exited non-zero. Do NOT open a PR.
Feed the failing output above back to --agent and revise inside touches_paths,
or (if the budget is exhausted / it is an upstream gap) emit a blocked-task report:
  .claude/skills/task-loop/references/blocked-task-report.md
```

## Next steps for whoever picks this up

1. Read the failing eval above — it is the definition of done.
2. `cvg loop --issue T-20260721-cap-steelthread --resume` continues from iteration 2.
3. If the gap is upstream (a wrong ADR, a wrong plan, a wrong spec),
   fix the pass that owns it rather than this task.
