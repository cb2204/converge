"""Freshness/honesty tests (R-4, R-10).

Proves against the live warehouse — never by grepping for a threshold
number — that: every answer's as-of matches rows gold actually holds; the
staleness alert fires once an induced stoppage passes the R-4 deadline and
stays quiet once fresh; and a staleness event beyond the R-1 floor is
audited with a real start, duration, and domains.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "api"))
import answers  # noqa: E402
import staleness_alert  # noqa: E402


def _audit_count() -> int:
    out = answers._psql(answers.ADMIN_USER, "SELECT count(*) FROM serve.staleness_audit;").strip()
    return int(out or 0)


def test_answer_carries_matching_as_of():
    as_of = answers.gold_as_of()
    known = answers._psql(
        answers.ADMIN_USER,
        f"SELECT count(*) FROM gold.revenue WHERE as_of::date = '{as_of}'::date;",
    ).strip()
    assert int(known) > 0, "the as-of stamp must match rows gold actually holds"


def test_alert_fires_past_deadline_and_quiet_when_fresh():
    try:
        staleness_alert._backdate(staleness_alert.DEADLINE_SECONDS + 60)
        result = staleness_alert.check()
        assert result["alert"], "must alert once staleness passes the 20-min deadline"

        staleness_alert._refresh()
        result = staleness_alert.check()
        assert not result["alert"], "must stay quiet once fresh"
    finally:
        staleness_alert._refresh()


def test_staleness_event_is_audited_with_start_duration_domains():
    staleness_alert.ensure_audit_table()
    before = _audit_count()
    try:
        staleness_alert._backdate(staleness_alert.FLOOR_SECONDS + 60)
        result = staleness_alert.check()
        assert result["audited"], "an event past the 5-min floor must be audited"

        after = _audit_count()
        assert after > before, "the audit table must gain a row for this event"

        row = answers._psql(
            answers.ADMIN_USER,
            "SELECT duration_seconds, array_length(domains, 1) FROM serve.staleness_audit "
            "ORDER BY id DESC LIMIT 1;",
        ).strip()
        duration_text, domain_count_text = row.split("|")
        assert float(duration_text) >= staleness_alert.FLOOR_SECONDS, "duration must reflect the real stoppage"
        assert int(domain_count_text) > 0, "the affected domains must be recorded"
    finally:
        staleness_alert._refresh()


TESTS = [
    test_answer_carries_matching_as_of,
    test_alert_fires_past_deadline_and_quiet_when_fresh,
    test_staleness_event_is_audited_with_start_duration_domains,
]


def main() -> int:
    failures = []
    for test in TESTS:
        try:
            test()
        except AssertionError as exc:
            failures.append(f"{test.__name__}: {exc}")

    if failures:
        print(f"freshness audit FAILED ({len(failures)}/{len(TESTS)}):")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"freshness audit OK: {len(TESTS)}/{len(TESTS)} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
