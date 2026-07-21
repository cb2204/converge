# Plan · transform lane

lane-meta: thread=yes · risk=med · owner=analytics

## Features

- **ingest** — pin the raw sources read-only.
- **conform** — dedup, types, UTC grain.
- **publish** — serving-ready gold tables.

## Dependencies

raw.* -> ingest -> conform -> publish

## Build order

1. ingest first.
2. conform next.
3. publish last.

## Tests that prove each piece

| Piece | Tests |
|---|---|
| **ingest** | reachable |
| **conform** | uniqueness |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | none yet | owner | No |
