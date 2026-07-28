# Handoff — T-20260721-cap-steelthread

**Why the loop stopped:** iteration budget exhausted (1)


## Last failure

```
{"is_error":false,"duration_api_ms":454414,"num_turns":34,"stop_reason":"end_turn","session_id":"e57c2873-8b65-4c8d-b74c-79d6a7fe9b11","total_cost_usd":2.9102370000000004,"usage":{"input_tokens":51,"cache_creation_input_tokens":106624,"cache_read_input_tokens":2025234,"output_tokens":33245,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":106624,"ephemeral_5m_input_tokens":0},"inference_geo":"not_available","iterations":[{"input_tokens":2,"output_tokens":1276,"cache_read_input_tokens":105377,"cache_creation_input_tokens":1247,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":1247},"type":"message"}],"speed":"standard"},"modelUsage":{"claude-opus-5[1m]":{"inputTokens":51,"outputTokens":33245,"cacheReadInputTokens":2025234,"cacheCreationInputTokens":106624,"webSearchRequests":0,"costUSD":2.9102370000000004,"contextWindow":1000000,"maxOutputTokens":64000,"canonicalModel":"claude-opus-5","provider":"firstParty"}},"permission_denials":[],"terminal_reason":"completed","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required","subtype":"success","api_error_status":null,"result":"I did not settle this task green. It is **blocked on an upstream harness bug**, and the report is at `cvg/loop/T-20260721-cap-steelthread/BLOCKED.md`.\n\n## What was actually wrong\n\nThe RED is not in the task's code. All three evals failed in `0s` — too fast to have touched Postgres. Each eval opens with `test -f cvg/capture/<file>`, and the runner executes them from the **wrong directory**:\n\n- `skills/task-spec/scripts/run-task-spec.sh:205` does `cd \"$GIT_ROOT\"` — the worktree root, which has no `cvg/`.\n- The workspace is nested at `tests/uc-analytics/`, which is what the spec's relative paths are written against.\n\nThe correct logic already exists in `skills/task-loop/scripts/run-issue-eval.sh:124-130`, with a comment stating exactly this (\"*a spec that creates `cvg/capture/orders.py` means relative to its own workspace, not to whatever repo happens to contain it*\") — then line 361 delegates to `run-task-spec.sh`, which discards it. The correct value is computed and never used.\n\nCorroborating: `check-path-policy.py` resolves `fs.write` scope **workspace**-relative (it hard-errors without `--repo tests/uc-analytics`). So the contract and the runner disagree about the root, and the contract's reading is authoritative.\n\n## The deliverable itself is green\n\nI reset the cluster to virgin state (`wal_level=replica`, no capture role, no `raw` schema, seeded 200 orders) and ran the same eval bodies with the workspace as CWD:\n\n```\neval_1 (COLD, includes wal_level flip + restart) => 0\neval_2 => 0    eval_3 => 0    EXIT CHECK => 0\n```\n\nReal WAL LSNs decoded from pgoutput, `_source_committed_at` from the COMMIT record, all five contract columns; `capture_reader` holds `REPLICATION` + `SELECT` on `public.orders` with **no** `_control` USAGE. The decisive check: with the cluster fully provisioned and green, the runner *still* reported `0s × 3` — proving the failure is CWD, not database state.\n\n## Why I couldn't fix it in scope\n\n`test -f cvg/capture/probe_commit_to_answer.py` with CWD=git root requires a `cvg/capture/` tree at the git root — outside the sealed scope, invisible to the settlement guard (`git diff --relative` scopes it away), and it would duplicate product artifacts into the Converge tool repo. The only real fix is one line in the grader, which I'm forbidden to edit. So: blocked, no PR, routed to Pass 5.\n\nTwo notes:\n- **No commit made.** Nothing under `fs.write` scope needed changing — the four artifacts were already correct at `f699e1d`. `BLOCKED.md` is framework output under `cvg/loop/`, which the guard exempts and explicitly never stages. Working-tree path policy: `CHECK_PATH_POLICY=PASS`.\n- **`--base main` reports FAIL, pre-existing.** It flags `src/seed/*`, `uv.lock` — the branch's committed history vs `main`. It fails identically with my file removed, so I introduced no violation.\n- I left the cluster provisioned (`raw.orders`=2, slot active). `public.orders` is 202: 200 seeded + 2 probe inserts, which the spec's Goal mandates. I removed the 4 rows from my earlier diagnostic runs to keep the seed-42 fixture deterministic.\n\nOne spec inconsistency worth reconciling while Pass 5 is open: the **Why** says *\"Accepted only on `execution_backend: glm`\"* but the frontmatter declares `claude`.","ttft_ms":3999,"ttft_stream_ms":3013,"time_to_request_ms":344,"type":"result","duration_ms":478608,"uuid":"8a96beeb-f0ad-451e-aa47-7b8183adcd08"}
Runtime contract ready: task hash, evidence, topology, and guards verified.
CHECK_RUNTIME_CONTRACT=PASS
issue:  /var/folders/zf/r0gsd5px2v9_q24j3tfnyb5c0000gn/T/cvg-wt-T-20260721-cap-steelthread.XXXXXX.mKdvwX3HHA/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md
task:   T-20260721-cap-steelthread
title:  "Capture steel thread — one domain (orders) end-to-end off the WAL"
spec:   /var/folders/zf/r0gsd5px2v9_q24j3tfnyb5c0000gn/T/cvg-wt-T-20260721-cap-steelthread.XXXXXX.mKdvwX3HHA/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md
----------------------------------------------------------------------
[fail] eval_1 (0s)
[fail] eval_2 (0s)
[fail] eval_3 (0s)
Exit Check: fail (0s)
----------------------------------------------------------------------
RED
issue: /var/folders/zf/r0gsd5px2v9_q24j3tfnyb5c0000gn/T/cvg-wt-T-20260721-cap-steelthread.XXXXXX.mKdvwX3HHA/tests/uc-analytics/cvg/tasks/T-20260721-cap-steelthread.md  task: T-20260721-cap-steelthread
The task's own eval exited non-zero. Do NOT open a PR.
Feed the failing output above back to --agent and revise inside touches_paths,
or (if the budget is exhausted / it is an upstream gap) emit a blocked-task report:
  .claude/skills/task-loop/references/blocked-task-report.md
```

## Next steps for whoever picks this up

1. Read the failing eval above — it is the definition of done.
2. `cvg loop --issue T-20260721-cap-steelthread --resume` continues from iteration 1.
3. If the gap is upstream (a wrong ADR, a wrong plan, a wrong spec),
   fix the pass that owns it rather than this task.
