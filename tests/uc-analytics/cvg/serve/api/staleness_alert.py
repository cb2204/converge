"""R-4 staleness alert + R-10 staleness audit.

A feed stoppage past 15 min must fire an alert no later than 20 min after
the last update (R-4); any staleness event beyond the 5-min freshness floor
(R-1) is audited with its start, duration, and affected domains (R-10),
whether or not it ever reaches the alert threshold. Both read the live
`gold.revenue.as_of` watermark from `answers.py` — never a value invented
in this script — so `--selftest` proves the alert against an induced,
live feed stoppage instead of grepping for the number 20.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import answers  # noqa: E402

FLOOR_SECONDS = 5 * 60      # R-1 floor: staleness events are audited from here up
ALERT_SECONDS = 15 * 60     # R-4: a stoppage past this point must alert
DEADLINE_SECONDS = 20 * 60  # R-4: ... no later than this point

DOMAINS = ("orders", "payments")  # revenue's two-hop feed (payments -> orders)

_AUDIT_SCHEMA_SQL = """
CREATE SCHEMA IF NOT EXISTS serve;
CREATE TABLE IF NOT EXISTS serve.staleness_audit (
    id serial PRIMARY KEY,
    started_at timestamptz NOT NULL,
    detected_at timestamptz NOT NULL DEFAULT now(),
    duration_seconds numeric NOT NULL,
    domains text[] NOT NULL
);
"""


def ensure_audit_table() -> None:
    answers._psql(answers.ADMIN_USER, _AUDIT_SCHEMA_SQL)


def _seconds_stale(as_of_text: str) -> float:
    out = answers._psql(
        answers.ADMIN_USER,
        f"SELECT extract(epoch FROM now() - '{as_of_text}'::timestamptz);",
    ).strip()
    return float(out)


def record_if_stale(as_of_text: str, staleness_seconds: float) -> bool:
    """R-10: any staleness event beyond the 5-min floor is recorded with its
    start (the last known-good as_of), duration, and affected domains."""
    if staleness_seconds < FLOOR_SECONDS:
        return False
    ensure_audit_table()
    domains_sql = "ARRAY[" + ", ".join(f"'{d}'" for d in DOMAINS) + "]"
    answers._psql(
        answers.ADMIN_USER,
        "INSERT INTO serve.staleness_audit (started_at, duration_seconds, domains) "
        f"VALUES ('{as_of_text}'::timestamptz, {staleness_seconds}, {domains_sql});",
    )
    return True


def check() -> dict:
    as_of_text = answers.gold_as_of()
    staleness = _seconds_stale(as_of_text)
    audited = record_if_stale(as_of_text, staleness)
    return {
        "as_of": as_of_text,
        "staleness_seconds": staleness,
        "alert": staleness >= ALERT_SECONDS,
        "audited": audited,
    }


def _backdate(seconds: float) -> None:
    """Test-only: induce a feed stoppage by pushing gold's as_of into the
    past, so the alert/audit are proven against a real, live condition."""
    answers.ensure_freshness_column()
    answers._psql(
        answers.ADMIN_USER,
        f"UPDATE gold.revenue SET as_of = now() - interval '{int(seconds)} seconds';",
    )


def _refresh() -> None:
    answers._psql(answers.ADMIN_USER, "UPDATE gold.revenue SET as_of = now();")


def selftest() -> None:
    try:
        _backdate(DEADLINE_SECONDS + 5 * 60)  # 25 min stale: past the R-4 deadline
        stale = check()
        assert stale["alert"], "alert must fire once staleness passes the deadline"
        assert stale["audited"], "an event past the 5-min floor must be audited"

        _refresh()
        fresh = check()
        assert not fresh["alert"], "a fresh feed must not alert"
    finally:
        _refresh()


def main(argv: list[str]) -> int:
    if "--selftest" in argv:
        try:
            selftest()
        except AssertionError as exc:
            print(f"staleness_alert selftest FAILED: {exc}")
            return 1
        print("staleness_alert selftest OK")
        return 0

    result = check()
    status = "ALERT" if result["alert"] else "ok"
    print(f"staleness={result['staleness_seconds']:.0f}s as_of={result['as_of']} status={status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
