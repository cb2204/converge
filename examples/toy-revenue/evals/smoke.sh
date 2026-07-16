#!/usr/bin/env bash
# smoke.sh — the fixture's PASSING eval: seed integrity + silver layer + control sum.
# Exit 0 iff the seeded database is exactly as documented in README.md.
set -euo pipefail
cd "$(dirname "$0")/.."
DB=data/toy.db

fail() { echo "SMOKE FAIL: $1" >&2; exit 1; }

[ -f "$DB" ] || fail "missing $DB — run seed.sh first"

[ "$(sqlite3 "$DB" 'SELECT count(*) FROM products;')" = "3" ] || fail "products count != 3"
[ "$(sqlite3 "$DB" 'SELECT count(*) FROM orders;')"   = "6" ] || fail "orders count != 6"
[ "$(sqlite3 "$DB" 'SELECT count(*) FROM payments;')" = "4" ] || fail "payments count != 4"

[ "$(sqlite3 "$DB" 'SELECT count(*) FROM silver_orders;')" = "6" ] || fail "silver_orders view != 6 rows"

# The control sum: paid revenue must be exactly 240.00 (revenue-is-paid-only).
got=$(sqlite3 "$DB" "SELECT printf('%.2f', sum(paid_amount)) FROM silver_orders WHERE is_paid = 1;")
[ "$got" = "240.00" ] || fail "paid revenue control-sum: expected 240.00, got $got"

echo "SMOKE: PASS (tables 3/6/4, silver ok, paid revenue = 240.00)"
