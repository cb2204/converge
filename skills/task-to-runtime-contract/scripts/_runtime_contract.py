#!/usr/bin/env python3
"""Shared dependency-free helpers for Pass 6 runtime-contract scripts."""

from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any, Iterable

SCHEMA = "cvg.execution-profile.v1"
VERSION = "1.0.0"
TOPOLOGIES = {"single", "single-explorer", "implementer-verifier", "parallel"}
PERMISSIONS = {"read-only", "scoped-write"}


class ContractError(Exception):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relpath(path: Path, repo: Path) -> str:
    try:
        return path.resolve().relative_to(repo.resolve()).as_posix()
    except ValueError as exc:
        raise ContractError(f"path is outside repository: {path}") from exc


def resolve_repo(value: str | None) -> Path:
    if value:
        repo = Path(value).expanduser().resolve()
    else:
        proc = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            text=True,
            capture_output=True,
            check=False,
        )
        repo = Path(proc.stdout.strip() or os.getcwd()).resolve()
    if not repo.is_dir():
        raise ContractError(f"repository does not exist: {repo}")
    return repo


def resolve_inside_repo(value: str, repo: Path, must_exist: bool = True) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = repo / path
    path = path.resolve()
    relpath(path, repo)
    if must_exist and not path.exists():
        raise ContractError(f"required path does not exist: {path}")
    return path


def _scalar(value: str) -> Any:
    value = value.strip()
    if value in {"", "null", "~"}:
        return None
    if value == "[]":
        return []
    if value == "{}":
        return {}
    if value.lower() in {"true", "false"}:
        return value.lower() == "true"
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [_scalar(part) for part in inner.split(",")]
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_frontmatter(path: Path) -> tuple[dict[str, Any], str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ContractError(f"Task-Spec has no opening frontmatter delimiter: {path}")
    try:
        end = next(i for i, line in enumerate(lines[1:], 1) if line.strip() == "---")
    except StopIteration as exc:
        raise ContractError(f"Task-Spec has no closing frontmatter delimiter: {path}") from exc

    data: dict[str, Any] = {}
    current: str | None = None
    nested_list: str | None = None
    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        top = re.match(r"^([A-Za-z0-9_-]+):(?:[ \t]*(.*))?$", raw)
        if top:
            current = top.group(1)
            nested_list = None
            value = (top.group(2) or "").split("  #", 1)[0].rstrip()
            data[current] = _scalar(value) if value else {}
            continue
        nested_item = re.match(r"^[ \t]{4,}-[ \t]+(.+?)\s*$", raw)
        if nested_item and current and nested_list:
            if not isinstance(data.get(current), dict):
                data[current] = {}
            if not isinstance(data[current].get(nested_list), list):
                data[current][nested_list] = []
            data[current][nested_list].append(_scalar(nested_item.group(1)))
            continue
        item = re.match(r"^[ \t]{2}-[ \t]+(.+?)\s*$", raw)
        if item and current:
            if not isinstance(data.get(current), list):
                data[current] = []
            data[current].append(_scalar(item.group(1)))
            continue
        nested = re.match(r"^[ \t]+([A-Za-z0-9_-]+):[ \t]*(.*?)\s*$", raw)
        if nested and current:
            if not isinstance(data.get(current), dict):
                data[current] = {}
            nested_list = nested.group(1)
            nested_value = nested.group(2).split("  #", 1)[0].rstrip()
            data[current][nested_list] = _scalar(nested_value) if nested_value else []
    body = "\n".join(lines[end + 1 :]) + ("\n" if text.endswith("\n") else "")
    return data, body


def task_paths(frontmatter: dict[str, Any]) -> list[str]:
    values: list[str] = []
    for key in ("touches_paths", "creates_paths"):
        raw = frontmatter.get(key, [])
        if isinstance(raw, list):
            values.extend(str(item).strip() for item in raw if str(item).strip())
    return sorted(set(values))


def do_not_touch(body: str) -> list[str]:
    match = re.search(
        r"^## Do-Not-Touch[ \t]*\n(.*?)(?=^## |\Z)",
        body,
        flags=re.MULTILINE | re.DOTALL,
    )
    if not match:
        return []
    paths = []
    for line in match.group(1).splitlines():
        item = re.match(r"^[ \t]*-[ \t]+(.+?)\s*$", line)
        if not item:
            continue
        value = item.group(1).strip().strip("`")
        if value.lower().startswith("(none"):
            continue
        value = value.split(" — ", 1)[0].strip().strip("`")
        if value:
            paths.append(value)
    return sorted(set(paths))


def path_matches(candidate: str, rule: str) -> bool:
    candidate = candidate.lstrip("./")
    rule = rule.strip().lstrip("./")
    if not candidate or not rule:
        return False
    if any(ch in rule for ch in "*?["):
        return fnmatch.fnmatchcase(candidate, rule)
    base = rule.rstrip("/")
    return candidate == base or candidate.startswith(base + "/")


def path_allowed(candidate: str, allowed: Iterable[str], forbidden: Iterable[str]) -> bool:
    if any(path_matches(candidate, rule) for rule in forbidden):
        return False
    return any(path_matches(candidate, rule) for rule in allowed)


def cited_adrs(body: str, repo: Path) -> list[Path]:
    pattern = r"(?<![A-Za-z0-9_.-])((?:cvg/)?docs/adrs/[A-Za-z0-9_./-]+\.md)"
    found = []
    for value in re.findall(pattern, body):
        path = resolve_inside_repo(value, repo, must_exist=True)
        if path not in found:
            found.append(path)
    return found


def evidence_entry(path: Path, repo: Path, kind: str) -> dict[str, str]:
    return {"kind": kind, "path": relpath(path, repo), "sha256": sha256_file(path)}


def load_profile(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractError(f"profile is not valid JSON-subset YAML: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ContractError("execution profile must be an object")
    return value


def profile_task_path(profile: dict[str, Any], repo: Path) -> Path:
    try:
        value = profile["task"]["spec_ref"]["path"]
    except (KeyError, TypeError) as exc:
        raise ContractError("profile is missing task.spec_ref.path") from exc
    return resolve_inside_repo(str(value), repo, must_exist=True)


def run_signoff_gate(
    task: Path, repo: Path, tool_home: Path, supervised: bool
) -> tuple[int, str]:
    candidates = [
        tool_home / "skills/task-spec/scripts/safe-to-delegate.sh",
        tool_home / ".claude/skills/task-spec/scripts/safe-to-delegate.sh",
    ]
    gate = next((path for path in candidates if path.is_file()), candidates[0])
    if not gate.is_file():
        searched = ", ".join(str(path) for path in candidates)
        raise ContractError(f"Task-Spec sign-off gate not found (searched: {searched})")
    command = ["bash", str(gate)]
    if not supervised:
        command.append("--require-tier1")
    command.append(str(task))
    proc = subprocess.run(command, cwd=repo, text=True, capture_output=True, check=False)
    output = (proc.stdout + "\n" + proc.stderr).strip()
    if proc.returncode != 0:
        tail = "\n".join(output.splitlines()[-12:])
        raise ContractError(f"Task-Spec is not execution-ready:\n{tail}")
    tier_match = re.findall(r"^TIER=([123])$", output, flags=re.MULTILINE)
    if not tier_match:
        raise ContractError("sign-off gate returned no trust tier; task is not signed")
    tier = int(tier_match[-1])
    if tier == 3:
        raise ContractError("Task-Spec signature is invalid (Tier 3)")
    return tier, output


def parse_worker(value: str) -> dict[str, Any]:
    parts = value.split(":", 2)
    if len(parts) != 3:
        raise ContractError(
            f"worker must be name:read-only|scoped-write:path[,path]: {value}"
        )
    name, permission, raw_paths = (part.strip() for part in parts)
    if not re.fullmatch(r"[a-z][a-z0-9-]*", name):
        raise ContractError(f"invalid worker name: {name}")
    if permission not in PERMISSIONS:
        raise ContractError(f"invalid worker permission class: {permission}")
    ownership = [item.strip() for item in raw_paths.split(",") if item.strip()]
    if permission == "read-only" and ownership:
        raise ContractError(f"read-only worker '{name}' cannot own writable paths")
    if permission == "scoped-write" and not ownership:
        raise ContractError(f"scoped-write worker '{name}' needs ownership paths")
    return {"name": name, "permission_class": permission, "owns_paths": ownership}


def validate_topology(
    mode: str,
    justification: str,
    workers: list[dict[str, Any]],
    allowed: list[str],
) -> list[str]:
    errors: list[str] = []
    if mode not in TOPOLOGIES:
        return [f"unsupported topology: {mode}"]
    if mode != "single":
        generic = {"use multiple agents", "parallel is faster", "independent work"}
        if len(justification.strip()) < 24 or justification.strip().lower() in generic:
            errors.append("non-single topology requires a substantive static justification")
    if mode == "parallel":
        writers = [w for w in workers if w.get("permission_class") == "scoped-write"]
        if len(writers) < 2:
            errors.append("parallel topology requires at least two scoped-write workers")
        seen: list[tuple[str, str]] = []
        for worker in writers:
            for owned in worker.get("owns_paths", []):
                if not any(path_matches(owned, rule) or path_matches(rule, owned) for rule in allowed):
                    errors.append(
                        f"worker {worker.get('name')} owns path outside Task-Spec scope: {owned}"
                    )
                for other_name, other_path in seen:
                    if (
                        path_matches(owned, other_path)
                        or path_matches(other_path, owned)
                        or owned == other_path
                    ):
                        errors.append(
                            f"parallel ownership overlaps: {other_name}:{other_path} and "
                            f"{worker.get('name')}:{owned}"
                        )
                seen.append((str(worker.get("name")), str(owned)))
    elif workers:
        errors.append("explicit --worker partitions are only valid with parallel topology")
    return errors


def unresolved_placeholder(text: str) -> bool:
    patterns = (
        r"\{\{[^}]+\}\}",
        r"<!--\s*TODO\b",
        r"<(?:task-id|path|slug|url|todo)>",
    )
    return any(re.search(pattern, text, flags=re.IGNORECASE) for pattern in patterns)
