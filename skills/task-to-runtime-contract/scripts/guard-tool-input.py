#!/usr/bin/env python3
"""Vendor-hook bridge: read tool JSON from stdin and guard every candidate path."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


PATH_KEYS = {"file_path", "path", "target_path", "destination"}


def collect(value: object) -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            if key in PATH_KEYS and isinstance(item, str):
                found.append(item)
            else:
                found.extend(collect(item))
    elif isinstance(value, list):
        for item in value:
            found.extend(collect(item))
    return found


def main() -> int:
    profile = os.environ.get("CVG_EXECUTION_PROFILE", "")
    if not profile:
        print("CVG_EXECUTION_PROFILE is required", file=sys.stderr)
        return 2
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        print(f"invalid tool-input JSON: {exc}", file=sys.stderr)
        return 2
    paths = sorted(set(collect(payload)))
    if not paths:
        return 0
    guard = Path(__file__).with_name("check-path-policy.py")
    command = [sys.executable, str(guard), "--profile", profile]
    for path in paths:
        command.extend(["--candidate", path])
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())

