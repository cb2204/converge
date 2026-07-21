---
leg: swimlane-transform-leg-03
tech: ducklake
swimlane: swimlane-transform
parent: swimlane-transform.plan.md
status: proposed
spec_ref: [R-3]
depends_on: [swimlane-transform-leg-02]
type: leg
---

# swimlane-transform-leg-03-ducklake — publish gold

> Part of swimlane **transform** ([swimlane-transform.plan.md](swimlane-transform.plan.md)).
> Plan altitude only.

## Responsibility

Publish the gold metrics as serving-ready DuckLake tables shaped to the frozen
Q-SET-1, so that the serve lane has a stable published contract to read.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given the frozen Q-SET-1, when gold is published, then every question maps to a gold table.
- Given a published gold table, when the serve lane reads it, then it needs nothing below the contract.

## Independence

Provable by a question→table coverage check over Q-SET-1; depends on leg-02's models.

## Consumes / produces

- Consumes: the gold metric models (leg-02).
- Produces: the `gold.*` published contract for serve.

## Appetite

small — the publish step + the coverage check.

## Yields at Pass 5B (named units, not specified here)

- the DuckLake publish of each gold table.
- the Q-SET-1 question→table coverage check.

## Re-verify when

Q-SET-1 changes, or the `gold.*` contract shape changes.
