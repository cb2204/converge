"""Q-SET-1 question -> gold table coverage check (leg-03, seam contract).

Q-SET-1 is frozen by analytics-eng and the `gold.*` schema is derived from it
(one freeze event — see the seam contract). This checks the half of that
freeze this leg owns: every question in the set maps to a published gold
table, and the mapped query actually runs against it — a stub table or a
renamed column would fail here, not just a file-shape check.

Stdlib-only, `docker exec psql` transport (same convention as capture and
publish/ducklake.py — no driver, no network egress in this environment).
"""

from __future__ import annotations

import subprocess
import sys

CONTAINER = "uc-analytics-postgres"
DB = "ecommerce"
ADMIN_USER = "postgres"

# Q-SET-1: the frozen question set this gold shape answers. Each question is
# pinned to the gold table + query that answers it, so the mapping is
# verified by execution, not asserted by name.
QSET1 = [
    {
        "id": "Q1",
        "question": "What is total revenue captured?",
        "domain": "payments",
        "gold_table": "revenue",
        "query": "SELECT coalesce(sum(revenue), 0) FROM gold.revenue",
    },
    {
        "id": "Q2",
        "question": "What is revenue by product?",
        "domain": "products",
        "gold_table": "revenue_by_product",
        "query": "SELECT product_id, revenue FROM gold.revenue_by_product ORDER BY product_id LIMIT 1",
    },
    {
        "id": "Q3",
        "question": "What is revenue by customer?",
        "domain": "customers",
        "gold_table": "revenue",
        "query": "SELECT customer_id, sum(revenue) FROM gold.revenue GROUP BY customer_id ORDER BY customer_id LIMIT 1",
    },
    {
        "id": "Q4",
        "question": "What is revenue over time (by day)?",
        "domain": "orders",
        "gold_table": "revenue",
        "query": "SELECT date_trunc('day', ordered_at), sum(revenue) FROM gold.revenue GROUP BY 1 ORDER BY 1 LIMIT 1",
    },
    {
        "id": "Q5",
        "question": "What is the revenue for a specific order?",
        "domain": "orders",
        "gold_table": "revenue",
        "query": "SELECT order_id, revenue FROM gold.revenue ORDER BY order_id LIMIT 1",
    },
    {
        "id": "Q6",
        "question": "Which product earns the most revenue?",
        "domain": "products",
        "gold_table": "revenue_by_product",
        "query": "SELECT product_id, revenue FROM gold.revenue_by_product ORDER BY revenue DESC LIMIT 1",
    },
]

GOLD_TABLES_REQUIRED = {q["gold_table"] for q in QSET1}


def _psql(sql: str) -> tuple[int, str, str]:
    result = subprocess.run(
        [
            "docker", "exec", "-i", CONTAINER,
            "psql", "-U", ADMIN_USER, "-d", DB,
            "-v", "ON_ERROR_STOP=1", "-tAc", sql,
        ],
        capture_output=True, text=True,
    )
    return result.returncode, result.stdout, result.stderr


def _published_gold_tables() -> set[str]:
    code, out, err = _psql(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'gold'"
    )
    if code != 0:
        raise RuntimeError(f"could not list gold.* tables: {err.strip()}")
    return {line.strip() for line in out.splitlines() if line.strip()}


def check_coverage() -> list[str]:
    """Returns a list of failure messages; empty means full coverage."""
    failures = []

    published = _published_gold_tables()
    missing_tables = GOLD_TABLES_REQUIRED - published
    if missing_tables:
        failures.append(f"gold tables missing from the database: {sorted(missing_tables)}")
        return failures  # no point running queries against tables that don't exist

    for q in QSET1:
        code, out, err = _psql(q["query"])
        if code != 0:
            failures.append(f"{q['id']} ({q['question']}) -> gold.{q['gold_table']}: query failed: {err.strip()}")
        elif not out.strip():
            failures.append(f"{q['id']} ({q['question']}) -> gold.{q['gold_table']}: query returned no answer")

    return failures


def main() -> int:
    failures = check_coverage()
    if failures:
        print(f"Q-SET-1 coverage FAILED ({len(failures)}/{len(QSET1)} questions unanswered):")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Q-SET-1 coverage OK: {len(QSET1)}/{len(QSET1)} questions map to a gold table and answer.")
    for q in QSET1:
        print(f"  - {q['id']} [{q['domain']}] {q['question']} -> gold.{q['gold_table']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
