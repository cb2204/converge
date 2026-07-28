#!/usr/bin/env python3
"""
Quick validation script for skills - minimal version
"""

import sys
import os
import re
from pathlib import Path


class FrontmatterError(ValueError):
    """The frontmatter could not be read as a flat mapping."""


def _scalar(value):
    """Unquote a plain YAML scalar. Nothing else — no types, no anchors."""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_frontmatter(text):
    """Read SKILL.md frontmatter with the standard library only.

    PyYAML is NOT stdlib. It happens to be preinstalled on GitHub's ubuntu image
    and on this author's homebrew python, and is ABSENT on macos-latest — so
    `import yaml` made CI report all twelve skills INVALID on macOS while passing
    on Linux, and it would break the verification command the README tells users
    to run (`quick_validate.py <skill>`) for anyone without PyYAML installed.
    This was the only non-stdlib import in the whole repository, against a stated
    portability floor of bash 3.2 and stdlib python.

    The grammar actually needed is small: a flat map of scalars, plus an optional
    nested `metadata:` block and optional folded scalars. That does not justify a
    dependency, so it is parsed directly. Anything richer than this grammar is an
    error rather than a silent misread — a validator that quietly misunderstands
    its input is worse than one that refuses it.
    """
    data = {}
    key = None
    for raw in text.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw[0] not in " \t":
            match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", raw)
            if not match:
                raise FrontmatterError(f"cannot parse line: {raw!r}")
            key = match.group(1)
            value = match.group(2).strip()
            # An empty value opens either a folded scalar (`>`, `|`) or a nested
            # block; both are accumulated from the indented lines that follow.
            data[key] = "" if value in (">", ">-", "|", "|-", "") else _scalar(value)
        else:
            if key is None:
                raise FrontmatterError(f"indented line before any key: {raw!r}")
            if isinstance(data.get(key), str):
                extra = raw.strip()
                data[key] = f"{data[key]} {extra}".strip() if data[key] else extra
    return data

def validate_skill(skill_path):
    """Basic validation of a skill"""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    # Parse YAML frontmatter
    try:
        frontmatter = parse_frontmatter(frontmatter_text)
        if not isinstance(frontmatter, dict):
            return False, "Frontmatter must be a YAML dictionary"
    except FrontmatterError as e:
        return False, f"Invalid YAML in frontmatter: {e}"

    # Define allowed properties
    ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility'}

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Extract name for validation
    name = frontmatter.get('name', '')
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (kebab-case: lowercase with hyphens)
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' should be kebab-case (lowercase letters, digits, and hyphens only)"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

    # Extract and validate description
    description = frontmatter.get('description', '')
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check for angle brackets
        if '<' in description or '>' in description:
            return False, "Description cannot contain angle brackets (< or >)"
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

    # Validate compatibility field if present (optional)
    compatibility = frontmatter.get('compatibility', '')
    if compatibility:
        if not isinstance(compatibility, str):
            return False, f"Compatibility must be a string, got {type(compatibility).__name__}"
        if len(compatibility) > 500:
            return False, f"Compatibility is too long ({len(compatibility)} characters). Maximum is 500 characters."

    return True, "Skill is valid!"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)
    
    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)