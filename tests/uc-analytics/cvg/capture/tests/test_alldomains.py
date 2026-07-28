"""All-domains capture tests: every domain lands the frozen change-record
shape, carries rows, and the _control fence holds — mirrors the
Task-Spec's Success Criteria (B-1/B-2/B-3).
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "pipelines"))
import customers  # noqa: E402
import orders  # noqa: E402
import payments  # noqa: E402
import products  # noqa: E402

DOMAINS = {
    "customers": customers,
    "products": products,
    "orders": orders,
    "payments": payments,
}

REQUIRED_COLUMNS = {"_lsn", "_op", "_captured_at", "_source_committed_at"}


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


def test_all_domains_have_frozen_change_record_shape():
    for name, module in DOMAINS.items():
        module.bootstrap()
        cols = _psql(
            module.ADMIN_USER,
            "SELECT column_name FROM information_schema.columns "
            f"WHERE table_schema='raw' AND table_name='{name}';",
        )
        present = {c.strip() for c in cols.splitlines() if c.strip()}
        assert REQUIRED_COLUMNS <= present, f"{name} missing required columns"


def test_all_domains_carry_rows():
    for name in DOMAINS:
        count = _psql(
            orders.ADMIN_USER, f"SELECT count(*) FROM raw.{name};"
        ).strip()
        assert int(count or 0) > 0, f"raw.{name} has no landed rows"


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


def test_no_pipeline_references_control_schema():
    pipelines_dir = Path(__file__).parent.parent / "pipelines"
    for path in pipelines_dir.glob("*.py"):
        assert "_control" not in path.read_text()
