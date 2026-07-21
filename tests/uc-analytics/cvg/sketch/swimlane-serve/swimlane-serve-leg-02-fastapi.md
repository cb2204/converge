---
leg: swimlane-serve-leg-02
tech: fastapi
swimlane: swimlane-serve
parent: swimlane-serve.plan.md
status: proposed
spec_ref: [R-4, R-10, ADR-0002]
depends_on: [swimlane-serve-leg-01]
type: leg
---

# swimlane-serve-leg-02-fastapi — honest answer surface

> Part of swimlane **serve** ([swimlane-serve.plan.md](swimlane-serve.plan.md)).
> Plan altitude only.

## Responsibility

Serve answers that never lie about freshness — every answer carries its as-of, and
staleness is surfaced, alerted, and recorded — so that a late feed is visible, never
fabricated (R-4, R-10).

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given any answer, when it is returned, then it carries its as-of freshness.
- Given a feed stoppage, when staleness passes 15 min, then an alert fires no later than 20 min after the last update (R-4).
- Given a staleness event beyond the 5-min floor, when it occurs, then its start, duration, and domains are recorded (R-10).

## Independence

Provable against the core (leg-01) + an induced feed stoppage; leg-03 layers access on top.

## Consumes / produces

- Consumes: the query core (leg-01).
- Produces: the honest answer surface (as-of + staleness alerting/audit).

## Appetite

medium — the as-of surfacing + the alert + the audit record.

## Yields at Pass 5B (named units, not specified here)

- the as-of stamp on every answer.
- the staleness alert (fires ≤ 20 min).
- the staleness audit record.

## Re-verify when

R-4/R-10 thresholds move, or ADR 0002 (the clock) is superseded.
