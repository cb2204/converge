---
adr: "0002"
status: accepted
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-1, R-4, R-10"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0002 — no row-level change timestamp

## Context

R-1 measures freshness as `write-timestamp → first-queryable-timestamp`, and
R-4/R-10 track staleness of the *latest* committed state. A Pass 3 planner
would naturally reach for an `updated_at` column to detect and timestamp
changes. The terrain has none — and rows are not append-only: `orders` are
mutated **in place** after creation (status transitions and even
`total_amount` are overwritten by the operational workload), while the row
keeps its original `ordered_at`. This record pins that the "write timestamp"
of a *change* is not observable from the business columns — so no freshness
clock can rest on a column that does not exist.

## Decision

The `public` business tables expose **no row-level change timestamp** — no
`updated_at`, no CDC/version/LSN column (column count = 0). The only time
columns are insert-oriented: `customers.created_at`, `products.created_at`,
`orders.ordered_at`, `payments.paid_at`, all `TIMESTAMPTZ` (UTC). Yet `orders`
rows are updated in place — `orders.status` moves through its lifecycle and
`orders.total_amount` can be overwritten — with **nothing recording when the
update happened**. (`payments` rows are insert-terminal in this terrain: no
`UPDATE payments` exists, so `paid_at` is a stable event time — see 0004/0005.)
Because the moment a committed *change* becomes queryable (R-1) and the
staleness of current state (R-4, R-10) cannot be read from any `public`
column, they must be derived from a change signal outside the row data.

## Rejected reading

That `ordered_at` (or `created_at`/`paid_at`) can serve as the freshness
write-timestamp. Killed because those mark original insertion, not the later
in-place updates the freshness guarantee must cover: an order row that flips
`placed`→`cancelled`, or has `total_amount` zeroed, keeps its old `ordered_at`
and gains no new timestamp — so lag measured against it is blind to the very
change R-1 promises to make queryable within 5 minutes.

## Evidence

No change/CDC-style column exists; the only time columns are insert-time and
all UTC; and `orders` is mutated in place while `payments` is not:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT count(*) FROM information_schema.columns WHERE table_schema='public'
   AND (column_name LIKE '%updated%' OR column_name LIKE '%changed%'
        OR column_name LIKE '%version%' OR column_name LIKE '%lsn%');"
docker compose exec -T postgres psql -U postgres -d ecommerce -A -F'|' -t -c \
  "SELECT table_name||'.'||column_name||' :: '||data_type
   FROM information_schema.columns WHERE table_schema='public'
   AND data_type LIKE '%timestamp%' ORDER BY 1;"
grep -rnE "UPDATE orders SET|UPDATE payments" src/gen/failures.py
```

observed output: change-column count = `0`; time columns =
`customers.created_at`, `orders.ordered_at`, `payments.paid_at`,
`products.created_at`, each `timestamp with time zone`. In-place order
mutation is real (`src/gen/failures.py`): `UPDATE orders SET status='cancelled'`,
`UPDATE orders SET total_amount = 0`, `UPDATE orders SET status = %s`. There is
**no** `UPDATE payments` in `src/` — payment status is assigned once at seed
(`src/seed/factories.py:192`).

## Consequences

Pass 3 must obtain the change signal for updated rows from a source **outside
the `public` column data** — no column marks that an `orders` row changed, and
`ordered_at` cannot stand in for it. Which mechanism supplies that signal
(log-based capture, snapshot-diff, or another approach) is a Pass 3 decision,
weighed against R-2's capture-overhead budget and W-1's no-touch constraint on
the operational system — this record does not choose it, only fixes the
constraint it must satisfy. Freshness (R-1), staleness alerting (R-4), and the
staleness audit log (R-10) all stand on whatever change signal Pass 3 selects.
Re-verify when: the operational schema adds a change-tracking column, or the
source begins emitting an explicit change-event feed.
