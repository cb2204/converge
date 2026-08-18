#!/usr/bin/env python3
"""Release documentation gate: links, anchors, fences, smoke blocks, and truth."""

from __future__ import annotations

import json
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
CANONICAL = [
    ROOT / "README.md",
    ROOT / "docs" / "README.md",
    ROOT / "docs" / "architecture.md",
    ROOT / "docs" / "composed-flow.md",
    ROOT / "docs" / "cli-reference.md",
    ROOT / "docs" / "release-readiness.md",
    ROOT / "bin" / "README.md",
]
LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.MULTILINE)
FENCE_RE = re.compile(r"^```([^\n]*)\n(.*?)^```\s*$", re.MULTILINE | re.DOTALL)
HTML_HREF_RE = re.compile(r"""href=(['"])([^'"]+)\1""", re.IGNORECASE)
ARCHIVED_ASSETS = (
    "converge-v0.1.pdf",
    "task-spec-v0.1.pdf",
    "converge.pdf",
    "converge-deck.pdf",
    "converge-brand-concepts-round-01.zip",
    "converge-v0.2.0-alpha.1.pdf",
)
ARCHIVED_TREE_PATHS = (
    "docs/converge.pdf",
    "docs/converge-v0.1.pdf",
    "docs/task-spec-v0.1.pdf",
    "docs/converge-deck.pdf",
    "docs/converge-v0.2.0-alpha.1.pdf",
    "converge-brand-kit-v1.zip",
    "converge-brand-concepts-round-01.zip",
)


def anchor(value: str) -> str:
    value = re.sub(r"[`*_]", "", value).strip().lower()
    value = re.sub(r"[^a-z0-9\- ]", "", value)
    return re.sub(r" +", "-", value)


def headings(text: str) -> set[str]:
    return {anchor(match.group(2)) for match in HEADING_RE.finditer(text)}


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"FAIL {message}", file=sys.stderr)


def check_links(path: pathlib.Path, text: str, failures: list[str]) -> None:
    own_headings = headings(text)
    for raw in LINK_RE.findall(text):
        target = raw.strip().split()[0].strip("<>")
        if re.match(r"^[a-z]+://", target) or target.startswith("mailto:"):
            continue
        if target.startswith("#"):
            if target[1:] not in own_headings:
                fail(f"{path.relative_to(ROOT)} missing anchor {target}", failures)
            continue
        file_part, _, fragment = target.partition("#")
        resolved = (path.parent / file_part).resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError:
            fail(f"{path.relative_to(ROOT)} link escapes repository: {target}", failures)
            continue
        if not resolved.exists():
            fail(f"{path.relative_to(ROOT)} broken link: {target}", failures)
            continue
        if fragment and resolved.is_file() and resolved.suffix.lower() == ".md":
            target_headings = headings(resolved.read_text(encoding="utf-8"))
            if fragment not in target_headings:
                fail(f"{path.relative_to(ROOT)} broken anchor: {target}", failures)


def check_fences(path: pathlib.Path, text: str, failures: list[str]) -> None:
    if len(re.findall(r"^```", text, re.MULTILINE)) % 2:
        fail(f"{path.relative_to(ROOT)} has an unclosed code fence", failures)
    for language, body in FENCE_RE.findall(text):
        language = language.strip()
        if language == "mermaid":
            first = next((line.strip() for line in body.splitlines() if line.strip()), "")
            if not re.match(r"^(flowchart|graph|sequenceDiagram|stateDiagram|classDiagram)", first):
                fail(f"{path.relative_to(ROOT)} has an invalid Mermaid opening: {first}", failures)
        if language == "bash":
            result = subprocess.run(["bash", "-n"], input=body, text=True, capture_output=True)
            if result.returncode != 0:
                fail(
                    f"{path.relative_to(ROOT)} bash block fails syntax smoke: {result.stderr.strip()}",
                    failures,
                )


def main() -> int:
    failures: list[str] = []
    for path in CANONICAL:
        if not path.is_file():
            fail(f"missing canonical document {path.relative_to(ROOT)}", failures)
            continue
        text = path.read_text(encoding="utf-8")
        check_links(path, text, failures)
        check_fences(path, text, failures)

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for claim in (
        f"Converge {VERSION}",
        "Seamwise 0.2.0",
        "Task-Spec 3.8.0",
        "Hosted CI",
        "Historical Converge 0.1.0",
    ):
        if claim not in readme:
            fail(f"README missing release truth: {claim}", failures)

    matrix = json.loads((ROOT / "contracts" / "cli-command-matrix.json").read_text())
    names = [row["name"] for row in matrix.get("commands", [])]
    if matrix.get("contract") != "ConvergeCLICommandMatrix/v1" or len(names) != 57 or len(set(names)) != 57:
        fail("canonical CLI matrix must contain 57 unique forms", failures)
    compose = {name for name in names if name.startswith("compose ")}
    if compose != {
        "compose prepare --source <recipe>",
        "compose review --reviewer <name> --reason <text>",
        "compose preview",
        "compose materialize",
        "compose status",
    }:
        fail("canonical CLI matrix compose forms drifted", failures)

    rendered = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "render-cli-reference.py"), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if rendered.returncode != 0:
        fail("docs/cli-reference.md is stale against the command matrix", failures)

    # Historical v0.1 binaries live as assets on the v0.1.0 GitHub release,
    # not in the tree. The release is not GitHub-immutable. The inventory must
    # name each artifact and carry a download path; when `gh` can see the
    # private repo, also confirm the asset exists on the release.
    archive = (ROOT / "docs" / "README.md").read_text(encoding="utf-8")
    for historical in ARCHIVED_ASSETS:
        asset_url = f"releases/download/v0.1.0/{historical}"
        if historical not in archive or asset_url not in archive:
            fail(f"historical evidence inventory missing {historical}", failures)
    listed = subprocess.run(
        ["gh", "release", "view", "v0.1.0", "--json", "assets", "--jq", ".assets[].name"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if listed.returncode == 0:
        present = {line.strip() for line in listed.stdout.splitlines() if line.strip()}
        missing = [name for name in ARCHIVED_ASSETS if name not in present]
        if missing:
            fail(f"v0.1.0 release missing assets: {missing}", failures)
    elif os.environ.get("GITHUB_ACTIONS"):
        fail("could not list v0.1.0 release assets in CI", failures)
    for historical_html in (
        ROOT / "docs" / "decks" / "converge-deck.html",
        ROOT / "docs" / "decks" / "asd-agentic-loop.html",
        ROOT / "docs" / "decks" / "converge.html",
        ROOT / "docs" / "decks" / "cvg-passes-skills-cli.html",
        ROOT / "docs" / "decks" / "task-spec.html",
    ):
        html = historical_html.read_text(encoding="utf-8")
        if "ARCHIVED v0.1 EVIDENCE" not in html:
            fail(f"historical HTML missing intrinsic archive notice: {historical_html.relative_to(ROOT)}", failures)
        for _, href in HTML_HREF_RE.findall(html):
            target = href.strip()
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                continue
            file_part = target.split("#", 1)[0]
            if not file_part:
                continue
            resolved = (historical_html.parent / file_part).resolve()
            if not resolved.exists():
                fail(
                    f"{historical_html.relative_to(ROOT)} broken href: {target}",
                    failures,
                )
    current_pdf = ROOT / "docs" / "converge-v0.2.0.pdf"
    if not current_pdf.is_file() or current_pdf.stat().st_size < 10_000:
        fail("current composed release PDF is missing or implausibly small", failures)

    tracked = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()
    debris = [
        item
        for item in tracked
        if (ROOT / item).exists()
        and (
            re.search(r"(^|/)(node_modules|test-results|playwright-report|__pycache__)(/|$)", item)
            or item.endswith((".pyc", ".pyo", ".DS_Store", ".tsbuildinfo"))
        )
    ]
    if debris:
        fail(f"tracked runtime debris: {debris}", failures)
    recommitted = [item for item in tracked if item in ARCHIVED_TREE_PATHS]
    if recommitted:
        fail(f"archived binaries recommitted to the tree: {recommitted}", failures)

    if failures:
        print(f"DOCS=BLOCKED failures={len(failures)}")
        return 1
    print(f"DOCS=READY files={len(CANONICAL)} commands=57")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
