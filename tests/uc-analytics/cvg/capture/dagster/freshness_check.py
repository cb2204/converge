"""Dagster asset check — R-1 freshness (p99 write->queryable <= 5min).

Written so a real Dagster `@asset_check` can wrap `evaluate()` directly; the
transport stays stdlib-only + `docker exec psql`, matching the leg-01/leg-02
capture pipeline (see ../pipelines/orders.py, ADR-0002).

Samples one write->queryable cycle: commit a source order, run the capture
pipeline, then measure lag off `raw.orders._captured_at` — the same freshness
lineage seed leg-01/02 land on every row.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipelines"))
import orders  # noqa: E402

FRESHNESS_BUDGET_SECONDS = 5 * 60


def _run_psql(user: str, sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", orders.CONTAINER,
            "psql", "-U", user, "-d", orders.DB,
            "-v", "ON_ERROR_STOP=1", "-tAF", "|",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql ({user}) failed: {result.stderr.strip()}")
    return result.stdout


def _commit_source_change() -> None:
    customer_id = _run_psql(orders.ADMIN_USER, "SELECT customer_id FROM customers LIMIT 1;").strip()
    product_id = _run_psql(orders.ADMIN_USER, "SELECT product_id FROM products LIMIT 1;").strip()
    _run_psql(
        orders.ADMIN_USER,
        "INSERT INTO orders (customer_id, product_id, quantity, unit_price, "
        "total_amount, status, ordered_at) VALUES "
        f"({customer_id}, {product_id}, 1, 1.00, 1.00, 'placed', now());",
    )


def measure_lag_seconds() -> float:
    lag = _run_psql(
        orders.ADMIN_USER,
        "SELECT coalesce(ceil(extract(epoch from now() - max(_captured_at))), 999999) "
        "FROM raw.orders;",
    ).strip()
    return float(lag) if lag else 999999.0


def evaluate() -> bool:
    """Sample one write->queryable cycle; True/False is the shape a Dagster
    `AssetCheckResult.passed` would carry."""
    orders.bootstrap()
    _commit_source_change()
    orders.fetch_and_land()
    lag = measure_lag_seconds()
    passed = lag < FRESHNESS_BUDGET_SECONDS
    print(f"freshness_check: lag={lag:.1f}s budget={FRESHNESS_BUDGET_SECONDS}s passed={passed}")
    return passed


def main() -> int:
    return 0 if evaluate() else 1


if __name__ == "__main__":
    raise SystemExit(main())
