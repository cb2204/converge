"""Publish `gold.*` as serving-ready snapshots via an atomic snapshot swap.

Stdlib-only, `docker exec psql` transport (no driver, no network egress in
this environment — see cvg/capture/pipelines/*.py for the same convention).
Each run dumps every gold table to a fresh, numbered snapshot directory, then
flips a `CURRENT` pointer file with `os.replace` — a single atomic filesystem
rename, so a reader sees the whole old snapshot or the whole new one, never a
torn mix (the seam contract's "atomic DuckLake snapshot swap").

Snapshot data lives under publish/data/, which is gitignored (ecommerce's
`.gitignore` excludes `data/`) — it is a runtime publish target, not part of
the transform's tracked source.
"""

from __future__ import annotations

import csv
import io
import json
import subprocess
import sys
from pathlib import Path

CONTAINER = "uc-analytics-postgres"
DB = "ecommerce"
ADMIN_USER = "postgres"

GOLD_TABLES = ["revenue", "revenue_by_product"]

DATA_ROOT = Path(__file__).resolve().parent / "data"
SNAPSHOTS_ROOT = DATA_ROOT / "snapshots"
CURRENT_POINTER = DATA_ROOT / "CURRENT"


def _psql(sql: str) -> str:
    result = subprocess.run(
        [
            "docker", "exec", "-i", CONTAINER,
            "psql", "-U", ADMIN_USER, "-d", DB,
            "-v", "ON_ERROR_STOP=1",
            "-c", sql,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql failed: {result.stderr.strip()}")
    return result.stdout


def _dump_table(table: str) -> str:
    return _psql(f"COPY (SELECT * FROM gold.{table}) TO STDOUT WITH CSV HEADER")


def _row_count(csv_text: str) -> int:
    rows = list(csv.reader(io.StringIO(csv_text)))
    return max(len(rows) - 1, 0)


def _next_snapshot_id() -> int:
    if not SNAPSHOTS_ROOT.exists():
        return 1
    existing = [int(p.name) for p in SNAPSHOTS_ROOT.iterdir() if p.name.isdigit()]
    return (max(existing) + 1) if existing else 1


def publish() -> dict:
    """Dump every gold table into a new snapshot dir, then atomically swap
    the CURRENT pointer to it. Returns the manifest that was published."""
    SNAPSHOTS_ROOT.mkdir(parents=True, exist_ok=True)

    snapshot_id = _next_snapshot_id()
    snapshot_dir = SNAPSHOTS_ROOT / str(snapshot_id)
    snapshot_dir.mkdir(parents=True, exist_ok=False)

    counts = {}
    for table in GOLD_TABLES:
        csv_text = _dump_table(table)
        (snapshot_dir / f"{table}.csv").write_text(csv_text)
        counts[table] = _row_count(csv_text)

    manifest = {"snapshot_id": snapshot_id, "tables": GOLD_TABLES, "counts": counts}
    manifest_path = snapshot_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))

    # Atomic swap: write the new pointer value to a temp file, then rename it
    # onto CURRENT in one filesystem call — never a half-written pointer.
    tmp_pointer = DATA_ROOT / "CURRENT.tmp"
    tmp_pointer.write_text(str(snapshot_id))
    tmp_pointer.replace(CURRENT_POINTER)

    return manifest


def current_manifest() -> dict:
    if not CURRENT_POINTER.exists():
        raise RuntimeError("no snapshot has been published yet")
    snapshot_id = CURRENT_POINTER.read_text().strip()
    manifest_path = SNAPSHOTS_ROOT / snapshot_id / "manifest.json"
    return json.loads(manifest_path.read_text())


def main(argv: list[str]) -> int:
    if "--count" in argv:
        manifest = current_manifest()
        counts = manifest["counts"]
        print(" ".join(f"{table}={counts[table]}" for table in manifest["tables"]))
        return 0

    manifest = publish()
    counts = manifest["counts"]
    summary = ", ".join(f"{table}={counts[table]} rows" for table in manifest["tables"])
    print(f"published snapshot {manifest['snapshot_id']}: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
