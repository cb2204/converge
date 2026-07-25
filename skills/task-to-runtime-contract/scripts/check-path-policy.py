#!/usr/bin/env python3
"""Enforce Task-Spec write scope for one candidate path or the current diff."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from _runtime_contract import (
    ContractError,
    do_not_touch,
    load_profile,
    parse_frontmatter,
    path_allowed,
    profile_task_path,
    relpath,
    resolve_inside_repo,
    resolve_repo,
    task_paths,
)


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check paths against a runtime contract.")
    parser.add_argument("--profile", required=True)
    parser.add_argument("--repo")
    parser.add_argument("--candidate", action="append", default=[])
    parser.add_argument("--base")
    parser.add_argument("--paths-from-stdin", action="store_true")
    return parser.parse_args()


def diff_paths(repo: Path, base: str | None) -> list[str]:
    # --relative does two things that both matter for a workspace nested inside
    # a larger repo: it SCOPES the diff to that directory, and it returns paths
    # relative to it. Without it, `git diff` reports the whole repository using
    # repo-root-relative paths, while the contract's fs.write scope is written
    # relative to the workspace — so every authorized file looks like a
    # violation and every file elsewhere in the repo looks like the task's.
    commands = []
    if base:
        commands.append(["git", "-C", str(repo), "diff", "--relative", "--name-only", f"{base}...HEAD"])
    commands.append(["git", "-C", str(repo), "diff", "--relative", "--name-only", "HEAD"])
    changed = ""
    for command in commands:
        proc = subprocess.run(command, text=True, capture_output=True, check=False)
        if proc.returncode != 0:
            raise ContractError(proc.stderr.strip() or "git diff failed")
        changed += proc.stdout + "\n"
    untracked = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "--others", "--exclude-standard"],
        text=True,
        capture_output=True,
        check=False,
    )
    if untracked.returncode != 0:
        raise ContractError(untracked.stderr.strip() or "git ls-files failed")
    return sorted(
        set(
            line.strip()
            for line in (changed + untracked.stdout).splitlines()
            if line.strip()
        )
    )


def main() -> int:
    args = arguments()
    try:
        repo = resolve_repo(args.repo)
        profile_path = resolve_inside_repo(args.profile, repo)
        profile = load_profile(profile_path)
        task = profile_task_path(profile, repo)
        frontmatter, body = parse_frontmatter(task)
        allowed = task_paths(frontmatter)
        forbidden = do_not_touch(body)

        candidates = list(args.candidate)
        if args.paths_from_stdin:
            import sys

            candidates.extend(line.strip() for line in sys.stdin if line.strip())
        diff_mode = not candidates and not args.paths_from_stdin
        if diff_mode:
            candidates = diff_paths(repo, args.base)
            receipt_value = str(profile.get("receipt", {}).get("path", ""))
            framework_paths = {receipt_value} if receipt_value else set()
            task_dir = Path(profile["task"]["spec_ref"]["path"]).parent
            framework_paths.update(
                {
                    (task_dir / "_state.yaml").as_posix(),
                    (task_dir / "_metrics.jsonl").as_posix(),
                }
            )
            if receipt_value:
                receipt = Path(receipt_value)
                candidates = [
                    path
                    for path in candidates
                    if path not in framework_paths
                    and not (
                        Path(path).parent == receipt.parent
                        and Path(path).name.startswith(receipt.stem + ".attempt-")
                        and Path(path).suffix == receipt.suffix
                    )
                ]
        if not candidates:
            print("No changed paths.")
            print("CHECK_PATH_POLICY=PASS")
            return 0

        normalized = []
        outside = []
        for candidate in candidates:
            value = Path(candidate)
            if value.is_absolute():
                try:
                    normalized.append(relpath(value, repo))
                except ContractError:
                    outside.append(candidate)
            else:
                normalized.append(candidate.lstrip("./"))
        violations = outside + [
            path for path in normalized if not path_allowed(path, allowed, forbidden)
        ]
        if violations:
            print("Out-of-scope paths:")
            for path in violations:
                print(f"  - {path}")
            print("CHECK_PATH_POLICY=FAIL")
            return 1
        print(f"Path policy ready: {len(normalized)} path(s) inside Task-Spec scope.")
        print("CHECK_PATH_POLICY=PASS")
        return 0
    except ContractError as exc:
        print(f"Path policy error: {exc}")
        print("CHECK_PATH_POLICY=FAIL")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
