#!/usr/bin/env python3
"""Assert the archived v0.1 binaries still exist on the release that hosts them.

WHY THIS EXISTS
On 2026-08-17 about 32 MB of historical binaries left the working tree and became
assets on the v0.1.0 GitHub release. `scripts/check-docs.py` gates the inventory
in docs/README.md — but it only checks that a *string* appears in the markdown.
It never resolves the URL. So the inventory could name five artifacts, every gate
could stay green, and all five could have been deleted from the release: the docs
would link to 404s and nothing would say so.

A release asset is mutable. Anyone with write access can delete or replace one,
and the release is not marked immutable. That makes the archive a real dependency,
and an unverified dependency is not an archive — it is a hope.

This resolves the actual assets. Network-dependent by nature, so it is a separate
verb from check-docs and skips cleanly when GitHub is unreachable or unauthorized,
rather than failing a developer's offline run.

Token: RELEASE_ASSETS=OK | MISSING | SKIPPED | ERROR
Exit:  0 for OK/SKIPPED, 1 for MISSING, 2 for ERROR.
"""

from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
RELEASE_TAG = "v0.1.0"
ASSET_RE = re.compile(rf"releases/download/{re.escape(RELEASE_TAG)}/([^)\s]+)")


def main() -> int:
    inventory = (ROOT / "docs" / "README.md").read_text(encoding="utf-8")
    expected = sorted(set(ASSET_RE.findall(inventory)))
    if not expected:
        print("no archived assets are referenced in docs/README.md", file=sys.stderr)
        print("RELEASE_ASSETS=ERROR")
        return 2

    try:
        proc = subprocess.run(
            ["gh", "release", "view", RELEASE_TAG, "--json", "assets"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        # No gh, or no network. Not a failure of the repository.
        print(f"skipped: cannot reach the release API ({type(exc).__name__})")
        print("RELEASE_ASSETS=SKIPPED")
        return 0

    if proc.returncode != 0:
        print(f"skipped: gh could not read {RELEASE_TAG} ({proc.stderr.strip()[:120]})")
        print("RELEASE_ASSETS=SKIPPED")
        return 0

    published = {asset["name"] for asset in json.loads(proc.stdout).get("assets", [])}
    missing = [name for name in expected if name not in published]

    for name in expected:
        print(f"  {'ok  ' if name in published else 'GONE'} — {name}")

    if missing:
        print(
            f"\ndocs/README.md links {len(missing)} artifact(s) that are no longer on "
            f"the {RELEASE_TAG} release: {', '.join(missing)}",
            file=sys.stderr,
        )
        print("RELEASE_ASSETS=MISSING")
        return 1

    print(f"\nall {len(expected)} archived artifacts resolve on {RELEASE_TAG}")
    print("RELEASE_ASSETS=OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
