---
adr: "0004"
status: proposed
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-3"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0004 — revenue is captured, not "paid"

## Context

The tech-spec and the domain speak of "revenue" and "paid payments" (R-3's
Q-SET-1 names "revenue by product over time"). A Pass 3 planner writing the
revenue metric would look for a `paid` payment status — and there isn't one.
The word in the spec does not match any value in the data. This record
resolves that spec-vs-data conflict so the revenue figure is defined against a
real column value, once, before any plan computes it.

## Decision

`payments.status` takes exactly four values — `authorized`, `captured`,
`refunded`, `failed` — and **there is no `paid`**. Realized revenue corresponds
to the `captured` state; `authorized` is money promised but not taken,
`refunded` and `failed` are not revenue. The canonical definition is therefore:
**revenue = sum of `payments.amount` where `status = 'captured'`**, in the
payment's `TIMESTAMPTZ` grain. Refunds are their own status on the payment row
(not a separate negative row); whether a net-of-refunds figure is also needed
is a metric question for Pass 3, but the base "revenue" term is captured-only.

## Rejected reading

That "revenue" = order totals (`orders.total_amount`), or = any
non-`failed` payment (thereby counting `authorized` and `refunded`). Killed by
the status distribution: authorizations and refunds are large, distinct states
(refunded 82, failed 52, captured 36, authorized 30 in the current seed), so
conflating them with realized revenue would overstate it substantially and
count money that was never taken or was given back.

## Evidence

`payments.status` has no `paid` value; the states and their amounts are:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -F'|' -t -c \
  "SELECT status, count(*), coalesce(sum(amount),0) FROM payments
   GROUP BY status ORDER BY 2 DESC;"
```

observed output (current seed, 200 payments): `refunded|82`, `failed|52`,
`captured|36`, `authorized|30` — no `paid` row. `orders.status` is a separate
lifecycle ({placed, shipped, delivered, cancelled, returned}) and is not a
payment-settlement signal.

## Consequences

Pass 3 plans and the R-3 answer-key oracle must compute revenue as
`sum(payments.amount) WHERE payments.status = 'captured'`, never from
`orders.total_amount` and never by treating "paid" as a status literal. The
term is pinned in `docs/CONTEXT.md` so downstream passes cite it instead of
re-deriving it.
Re-verify when: `payments.status` gains or renames a settlement state (e.g. a
literal `paid` or `settled` value appears), or a net-of-refunds revenue
definition is adopted.
