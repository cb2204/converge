# CONTEXT — domain glossary (Converge Pass 2)

Canonical terms for the analytical backbone. **Terms only** — a name, its
one-line meaning against the real data, and the evidence it traces to. No
build notes, no design. Downstream passes (plans, task-specs, harness KBs)
cite these instead of re-deriving them. Grounded 2026-07-21 against the
operational Postgres (`ecommerce`, seed 42).

| Term | Canonical meaning | Traces to |
|---|---|---|
| **revenue** | Sum of `payments.amount` where `status = 'captured'`. The spec's word "paid" has **no** matching status value; `captured` is the realized-revenue state. | ADR 0004; `payments.status` ∈ {authorized, captured, refunded, failed} |
| **payment settlement states** | `authorized` (promised, not taken), `captured` (taken = revenue), `refunded` (given back), `failed` (never taken). | ADR 0004; `src/db/01_schema.sql:32-39` |
| **order lifecycle** | `orders.status` ∈ {placed, shipped, delivered, cancelled, returned} — fulfillment state, **not** a payment/revenue signal. | ADR 0004; `orders` distinct status |
| **order↔payment cardinality** | `payments.order_id` is a **non-unique** FK — the schema permits many payments per order; the seed's 1:1 is data, not a guarantee. Aggregate, don't assume 1:1. | ADR 0005; `payments` indexes |
| **analytical query** | A read on the operational DB **not** issued by the operational application or the backbone capture connection, each identified by its own database principal; counted from the connection log by principal. | tech-spec R-2; ADR 0003 |
| **freshness lag** | Elapsed time from a committed write in the four domains to that change being queryable in the backbone; the R-1 guarantee is p99 ≤ 5 min. Not derivable from any `public` column — see the change-stream constraint. | tech-spec R-1; ADR 0002 |
| **staleness** | How far behind the source the served answer is; surfaced as as-of freshness (R-4), alerted beyond 15 min, audited from the R-1 floor (5 min) up (R-10). | tech-spec R-4, R-10; ADR 0002 |
| **the four domains** | `customers`, `products`, `orders`, `payments` in schema `public` — the entire analytical source surface. | ADR 0000, 0001; three FKs |
| **`_control` ledger** | `_control.injected_incidents` — facilitator ground truth, fenced outside `public`; readable by verifiers as an oracle, never by the analytical pipeline or any answer surface. | ADR 0001; `src/db/01_schema.sql:46-59` |
| **greenfield (this workspace)** | Operational source exists; the analytical lane (capture, store, transform, serving) does not — it is built pass by pass. | ADR 0000; `CLAUDE.md` |
