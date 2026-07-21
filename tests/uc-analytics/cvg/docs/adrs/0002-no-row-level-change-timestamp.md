---
adr: "0002"
status: proposed
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
changes. The terrain has none — and rows are not append-only: `orders.status`
and `payments.status` both move through lifecycles (placed→…→delivered;
authorized→captured→refunded). This record pins that the "write timestamp" of
a *change* is not observable from the business columns, so the capture design
cannot be built on one.

## Decision

The `public` business tables expose **no row-level change timestamp** — no
`updated_at`, no CDC/version/LSN column. The only time columns are
insert-oriented: `customers.created_at`, `products.created_at`,
`orders.ordered_at`, `payments.paid_at`, all `TIMESTAMPTZ` (UTC). Because
`status` fields mutate in place with nothing recording *when*, the moment a
committed change becomes queryable (R-1) and the staleness of current state
(R-4, R-10) MUST be derived from the database's change/replication stream, not
from any column in `public`.

## Rejected reading

That `ordered_at` / `paid_at` / `created_at` can serve as the freshness
write-timestamp. Killed because those mark original insertion, not the later
status transitions the freshness guarantee must cover; a row that flips
`authorized`→`captured` carries the old `paid_at` and no new timestamp, so
lag measured against it would be blind to the very change R-1 promises to make
queryable within 5 minutes.

## Evidence

No change/CDC-style column exists; the only time columns are insert-time and
all UTC:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT count(*) FROM information_schema.columns WHERE table_schema='public'
   AND (column_name LIKE '%updated%' OR column_name LIKE '%changed%'
        OR column_name LIKE '%version%' OR column_name LIKE '%lsn%');"
docker compose exec -T postgres psql -U postgres -d ecommerce -A -F'|' -t -c \
  "SELECT table_name||'.'||column_name||' :: '||data_type
   FROM information_schema.columns WHERE table_schema='public'
   AND data_type LIKE '%timestamp%' ORDER BY 1;"
```

observed output: change-column count = `0`; time columns =
`customers.created_at`, `orders.ordered_at`, `payments.paid_at`,
`products.created_at`, each `timestamp with time zone`. Status mutation is real:
`orders.status` ∈ {placed, shipped, delivered, cancelled, returned};
`payments.status` ∈ {authorized, captured, refunded, failed}.

## Consequences

Pass 3's capture plan must obtain change events from the Postgres WAL /
logical-replication stream (or an equivalent log-based mechanism), not by
polling an `updated_at` column — none exists, and adding one would be a change
to the operational system, which W-1 forbids. Freshness (R-1), staleness
alerting (R-4), and the staleness audit log (R-10) all stand on the capture
stream as their clock source.
Re-verify when: the operational schema adds a change-tracking column, or the
source begins emitting an explicit change-event feed.
