# Scoping the stack — mapping `tasks/T-*.md` paths to the tech set

> **Purpose:** the one judgment call in Pass 6. Read the in-scope Task-Specs, detect exactly which techs the work touches, and record that set as `TECHS`. The harness is fitted to this set and nothing else.
> **Owner skill:** `stack-to-harness` (Converge Pass 6 · Harness)
> **Scoped set for this repo:** `dbt duckdb fastapi mcp` — four techs, no more.

---

## The rule in one line

**A tech is in scope iff an in-scope task touches it.** Not the ADRs, not the README, not "the stack diagram" — the tasks. Tasks are the requirements; the harness is fitted to what they need, never built ahead of them. That is why Tasking (5B) runs *before* Harness (6): you can only scope the stack once the tasks exist.

## What to read (and what to ignore)

For each `tasks/T-*.md`, three signals carry the mapping — in priority order:

1. **`touches_paths:`** (frontmatter) — the strongest signal. It names the exact directories the task writes. `transform/models/silver` → `dbt`; `src/serving` → `fastapi` and/or `mcp`.
2. **The body** — the "Ship a …" paragraph and the eval blocks. A task whose `touches_paths` is `src/serving` may be FastAPI *or* MCP; the body disambiguates (`src/serving/api.py` vs `src/serving/mcp_server.py`).
3. **`tags:`** — a confirmation, not a source. `[dbt, gold, medallion]` corroborates the path read; never scope off tags alone.

**Ignore the `agent:` field.** In this repo it is `any` on every task — it is an execution-backend hint, not a tech signal. Scoping off `agent:` would scope nothing.

## The mapping (grounded in this repo's real paths)

| Path / signal in the task | Tech | Why |
|---|---|---|
| `transform/models/**` (bronze, silver, gold) | `dbt` | dbt models — the medallion transform lives here |
| `transform/models/sources.yml`, `transform/dbt_project.yml` | `dbt` | dbt project + source config |
| `transform/macros/**` | `dbt` **and** `duckdb` | Jinja macros are dbt; the SQL they emit is DuckDB dialect |
| `src/warehouse/warehouse.duckdb`, DuckDB SQL, `connect_read_only()` | `duckdb` | the in-process analytical engine + its read-only contract |
| `src/serving/api.py`, `src/serving/queries.py`, FastAPI routes, `make serve` | `fastapi` | the read-only HTTP serving layer |
| `src/serving/mcp_server.py`, MCP tools, `make serve-mcp` | `mcp` | the agent-callable transport over the same query core |

## Worked example — the seven tasks in this repo

| Task | `touches_paths` | Body signal | Techs |
|---|---|---|---|
| `T-…-bronze-views` | `transform/models/bronze`, `sources.yml`, `dbt_project.yml` | "Bronze dbt views" | **dbt** (+ duckdb dialect) |
| `T-…-silver-conform` | `transform/models/silver` | "Silver dbt tables" | **dbt** (+ duckdb) |
| `T-…-gold-marts` | `transform/models/gold` | "Gold dbt marts + schema.yml" | **dbt** (+ duckdb) |
| `T-…-gold-freshness` | `transform/models/gold` | "gold_freshness mart" | **dbt** (+ duckdb) |
| `T-…-gold-atomic-publish` | `transform/models/gold`, `transform/macros` | shared `_gold_run_id`, readers are API/MCP | **dbt** + **duckdb** |
| `T-…-api-fastapi` | `src/serving` | `src/serving/api.py`, `queries.py`, `make serve` | **fastapi** (reads **duckdb**) |
| `T-…-mcp-tools` | `src/serving` | `src/serving/mcp_server.py`, `make serve-mcp` | **mcp** (reuses the same core) |

**Union of the columns → `TECHS = dbt duckdb fastapi mcp`.** DuckDB is in scope even though no task *names* it in a title: every dbt model compiles to DuckDB SQL against `src/warehouse/warehouse.duckdb`, and the serving core opens that warehouse read-only. The engine under the models is a real tech the work touches, so it earns a KB.

## The never-speculative rule

**Only build harness for techs an in-scope task actually touches. If a tech is not named by any task, leave it out.** The harness is a moat, not a mall — every agent and KB you scaffold is content someone must keep grounded, so an unused one is pure drift.

Concrete applications of the rule in this repo:

- **Postgres is NOT in `TECHS`.** It is the *source* (`docker-compose.yml`, `src/db/01_schema.sql`, `make land`), landed into DuckDB before dbt runs. No task writes Postgres SQL as its deliverable — `make land` is a precondition, not a task's `touches_paths`. So no `postgres-architect`. If a future task shipped Postgres DDL or tuned the source schema, Postgres would enter scope then, and not before.
- **DuckDB IS in `TECHS`** even without a title naming it — because the models and the query core touch it directly (see above). Under-scoping is as wrong as over-scoping: do not drop a tech a task needs.
- **A tech named only in an ADR or the README does NOT qualify.** Grounding docs describe the terrain; the tasks decide the harness. If Kafka appeared in an ADR but no in-scope task touched it, it stays out.
- **Adding one tech later is not a Pass 6 call.** "Add a Kafka architect" is a single additive tech — route it to `agents-kbs-tech-stack` directly (confirm `kafka` exists in `menu/techs.yaml` first). Pass 6 scopes the harness to the whole task set; it is not for one-off additions.

## Ambiguity — ask once

If a task's path is genuinely dual-use (`src/serving` covers both FastAPI and MCP), the body resolves it. If even the body is ambiguous — a path maps to no menu tech, or two techs equally — **ask once before scaffolding.** This is the single human-in-the-loop moment in the pass. Everything downstream (scaffold, closers, quality-gate, cross-tool emit) is deterministic once `TECHS` is fixed.

## After you have `TECHS`

Record the set, then hand it to Step 3 of the SKILL. Every scoped tech must exist in the bundled skill's `menu/techs.yaml` (`dbt`, `duckdb`, `fastapi`, `mcp` all do). A scoped tech missing from the menu fails `scaffold.sh` with `TECH not in menu` — add it to the menu first, then re-run. The scaffold is idempotent and refuses to clobber, so re-running after a scope correction is safe.
