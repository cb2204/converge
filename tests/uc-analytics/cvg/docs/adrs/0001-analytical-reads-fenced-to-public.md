---
adr: "0001"
status: proposed
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-3"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0001 — analytical reads fenced to public

## Context

The operational database carries two physically separate schemas: `public`
(the four business domains) and `_control` (the facilitator's chaos ledger).
A Pass 3 planner deciding what the capture feed and the answer-correctness
oracle may read would get the system wrong if it treated `_control` as just
another source table. This record pins which side of the fence each consumer
stands on. Grounds R-3's correctness-oracle clause and the spec's terrain
scope-out ("the operational system's internal control ledger … never part of
the analytical surface").

## Decision

The analytical backbone's feed reads **`public.*` only**. `_control.*`
(today: `_control.injected_incidents`) is fenced ground truth: it MUST NOT be
captured into the backbone, modeled, or exposed on any business/analytical
answer surface. The eval harness verifying answer correctness (R-3) MAY read
`_control` as an oracle — a verifier is not an analytical consumer, so the
fence holds for the product surface while the oracle sees ground truth.

## Rejected reading

That `_control` is a normal source schema to ingest alongside `public` — after
all, it lives in the same database. Killed by the schema's own comment (a
facilitator-only ledger, "NOT in public … no incident table in the data anyone
investigates") and by the spec's explicit scope-out. Ingesting it would leak
the answer key into the surface whose correctness it is supposed to judge.

## Evidence

Two schemas exist; `_control` is separate from `public` and holds the ledger:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT nspname FROM pg_namespace WHERE nspname IN ('public','_control') ORDER BY 1;"
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT table_schema||'.'||table_name FROM information_schema.tables
   WHERE table_schema IN ('public','_control') ORDER BY 1;"
```

observed output: schemas `_control` and `public` both present; tables
`public.customers`, `public.orders`, `public.payments`, `public.products`,
`_control.injected_incidents`. Source comment `src/db/01_schema.sql:46-51`
declares `_control` facilitator-only, read only at the reveal.

## Consequences

Pass 3 plans must source the feed from `public.*` exclusively; no plan, task,
or transform may name `_control.*` as an input to the backbone. The R-3 eval
harness may cite `_control` strictly as a correctness oracle, never as a
pipeline source.
Re-verify when: a new schema appears alongside `public`/`_control`, or the
`_control` fence moves (e.g. a control table is relocated into `public`).
