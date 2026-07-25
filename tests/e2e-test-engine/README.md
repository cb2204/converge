# e2e-test-engine — the cvg golden fixture (B-9)

The tiny, deterministic test bed every `cvg` piece is proven on
(see [`PLAN.md`](../../PLAN.md), §6). A brownfield-shaped
mini data stack: raw tables + a silver view exist; the **gold layer is
deliberately missing** — building it is the fixture backlog's work.

## Run

```bash
bash seed.sh            # rebuild data/toy.db from scratch (deterministic)
bash evals/smoke.sh     # PASSING eval  → exit 0 (seed integrity + control sum)
bash evals/red.sh       # DESIGNED-RED  → exit 1 until gold_daily_revenue is built
```

## The data (fixed — these numbers are load-bearing)

| table | rows | notes |
|---|---|---|
| `products` | 3 | 2 categories: widgets, gadgets |
| `orders` | 6 | 2 days: 2026-07-14, 2026-07-15 |
| `payments` | 4 | orders 1, 2, 3, 5 are paid |
| `silver_orders` (view) | 6 | joins all three, `is_paid` flag |

**Control sums (used by evals — do not change seed data without updating both):**

- Paid revenue total: **240.00** (20 + 40 + 100 + 80; revenue-is-paid-only)
- Expected gold, once built — `gold_daily_revenue(order_date, category, revenue)`:
  `2026-07-14`: widgets 20.00, gadgets 40.00 · `2026-07-15`: widgets 100.00, gadgets 80.00

## Rules

- Deterministic: no randomness, no timestamps-of-now in seeded data.
- `data/` is gitignored — the DB is always rebuilt, never committed.
- `evals/red.sh` doubles as backlog task T1's Success Criteria: RED on the
  unbuilt baseline, GREEN only when gold is real (a discriminating eval,
  gold-sanity by construction).

Requires: `bash` 3.2+, `sqlite3` (both ship with macOS).
