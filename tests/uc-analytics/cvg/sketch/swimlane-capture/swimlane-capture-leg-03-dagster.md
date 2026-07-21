---
leg: swimlane-capture-leg-03
tech: dagster
swimlane: swimlane-capture
parent: swimlane-capture.plan.md
status: proposed
spec_ref: [R-1, R-2, R-5, ADR-0003]
depends_on: [swimlane-capture-leg-02]
type: leg
---

# swimlane-capture-leg-03-dagster — freshness + load instrumentation

> Part of swimlane **capture** ([swimlane-capture.plan.md](swimlane-capture.plan.md)).
> Plan altitude only. Depends on the landed rows from leg-02.

## Responsibility

Instrument the feed — measure write→queryable p99 freshness and the by-principal
analytical-query count on the source — so that R-1 and R-2 become observable facts,
surfaced through Dagster asset checks and sensors over the landed `raw.*`.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given ≥ 1,000 sampled writes over 24h, when lag is measured, then p99 write→queryable ≤ 5 minutes.
- Given the source connection log, when analytical queries are counted by principal, then the count for non-capture principals is zero.
- Given feed-on vs feed-off runs, when overhead is measured, then the added p95 latency is recorded and ≤ 20% (D6).

## Independence

A measurement layer over leg-02's landed rows; provable alone by replaying a sampled
write window. Blocked until the by-principal seam exists (ADR 0003, Q1).

## Consumes / produces

- Consumes: `raw.*` (landed) + the source's connection/query log by principal.
- Produces: the freshness + load evidence surface (feeds R-4/R-10 downstream).

## Appetite

small — a probe + a by-principal counter + the overhead measurement.

## Yields at Pass 5B (named units, not specified here)

- a freshness probe sampling write→queryable lag at ≤ 30-second intervals.
- a by-principal query-count check against the source connection log.
- the overhead measurement (feed-on vs feed-off) and its published number.

## Re-verify when

The principal model changes (ADR 0003 supersede) or the freshness floor moves.
