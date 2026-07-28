"""Dagster asset check — R-2 by-principal seam precondition.

The by-principal analytical-query count (non-capture principals == 0, R-2)
is only meaningful if the cluster has exactly one distinct dedicated capture
role (ADR-0003). This check asserts that precondition against `pg_roles`
directly; it does not create or grant anything (see ../principal.sql for
that) -- a check proves state, it doesn't establish it.
"""

from __future__ import annotations

import subprocess

CONTAINER = "uc-analytics-postgres"
DB = "ecommerce"
ADMIN_USER = "postgres"


def _run_psql(sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", CONTAINER,
            "psql", "-U", ADMIN_USER, "-d", DB,
            "-v", "ON_ERROR_STOP=1", "-tAc", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql failed: {result.stderr.strip()}")
    return result.stdout.strip()


def evaluate() -> bool:
    count = _run_psql(
        "select count(*) from pg_roles where rolname like '%capture%' "
        "and rolname <> 'postgres';"
    )
    n = int(count) if count else 0
    passed = n == 1
    print(f"principal_count_check: capture principals={n} passed={passed}")
    return passed


def main() -> int:
    return 0 if evaluate() else 1


if __name__ == "__main__":
    raise SystemExit(main())
