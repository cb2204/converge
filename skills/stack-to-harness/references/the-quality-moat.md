# The quality moat — why the harness outlives the project

> **Purpose:** the *why* behind Pass 6. The harness is the one artifact that outlives any single task, any single project, and any single coding agent. It is the standing control plane that makes a commodity agent produce senior-level output. This doc explains the stack-derived / task-derived split, the architect / developer split, and why the moat is durable.
> **Owner skill:** `stack-to-harness` (Converge Pass 6 · Harness)

---

## The claim

The model is a commodity. Any capable coding agent — Claude, Codex, Kimi, Gemini — can write a dbt model or a FastAPI endpoint. What separates a throwaway prototype from a system that holds is **the control plane the agent runs inside**: the paired architect + developer agents per tech, their grounded KBs, the `doctrine.yaml` numeric floors, the rules, and the cross-tool mirrors. That control plane is the **moat**. Pass 6 builds it.

Everything else in Converge is consumed and discarded. A BRD is answered and archived. A tech-spec is superseded. A task is run once and closed. The harness is the only artifact that is *read again on every future task* — so it is the only one worth grounding deeply.

## Stack-derived vs task-derived

This is the load-bearing distinction of the whole pass.

- **Task-derived** = content that exists because *one specific task* asked for it. A task's eval, its acceptance query, its `touches_paths`. It dies with the task.
- **Stack-derived** = content that exists because *the system uses a technology*. The dbt KB exists because the system runs dbt — not because `T-…-bronze-views` named dbt. It outlives every task that touches dbt.

**The tasks only *scope* the stack; they do not *author* the harness.** (See [`scoping-the-stack.md`](scoping-the-stack.md) for the scoping mechanics.) A dbt KB says how dbt materializations, ref-graph discipline, and schema tests work *in general, grounded in this repo* — knowledge that is true across all five dbt tasks and every dbt task not yet written. If you scaffolded the harness from the tasks instead of the stack, you would rebuild it every sprint and it would rot the moment a task closed. Scaffold the tech, not the task.

| | Task-derived | Stack-derived (the harness) |
|---|---|---|
| Exists because | one task asked | the system uses the tech |
| Lifespan | one run, then closed | outlives every task on that tech |
| Example here | `T-…-gold-marts`'s eval | `kb/dbt/` materialization + ref-graph KB |
| Who reads it | the loop, once | every future task-loop on that tech |
| Rebuild cost if lost | re-derive from intent | re-ground the whole stack |

## The architect / developer split

Each in-scope tech gets **two** agents, and the split is a role boundary, not a style choice:

- **`<tech>-architect`** owns *judgment*: trade-off matrices, thresholds, decision frameworks. It plans and reasons. **It has no Bash** — an architect that can run commands starts writing code, and the boundary collapses. In this repo the `duckdb-architect` decides what materializes in DuckDB vs stays in Postgres and designs gold One-Big-Tables for the latency budget; the `dbt-architect` designs the ref-graph boundaries and picks materializations per model.
- **`<tech>-developer`** owns *implementation*: production patterns, tests, fixes. It ships. **It has Bash** — that is how it runs `dbt build`, executes the eval, reads `EXPLAIN`. The `dbt-developer` writes the incremental models and schema.yml tests; the `mcp-developer` implements the FastMCP server whose tools wrap the shared query core.

Both ground in the same real `kb/<tech>/` tree — never a stub. The split is what lets the harness reason *and* build without one mode contaminating the other. The `quality-gate` lint enforces the boundary: Bash in an architect's tools is a BLOCKER, missing Bash on a developer is a BLOCKER.

On top of the pairs sit **three universal closers** — `code-reviewer`, `code-simplifier`, `code-documenter` — installed once per repo. They are **tech-agnostic by interface, tech-aware by grounding**: at runtime each reads `kb/_index.yaml`, sniffs the file's language, and loads the matching tech KB via the **closer-hook protocol**. So the reviewer of a dbt model reviews it *as a dbt expert would*, without a per-tech reviewer. That is how the loop closes: architect plans → developer ships → closers polish, all grounded in one KB.

## Why the moat is durable

1. **It is read on every future task.** The task-loop (Pass 8) grounds the coding agent in the right tech KB before it writes a line. The harness compounds: every task made it, and every task benefits from it.
2. **It is engine-agnostic — one contract, every engine.** The canonical `.claude/` surface is mirrored to `AGENTS.md`, `.cursor/rules/`, and `.github/copilot-instructions.md`. Swap Claude for Codex tomorrow and the new agent inherits the *same* architect/developer contract, the same doctrine floors, the same KBs. The moat does not depend on which model you rent this quarter.
3. **`doctrine.yaml` is the single numeric source of truth.** Thresholds, the Bash boundary, the closer-hook protocol live in one tunable file that every agent and every mirror derives from. Retune once, re-emit, done — no drift across four tools.
4. **It survives the project's problem.** The BRD's E4 question set will change; the gold marts will be re-cut. The dbt KB — how to write a correct incremental model against this warehouse — is still true. The knowledge outlives the requirement that occasioned it.

## What "converged" means for this pass

Not "feels done" — the gate passed. Every tech the tasks touch (`dbt`, `duckdb`, `fastapi`, `mcp`) has its architect + developer + grounded KB; the three closers are wired via the closer-hook protocol; `doctrine.yaml` exists; the cross-tool mirrors are emitted; and `quality-gate.sh --strict` exits 0 with no scaffold drift and nothing speculative. When that holds, the control plane stands — and the loop can start.

## The one caveat

The scaffold seeds KB `TODO` blocks by design. **Closer sharpness is bounded by KB content quality** — an empty KB grounds nothing. The moat is not dug by running the scripts; it is dug by populating the KBs with the real patterns, anti-patterns, and thresholds this stack demands. Pass 6 stands the frame; the frame is only as strong as what you write into it.

> **The model is rented. The harness is owned.**
