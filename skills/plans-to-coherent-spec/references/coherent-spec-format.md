# Coherent-spec format — Converge Pass 5A (Fork A)

The shape of the ONE coherent spec this pass produces. Not a template to fill
blindly — a contract for what "one document, one boundary, one eval" means, so
the spec you write passes the gate and Execution can drive it to green.

## The invariant

> **One document. One boundary. One eval.**

The two hardened swimlane plans — `sketch/duckdb-dbt-med-arch.plan` (the shaping
half: `raw.* → bronze → silver → gold`) and `sketch/fast-api-mcp.plan` (the
exposing half: FastAPI/MCP over `gold.*`) — become a **single coherent spec**
whose boundary wraps the **whole system**: `sources → gold → serving answers`.
The unit of trust is that whole, not a layer and not a task.

If you find yourself writing one spec per layer, you are on the wrong fork — stop
and switch to Fork B (`task-spec`).

## Framework-native filename (`--framework`)

The framework decides the file *name and section shape*, never the content. The
`check-coherent-spec.sh` gate looks for any of these:

| `--framework` | Coherent spec lands as | Notes |
|---|---|---|
| `speckit` (default) | `specs/spec.md` (+ `specs/plan.md`) | Constitution-checked; the e2e eval is the acceptance criterion. |
| `kiro` | `specs/requirements.md` + `specs/design.md` | ONE spec dir for the whole system, not one per layer. |
| `openspec` | one change proposal (`proposal.md`) + spec deltas | The delta wraps the whole coupled change, reviewed as one. |
| `bmad` | one PRD-style doc (`prd.md`) | Keep it coupled; do not shard into stories on this fork. |

Whatever the filename, the eval is always `specs/e2e-eval.sh` — the framework
changes the spec's shape, never the eval.

## What one coherent spec contains

A single narrative, resolved (not two plans stapled together). At minimum:

1. **Problem & boundary** — one paragraph restating what the system does, and an
   explicit statement that the boundary wraps `sources → gold → serving answers`.
   This is the unit of trust.

2. **The one-way dependency, stated as an invariant.** Postgres is the source
   floor, DuckDB the analytical store, the **read-only `ATTACH`** (the `make land`
   bridge) the single crossing. Everything reads from `raw.*` upward; **nothing
   writes back down.** State it as a directed chain the gate can find:

   ```
   Postgres → DuckDB (raw.*) → bronze → silver → gold → serving
   (source)   (read-only land)                    (= seam)  (read-only)
   ```

3. **The two halves, fused at the gold seam.**
   - *Shaping half* (from the medallion plan): `raw.* → bronze (views) → silver
     (tables, the trust boundary, 14 defects neutralized + quarantine) → gold
     (serving-ready marts)`.
   - *Exposing half* (from the serving plan): a read-only query core over
     `gold.*` via `connect_read_only()`, one FastAPI endpoint and one MCP tool per
     frozen question.
   - The **gold-table interface is the seam** where they join — see below.

4. **The gold-table interface — named as the internal contract.** The medallion
   half *owns* it (each mart ships a dbt `schema.yml` declaring columns, types,
   nullability, grain). The serving half *binds* to it and never redefines it. A
   gold column does not exist for serving until it exists in a committed
   `schema.yml`. Candidate marts (final list gated on the frozen E4 set):
   `gold_revenue_by_category`, `gold_customer_segments`, `gold_order_health`,
   `gold_payment_reconciliation`, `gold_freshness`.

5. **Carried-forward risks & open questions — verbatim.** Every accepted risk and
   open question the Pass-4 adversary surfaced moves into the spec unchanged.
   Nothing raised may be silently dropped in the lift. (E.g. the E4 question set
   is still owner-gated; `event_to_reportable_lag` is the real E3 instrument, not
   bare land cadence; the single `_gold_run_id` atomic-publish invariant.)

6. **The definition of done** — a pointer to `specs/e2e-eval.sh`: done is that
   eval green, never "looks done."

## Coupling invariants (Step 2 — COUPLE)

These are the load-bearing statements the spec must make explicit, because they
are what makes the two halves ONE system:

- **Single crossing, one direction.** The only Postgres→DuckDB path is the
  read-only `ATTACH` in `make land`. Serving reads `gold.*` only, through
  `connect_read_only()` — never `silver.*`, `bronze.*`, `raw.*`, or Postgres. This
  is what makes storefront isolation (E1) true *by construction*.
- **The gold seam is a versioned contract, owned upstream.** Serving compiles
  against the medallion's `schema.yml`; a new answer needs a **new gold mart**,
  never a deeper read.
- **Atomic gold generation.** Every gold mart carries a shared `_gold_run_id`;
  serving binds to the latest fully-published run id, so a mid-`dbt` run never
  exposes a half-published mix. State it as an invariant, not a lock.
- **Single-writer warehouse.** `make land` then `dbt`, serialized — one writer at
  a time; readers (serving) run concurrently read-only. This matches
  `src/warehouse/connection.py`'s concurrency contract.

## New architecture choices become ADRs

Where coupling forces a decision (full-refresh vs. incremental, single-writer
DuckDB, read-only gold reader, the order-health status→rate map), record it as an
ADR under `--adrs-dir` (`docs/adrs/NNNN-*.md`), **append-only**, so the record of
*why* is never lost. Do not reopen questions Pass 4 already settled — lifting must
not add scope.

## Altitude

Spec altitude throughout: the system's **shape and contract**, not its SQL or
handler code. Naming `gold_revenue_by_category(category, day, revenue,
order_count)` as a contract is spec altitude; writing the `SELECT` that fills it
is Execution (Pass 8 · The Loop). Drift below this line means you have started
building, not specifying.

## The gate

Run `scripts/check-coherent-spec.sh --specs-dir specs/`. It mechanically checks
the structural items (spec present, one-way invariant stated, gold seam named,
`e2e-eval.sh` present + executable + valid bash + drives the real flow, no Fork-B
drift). The judgment items (⊙) — one narrative not two, boundary wraps the whole,
every serving read maps to an emitted gold column, every Pass-4 risk carried
forward, done = eval green — you confirm by eye.
