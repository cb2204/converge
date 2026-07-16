#!/usr/bin/env bash
# red.sh — the fixture's designed-to-FAIL eval (exit 1 today, by design).
#
# It asserts the gold layer exists and matches the control sum. gold_daily_revenue
# is deliberately NOT built by seed.sh — building it is the fixture backlog's T1
# (step 0.2). So this eval discriminates: RED on the unbuilt baseline, GREEN only
# after a worker really builds gold correctly. It doubles as T1's Success Criteria.
set -euo pipefail
cd "$(dirname "$0")/.."
DB=data/toy.db

[ -f "$DB" ] || { echo "RED FAIL: missing $DB — run seed.sh first" >&2; exit 1; }

total=$(sqlite3 "$DB" "SELECT printf('%.2f', sum(revenue)) FROM gold_daily_revenue;" 2>/dev/null) || {
  echo "RED: gold_daily_revenue does not exist yet (expected until backlog T1 builds it)" >&2
  exit 1
}
[ "$total" = "240.00" ] || { echo "RED FAIL: gold total expected 240.00, got $total" >&2; exit 1; }

echo "RED eval now GREEN: gold_daily_revenue exists and sums to 240.00"
