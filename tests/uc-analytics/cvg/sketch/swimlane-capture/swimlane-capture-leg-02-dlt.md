---
leg: swimlane-capture-leg-02
tech: dlt
swimlane: swimlane-capture
parent: swimlane-capture.plan.md
status: proposed
spec_ref: [R-1, ADR-0001, ADR-0002]
depends_on: [swimlane-capture-leg-01]
type: leg
---

# swimlane-capture-leg-02-dlt — land all four domains

> Part of swimlane **capture** ([swimlane-capture.plan.md](swimlane-capture.plan.md)).
> Plan altitude only. Fattens the steel thread (leg-01) to full coverage.

## Responsibility

Land all four operational domains — customers, products, orders, payments — into the
`raw.*` landing contract as change records, each row carrying its capture as-of / lag,
so that the full landing contract the transform lane consumes exists and is complete.

## Proves (acceptance criteria — Given/When/Then; no evals)

- Given a committed change in any of the four domains, when the feed runs, then it appears in `raw.*`.
- Given a landed `raw.*` row, when it is inspected, then it carries a capture as-of timestamp and its measured lag.
- Given the full feed, when `_control` is checked, then nothing from it was captured.

## Independence

Consumes the mechanism proven by leg-01; adds breadth, not a new seam. Provable alone
by row-parity between the four `public` domains and their `raw.*` landing.

## Consumes / produces

- Consumes: `public.{customers,products,orders,payments}` + WAL change stream.
- Produces: the complete `raw.*` landing contract for transform.

## Appetite

medium — one dlt resource per domain + row-parity checks.

## Yields at Pass 5B (named units, not specified here)

- one dlt resource per domain landing into `raw.<domain>`.
- a row-parity check per domain (source committed vs `raw.*` landed).
- the as-of / lag stamping on every landed row.

## Re-verify when

A domain is added or removed from `public`, or the landing contract shape changes.
