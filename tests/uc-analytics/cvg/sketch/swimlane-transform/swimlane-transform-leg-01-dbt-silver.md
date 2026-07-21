---
leg: swimlane-transform-leg-01
tech: dbt-silver
swimlane: swimlane-transform
parent: swimlane-transform.plan.md
status: proposed
spec_ref: [ADR-0002, ADR-0005]
depends_on: []
type: leg
---

# swimlane-transform-leg-01-dbt-silver — conform to silver

> Part of swimlane **transform** ([swimlane-transform.plan.md](swimlane-transform.plan.md)).
> Plan altitude only.

## Responsibility

Conform `raw.*` to a silver layer — dedup to **one row per business key** (keep the
**max-`_lsn`** change event; a `_op=delete` tombstone removes the key), pin types,
and set the UTC grain — so that gold models build on clean, deterministic, tz-correct
data. (Dedup is by business key + max-`_lsn`, per capture's `raw.*` contract — NOT a
hash of business columns, which would never collapse distinct change events.)

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given multiple change events for one business key, when conform runs, then only the max-`_lsn` event survives (a max-`_lsn` `_op=delete` removes the key).
- Given raw timestamps, when conform runs, then every silver timestamp is UTC.
- Given multiple payments for one order, when conform runs, then they are aggregated, never assumed 1:1 (ADR 0005).

## Independence

Provable alone against a raw fixture by uniqueness + tz + aggregation checks; leg-02
depends on it, not the reverse.

## Consumes / produces

- Consumes: `raw.*` (landing contract).
- Produces: the silver layer for gold modeling.

## Appetite

medium — the conform models across four domains.

## Yields at Pass 5B (named units, not specified here)

- the dedup-to-max-`_lsn`-per-business-key model and its uniqueness check.
- the type + UTC-grain casts.
- the payment aggregation (no 1:1 assumption).

## Re-verify when

ADR 0002 (grain) or ADR 0005 (cardinality) is superseded, or `raw.*` shape changes.
