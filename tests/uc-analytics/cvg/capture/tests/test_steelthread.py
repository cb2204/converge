"""Steel-thread capture tests: dedicated principal, the seam shape, the
fence, and end-to-end freshness — mirrors the Task-Spec's Success Criteria.
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "pipelines"))
import orders  # noqa: E402

REQUIRED_COLUMNS = {"order_id", "_lsn", "_op", "_captured_at", "_source_committed_at"}


def _psql(user: str, sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", orders.CONTAINER,
            "psql", "-U", user, "-d", orders.DB,
            "-v", "ON_ERROR_STOP=1", "-tAF", "|",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
    return result.stdout


def test_capture_principal_exists_and_can_read_orders():
    role = _psql(
        orders.ADMIN_USER,
        "SELECT rolname FROM pg_roles WHERE rolname LIKE '%capture%' "
        "AND rolname <> 'postgres' LIMIT 1;",
    ).strip()
    assert role
    granted = _psql(
        orders.ADMIN_USER, f"SELECT has_table_privilege('{role}','public.orders','SELECT');"
    ).strip()
    assert granted == "t"


def test_control_fence_holds_for_capture_principal():
    role = _psql(
        orders.ADMIN_USER,
        "SELECT rolname FROM pg_roles WHERE rolname LIKE '%capture%' "
        "AND rolname <> 'postgres' LIMIT 1;",
    ).strip()
    assert role
    fenced = _psql(
        orders.ADMIN_USER, f"SELECT has_schema_privilege('{role}','_control','USAGE');"
    ).strip()
    assert fenced == "f"


def test_raw_orders_has_frozen_change_record_shape():
    orders.bootstrap()
    cols = _psql(
        orders.ADMIN_USER,
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_schema='raw' AND table_name='orders';",
    )
    present = {c.strip() for c in cols.splitlines() if c.strip()}
    assert REQUIRED_COLUMNS <= present


def test_probe_lands_a_change_record():
    before = _psql(orders.ADMIN_USER, "SELECT count(*) FROM raw.orders;").strip()
    result = subprocess.run(
        [sys.executable, str(Path(__file__).parent.parent / "probe_commit_to_answer.py")],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
    after = _psql(orders.ADMIN_USER, "SELECT count(*) FROM raw.orders;").strip()
    assert int(after) > int(before or 0)
