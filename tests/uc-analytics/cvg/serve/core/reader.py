"""Serve core — one read-only reader per published `gold.*` table.

Stdlib-only, `docker exec psql` transport (same convention as capture and
transform/publish/ducklake.py — no driver, no network egress in this
environment). Below-seam isolation (ADR-0001) is enforced two ways at once:

  1. Database grants: all reads run as the dedicated `serve_reader`
     principal, which is only ever granted USAGE on `gold` + SELECT on the
     published gold tables — it is never granted anything on raw/silver/
     public, so a query below the seam fails at the database, not by
     discipline.
  2. Contract check in code: `GoldReader` only knows the columns each gold
     table actually publishes. A request for a table or field outside that
     contract is refused before any SQL is issued — never resolved by
     falling through to a deeper read.
"""

from __future__ import annotations

import subprocess
import sys

CONTAINER = "uc-analytics-postgres"
DB = "ecommerce"
ADMIN_USER = "postgres"
SERVE_ROLE = "serve_reader"

# The published gold contract (ADR-0001 seam): table -> its published
# columns. Nothing outside this dict is a "gold table" as far as this
# reader is concerned.
GOLD_CONTRACT = {
    "revenue": ("order_id", "customer_id", "product_id", "ordered_at", "revenue"),
    "revenue_by_product": ("product_id", "name", "revenue"),
}


def _psql(user: str, sql: str) -> str:
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


def ensure_serve_role() -> None:
    """Idempotent: create the serve principal and grant it exactly
    USAGE on gold + SELECT on the published gold tables — nothing else.
    Below-seam isolation holds by omission (raw/silver are never granted),
    the same pattern principal.sql uses for the _control fence."""
    _psql(
        ADMIN_USER,
        f"""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{SERVE_ROLE}') THEN
                CREATE ROLE {SERVE_ROLE} LOGIN;
            END IF;
        END
        $$;
        """,
    )
    _psql(ADMIN_USER, f"GRANT CONNECT ON DATABASE {DB} TO {SERVE_ROLE};")
    _psql(ADMIN_USER, "GRANT USAGE ON SCHEMA gold TO " + SERVE_ROLE + ";")
    tables = ", ".join(f"gold.{t}" for t in GOLD_CONTRACT)
    _psql(ADMIN_USER, f"GRANT SELECT ON {tables} TO {SERVE_ROLE};")


class GoldReader:
    """A read-only reader scoped to exactly one published gold table."""

    def __init__(self, table: str):
        if table not in GOLD_CONTRACT:
            raise PermissionError(
                f"'{table}' is not a published gold table — refused, "
                "not resolved by a deeper read"
            )
        self.table = table
        self.columns = GOLD_CONTRACT[table]

    def select(self, columns: tuple[str, ...] | None = None) -> str:
        columns = columns or self.columns
        unknown = [c for c in columns if c not in self.columns]
        if unknown:
            raise PermissionError(
                f"{unknown} not published in gold.{self.table}'s contract — "
                "refused, not resolved by a deeper read"
            )
        col_sql = ", ".join(columns)
        return _psql(SERVE_ROLE, f"SELECT {col_sql} FROM gold.{self.table};")

    def total_revenue(self) -> str:
        if "revenue" not in self.columns:
            raise PermissionError(
                f"gold.{self.table} does not publish a 'revenue' column — refused"
            )
        out = _psql(SERVE_ROLE, f"SELECT coalesce(sum(revenue), 0) FROM gold.{self.table};")
        return out.strip()


REVENUE = GoldReader("revenue")
REVENUE_BY_PRODUCT = GoldReader("revenue_by_product")


def main() -> int:
    ensure_serve_role()

    total = REVENUE.total_revenue()
    print(f"gold.revenue total_captured_revenue={total}")

    rows = [r for r in REVENUE_BY_PRODUCT.select().splitlines() if r]
    for row in rows[:5]:
        print(f"gold.revenue_by_product {row}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
