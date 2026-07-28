"""Probe: commit a source order, run the capture pipeline, prove the change
reaches a served answer (raw.orders) inside the R-1 freshness budget (p99 <=
5 min). This is the steel thread's one coherent done-condition (B-1).
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "pipelines"))
import orders  # noqa: E402

FRESHNESS_BUDGET_SECONDS = 5 * 60


def _run_psql(sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", orders.CONTAINER,
            "psql", "-U", orders.ADMIN_USER, "-d", orders.DB,
            "-v", "ON_ERROR_STOP=1", "-tAF", "|",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql failed: {result.stderr.strip()}")
    return result.stdout


def _commit_source_order() -> int:
    customer_id = _run_psql("SELECT customer_id FROM customers LIMIT 1;").strip()
    product_id = _run_psql("SELECT product_id FROM products LIMIT 1;").strip()
    _run_psql(
        "INSERT INTO orders (customer_id, product_id, quantity, unit_price, "
        "total_amount, status, ordered_at) VALUES "
        f"({customer_id}, {product_id}, 1, 9.99, 9.99, 'placed', now()) "
        "RETURNING order_id;"
    )
    order_id = _run_psql(
        "SELECT order_id FROM orders ORDER BY order_id DESC LIMIT 1;"
    ).strip()
    return int(order_id)


def main() -> int:
    orders.bootstrap()

    committed_at = time.time()
    order_id = _commit_source_order()

    orders.fetch_and_land()

    landed = _run_psql(
        f"SELECT count(*) FROM raw.orders WHERE order_id = {order_id};"
    ).strip()
    if landed == "0" or landed == "":
        print(f"probe FAILED: order {order_id} never reached raw.orders")
        return 1

    elapsed = time.time() - committed_at
    if elapsed > FRESHNESS_BUDGET_SECONDS:
        print(f"probe FAILED: freshness lag {elapsed:.1f}s exceeds R-1 budget")
        return 1

    print(f"probe OK: order {order_id} landed in raw.orders after {elapsed:.2f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
