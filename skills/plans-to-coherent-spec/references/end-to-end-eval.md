# The single end-to-end eval — Converge Pass 5A (Fork A)

Fork A produces **exactly ONE eval**: `specs/e2e-eval.sh`. It is the definition of
done for the whole coherent spec. Done = this eval is green — never "looks done."
If you cannot write it, the spec is not yet coherent/coupled enough to leave this
pass; go back to COUPLE (Step 2) and sharpen the seam or an invariant.

This is the single artifact the shared Execution gate (Pass 8 · The Loop) drives
to green. On Fork A the runner converges the whole coupled system against this one
eval, rather than closing tasks one by one.

## Why one eval, not many

Fork B (`task-spec`) writes one atomic eval per task — each layer verified in
isolation, unattended. Fork A trades the other way: the unit of trust is the
**whole system**, so a human holds ONE big gate and the eval spans the entire
spine. One eval that fails somewhere is more honest about a coupled system than N
green per-layer evals that each pass while the seam between them is broken.

## What it must drive — the real flow

The eval drives the actual repo pipeline, end to end. No mocks, no stand-ins:

| Stage | Real command (grounded in this repo) | What it establishes |
|---|---|---|
| **seed** | `make seed CUSTOMERS=… PRODUCTS=… ORDERS=… SEED=42` | a **known, deterministic** Postgres source |
| **land** | `make land` | Postgres → `raw.*` in the DuckDB warehouse (read-only `ATTACH`) |
| **build** | `dbt build` (in the dbt project dir) | `raw.* → bronze → silver → gold` + dbt tests |
| **gold** | read-only query via `connect_read_only()` | the expected `gold.*` shape for the known seed |
| **serving** | FastAPI endpoint + MCP tool | the expected answer at the **far end** |

Grounding facts the eval encodes (do not re-derive these elsewhere):

- Warehouse path is `${DUCKDB_DATABASE:-src/warehouse/warehouse.duckdb}` — the
  single source of truth from `src/warehouse/paths.py`. Never hardcode another.
- Reads go through `src.warehouse.connection.connect_read_only()` — the eval
  honors the SAME read-only invariant the serving layer must, so it cannot
  contend with or corrupt anything upstream (E1 by construction).
- The `.venv` python is `.venv/bin/python` (uv-managed); fall back to `python3`.
- Make targets that exist today: `seed`, `land` (plus `up`, `reseed`, `inject`,
  `watch`, `test`). `dbt build` and the serving entrypoint are added by Execution
  when Components A and B are built.

## What it must assert — the far end

A known seed must produce **both**:

1. **The expected gold shape** — the internal contract holds: each frozen mart
   exists with the columns the medallion's `schema.yml` declares, aggregates
   reconcile to silver, and the atomic-publish invariant holds (one
   `_gold_run_id` across all marts — no half-published generation is visible).
2. **The expected serving answer** — the FastAPI endpoint and the MCP tool return
   the **same** value for the same frozen E4 question (same B1 core ⇒ same
   answer), and that value matches the gold shape asserted above.

One eval, end to end, unambiguous pass/fail.

## RED until built — by design

The scaffold (`scripts/scaffold-e2e-eval.sh`) stamps a runnable skeleton that is
**RED until the medallion and serving layers exist**. That is the correct Fork-A
signal, not a bug: the eval is what Execution drives to GREEN. Each stage prints a
precise, actionable reason when its layer is not yet built — e.g. "no
dbt_project.yml found — the medallion (Component A) is not built yet" or
"src/serving missing — the serving layer (Component B) is not built yet" — so a
RED run always names the exact gap to close next.

The skeleton uses `set -uo pipefail` (not `-e`) on purpose: it runs **every**
stage and reports **all** gaps in one pass, instead of stopping at the first
failure. It exits non-zero if any check fails and zero only when the whole spine
is green.

## Authoring workflow

1. `scripts/scaffold-e2e-eval.sh --specs-dir specs/` — stamp the skeleton.
2. Freeze the **E4 question set** and the **gold `schema.yml` contract** (the one
   gating input from Pass 4 / VP Data). Until frozen, the mart list and the exact
   answers are provisional.
3. Fill the `TODO(author)` assertions: the concrete gold values for `SEED=42` and
   the concrete endpoint/MCP answers they map to.
4. `chmod +x specs/e2e-eval.sh` (the scaffold already does this) and
   `bash -n specs/e2e-eval.sh` — must be clean.
5. `scripts/check-coherent-spec.sh --specs-dir specs/` — the gate confirms the
   eval exists, is executable, is valid bash, and drives the real flow.

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Can't write a single eval | plans not coherent/coupled enough | Return to COUPLE (Step 2): the seam or an invariant is still ambiguous. |
| Eval passes but the system is wrong | assertions stop at "table exists" | Assert the **far-end value** (gold total + the serving answer that equals it), not mere existence. |
| Tempted to write one eval per layer | Fork-B thinking | Fork A binds ONE eval spanning `sources → gold → serving`. If you truly need per-layer evals, you are on Fork B. |
| `check-coherent-spec.sh` fails on the eval | not executable or invalid bash | `chmod +x specs/e2e-eval.sh`; run `bash -n specs/e2e-eval.sh` and fix syntax. |
| Eval reads `silver.*`/`raw.*` to "help" | broke the read-only gold-only seam | Read `gold.*` only, through `connect_read_only()`. A missing column is a new-mart request to Component A, not a deeper read. |
