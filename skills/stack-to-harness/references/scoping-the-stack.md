# Scoping the stack — mapping `tasks/T-*.md` paths to the tech set

> **Purpose:** the one judgment call in Pass 6. Read the in-scope Task-Specs, detect exactly which techs the work touches, and record that set as `TECHS`. The harness is fitted to this set and nothing else.
> **Owner skill:** `stack-to-harness` (Converge Pass 6 · Harness)
> **The scoped set is whatever your tasks touch** — it might be one tech or five. It is derived per project, never assumed.

---

## The rule in one line

**A tech is in scope iff an in-scope task touches it.** Not the ADRs, not the README, not "the stack diagram" — the tasks. Tasks are the requirements; the harness is fitted to what they need, never built ahead of them. That is why Tasking (5B) runs *before* Harness (6): you can only scope the stack once the tasks exist.

## What to read (and what to ignore)

For each `tasks/T-*.md`, three signals carry the mapping — in priority order:

1. **`touches_paths:`** (frontmatter) — the strongest signal. It names the exact directories the task writes. Map each path to the tech that owns it (a transform-layer path → your transform tool; a serving-layer path → your serving tech).
2. **The body** — the "Ship a …" paragraph and the eval blocks. When a `touches_paths` directory is shared by more than one tech (for example, a single `serving/` dir that could be an HTTP API *or* an agent-callable tool), the body disambiguates by naming the specific files or entrypoints.
3. **`tags:`** — a confirmation, not a source. Tags corroborate the path read; never scope off tags alone.

**Ignore the `agent:` field.** It is an execution-backend hint, not a tech signal — if every task carries the same value (e.g. `any`), scoping off `agent:` would scope nothing.

## The mapping (build it from your own tasks' real paths)

Read your tasks and build a path-to-tech table grounded in the directories they actually write. The principle is one-directory-to-one-owning-tech, with a note when a path implies a second tech (e.g. a transform tool that emits SQL in a particular engine's dialect pulls that engine into scope too).

**Example — a dbt/warehouse project.** Suppose the in-scope tasks touch a warehouse transform layer, an analytical query engine, and a serving layer. The mapping might read:

| Path / signal in the task | Tech | Why |
|---|---|---|
| `transform/models/**` (bronze, silver, gold) | `dbt` | dbt models — the transform layer lives here |
| `transform/models/sources.yml`, `transform/dbt_project.yml` | `dbt` | dbt project + source config |
| `transform/macros/**` | `dbt` **and** `duckdb` | Jinja macros are dbt; the SQL they emit is DuckDB dialect |
| the project's warehouse file, its SQL, its read-only connection | `duckdb` | the analytical engine + its read-only contract |
| `src/serving/api.py`, HTTP routes | `fastapi` | the read-only HTTP serving layer |
| `src/serving/mcp_server.py`, MCP tools | `mcp` | the agent-callable transport over the same query core |

Your own table will name your own tools and paths. The shape — path → tech, with a "why" — is what carries over.

## Worked example — reading a task set

The point of the exercise is to run down each task, read its `touches_paths` and body signal, assign techs, then take the **union of the columns** as `TECHS`.

**Example — a dbt/warehouse project.** A set of tasks shipping warehouse transform models plus a serving layer might resolve like this:

| Task | `touches_paths` | Body signal | Techs |
|---|---|---|---|
| `T-…-bronze-views` | `transform/models/bronze`, `sources.yml` | "Bronze dbt views" | **dbt** (+ duckdb dialect) |
| `T-…-silver-conform` | `transform/models/silver` | "Silver dbt tables" | **dbt** (+ duckdb) |
| `T-…-gold-marts` | `transform/models/gold` | "Gold dbt marts + schema.yml" | **dbt** (+ duckdb) |
| `T-…-output-atomic-publish` | `transform/models/gold`, `transform/macros` | shared run-id macro, readers are API/MCP | **dbt** + **duckdb** |
| `T-…-api` | `src/serving` | `src/serving/api.py`, HTTP routes | **fastapi** (reads **duckdb**) |
| `T-…-mcp-tools` | `src/serving` | `src/serving/mcp_server.py` | **mcp** (reuses the same core) |

**Union of the columns → `TECHS = dbt duckdb fastapi mcp`** for that example. Note that `duckdb` is in scope even though no task *names* it in a title: every dbt model compiles to DuckDB SQL, and the serving core opens that warehouse read-only. The engine under the transform layer is a real tech the work touches, so it earns a KB. The general lesson: **a tech an in-scope task depends on is in scope even when no title names it.**

## The never-speculative rule

**Only build harness for techs an in-scope task actually touches. If a tech is not named by any task, leave it out.** The harness is a moat, not a mall — every agent and KB you scaffold is content someone must keep grounded, so an unused one is pure drift.

The rule cuts both ways, and a few recurring cases show how:

- **A source or precondition tech is NOT automatically in scope.** If a tech only appears as an upstream *source* — landed or ingested into your data store before the transform step runs — and no in-scope task ships a deliverable in that tech, it stays out. A data-prep/ingest step is a precondition, not a task's `touches_paths`. *(Example — in a dbt/warehouse project, Postgres feeding the warehouse via an ingest step is the source, not a deliverable; no task writes Postgres DDL, so there is no `postgres-architect`.)* If a future task shipped that tech's deliverable — for example DDL or a tuned source schema — it would enter scope then, and not before.
- **A tech the work directly touches IS in scope even without a title naming it.** Under-scoping is as wrong as over-scoping: do not drop a tech a task needs just because no title advertises it *(see the query-engine case above)*.
- **A tech named only in an ADR or the README does NOT qualify.** Grounding docs describe the terrain; the tasks decide the harness. If a tech appeared in an ADR but no in-scope task touched it, it stays out.
- **Adding one tech later is not a Pass 6 call.** "Add an architect for tech X" is a single additive tech — route it to `agents-kbs-tech-stack` directly (confirm the tech exists in `menu/techs.yaml` first). Pass 6 scopes the harness to the whole task set; it is not for one-off additions.

## Ambiguity — ask once

If a task's path is genuinely dual-use (one directory shared by two techs, such as a serving dir covering both an HTTP API and an agent-callable tool), the body resolves it. If even the body is ambiguous — a path maps to no menu tech, or two techs equally — **ask once before scaffolding.** This is the single human-in-the-loop moment in the pass. Everything downstream (scaffold, closers, quality-gate, cross-tool emit) is deterministic once `TECHS` is fixed.

## After you have `TECHS`

Record the set, then hand it to Step 3 of the SKILL. Every scoped tech must exist in the bundled skill's `menu/techs.yaml`. A scoped tech missing from the menu fails `scaffold.sh` with `TECH not in menu` — add it to the menu first, then re-run. The scaffold is idempotent and refuses to clobber, so re-running after a scope correction is safe.
