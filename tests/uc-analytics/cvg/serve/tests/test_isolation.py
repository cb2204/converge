"""Below-seam isolation tests for the serve core (B-2).

Proves isolation is enforced by GRANTS, not by application discipline:
the `serve_reader` principal itself is denied at the database when it
tries to read raw/silver, and `GoldReader` refuses any table/field outside
the published gold contract before ever issuing a query below the seam.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "core"))
import reader  # noqa: E402


def _run_psql(user: str, sql: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [
            "docker", "exec", "-i", reader.CONTAINER,
            "psql", "-U", user, "-d", reader.DB,
            "-v", "ON_ERROR_STOP=1", "-tAF", "|",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )


def test_serve_role_exists_and_reads_gold():
    reader.ensure_serve_role()
    result = _run_psql(reader.SERVE_ROLE, "SELECT count(*) FROM gold.revenue;")
    assert result.returncode == 0, result.stderr


def test_serve_role_cannot_read_raw():
    reader.ensure_serve_role()
    result = _run_psql(reader.SERVE_ROLE, "SELECT * FROM raw.orders LIMIT 1;")
    assert result.returncode != 0, "serve_reader must be denied below the seam"
    assert "permission denied" in result.stderr.lower(), result.stderr


def test_serve_role_cannot_read_silver():
    reader.ensure_serve_role()
    result = _run_psql(reader.SERVE_ROLE, "SELECT * FROM silver.orders LIMIT 1;")
    assert result.returncode != 0, "serve_reader must be denied below the seam"
    assert "permission denied" in result.stderr.lower(), result.stderr


def test_reader_refuses_unpublished_field():
    try:
        reader.REVENUE.select(("not_a_real_column",))
    except PermissionError:
        return
    raise AssertionError("GoldReader must refuse a field outside the gold contract")


def test_reader_refuses_unpublished_table():
    try:
        reader.GoldReader("orders")
    except PermissionError:
        return
    raise AssertionError("GoldReader must refuse a table outside gold.*")


TESTS = [
    test_serve_role_exists_and_reads_gold,
    test_serve_role_cannot_read_raw,
    test_serve_role_cannot_read_silver,
    test_reader_refuses_unpublished_field,
    test_reader_refuses_unpublished_table,
]


def main() -> int:
    failures = []
    for test in TESTS:
        try:
            test()
        except AssertionError as exc:
            failures.append(f"{test.__name__}: {exc}")

    if failures:
        print(f"below-seam isolation FAILED ({len(failures)}/{len(TESTS)}):")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"below-seam isolation OK: {len(TESTS)}/{len(TESTS)} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
