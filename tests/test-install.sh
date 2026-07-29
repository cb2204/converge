#!/usr/bin/env bash
# test-install.sh — the install surface, exercised the way a stranger will use it.
#
# Everything here runs against a THROWAWAY consuming repo, never this checkout.
# The install path is the one part of Converge that is only ever exercised by
# people who are not us, so it gets tested the same way they'll hit it: clone,
# run install.sh, use `cvg` from PATH with no environment set.
#
# Bash 3.2 compatible (stock macOS).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
PASS=0
FAIL=0

ok()  { printf '  ok   — %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  FAIL — %s\n' "$1"; FAIL=$((FAIL + 1)); }

echo "=================================================================="
echo "install surface"
echo "=================================================================="

T="$(mktemp -d -t cvg-install.XXXXXX)"
git -C "$T" init --quiet

OUT="$(bash "$SRC/install.sh" --target "$T" --bin-dir "$T/bin" 2>&1)"
RC=$?

if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '^INSTALL=OK$'; then
  ok "a clean install succeeds and emits INSTALL=OK"
else
  bad "install failed (rc=$RC)"
fi

# Every skill, and only skills — skills/README.md must not become a skill dir.
COUNT="$(find "$T/.claude/skills" -maxdepth 1 -mindepth 1 | wc -l | tr -d ' ')"
EXPECTED="$(find "$SRC/skills" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
if [ "$COUNT" = "$EXPECTED" ]; then
  ok "every skill installs, and nothing that is not a skill ($COUNT)"
else
  bad "installed $COUNT entries, expected $EXPECTED"
fi

# THE regression: the normal install puts a SYMLINK on PATH. If cvg locates its
# companions via `dirname $0` without resolving that link, it looks for _ui.sh
# in the bin dir and dies on line 21 — broken for every user, invisible to us,
# because running ./bin/cvg from the checkout always works.
VOUT="$("$T/bin/cvg" version 2>&1)"
if printf '%s' "$VOUT" | grep -q '^cvg '; then
  ok "cvg runs through a PATH symlink (resolves its own link to find _ui.sh)"
else
  bad "cvg is broken when invoked through a symlink: $(printf '%s' "$VOUT" | head -1)"
fi

# A consuming repo has no CVG_HOME and no .cvg/ — the CLI must still work.
LOUT="$(cd "$T" && env -u CVG_HOME "$T/bin/cvg" lane "fix a typo in the readme" 2>&1)"
if printf '%s' "$LOUT" | grep -q '^LANE=FAST$'; then
  ok "the CLI works from a consuming repo with no configuration"
else
  bad "the CLI needs configuration a new user does not have"
fi

# Re-running must not damage a working install.
OUT2="$(bash "$SRC/install.sh" --target "$T" --bin-dir "$T/bin" 2>&1)"
if printf '%s' "$OUT2" | grep -q 'skipped 11' && "$T/bin/cvg" version >/dev/null 2>&1; then
  ok "re-running the installer is safe and skips what is already there"
else
  bad "re-running the installer is not idempotent"
fi

# Installing into the checkout itself is a mistake worth refusing.
if ! bash "$SRC/install.sh" --target "$SRC" >/dev/null 2>&1; then
  ok "installing onto the Converge checkout itself is refused"
else
  bad "the installer overwrote its own source"
fi

# --copy must pin, not link — the point of the flag.
T2="$(mktemp -d -t cvg-install2.XXXXXX)"
git -C "$T2" init --quiet
bash "$SRC/install.sh" --target "$T2" --no-bin --copy >/dev/null 2>&1
if [ -d "$T2/.claude/skills/task-spec" ] && [ ! -L "$T2/.claude/skills/task-spec" ]; then
  ok "--copy pins a real directory instead of tracking upstream"
else
  bad "--copy still produced a symlink"
fi

rm -rf "$T" "$T2"

echo "------------------------------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  printf 'PASS — %d install checks green.\n' "$PASS"
  exit 0
fi
printf 'FAIL — %d of %d install checks red.\n' "$FAIL" "$((PASS + FAIL))"
exit 1
