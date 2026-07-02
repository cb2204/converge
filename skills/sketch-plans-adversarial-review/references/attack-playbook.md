# Attack Playbook — how the adversary refutes a swimlane plan

Converge Pass 4 (Consensus), Steps 1–2. This is the lens a *different* model
(`--adversary`, default `codex`) attacks the Pass 3 plans through. The author is
Claude; the same model reviewing its own plans produces agreement, not
consensus. If the adversary is unavailable, fall back to a fresh same-model
session with **no memory** of writing the plans — weaker, but still not
self-review in the same context.

The output of this playbook is a ranked objection list feeding Step 3 (SHARPEN),
where each objection is FIXED in a plan or ACCEPTED with a named owner.

## The stance: default to refuted

A merely-plausible plan step is **not** "fine". The adversary's job is to state
*why a step might be wrong*, per plan, or the objection stands. Silence is not
passing. Frame the adversary as a skeptical principal engineer who did **not**
write these plans and is paid to find what bites at build time — not to bless.

Three rules the adversary holds:

1. **One plan at a time.** Refutation is per-plan and ranked by build-time
   damage, so the cheapest-to-kill wrong idea dies first — at the plan, before
   any model, mart, or endpoint exists.
2. **Cite the section.** Every objection names the specific plan section it
   attacks (e.g. "Gold — serving-ready marts", "The interface this layer
   consumes"). An objection with no citation is not actionable.
3. **Lower altitude, do not invert it.** Pass 4 hardens what Pass 3 sketched.
   No new files, no new scope. A "requirement" that appears here is drift — log
   it as an open question and push it back up the chain (Pass 1/2/3).

Demand the **5–7 highest-leverage objections**, ranked by build-time damage.

## The refutation prompt (hand this to the adversary)

> You are a skeptical principal engineer. You did NOT write the plan below and
> your job is to REFUTE it, not bless it. Default to refuted: for every step you
> cannot prove wrong, state precisely why it *might* be wrong at build time.
>
> Stack context (ground truth you attack through):
> Postgres → DuckDB → dbt medallion (bronze/silver/gold) → FastAPI + MCP serving.
> The DuckDB warehouse is `src/warehouse/warehouse.duckdb`. `make land` ATTACHes
> Postgres and lands it into `raw.*` with defects intact and lineage stamps
> (`_ingested_at`, `_source_watermark`, `_schema_drift`). DuckDB is
> single-writer. Serving reads `gold.*` read-only, never below gold.
>
> Return the 5–7 highest-leverage objections, ranked by build-time damage. Each
> objection MUST cite a specific plan section and say what breaks if it ships
> unchanged. Do not propose new scope; if you find a missing requirement, flag
> it as an open question, do not add it.

Run it once per plan (`sketch/duckdb-dbt-med-arch.plan`, then
`sketch/fast-api-mcp.plan`), never on both at once.

## The bite list — what actually bites THIS stack at build time

Pattern-5 domain intelligence: the pass already knows where this stack breaks.
Point the adversary at these seams first.

### 1. Brownfield assumptions about the `raw.*` contract

`make land` lands **defects intact** — cleaning is the medallion's job, not the
landing's. Attack any plan step that assumes something unproven about:

- The `raw.*` columns and stamps — `_ingested_at` (freshness anchor),
  `_source_watermark` (event clock), `_schema_drift` on `raw_orders`.
- **`duplicate_order`**: the injector re-inserts the latest order verbatim with a
  *new* `order_id`. So `order_id` stays unique while the duplicate row survives.
  Any dedup keyed on `order_id` is wrong — it must dedup on a business signature.
- **Canonical vocab**: `orders.status` is `placed/shipped/delivered/returned/
  cancelled` — there is **no raw `fulfilled` status**. A plan that reads a
  `fulfilled_rate` straight off raw has invented a status. It must be a *derived*
  metric via an owner-gated status→health map.
- `DECIMAL` money never recast to float; timestamps are tz-aware.

### 2. Build order — nothing built before what it reads

DuckDB + dbt make the DAG the contract. Attack any inversion:

- Gold materialized before silver conforms it; silver before bronze types it;
  any dbt model before its `raw` source lands.
- A serving endpoint or MCP tool built before the mart it reads exists.
- `make land` and `dbt run` overlapping — DuckDB is **single-writer**; land,
  then dbt, never concurrent. Readers may run concurrently with the one writer.

### 3. Cross-lane interface — the medallion → serving gold-table contract

The seam that most often gaps at build time:

- A FastAPI/MCP endpoint that needs a gold column the medallion lane never
  emits (the classic: serving reads `gold.customer_revenue` but the medallion
  plan only emits `gold_revenue_by_category`).
- Serving *declaring* gold columns instead of *consuming* them. The gold
  contract is owned by Component A via a per-mart `schema.yml`; a column does not
  exist for B until A has committed it with a type. Attack any serving plan that
  names columns A never promised.
- **Atomic generation**: mid-`dbt run`, one endpoint could read a refreshed mart
  while another reads the stale one — inconsistent cross-endpoint answers. The
  fix is a shared `_gold_run_id` per published generation; B binds to the latest
  *fully-published* run id. Attack any "no serialization needed" claim.
- **Freshness clock**: `_ingested_at` alone measures land cadence — it can report
  "fresh" while the newest business event is old/late-arriving. E3 needs
  `event_to_reportable_lag = _ingested_at − max(<event_ts>)`, carrying both
  clocks. Attack any freshness mart that exposes only one.
- **pytz trap**: tz-aware timestamps must be cast to text/epoch at the SQL
  boundary or a Python consumer trips DuckDB's pytz requirement. dbt SQL is safe;
  the FastAPI/MCP query core is where this bites.

## Step 2 — grounding (drift vs. tech-spec + ADRs)

The plans answer to `docs/tech-spec-*.pdf` and `docs/adrs/*.md`, not the author
model's memory. For each plan, list every drift as:

`plan section ↔ spec/ADR section ↔ the conflict`

citing **both** sides. Hunt four drift shapes:

- **Uncovered claim** — the plan says it covers a requirement it does not.
- **Out-of-scope build** — it builds something the spec marked out-of-scope, or a
  metric never asked for.
- **ADR violation** — it contradicts a recorded decision (e.g. an ADR pinning
  DuckDB single-writer, or the strict bronze→silver→gold layering).
- **Number disagreement** — a freshness target, latency budget, or success
  metric that differs from the spec (e.g. a p95 window the plan invented).

If `docs/adrs/` is empty, ground against the tech-spec alone and log
"ADRs absent" as a **blocking** open question — never fabricate ADR content.

## From objection to resolution (feeds Step 3)

Every objection surfaced here ends in exactly one of:

- **FIX** — the relevant plan is revised **in place** to resolve it. The diff on
  `sketch/*.plan` is the record. Reference the objection id (e.g. C3) where the
  fix lands so the gate can see one resolution per objection.
- **ACCEPT** — recorded as a known risk with a **named owner** and the reason to
  proceed (e.g. `ACCEPT — owner: data-eng — reason: DuckDB single-writer under
  concurrent load is out of demo scope`).

Nothing is silently dropped. The gate
(`scripts/check-consensus-gate.sh`) refuses to pass if any logged objection has
no resolution or any accepted risk has no owner.
