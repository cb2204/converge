---
adr: "0005"
status: accepted
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-3"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0005 — payments↔order cardinality is not enforced 1:1

## Context

`payments.order_id` is the orders↔payments seam (a foreign key). A Pass 3
planner computing revenue per order, or joining payments to orders, would
naturally treat the relationship as one-payment-per-order — because in the
current seed it is exactly that. The schema does not enforce it. This record
pins that the 1:1 shape is a property of *today's data*, not a *constraint*, so
no aggregation is built on an assumption the database can violate.

## Decision

The relationship `payments.order_id → orders.order_id` is a **non-unique**
foreign key: the schema permits **many** payments per order. The only unique
index on `payments` is its primary key (`payment_id`); `order_id` carries a
plain (non-unique) btree index. The current seed happens to be 1:1 (every order
has exactly one payment), but that is data, not a guarantee — retries, partial
captures, or refund rows could make it N:1 in production.

## Rejected reading

That payments-to-orders is 1:1 and can be joined as such (or that
`orders.total_amount` and a single payment are interchangeable). Killed by the
index catalog: no unique constraint or unique index exists on
`payments.order_id`, so the database will accept multiple payment rows for one
order. Assuming 1:1 would silently double-count (or drop) revenue the moment
production writes a second payment row for an order.

## Evidence

Seed is 1:1, but only `payment_id` is unique — `order_id` is not:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT max(cnt) FROM (SELECT order_id, count(*) cnt FROM payments GROUP BY order_id) s;"
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT indexdef FROM pg_indexes WHERE tablename='payments' ORDER BY 1;"
```

observed output: max payments per order = `1` (current seed); indexes =
`CREATE INDEX idx_payments_order_id ON public.payments USING btree (order_id)`
(non-unique) and `CREATE UNIQUE INDEX payments_pkey … (payment_id)`. No unique
index on `order_id`. Schema source: `src/db/01_schema.sql:32-44`.

## Consequences

Pass 3 plans and the R-3 revenue oracle must aggregate payments per order
(e.g. `GROUP BY order_id` / `SUM`), never assume a single payment row per
order, and must not substitute `orders.total_amount` for settled payment
amounts. Any correctness check that relies on 1:1 must state it as a seed
assumption, not a schema guarantee.
Re-verify when: a unique constraint is added to `payments.order_id`, or the
seed/production begins writing more than one payment row per order (max > 1).
