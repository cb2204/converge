---
leg: swimlane-capture-leg-01
tech: dlt
swimlane: swimlane-capture
parent: swimlane-capture.plan.md
status: proposed
spec_ref: [R-1, R-2, ADR-0002, ADR-0003]
depends_on: []
type: leg
---

# swimlane-capture-leg-01-dlt — steel-thread anchor

> Part of swimlane **capture** ([swimlane-capture.plan.md](swimlane-capture.plan.md)).
> Plan altitude only — the runnable eval binds at Pass 5B.

## Responsibility

Stand up a distinct capture principal and land ONE domain's committed changes
end-to-end (source → `raw.*` → a thin served answer), so that the whole pipe is
proven on a razor-thin slice before any lane fattens.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given a committed change in the chosen domain, when the feed runs, then it appears in a served answer within the freshness budget.
- Given the capture read, when the source query log is inspected, then the read is attributed to the dedicated capture principal, not the operational app.
- Given any capture run, when `_control` is checked, then nothing from it was ever read.

## Independence

Buildable and provable with no later leg existing: one domain, one thin path, one
answer. leg-02 and leg-03 fatten this thread; they do not gate it.

## Consumes / produces

- Consumes: `public.<one domain>` (given, frozen) + its WAL change stream.
- Produces: the first slice of the `raw.*` landing contract.

## Appetite

medium — one principal + one domain + a thin end-to-end probe.

## Yields at Pass 5B (named units, not specified here)

- provision the capture principal and grant its read-only scope.
- a dlt pipeline landing one domain off the WAL into `raw.orders`.
- an end-to-end probe proving a fresh source commit reflects in the served answer.

## Re-verify when

The capture mechanism changes (ADR 0002 supersede) or the principal model changes (ADR 0003).
