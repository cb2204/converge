# Plan · transform lane

lane-meta: thread=yes · risk=med · owner=analytics

The `## Legs` heading is present but the stretches are not named leg-NN — this
fixture exercises the second leg branch: section populated, no leg identifiers.

## Legs

- **ingest** — pin the raw sources read-only.
- **conform** — dedup, types, UTC grain.
- **publish** — serving-ready gold tables.

## Dependencies

raw.* -> ingest -> conform -> publish

## Build order

1. ingest first.
2. conform next.
3. publish last.

## Tests that prove each leg

| Leg | Tests |
|---|---|
| **ingest** | reachable |
| **conform** | uniqueness |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | none yet | owner | No |
