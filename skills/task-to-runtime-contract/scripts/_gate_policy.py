"""Repo-level write fence — the one a Task-Spec cannot widen.

WHY THIS EXISTS

Until now the ONLY thing constraining a run's writes was the per-task
`fs.write` scope in the capability envelope. That is a strong control and it
has a blind spot that is easy to miss: the guard's whole job is to enforce what
the spec declared, so a spec that declares `touches_paths: [auth/]` is not a
violation — it is an instruction. Everything downstream then works perfectly to
let the agent edit your auth code.

A repo-level gate is a SECOND, INDEPENDENT fence. It answers a different
question:

    contract  — "may this task write here?"          (per task, authored)
    gate      — "may ANY task ever write here?"      (per repo, standing)

Denylist beats contract, always. A spec cannot grant what the repo forbids, and
no amount of re-signing changes that, because the gate is not part of the
signed payload — it belongs to the repository, not to the task.

`max_files` is orthogonal to paths: a blast-radius cap. Twelve in-scope files
changed by an unattended agent is a different event from two, even when every
path is legal.

FAILS CLOSED, BUT ONLY WHEN PRESENT

No gate file means no gate — existing installs are unaffected and this is
strictly opt-in. But a gate file that cannot be parsed is a FAILURE, never a
silently-skipped control. A safety fence you can disable with a typo is not a
fence.

Format is a deliberately tiny YAML subset (stdlib only, no dependencies):

    version: 1
    denylist:
      - ".env"
      - "**/secrets/**"
      - "auth/**"
    max_files: 10
    auto_merge_allowlist:
      - "docs/**"

Credit: the gate.yaml idea comes from the loop-engineering project
(github.com/cobusgreyling/loop-engineering, MIT), which pairs a machine-readable
denylist with a prose safety doc. The precedence rule and the fail-closed parse
are ours.
"""

from __future__ import annotations

import fnmatch
from pathlib import Path

GATE_FILENAME = "gate.yaml"


class GatePolicyError(Exception):
    """The gate exists but could not be read. Never treated as 'no gate'."""


class GatePolicy:
    def __init__(
        self,
        source: Path | None = None,
        denylist: list[str] | None = None,
        max_files: int | None = None,
        auto_merge_allowlist: list[str] | None = None,
    ) -> None:
        self.source = source
        self.denylist = denylist or []
        self.max_files = max_files
        self.auto_merge_allowlist = auto_merge_allowlist or []

    @property
    def active(self) -> bool:
        return self.source is not None

    def forbids(self, path: str) -> str | None:
        """Return the denylist rule a path violates, or None."""
        # NOT lstrip("./") — that strips every leading dot and would turn
        # ".env" into "env", exempting the files most worth guarding.
        candidate = path
        while candidate.startswith("./"):
            candidate = candidate[2:]
        for rule in self.denylist:
            if _matches(candidate, rule):
                return rule
        return None

    def violations(self, paths: list[str]) -> list[tuple[str, str]]:
        found = []
        for path in paths:
            rule = self.forbids(path)
            if rule:
                found.append((path, rule))
        return found

    def exceeds_blast_radius(self, count: int) -> bool:
        return self.max_files is not None and count > self.max_files


def _matches(path: str, rule: str) -> bool:
    """Glob match with `**` meaning 'any depth', including zero.

    fnmatch alone treats `*` as crossing separators, which makes `auth/**` and
    `auth/*` behave identically and would silently over-match. Normalising the
    zero-directory case first keeps `**/secrets/**` matching a top-level
    `secrets/x` as well as `a/b/secrets/x`.
    """
    variants = {rule}
    if "/**/" in rule:
        variants.add(rule.replace("/**/", "/", 1))
    if rule.startswith("**/"):
        variants.add(rule[3:])
    if rule.endswith("/**"):
        stem = rule[:-3]
        variants.add(stem)
        variants.add(f"{stem}/*")
    return any(fnmatch.fnmatch(path, variant) for variant in variants)


def _strip_comment(line: str) -> str:
    # Only strip a comment that is not inside quotes — paths legitimately
    # contain '#' far less often than this parser would corrupt them.
    out, quote = [], None
    for ch in line:
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_gate(text: str, source: Path | None = None) -> GatePolicy:
    """Parse the tiny supported subset. Anything unexpected is an error."""
    denylist: list[str] = []
    auto_merge: list[str] = []
    max_files: int | None = None
    current: list[str] | None = None

    for raw in text.splitlines():
        line = _strip_comment(raw)
        if not line.strip():
            continue
        stripped = line.strip()

        if stripped.startswith("- "):
            if current is None:
                raise GatePolicyError(
                    f"list item outside any key: {stripped!r}"
                )
            current.append(_unquote(stripped[2:]))
            continue

        if ":" not in stripped:
            raise GatePolicyError(f"cannot parse line: {stripped!r}")

        key, _, value = stripped.partition(":")
        key = key.strip()
        value = value.strip()
        current = None

        if key == "version":
            if _unquote(value) not in ("1", ""):
                raise GatePolicyError(f"unsupported gate version: {value!r}")
        elif key == "denylist":
            current = denylist
            if value:
                raise GatePolicyError("denylist must be a block list, one '- rule' per line")
        elif key in ("max_files", "maxFiles"):
            try:
                max_files = int(_unquote(value))
            except ValueError as exc:
                raise GatePolicyError(f"max_files must be an integer, got {value!r}") from exc
        elif key in ("auto_merge_allowlist", "autoMergeAllowlist"):
            current = auto_merge
            if value:
                raise GatePolicyError("auto_merge_allowlist must be a block list")
        else:
            raise GatePolicyError(f"unknown gate key: {key!r}")

    return GatePolicy(
        source=source,
        denylist=denylist,
        max_files=max_files,
        auto_merge_allowlist=auto_merge,
    )


def load_gate(*roots: Path) -> GatePolicy:
    """First `.cvg/gate.yaml` found across the given roots, in order.

    Workspace before repo: a nested workspace may tighten the fence for itself,
    which is the only direction that is ever safe to allow locally.
    """
    for root in roots:
        if root is None:
            continue
        candidate = Path(root) / ".cvg" / GATE_FILENAME
        if candidate.is_file():
            try:
                return parse_gate(candidate.read_text(encoding="utf-8"), source=candidate)
            except GatePolicyError as exc:
                raise GatePolicyError(f"{candidate}: {exc}") from exc
    return GatePolicy()
