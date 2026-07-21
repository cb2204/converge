---
adr: "0003"
status: proposed
date: 2026-07-21
ground: greenfield
converge_pass: 2
spec_ref: "R-2, R-5"
supersedes: ""
superseded_by: ""
deciders: "VP of Engineering (Luan Moreno, persona)"
---

# 0003 — single principal, no analytical-query seam

## Context

R-2 defines an analytical query decidably "by identity, never by judgment": a
read on the operational database *not* issued by the operational application or
the backbone's capture connection, "each identified by its own database
principal", counted from the connection log by principal. R-5 then requires a
7-day window of **zero** analytical queries observed the same way, and a
post-lockdown access attempt that provably fails. Both acceptance tests stand
on the database being able to tell principals apart. This record pins that,
today, it cannot.

## Decision

The operational database has exactly **one login principal** (`postgres`, a
superuser). There is no separate role for the operational application, the
backbone capture connection, or partner/analytical readers. Therefore the
by-principal seam R-2 and R-5 measure against **does not exist in the terrain
yet** — it is a build-surface prerequisite, not a given. Until distinct
principals exist, "zero analytical queries by principal" and "revoke analytical
read access" are unmeasurable and unenforceable.

## Rejected reading

That principal separation already exists or is a trivial config detail Pass 3
can assume. Killed by `pg_roles`: only `postgres` can log in. Assuming the seam
is present would let a Pass 3 plan claim R-2/R-5 are satisfiable by observation
alone, when in fact establishing the principals is itself required work the
acceptance criteria silently depend on.

## Evidence

Exactly one role can log in:

```sh
docker compose exec -T postgres psql -U postgres -d ecommerce -A -t -c \
  "SELECT rolname FROM pg_roles WHERE rolcanlogin ORDER BY 1;"
```

observed output: single row — `postgres`. No `app`, `capture`, `analyst`, or
partner role exists; the operational app, any partner reader, and a future
capture connection would today be indistinguishable in the connection log.

## Consequences

Pass 3 must treat "distinct database principals for (a) the operational
application, (b) the backbone capture connection, and (c) analytical/partner
readers" as a precondition of R-2's measurement and R-5's lockdown — the
zero-analytical-query observation and the provable-revocation test are
undefined without it. The partner registry (R-5, D8) enumerates the reader
identities that must be revoked at the flip.
Re-verify when: additional login roles are created on the operational
database, or partner access is granted through a shared vs. per-consumer
principal.
