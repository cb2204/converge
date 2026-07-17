---
name: task-loop
description: The single execution loop for Converge Pass 8 (The Loop). Takes ONE issue (--issue N passed by a human or CI), reads its task-spec plus the cited ADRs and the grounded harness, cuts a branch, writes code, and runs the task's own eval in a tight local refinement loop until GREEN, then opens a PR that closes the issue. Use when a user or CI says "run issue N", "execute this task", "build task T-...", "work the loop", or "drive this issue to a green-eval PR". Knows one task deeply and never picks which task to run. Engine-agnostic via flags (--issue N required, --agent claude|codex|kimi). Do NOT use to choose or fan out across tasks — dispatch and PR-watching are a future CI/CD Manager pass, not this skill.
metadata:
  version: "0.3.0"
license: MIT
compatibility: "Converge chain Pass 8; consumes tasks/T-*.md + docs/adrs/*.md + .claude/ harness; any stack"
---

# task-loop — Pass 8 · The Loop (the execution loop)

The single EXECUTION loop of the Converge chain. Take exactly ONE issue that was handed to you (`--issue N`), read its task-spec + the ADRs it cites + the grounded harness, cut a branch, write the code, and run **that task's own eval** in a tight local loop until it is GREEN — then open a PR that closes the issue. This is the loop you build now.

## Important — read these rules first

- **You never pick the task.** `--issue N` is required and comes from outside (a human, or CI). Absence of `--issue N` is an error, not an invitation to triage the backlog. Choosing *which* issue to run is the Manager's job, and the Manager is a future CI/CD pass (see below), not this skill.
- **Converged = the eval passed, not "feels done".** The merge gate is the exact eval command the task-spec carries, run in a clean subshell and exiting 0 — never an eyeballed diff. No green eval, no PR.
- **READ before ACT is non-negotiable.** Load the task-spec eval, the cited ADRs, and the harness before writing a line. Code written before you understand the eval is code aimed at nothing.
- **Stay inside the task.** Respect `touches_paths` and `do-not-touch` from the spec. One task, deeply — never wander into a sibling task or refactor the world.
- **This is Pattern 3 (iterative refinement).** RED feeds the exact failure back and revises in a bounded local loop; it does not escalate or hop tasks. A task that cannot go green is surfaced as a blocked report, never papered over.

## The Manager is a future CI/CD pass

There is **no separate Manager / fleet-orchestrator skill**, and this skill references none. The two-loop design is collapsed: `task-loop` *is* the execution loop. The **Manager concern** — which issue runs, when, how many in parallel, watching PRs, settling dependencies, dispatching the next ready issue — is a **future, separate concern that lives in CI/CD (GitHub Actions)**, not an in-session skill. A human or a CI job passes you `--issue N`; you drive that one issue to a green-eval PR and stop. Fan-out is configured around this loop later; it is not built here.

## Inputs / Outputs / Gate

| | Artifact | Path |
|---|----------|------|
| **IN** | ONE task-spec (the issue) + the ADRs it cites + the grounded harness | `tasks/T-<id>.md` · `docs/adrs/*.md` · `.claude/` |
| **OUT** | A Pull Request that closes the issue (branch + diff + green eval in the body), OR an explicit blocked-task report | PR on a `task/<id>-<slug>` branch |
| **GATE** | The task's own eval is **GREEN** — the exact `eval_N()` / Exit Check command from the spec exits 0, run not read | `bash`-run eval from `tasks/T-<id>.md` |

The eval is whatever the task-spec ships — it is written for *your* stack, not assumed to be any particular one. It typically drives the project end-to-end (prep/ingest → transform → assert the output/contract layer → optionally exercise the serving layer) and asserts the far end. The task-spec already ships this eval as runnable bash; you run it, you do not re-invent it. (For example, in a dbt/warehouse project the eval might run the project's build step, then the transform step, then query the published tables — but any stack's eval works the same way: run it, do not read it.)

## Flags

| Flag | Values | Default | Meaning |
|------|--------|---------|---------|
| `--issue N` | issue id / task id | **required** | The single issue this loop owns. No default — absence is an error. You do not re-pick it. |
| `--agent` | `claude` \| `codex` \| `kimi` | `claude` | The coding engine that ACTS. `kimi` for mechanical, tightly-specced work; `claude` for judgment work (contract/interface design); `codex` when passed. |

The engine is a flag, never baked into the skill name. Whoever passes `--issue N` may also pin `--agent`; the loop does not change the issue.

## Instructions

### Step 1 — READ (load the task-spec, the ADRs, the harness)

Resolve `--issue N` to `tasks/T-<id>.md` and read it fully: `goal`, `touches_paths`, anti-patterns, `do-not-touch`, and — most important — its **Success Criteria eval bodies + Exit Check**. Read every ADR the spec cites under `docs/adrs/` so decided questions are not re-litigated. Confirm the harness is present (`.claude/` agents + KBs for the tech the task touches) so `--agent` grounds in the matching tech KB.

Stop conditions (do not code, emit a blocked report instead):
- No `--issue N` supplied → this loop never picks a task.
- The task-spec is missing or `signed_off: false` → upstream gap (Pass 5B gate not passed).
- Cited ADRs or the harness are missing → upstream gap (Pass 2 / Pass 6).

### Step 2 — ACT (cut a branch, write the code)

Cut a fresh branch `task/<id>-<slug>` off the default branch — never commit to `main`. Hand the spec + ADRs + harness to `--agent` and write code for THIS task only, staying inside `touches_paths` and honoring `do-not-touch`. The shape of the code is whatever the task calls for — a transform, an output/contract table, a serving-layer endpoint (API, MCP tool, etc.) — constrained by the spec's `touches_paths` and the contracts the harness and cited ADRs pin down. (For example, in a dbt/warehouse project this might be a transform model over your source tables, a published mart, or an endpoint over those published tables — but the loop is the same for any stack.)

### Step 3 — EVAL (run the task's own eval)

Run the exact eval the spec carries, in a clean subshell, via the bundled runner:

```bash
bash .claude/skills/task-loop/scripts/run-issue-eval.sh --issue <id>
```

It extracts the `eval_N()` bodies + Exit Check from `tasks/T-<id>.md`, runs each under `set -euo pipefail`, and reports **GREEN** (Exit Check exits 0) or **RED** (with the failing eval's output). What "green" means is whatever the spec's eval asserts for your stack — a transform passing its tests, an output table returning the contracted shape, a serving endpoint returning the contracted response, etc. (For example, in a dbt/warehouse project: the transform step and its schema tests pass, a published table query returns the contracted shape, an API endpoint returns a contracted 200.) Run it — do not eyeball the diff.

### Step 4 — SETTLE (RED → revise locally · GREEN → open the PR)

- **RED:** feed the exact eval output back to `--agent`, revise inside `touches_paths`, and re-run Step 3. This is the bounded local refinement loop (Pattern 3) — it never leaves this issue and never touches another task. Respect the spec's `budget_iterations`; if the budget is exhausted or the failure is an upstream gap, stop and emit a **blocked-task report** (what failed, the last eval output, the suspected upstream gap).
- **RED twice with the same failure → stop patching, start diagnosing.** Two consecutive REDs on the same assertion with no new hypothesis means the loop is guessing, and guessing burns `budget_iterations` without converging. Switch modes inside the same budget: (1) **reproduce minimally** — isolate the smallest input/command that shows the failure; (2) **hypothesize** — state in one sentence *why* it fails; (3) **verify the hypothesis** — with a read or an instrumented run, *before* writing the fix; (4) fix once, re-run the eval. A fix applied to a confirmed cause converges in one iteration; a fix applied to a guess converges by accident.
- **GREEN:** open a PR on the `task/<id>-<slug>` branch that closes the issue, with the green eval output pasted into the body. The PR is the unit of merge; only a green eval earns it. Then stop — merge order and dependency settling are the future CI/CD Manager's job, not this loop's.

## Gate — confirm before leaving this pass

- [ ] Exactly one issue was worked — the one named by `--issue N`; no other task was touched.
- [ ] The task-spec eval, the cited ADRs, and the harness were all READ before any code.
- [ ] Work happened on a `task/<id>-<slug>` branch, never directly on `main`.
- [ ] The task's eval was RUN (not eyeballed) and is GREEN — the exact command exits 0.
- [ ] The diff stays inside `touches_paths` and respects `do-not-touch`.
- [ ] Output is either a PR that closes the issue (green eval in the body) OR an explicit blocked-task report.

When these hold, the issue has converged: green eval, branch, PR.

## Examples

**Example 1 — "run issue T-20260625-staging-views" (illustrated with a dbt/warehouse stack)**
Read the spec (staging views over your source tables, `touches_paths: transform/models/staging`), read cited ADRs, confirm the harness. Branch `task/staging-views`. `--agent kimi` writes the staging view models. Run `run-issue-eval.sh --issue T-20260625-staging-views` → RED (row parity off by tagged rows). Feed the output back, fix the pass-through of tagged rows, re-run → GREEN. Open a PR closing the issue with the eval output in the body. → **Result:** one PR, green eval, no other task touched. (The stack here is just illustrative — the same READ → ACT → EVAL → SETTLE loop runs for any stack the spec targets.)

**Example 2 — "execute this task" with no issue given**
No `--issue N`. → **Result:** stop and report that the loop never picks a task; a human or CI must pass `--issue N` (choosing which issue is the future CI/CD Manager's job).

**Example 3 — "build task T-...-published-tables" but its ADR is missing**
Spec cites an ADR that does not exist under `docs/adrs/`. → **Result:** emit a blocked-task report naming the missing ADR (a Pass 2 gap) — do not guess the decision.

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| Loop asks which task to run | No `--issue N` | Pass `--issue N`; this loop never triages. Fan-out is the future CI/CD Manager. |
| Eval fails with "syntax error"/"unbound variable" | Broken eval bash, not a real assertion failure | Fix belongs upstream in the task-spec (Pass 5B gate). Emit a blocked report, don't hack the eval. |
| Eval RED after budget exhausted | Task not settleable in `budget_iterations`, or upstream gap | Stop; emit blocked-task report with last eval output + suspected gap. Do not open a PR. |
| Green diff but you want to "also fix" a nearby file | Scope creep past `touches_paths` | Stay in scope. Open a new task-spec for the other change; this loop owns one task. |
| Committed to `main` | Skipped the branch step | Branch first (`task/<id>-<slug>`); revert `main`. The PR is the unit of merge. |
