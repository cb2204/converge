"""Capture — products off the Postgres WAL into raw.products.

Stdlib-only, `docker exec psql` transport (no driver, no network egress in
this environment). Reads logical-decoding output (`test_decoding` plugin)
straight off a replication slot scoped to `public.products` via a
publication, and lands one change-record row per event into
`raw.products` in the frozen seam shape: product_id / _lsn / _op /
_captured_at / _source_committed_at.

The read is scoped to `public.products` only, via the dedicated
`capture_reader` principal (see principal.sql), never the operational app's
connection, and never anything below the seam.
"""

from __future__ import annotations

import re
import subprocess

CONTAINER = "uc-analytics-postgres"
DB = "ecommerce"
ADMIN_USER = "postgres"
CAPTURE_USER = "capture_reader"
SLOT = "products_capture_slot"
PUBLICATION = "products_pub"

_COL_RE = re.compile(r"(\S+)\[([^\]]+)\]:")
_OP_RE = re.compile(r"^table public\.products: (INSERT|UPDATE|DELETE):")
_COMMIT_TS_RE = re.compile(r"^COMMIT (\d+)(?: \(at (.+)\))?")
_BEGIN_RE = re.compile(r"^BEGIN (\d+)")


def _run_psql(user: str, sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", CONTAINER,
            "psql", "-U", user, "-d", DB,
            "-v", "ON_ERROR_STOP=1", "-tAF", "|",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql ({user}) failed: {result.stderr.strip()}")
    return result.stdout


def bootstrap() -> None:
    """Idempotent setup: raw landing table, publication, replication slot,
    and the grants the capture principal needs to read + land on its own."""
    _run_psql(ADMIN_USER, "CREATE SCHEMA IF NOT EXISTS raw;")
    _run_psql(
        ADMIN_USER,
        """
        CREATE TABLE IF NOT EXISTS raw.products (
            product_id           BIGINT      NOT NULL,
            sku                  TEXT,
            name                 TEXT,
            category             TEXT,
            unit_price           NUMERIC(10,2),
            cost                 NUMERIC(10,2),
            created_at           TIMESTAMPTZ,
            _lsn                 PG_LSN      NOT NULL,
            _op                  TEXT        NOT NULL,
            _captured_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
            _source_committed_at TIMESTAMPTZ
        );
        """,
    )
    _run_psql(ADMIN_USER, "GRANT USAGE ON SCHEMA raw TO capture_reader;")
    _run_psql(ADMIN_USER, "GRANT SELECT, INSERT ON raw.products TO capture_reader;")
    _run_psql(ADMIN_USER, "GRANT SELECT ON public.products TO capture_reader;")

    pub_exists = _run_psql(
        ADMIN_USER, f"SELECT 1 FROM pg_publication WHERE pubname = '{PUBLICATION}';"
    ).strip()
    if not pub_exists:
        _run_psql(ADMIN_USER, f"CREATE PUBLICATION {PUBLICATION} FOR TABLE public.products;")

    slot_exists = _run_psql(
        ADMIN_USER, f"SELECT 1 FROM pg_replication_slots WHERE slot_name = '{SLOT}';"
    ).strip()
    if not slot_exists:
        _run_psql(
            ADMIN_USER,
            f"SELECT pg_create_logical_replication_slot('{SLOT}', 'test_decoding');",
        )


def _parse_columns(data: str) -> dict[str, str]:
    matches = list(_COL_RE.finditer(data))
    cols: dict[str, str] = {}
    for i, m in enumerate(matches):
        name = m.group(1)
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(data)
        cols[name] = data[start:end].strip()
    return cols


def _sql_literal(cols: dict[str, str], key: str) -> str:
    return cols[key] if key in cols else "NULL"


def fetch_and_land() -> int:
    """Pull new changes off the slot (as the capture principal) and land
    them into raw.products. Returns the number of change-records landed."""
    raw = _run_psql(
        CAPTURE_USER,
        f"SELECT lsn, xid, data FROM pg_logical_slot_get_changes("
        f"'{SLOT}', NULL, NULL, 'include-timestamp', 'on');",
    )

    committed_at_by_xid: dict[str, str] = {}
    pending_by_xid: dict[str, list[tuple[str, str]]] = {}
    values: list[str] = []

    for line in raw.splitlines():
        if not line.strip():
            continue
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        lsn, xid, data = parts

        begin_m = _BEGIN_RE.match(data)
        if begin_m:
            pending_by_xid.setdefault(xid, [])
            continue

        commit_m = _COMMIT_TS_RE.match(data)
        if commit_m:
            committed_at = commit_m.group(2) or ""
            for pending_lsn, pending_data in pending_by_xid.pop(xid, []):
                op_m = _OP_RE.match(pending_data)
                if not op_m:
                    continue
                op = op_m.group(1).lower()
                cols = _parse_columns(pending_data)
                committed_literal = f"'{committed_at}'" if committed_at else "NULL"
                values.append(
                    "("
                    f"{_sql_literal(cols, 'product_id')}, "
                    f"{_sql_literal(cols, 'sku')}, "
                    f"{_sql_literal(cols, 'name')}, "
                    f"{_sql_literal(cols, 'category')}, "
                    f"{_sql_literal(cols, 'unit_price')}, "
                    f"{_sql_literal(cols, 'cost')}, "
                    f"{_sql_literal(cols, 'created_at')}, "
                    f"'{pending_lsn}', '{op}', now(), {committed_literal}"
                    ")"
                )
            continue

        if _OP_RE.match(data):
            pending_by_xid.setdefault(xid, []).append((lsn, data))

    if not values:
        return 0

    insert_sql = (
        "INSERT INTO raw.products (product_id, sku, name, category, "
        "unit_price, cost, created_at, _lsn, _op, _captured_at, "
        "_source_committed_at) VALUES " + ", ".join(values) + ";"
    )
    _run_psql(CAPTURE_USER, insert_sql)
    return len(values)


def run() -> int:
    bootstrap()
    return fetch_and_land()


if __name__ == "__main__":
    landed = run()
    print(f"landed {landed} change-record(s) into raw.products")
