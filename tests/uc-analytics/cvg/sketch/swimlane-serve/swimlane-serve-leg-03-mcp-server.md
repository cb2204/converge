---
leg: swimlane-serve-leg-03
tech: mcp-server
swimlane: swimlane-serve
parent: swimlane-serve.plan.md
status: proposed
spec_ref: [R-3, R-8, R-9, R-11]
depends_on: [swimlane-serve-leg-02]
type: leg
---

# swimlane-serve-leg-03-mcp-server — access + SLA classes

> Part of swimlane **serve** ([swimlane-serve.plan.md](swimlane-serve.plan.md)).
> Plan altitude only.

## Responsibility

Open partner and agent access to the answers, with the small/medium/hard SLA classes
and a runbook-driven onboarding path, so that answers are reachable within their
time bounds at the daily peak (R-3, R-8/9, R-11).

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given a question of each class, when it is asked at the daily peak, then it reaches the keyed answer within its SLA (small ≤ 5m, medium ≤ 30m, hard ≤ 60m).
- Given the 3× growth drill, when it runs, then no class breaches its SLA (R-9).
- Given a newly authorized partner, when they follow the runbook, then they reach first successful query in ≤ 1 business day (R-11).

## Independence

Provable against the honest surface (leg-02) via timed drills + an onboarding dry-run.

## Consumes / produces

- Consumes: the honest answer surface (leg-02).
- Produces: partner/agent access (MCP) + the SLA-classed answer path.

## Appetite

medium — the MCP transport + the SLA drills + the onboarding runbook.

## Yields at Pass 5B (named units, not specified here)

- the MCP server over the shared core.
- the per-class timed drill (peak + 3×).
- the partner-onboarding runbook.

## Re-verify when

The SLA classes or load shape change, or the transport set changes.
