"""Report row counts for the four public operational tables."""

from __future__ import annotations

import json
import subprocess
import sys

CONTAINER = "uc-analytics-postgres"
DATABASE = "ecommerce"
USER = "postgres"
TABLES = ("customers", "products", "orders", "payments")

COUNT_QUERY = """
SELECT count(*)::bigint FROM public.customers
UNION ALL
SELECT count(*)::bigint FROM public.products
UNION ALL
SELECT count(*)::bigint FROM public.orders
UNION ALL
SELECT count(*)::bigint FROM public.payments;
"""


def read_counts() -> dict[str, int]:
    result = subprocess.run(
        [
            "docker",
            "exec",
            "-i",
            CONTAINER,
            "psql",
            "-U",
            USER,
            "-d",
            DATABASE,
            "-v",
            "ON_ERROR_STOP=1",
            "-tA",
            "-c",
            COUNT_QUERY,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = " ".join(result.stderr.split()) or "psql exited non-zero"
        raise RuntimeError(detail)

    values = result.stdout.splitlines()
    if len(values) != len(TABLES):
        raise RuntimeError(f"expected {len(TABLES)} counts, received {len(values)}")

    try:
        return {table: int(value) for table, value in zip(TABLES, values)}
    except ValueError as exc:
        raise RuntimeError("psql returned a non-integer count") from exc


def main() -> int:
    try:
        counts = read_counts()
    except (OSError, RuntimeError) as exc:
        message = " ".join(str(exc).split()) or exc.__class__.__name__
        print(f"row_counts: {message}", file=sys.stderr)
        return 1

    print(json.dumps(counts, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
