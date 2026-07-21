---
adr: "0000"
status: proposed
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: ""
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0000 — Context: the ground we stand on

## Terrain

Greenfield. An operational e-commerce Postgres exists and runs today, but the
**analytical lane does not exist** — no capture, no store, no transform, no
serving surface. The ADRs in this set therefore record two kinds of fact: what
is already true about the operational source we must feed from, and the
constraints the tech-spec imposes on the lane still to be built.

## Given surface

What runs today, verified — not assumed (evidence in the numbered ADRs):

- **Operational Postgres** `postgres:17-alpine`, container `uc-analytics-postgres`,
  port 5433, database `ecommerce`.
- **Four business domains** in schema `public`: `customers`, `products`,
  `orders`, `payments` — related by three foreign keys
  (`orders.customer_id→customers`, `orders.product_id→products`,
  `payments.order_id→orders`).
- **A deterministic seeder** (`src/seed`, seed 42) and a **chaos generator**
  (`src/gen`) that mutates the terrain (traffic, failure injection).
- **A fenced control ledger** `_control.injected_incidents` — facilitator ground
  truth, physically outside `public`, empty under silent injection.
- Current seed state: 50 customers / 20 products / 200 orders / 200 payments.

## Build surface

What the spec still asks later passes to build (none of it exists yet):

- A **capture** mechanism feeding the four domains into the backbone (Pass 3
  chooses it; R-1, R-2).
- An **analytical store** separate from production (R-2, R-8).
- A **transform** layer producing business answers (R-3).
- An **answer surface** exposing as-of freshness and staleness (R-4, R-10).
- A **partner migration + production lockdown** path (R-5), an **alerting**
  point (R-4), and a **cost / local-loop** envelope (R-6, R-7).

## Spec

`cvg/docs/tech-spec-analytical-backbone.md` — Converge Pass 1 (Intent),
signed **canonical 2026-07-19** (Gate H1), requirements R-1…R-11.
