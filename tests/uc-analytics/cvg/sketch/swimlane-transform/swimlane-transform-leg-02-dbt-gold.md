---
leg: swimlane-transform-leg-02
tech: dbt-gold
swimlane: swimlane-transform
parent: swimlane-transform.plan.md
status: proposed
spec_ref: [ADR-0004, ADR-0005, ADR-0006, R-3]
depends_on: [swimlane-transform-leg-01]
type: leg
---

# swimlane-transform-leg-02-dbt-gold — model the gold metrics

> Part of swimlane **transform** ([swimlane-transform.plan.md](swimlane-transform.plan.md)).
> Plan altitude only.

## Responsibility

Model the gold business metrics on silver — revenue and its slices — so that the
serving layer answers Q-SET-1 correctly against the ADR-fixed definitions.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given the silver layer, when revenue is computed, then it equals the sum of `captured` payment amounts (ADR 0004), never order totals or "paid".
- Given a revenue-by-product request, when the model runs, then it routes through the transitive join payments→orders→products (ADR 0006), referencing no `payments.product_id`.
- Given the answer-key oracle, when gold revenue is compared, then they match.

## Independence

Provable against a silver fixture + the answer-key oracle; leg-03 publishes it but
does not gate the modeling.

## Consumes / produces

- Consumes: the silver layer (leg-01).
- Produces: the gold metric models (pre-publish).

## Appetite

medium — the revenue metric + its product/customer slices.

## Yields at Pass 5B (named units, not specified here)

- the captured-revenue model and its oracle check.
- the transitive-join slices (by product, by customer).

## Re-verify when

ADR 0004 (revenue), 0005 (cardinality), or 0006 (join grain) is superseded.
