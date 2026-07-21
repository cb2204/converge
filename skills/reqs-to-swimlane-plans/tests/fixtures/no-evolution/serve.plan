# Plan · serve lane

lane-meta: thread=no · risk=low · owner=analytics

## Legs

- **leg-01** — query core over gold. Proves: contract-only reads.

## The interface this lane consumes (the seam — hard boundary)

This lane reads **only the `gold.*` contract**, and never reaches below it.

| upstream unit | fields consumed | read by (this lane's leg) |
|---|---|---|
| `gold.daily_revenue` | day, category, revenue | leg-01 |

## Dependencies

gold.* -> leg-01

## Build order

1. **leg-01** only.

## Tests that prove each leg

| Leg | Tests |
|---|---|
| **leg-01** | reads only gold |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | none yet | owner | No |
