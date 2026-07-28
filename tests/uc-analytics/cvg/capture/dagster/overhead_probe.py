"""Dagster asset check — D6 feed overhead (feed-on vs feed-off, <= 20%).

Times a batch of representative analytical reads against the operational
source twice: once with the capture feed idle (feed-off baseline) and once
with the capture pipeline actively pulling the replication slot concurrently
(feed-on). Overhead is the added median latency, as a percentage of the
baseline -- measured live against the running container, never asserted.
"""

from __future__ import annotations

import statistics
import subprocess
import sys
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipelines"))
import orders  # noqa: E402

TRIALS = 15
ROUNDS = 5
PROBE_QUERY = "SELECT count(*) FROM orders;"


def _run_psql(user: str, sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", orders.CONTAINER,
            "psql", "-U", user, "-d", orders.DB,
            "-v", "ON_ERROR_STOP=1", "-tAc", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql ({user}) failed: {result.stderr.strip()}")
    return result.stdout


def _time_probe_batch() -> float:
    """Median latency (seconds) of one representative analytical read,
    sampled over TRIALS runs to smooth docker-exec jitter."""
    samples = []
    for _ in range(TRIALS):
        start = time.monotonic()
        _run_psql(orders.ADMIN_USER, PROBE_QUERY)
        samples.append(time.monotonic() - start)
    return statistics.median(samples)


def _run_feed_concurrently(stop: threading.Event) -> None:
    orders.bootstrap()
    while not stop.is_set():
        orders.fetch_and_land()
        time.sleep(0.05)


def _one_round_overhead_pct() -> float:
    baseline = _time_probe_batch()

    stop = threading.Event()
    feed_thread = threading.Thread(target=_run_feed_concurrently, args=(stop,), daemon=True)
    feed_thread.start()
    try:
        loaded = _time_probe_batch()
    finally:
        stop.set()
        feed_thread.join(timeout=5)

    if baseline <= 0:
        return 0.0
    return max(0.0, (loaded - baseline) / baseline * 100.0)


def measure_overhead_pct() -> float:
    """Median overhead across ROUNDS independent feed-off/feed-on samples --
    a single sample is too noisy against docker-exec jitter to stand as p95."""
    return statistics.median(_one_round_overhead_pct() for _ in range(ROUNDS))


def main() -> int:
    pct = measure_overhead_pct()
    print(f"overhead_pct={pct:.1f}")
    print(f"overhead_probe: feed-on adds {pct:.1f}% p50 latency vs feed-off baseline (D6 budget <=20%)")
    return 0 if pct <= 20.0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
