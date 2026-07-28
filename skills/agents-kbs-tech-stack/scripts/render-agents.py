#!/usr/bin/env python3
"""Render AGENTS.md from the tech index — extracted from emit-cross-tool.sh.

This was a heredoc inside a $( ) command substitution. bash 3.2 (stock macOS,
this repo's stated portability floor) cannot parse that construct: it tokenizes
the heredoc body while scanning for the closing paren, so an apostrophe in a
Python comment made the entire script fail `bash -n` on macOS while parsing
cleanly under bash 5 on Linux. Quoting the delimiter (<<'PYEOF') does not help.

A real file is the fix rather than a workaround: it is lint-able, testable, and
cannot be broken again by punctuation.

Usage: render-agents.py <index-path> <agents-dir> <template> <last-updated>
"""

import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

index_path = Path(sys.argv[1])
agents_dir = Path(sys.argv[2])
tpl_path   = Path(sys.argv[3])
last_updated = sys.argv[4]

data = yaml.safe_load(index_path.read_text()) or {}
project_name = data.get("project") or "<unnamed project>"
domains      = data.get("domains") or {}

# ─── Agents table ──────────────────────────────────────────────────────────
# Parse agent frontmatter to extract `name` + `description` per file. Falls
# back to the filename if frontmatter is malformed.
agent_rows = []
for md in sorted(agents_dir.glob("*.md")):
    text = md.read_text()
    name = md.stem
    description = ""
    role = "unknown"

    # Frontmatter parse: between leading '---' fences.
    fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if fm_match:
        try:
            fm = yaml.safe_load(fm_match.group(1)) or {}
            name = fm.get("name", name)
            description = (fm.get("description") or "").strip().replace("\n", " ")
            # First sentence only — keep the table tight.
            if description:
                first = re.split(r"(?<=[.!?])\s+", description, maxsplit=1)[0]
                description = first
        except yaml.YAMLError:
            pass

    # Infer role from name suffix.
    if name.endswith("-architect"):
        role = "architect"
    elif name.endswith("-developer"):
        role = "developer"
    elif name.endswith("-troubleshooter"):
        role = "troubleshooter"
    elif name in {"code-reviewer", "code-simplifier", "code-documenter"}:
        role = "closer"

    rel_path = md.relative_to(agents_dir.parent.parent).as_posix()
    agent_rows.append((name, role, description, rel_path))

if agent_rows:
    lines = [
        "| Agent | Role | Purpose | File |",
        "|-------|------|---------|------|",
    ]
    for name, role, desc, path in agent_rows:
        # Pipe-escape so table cells do not break.
        # NOTE: no apostrophes anywhere in this heredoc. The delimiter is quoted
        # (<<'PYEOF'), which should make the body opaque — but this heredoc sits
        # inside a $( ) command substitution, and bash 3.2 (stock macOS, this
        # repo's portability floor) still tokenizes the body while scanning for
        # the closing paren. A single "don't" made the whole script unparseable
        # under `bash -n` on macOS while parsing fine under bash 5 on Linux.
        desc_safe = (desc or "").replace("|", "\\|")
        lines.append(f"| `{name}` | {role} | {desc_safe} | [`{path}`]({path}) |")
    agents_table = "\n".join(lines)
else:
    agents_table = "_(no agents scaffolded yet)_"

# ─── KB table ──────────────────────────────────────────────────────────────
if domains:
    lines = [
        "| Domain | Description | Quick reference |",
        "|--------|-------------|-----------------|",
    ]
    for slug, block in domains.items():
        d_name = block.get("name") or slug
        d_desc = (block.get("description") or "").replace("|", "\\|")
        path = block.get("path") or f"{slug}/"
        qr_rel = (block.get("entry_points") or {}).get("quick_reference") or "quick-reference.md"
        qr_link = f".claude/kb/{path.rstrip('/')}/{qr_rel}"
        lines.append(f"| `{slug}` ({d_name}) | {d_desc} | [`{qr_link}`]({qr_link}) |")
    kb_table = "\n".join(lines)
else:
    kb_table = "_(no domains registered yet)_"

# ─── Render ────────────────────────────────────────────────────────────────
content = tpl_path.read_text()
content = content.replace("{PROJECT_NAME}", project_name)
content = content.replace("{AGENTS_TABLE}", agents_table)
content = content.replace("{KB_TABLE}", kb_table)
content = content.replace("{LAST_UPDATED}", last_updated)

print(content)
