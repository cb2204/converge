#!/usr/bin/env python3
"""Write the latest immutable-evidence execution receipt and archive its predecessor."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from _runtime_contract import (
    ContractError,
    load_profile,
    profile_task_path,
    relpath,
    resolve_inside_repo,
    resolve_repo,
    sha256_file,
)


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Write a Pass 8 execution receipt.")
    parser.add_argument("--profile", required=True)
    parser.add_argument("--result", required=True, choices=["pass", "blocked"])
    parser.add_argument("--eval-output", required=True)
    parser.add_argument(
        "--path-policy", required=True, choices=["pass", "fail", "not-run"]
    )
    parser.add_argument("--agent", required=True)
    parser.add_argument("--branch", required=True)
    parser.add_argument("--repo")
    parser.add_argument("--out")
    return parser.parse_args()


def main() -> int:
    args = arguments()
    try:
        repo = resolve_repo(args.repo)
        profile_path = resolve_inside_repo(args.profile, repo)
        eval_output = Path(args.eval_output).expanduser().resolve()
        if not eval_output.is_file():
            raise ContractError(f"eval output file does not exist: {eval_output}")
        profile = load_profile(profile_path)
        task = profile_task_path(profile, repo)
        task_id = str(profile.get("task", {}).get("id", ""))
        if not task_id:
            raise ContractError("profile has no task id")
        expected_spec_hash = profile["task"]["spec_ref"]["sha256"]
        if sha256_file(task) != expected_spec_hash:
            raise ContractError("Task-Spec changed after runtime binding")
        output = (
            resolve_inside_repo(args.out, repo, must_exist=False)
            if args.out
            else resolve_inside_repo(
                str(profile.get("receipt", {}).get("path", "")),
                repo,
                must_exist=False,
            )
        )
        payload = {
            "schema": "cvg.execution-receipt.v1",
            "task_id": task_id,
            "result": args.result,
            "task_spec": {
                "path": relpath(task, repo),
                "sha256": expected_spec_hash,
            },
            "execution_profile": {
                "path": relpath(profile_path, repo),
                "sha256": sha256_file(profile_path),
            },
            "evaluation": {
                "output_sha256": sha256_file(eval_output),
                "path_policy": args.path_policy,
            },
            "runtime": {"agent": args.agent, "branch": args.branch},
            "recorded_at": datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
            "generated_by": "task-loop",
        }
        rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
        output.parent.mkdir(parents=True, exist_ok=True)
        if output.exists() and output.read_text(encoding="utf-8") != rendered:
            previous = output.read_bytes()
            suffix = hashlib.sha256(previous).hexdigest()[:12]
            archive = output.with_name(
                f"{output.stem}.attempt-{suffix}{output.suffix}"
            )
            if not archive.exists():
                archive.write_bytes(previous)
        output.write_text(rendered, encoding="utf-8")
        print(f"Execution receipt written: {relpath(output, repo)}")
        print("EXECUTION_RECEIPT=PASS" if args.result == "pass" else "EXECUTION_RECEIPT=BLOCKED")
        return 0
    except (ContractError, KeyError, TypeError) as exc:
        print(f"Execution receipt failed: {exc}")
        print("EXECUTION_RECEIPT=FAIL")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
