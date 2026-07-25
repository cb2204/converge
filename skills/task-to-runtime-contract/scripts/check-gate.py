#!/usr/bin/env python3
"""cvg gate — show the repo write fence, or test paths against it.

The fence a Task-Spec cannot widen. Run it to see what is standing between an
unattended agent and the parts of the repo nothing should touch.

    cvg gate                      show the active policy
    cvg gate --path auth/x.py     would this path be refused?

Emits CHECK_GATE=OK|FORBIDDEN|ABSENT|ERROR.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _gate_policy import GatePolicyError, load_gate  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--path", action="append", default=[],
                    help="test a path against the fence (repeatable)")
    ap.add_argument("--repo", default=".")
    args = ap.parse_args()

    repo = Path(args.repo).resolve()
    try:
        gate = load_gate(repo, Path.cwd())
    except GatePolicyError as exc:
        print(f"Gate policy unreadable: {exc}")
        print("CHECK_GATE=ERROR")
        return 2

    if not gate.active:
        print("No repo gate. The per-task contract scope is the ONLY fence.")
        print(f"Create {repo.name}/.cvg/gate.yaml to add a standing one.")
        print("CHECK_GATE=ABSENT")
        return 0

    print(f"Repo write fence: {gate.source}")
    print(f"  denylist  : {len(gate.denylist)} rule(s) — no Task-Spec may widen these")
    for rule in gate.denylist:
        print(f"      {rule}")
    print(f"  max_files : {gate.max_files if gate.max_files is not None else '(no cap)'}")

    if args.path:
        print()
        forbidden = False
        for path in args.path:
            rule = gate.forbids(path)
            if rule:
                print(f"  REFUSED  {path}  (rule: {rule})")
                forbidden = True
            else:
                print(f"  allowed  {path}")
        if forbidden:
            print("CHECK_GATE=FORBIDDEN")
            return 1

    print("CHECK_GATE=OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
