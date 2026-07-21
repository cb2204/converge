# Plan · serve lane

lane-meta: thread=yes · risk=low · owner=analytics

## Legs

- **leg-01** — query core over gold. Proves: contract-only reads.

eval: ./check-query-core.sh

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
