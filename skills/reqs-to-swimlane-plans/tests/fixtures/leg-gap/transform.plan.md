# Plan · transform lane

lane-meta: thread=yes · risk=med · owner=analytics

Component **A · Transform** from the decomposition. Input contract: `raw.*`.
Output contract: `gold.*`.

Plan altitude: legs, responsibilities, dependencies, build order, tests.
This fixture is otherwise valid — it fails ONLY the leg-contiguity check: the
Legs section jumps leg-01 → leg-03 with no leg-02 (a dropped stretch).

## Legs

- **leg-01** — ingest and pin the raw sources read-only. Proves: raw reachable, counts stable.
- **leg-03** — publish gold: serving-ready tables shaped to the frozen questions. Proves: every frozen question maps to a gold table.

## Dependencies

```
raw.*  ->  leg-01  ->  leg-03  ->  gold.*
```

- One inbound seam: `raw.*` (given, frozen).

## Build order

1. **leg-01** — unblocks everything.
2. **leg-03** — publishes the contract.

Gating edge: the frozen acceptance-question set gates leg-03.

## Tests that prove each leg

| Leg | Tests (what they prove) |
|---|---|
| **leg-01** | Raw reachable + stable counts. Proves: the lane reads reality. |
| **leg-03** | Question-to-table mapping complete. Proves: the contract answers what was asked. |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | Refund handling in gold? | owner | No |

## Spec traceability

- **ADR-0002** — UTC grain honored.
