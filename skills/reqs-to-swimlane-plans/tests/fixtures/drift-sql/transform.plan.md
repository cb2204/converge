# Plan · transform lane

lane-meta: thread=yes · risk=med · owner=analytics

## Legs

- **leg-01** — conform to silver: dedup by business signature. Proves: no duplicate signatures.
- **leg-02** — publish gold, and here is exactly how:

SELECT category, date(ordered_at) AS day, sum(amount) AS revenue
FROM orders JOIN payments USING (order_id)
GROUP BY 1, 2;

## Dependencies

raw.* -> leg-01 -> leg-02

## Build order

1. **leg-01** first.
2. **leg-02** next.

## Tests that prove each leg

| Leg | Tests |
|---|---|
| **leg-01** | uniqueness |
| **leg-02** | mapping |

## Open questions

| # | Item | Owner | Blocks build? |
|---|---|---|---|
| Q1 | none yet | owner | No |
