# Grounding checklist — run-and-reconcile the brownfield

Pass 2 grounds by *running* the real source, not summarizing a doc. This is the
protocol behind Step 2. Every ADR you write in Step 3 must trace to something you
observed here.

## 1. Bring the terrain up and land it

```bash
make up            # Postgres source (public.* schema auto-applied on first boot)
make seed          # generate clean, correlated customers/products/orders/payments
make land          # read-only ATTACH Postgres -> DuckDB raw.raw_* (full refresh)
```

`make land` copies each `public.<entity>` into `raw.raw_<entity>` in
`src/warehouse/warehouse.duckdb` via a read-only Postgres ATTACH scoped to
`SCHEMA 'public'`. The password never enters the ATTACH string.

## 2. Reconcile row parity (Postgres → DuckDB)

For each entity, the source count and the landed count must match after a clean
full refresh:

```bash
# source
make psql   # then: SELECT count(*) FROM public.orders;
# landed
duckdb src/warehouse/warehouse.duckdb "SELECT count(*) FROM raw.raw_orders;"
```

- **Match** → landing is faithful; record the parity as evidence if a spec claim
  depends on it.
- **Mismatch** → do NOT hand-wave it. Either the landing is stale (`make land`
  again) or a defect changed rows mid-run. A persistent, explained mismatch is
  itself a grounding fact (e.g. *which of the 14 defect modes survive into `raw`*)
  and deserves its own ADR.

## 3. Inventory the warehouse schema

```bash
duckdb src/warehouse/warehouse.duckdb \
  "SELECT DISTINCT table_schema FROM information_schema.tables;"
```

Confirm `raw` is the **only** analytical schema — there is no transform or serving
layer yet. That absence is a fact Pass 3 relies on (it is what Pass 3 builds).

## 4. Interrogate the schema against the spec

Read `src/db/01_schema.sql` and pin the three facts that bite a planner if wrong:

- **Join** — `payments.order_id BIGINT NOT NULL REFERENCES orders(order_id)`. This
  is the sole orders↔payments seam. `orders` also joins `customers(customer_id)`
  and `products(product_id)`.
- **Grain** — `orders.ordered_at` and `payments.paid_at` are `TIMESTAMPTZ`. Any
  date grain is UTC; do not assume a local zone.
- **Metric** — "revenue" resolves against `payments.status` (paid/captured), not
  `orders.total_amount` (intent). Decide and record which.

## 5. Note the fence

`_control.injected_incidents` lives in a `_control` schema and is written only when
injection runs with `RECORD=1`. It is a facilitator-only answer key; the analytics
pipeline reads `public.*` only, and `_control.*` never lands into `raw.*`. Record
this so no downstream pass mistakes it for a business table.

## Output

You now have the 3–4 observed facts for Step 3. Each becomes one
`docs/adrs/NNNN-<slug>.md` via `scaffold-adr.sh`, with its evidence line copied
from what you ran here.
