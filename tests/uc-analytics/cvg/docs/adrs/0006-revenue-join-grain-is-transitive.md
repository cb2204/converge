---
adr: "0006"
status: accepted
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-3"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0006 — revenue join grain is transitive

## Context

R-3's Q-SET-1 names "revenue by product over time" and "partner activity" —
revenue sliced by product and by customer. Revenue lives on `payments` (0004),
but a Pass 3 planner would get the join wrong if they assumed `payments` carries
the slicing keys. It does not. This record pins the actual path from a payment
to its product and customer, so the revenue metric is built on the real grain.

## Decision

`payments` holds only `payment_id, order_id, method, amount, status, paid_at` —
**no `product_id`, no `customer_id`**. A payment reaches its product and customer
**transitively, through `orders`**: `payments.order_id → orders.order_id`, then
`orders.product_id → products` and `orders.customer_id → customers`. Therefore
revenue-by-product and revenue-by-customer both require the two-hop join
`payments → orders → products|customers`; there is no direct edge. Because each
order references exactly one product and one customer (single FK columns on
`orders`), a payment maps to exactly one product and one customer via its order.

## Rejected reading

That `payments` can be sliced by product or customer directly (a denormalized
`payments.product_id`/`customer_id`), or that revenue-by-product can read
`products` without going through `orders`. Killed by the payments column list:
the slicing keys are absent, so any query that names `payments.product_id`
fails, and any revenue-by-product figure not routed through `orders` is
ungrounded.

## Evidence

`payments` exposes no product/customer key; the path runs through `orders`:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
   FROM information_schema.columns
   WHERE table_schema='public' AND table_name='payments';"
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT conrelid::regclass||'.'||a.attname||' -> '||confrelid::regclass||'.'||af.attname
   FROM pg_constraint c
   JOIN pg_attribute a  ON a.attrelid=c.conrelid  AND a.attnum =ANY(c.conkey)
   JOIN pg_attribute af ON af.attrelid=c.confrelid AND af.attnum=ANY(c.confkey)
   WHERE c.contype='f' ORDER BY 1;"
```

observed output: payments columns = `payment_id, order_id, method, amount,
status, paid_at` (no `product_id`/`customer_id`); foreign keys =
`orders.customer_id -> customers.customer_id`,
`orders.product_id -> products.product_id`,
`payments.order_id -> orders.order_id`.

## Consequences

Pass 3 plans and the R-3 answer-key oracle must slice revenue by joining
`payments → orders → products` (by product) or `payments → orders → customers`
(by customer); no plan may reference `payments.product_id`/`customer_id`. Combined
with 0005 (aggregate payments per order, don't assume 1:1) this fixes the full
revenue join grain: sum `captured` payment amounts, grouped through `orders` to
the product or customer.
Re-verify when: `payments` gains a direct `product_id`/`customer_id` column, or
`orders` becomes able to reference more than one product/customer per order.
