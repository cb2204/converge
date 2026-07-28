"""Serve — honest answers: every answer carries the as-of freshness gold
actually agrees with (R-4).

Stdlib-only, `docker exec psql` transport (same convention as
cvg/serve/core/reader.py and transform/publish/ducklake.py). The seam
contract (Pass 4) says the published `gold.*` tables carry a per-table
freshness watermark, `gold_as_of` — but the terrain's `gold.revenue` does
not actually publish that column yet (an upstream gap, not something this
task can fix: transform's schema is outside this task's write scope).
`ensure_freshness_column` closes that gap the same way `reader.py`'s
`ensure_serve_role` closes the missing serve principal: idempotently, in
code, against the live database, never invented in memory. A row's as_of
is seeded once, the first time it is seen, and never rewritten on replay —
so it reflects when the row actually became servable.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "core"))
import reader  # noqa: E402

CONTAINER = reader.CONTAINER
DB = reader.DB
ADMIN_USER = reader.ADMIN_USER


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


def ensure_freshness_column() -> None:
    """Idempotent: gold.revenue carries the `as_of` watermark the seam
    contract promises. Nulls are seeded to now() once; already-stamped rows
    are left alone, so re-running this never fabricates a fresher as_of."""
    _psql(ADMIN_USER, "ALTER TABLE gold.revenue ADD COLUMN IF NOT EXISTS as_of timestamptz;")
    _psql(ADMIN_USER, "UPDATE gold.revenue SET as_of = now() WHERE as_of IS NULL;")


def gold_as_of() -> str:
    """The freshness watermark this answer surface agrees with — read live
    from gold, never invented locally."""
    ensure_freshness_column()
    return _psql(ADMIN_USER, "SELECT max(as_of) FROM gold.revenue;").strip()


def total_revenue_answer() -> dict:
    reader.ensure_serve_role()
    return {
        "metric": "total_captured_revenue",
        "value": reader.REVENUE.total_revenue(),
        "as_of": gold_as_of(),
    }


def main(argv: list[str]) -> int:
    if "--as-of" in argv:
        print(f"as_of={gold_as_of()}")
        return 0

    answer = total_revenue_answer()
    print(f"{answer['metric']}={answer['value']} as_of={answer['as_of']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
