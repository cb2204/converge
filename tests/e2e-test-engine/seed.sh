#!/usr/bin/env bash
# seed.sh — create and seed the toy-revenue SQLite database.
# Deterministic: fixed rows, no randomness, so control sums are stable.
# Paid-revenue control sum: 240.00 (orders 1,2,3,5 — see README.md).
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p data
rm -f data/toy.db

sqlite3 data/toy.db <<'SQL'
CREATE TABLE products (
  product_id INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  category   TEXT NOT NULL,
  unit_price REAL NOT NULL
);

CREATE TABLE orders (
  order_id   INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id),
  quantity   INTEGER NOT NULL,
  order_date TEXT NOT NULL              -- ISO date, UTC grain
);

CREATE TABLE payments (
  payment_id INTEGER PRIMARY KEY,
  order_id   INTEGER NOT NULL REFERENCES orders(order_id),
  amount     REAL NOT NULL,
  status     TEXT NOT NULL,             -- 'paid' only; failed payments never land here
  paid_at    TEXT NOT NULL
);

INSERT INTO products VALUES
  (1, 'Widget A', 'widgets', 10.00),
  (2, 'Widget B', 'widgets', 25.00),
  (3, 'Gadget X', 'gadgets', 40.00);

INSERT INTO orders VALUES
  (1, 1, 2, '2026-07-14'),
  (2, 3, 1, '2026-07-14'),
  (3, 2, 4, '2026-07-15'),
  (4, 1, 1, '2026-07-15'),
  (5, 3, 2, '2026-07-15'),
  (6, 2, 1, '2026-07-15');

INSERT INTO payments VALUES
  (1, 1,  20.00, 'paid', '2026-07-14T10:00:00Z'),
  (2, 2,  40.00, 'paid', '2026-07-14T11:30:00Z'),
  (3, 3, 100.00, 'paid', '2026-07-15T09:15:00Z'),
  (4, 5,  80.00, 'paid', '2026-07-15T16:45:00Z');

-- Brownfield silver layer: exists before any backlog task runs.
-- Gold (gold_daily_revenue) deliberately does NOT exist — building it is the
-- fixture backlog's work (see cvg-todo.md step 0.2).
CREATE VIEW silver_orders AS
SELECT
  o.order_id,
  o.order_date,
  p.category,
  o.quantity,
  p.unit_price,
  o.quantity * p.unit_price                    AS order_value,
  CASE WHEN pay.order_id IS NULL THEN 0 ELSE 1 END AS is_paid,
  COALESCE(pay.amount, 0.0)                    AS paid_amount
FROM orders o
JOIN products p       ON p.product_id = o.product_id
LEFT JOIN payments pay ON pay.order_id = o.order_id AND pay.status = 'paid';
SQL

echo "seeded data/toy.db (products=3 orders=6 payments=4, paid revenue control-sum=240.00)"
