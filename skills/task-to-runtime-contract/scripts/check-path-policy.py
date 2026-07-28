#!/usr/bin/env python3
"""Enforce Task-Spec write scope for one candidate path or the current diff."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from _gate_policy import GatePolicyError, load_gate
from _runtime_contract import (
    strip_dot_slash,
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
            # The loop's own bookkeeping is FRAMEWORK output, not task output.
            # Pass 8 writes briefs, attempt logs, a durable checkpoint and a
            # handoff note under cvg/loop/<task-id>/ — that is how the loop
            # externalizes memory instead of keeping it in a context window.
            # Counting it as the task's diff made every green run fail its own
            # path policy: the loop was convicted of the evidence it is required
            # to leave behind. It is exempt from the scope AND never staged,
            # because open-issue-pr.sh stages only the contract's fs.write paths.
            #
            # cvg/STATE.md is the same class and was missed. The kernel appends
            # one row to it on EVERY landing, so it is dirty before the second
            # run in a workspace ever reaches settlement — and that run is then
            # refused for a line the loop wrote about the previous run. The
            # first run in a fresh workspace passes, which is exactly why this
            # survived: the failure needs a history to appear.
            framework_paths.add("cvg/STATE.md")
            task_id = str(profile.get("task", {}).get("id", "")).strip()
            loop_prefixes = ["cvg/loop/"]
            if task_id:
                loop_prefixes.append(f"cvg/loop/{task_id}/")

            def _is_framework(path: str) -> bool:
                if path in framework_paths:
                    return True
                if any(path.startswith(prefix) for prefix in loop_prefixes):
                    return True
                if receipt_value:
                    receipt = Path(receipt_value)
                    if (
                        Path(path).parent == receipt.parent
                        and Path(path).name.startswith(receipt.stem + ".attempt-")
                        and Path(path).suffix == receipt.suffix
                    ):
                        return True
                return False

            candidates = [path for path in candidates if not _is_framework(path)]
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
                normalized.append(strip_dot_slash(candidate))
        # ---- FENCE 1: the repo gate. Checked FIRST and independently. --------
        # The contract answers "may this task write here?". The gate answers
        # "may ANY task ever write here?". A spec cannot grant what the repo
        # forbids, so the gate is evaluated before the scope and its verdict is
        # not overridable by re-signing — it is not part of the signed payload.
        try:
            gate = load_gate(repo, Path.cwd())
        except GatePolicyError as exc:
            # A gate that cannot be parsed is a FAILURE, never a skipped
            # control. A fence you can disable with a typo is not a fence.
            print(f"Gate policy unreadable: {exc}")
            print("CHECK_PATH_POLICY=FAIL")
            return 1

        if gate.active:
            forbidden_hits = gate.violations(normalized)
            if forbidden_hits:
                print(f"Repo gate ({gate.source}) forbids these paths — no spec may widen this:")
                for path, rule in forbidden_hits:
                    print(f"  - {path}  (denylist rule: {rule})")
                print("CHECK_PATH_POLICY=FAIL")
                return 1
            if gate.exceeds_blast_radius(len(normalized)):
                print(
                    f"Repo gate ({gate.source}): {len(normalized)} changed paths exceeds "
                    f"max_files={gate.max_files}. Every path may be in scope and the blast "
                    f"radius is still too large for one unattended change."
                )
                print("CHECK_PATH_POLICY=FAIL")
                return 1

        # ---- FENCE 2: the task's own declared scope --------------------------
        violations = outside + [
            path for path in normalized if not path_allowed(path, allowed, forbidden)
        ]
        if violations:
            print("Out-of-scope paths:")
            for path in violations:
                print(f"  - {path}")
            print("CHECK_PATH_POLICY=FAIL")
            return 1
        _fence = f" · repo gate {gate.source.parent.parent.name}/.cvg/gate.yaml" if gate.active else ""
        print(f"Path policy ready: {len(normalized)} path(s) inside Task-Spec scope{_fence}.")
        print("CHECK_PATH_POLICY=PASS")
        return 0
    except ContractError as exc:
        print(f"Path policy error: {exc}")
        print("CHECK_PATH_POLICY=FAIL")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
