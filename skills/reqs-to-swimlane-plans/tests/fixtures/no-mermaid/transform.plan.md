# Plan · transform lane

lane-meta: thread=yes · risk=med · owner=analytics

Component **A · Transform**. Input contract: `raw.*`. Output contract: `gold.*`.
Otherwise valid, but this fixture has NO ## Architecture / mermaid block — it
must fail ONLY the VISUAL check.

## Legs

- **leg-01** — ingest and pin raw read-only. Proves: reachable, stable counts.
- **leg-02** — conform to silver. Proves: dedup + UTC grain.

## Dependencies

```
raw.*  ->  leg-01  ->  leg-02  ->  gold.*
```

## Build order

1. **leg-01** first.
2. **leg-02** next.

## Tests that prove each leg

| Leg | Tests |
|---|---|
| **leg-01** | reachable + stable counts. |
| **leg-02** | dedup + UTC grain. |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | none yet | owner | No |
