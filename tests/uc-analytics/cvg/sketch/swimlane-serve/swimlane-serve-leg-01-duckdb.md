---
leg: swimlane-serve-leg-01
tech: duckdb
swimlane: swimlane-serve
parent: swimlane-serve.plan.md
status: proposed
spec_ref: [ADR-0001]
depends_on: []
type: leg
---

# swimlane-serve-leg-01-duckdb — query core

> Part of swimlane **serve** ([swimlane-serve.plan.md](swimlane-serve.plan.md)).
> Plan altitude only.

## Responsibility

Provide one read-only reader per published gold table — contract-only, never reaching
below the seam — so that the surface and every transport share one isolated core.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given a query core reader, when it runs, then it touches `gold.*` only, never silver / `raw.*` / the source (ADR 0001).
- Given a request for a field not in `gold.*`, when it is made, then it is refused, not resolved by a deeper read.

## Independence

Provable alone against a `gold.*` fixture by an isolation check; leg-02/03 build on it.

## Consumes / produces

- Consumes: `gold.*` (published contract).
- Produces: the read-only query core for the surface + transports.

## Appetite

small — one reader per published table.

## Yields at Pass 5B (named units, not specified here)

- one read-only reader per gold table.
- the below-seam isolation check.

## Re-verify when

The `gold.*` contract changes, or ADR 0001 is superseded.
