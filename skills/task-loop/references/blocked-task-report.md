# Blocked Task Report

Emitted by Pass 8 (The Loop) when an issue's own eval stays **RED** — the
`budget_iterations` are exhausted, the failure is a broken eval, or it is an
**upstream gap** the loop must not paper over. A blocked report is a first-class
output: it is what you produce *instead of* a PR. No green eval, no PR — but also
no silent give-up. This report names exactly what failed and who owns the fix.

> The loop owns ONE task deeply and never wanders. When a task cannot go green
> from inside its own `touches_paths`, the honest move is to surface the gap,
> not to widen scope or hand-wave the eval.

---

## Report

- **issue:** `<issue-id>`
- **task-spec:** `<task-id>` (`tasks/<task-id>.md`)
- **branch (intended):** `<branch>`
- **agent:** `<agent>`
- **verdict:** RED (eval did not exit 0)
- **iterations used / budget:** _(n of `budget_iterations`)_

## Failing eval

Which `eval_N()` / Exit Check assertion failed, and what it was asserting
(e.g. `eval_2` — bronze row-count parity with `raw.*`; `eval_1` —
`dbt build --select <model>` did not complete successfully; the FastAPI endpoint
did not return the contracted 200; the MCP tool did not return the gold-backed
payload).

- **failing eval id:** _(e.g. `eval_2`)_
- **what it asserts:** _(one line)_

## Last output

The verbatim tail of the last eval run — the real error, not a paraphrase.
Include the failing command's stderr and any log tail the spec points to
(e.g. `/tmp/bronze_build.log`).

```
<paste the last eval output here>
```

## Suspected upstream gap

Why this cannot be settled from inside `<task-id>`'s own `touches_paths`. Name
the concrete missing/wrong thing, not just "it fails":

- [ ] **Precondition unmet** — the pipeline state the eval assumes is absent
      (e.g. `raw.*` not landed: run `make seed && make land`; the warehouse at
      `src/warehouse/warehouse.duckdb` is missing or stale).
- [ ] **A cited ADR is missing or wrong** — the spec references
      `docs/adrs/NNNN-*.md` that does not exist or decides the wrong thing.
- [ ] **A dependency (`depends_on`) is not merged** — an upstream task-spec this
      one builds on has not landed (e.g. gold needs silver; silver needs bronze).
- [ ] **The harness is missing** — no `.claude/` agent + KB for the tech this
      task touches (dbt / DuckDB / FastAPI / MCP), so `--agent` cannot ground.
- [ ] **The eval itself is broken** — a syntax error / unbound variable in the
      task-spec's bash, not a real assertion failure. Do **not** hack the eval to
      pass; the fix belongs upstream in the task-spec.
- [ ] **Genuinely not settleable in budget** — the task is under-specified or
      larger than one unit and needs re-cutting.

## Which pass owns it

Route the fix to the Converge pass that owns the gap — do not fix it here:

| Suspected gap | Owning pass |
|---|---|
| Precondition / repo terrain wrong (raw not landed, warehouse stale) | operator / `make seed`+`make land` before re-dispatch |
| Missing or wrong cited ADR | **Pass 2** (`tech-req-to-adrs`) |
| Wrong swimlane seam / build order | **Pass 3** (`reqs-to-swimlane-plans`) |
| Eval broken / task under-specified / not atomic | **Pass 5B** (`task-spec`) |
| Missing agent + KB for the tech | **Pass 6** (`stack-to-harness`) |
| Dispatch order / dependency not yet merged | future **CI/CD Manager** (not this loop) |

## Next action

State the single next step: which pass to re-open with what change, or the
precondition to satisfy before re-dispatching `--issue <issue-id>`. Then stop.
The loop does not escalate, hop tasks, or open a PR from a red eval.
