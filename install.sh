#!/usr/bin/env bash
# install.sh — make Converge usable from a consuming repo.
#
# Two things get installed, and they are deliberately separate:
#
#   1. the SKILLS  → <target>/.claude/skills/*   so Claude Code can see them
#   2. the CLI     → `cvg` on your PATH          so the gates are runnable by hand
#
# Symlink (default) tracks this checkout, so `git pull` here updates every
# consuming repo at once. `--copy` pins a version instead — the right choice
# when a repo must build the same way in six months.
#
# This script installs. It never configures, never writes a credential, and
# never touches anything outside <target>/.claude/skills and the bin dir you
# pick. Re-running it is safe.
#
# Bash 3.2 compatible (stock macOS).
set -euo pipefail

CVG_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PWD"
MODE="symlink"
BIN_DIR=""
DO_BIN=1
FORCE=0

usage() {
  cat <<EOF
usage: install.sh [--target DIR] [--copy] [--bin-dir DIR] [--no-bin] [--force]

  --target DIR   repo to install into            (default: current directory)
  --copy         copy instead of symlink         (pins this version)
  --bin-dir DIR  where to link \`cvg\`             (default: first writable of
                 ~/.local/bin, /usr/local/bin)
  --no-bin       skip the CLI, install skills only
  --force        replace existing skill entries

Examples
  cd ~/my-project && bash /path/to/converge/install.sh
  bash install.sh --target ~/my-project --copy
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)  [ $# -ge 2 ] || { echo "ERROR: --target requires a directory" >&2; exit 2; }; TARGET="$2"; shift 2 ;;
    --target=*) TARGET="${1#--target=}"; shift ;;
    --copy)    MODE="copy"; shift ;;
    --bin-dir) [ $# -ge 2 ] || { echo "ERROR: --bin-dir requires a directory" >&2; exit 2; }; BIN_DIR="$2"; shift 2 ;;
    --bin-dir=*) BIN_DIR="${1#--bin-dir=}"; shift ;;
    --no-bin)  DO_BIN=0; shift ;;
    --force)   FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

[ -d "$CVG_SRC/skills" ] || { echo "ERROR: no skills/ beside install.sh — is this a Converge checkout?" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "ERROR: target '$TARGET' does not exist" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$CVG_SRC" ]; then
  echo "ERROR: target is the Converge checkout itself. Install INTO a consuming repo." >&2
  exit 2
fi

echo "Converge → $TARGET"
echo "  source : $CVG_SRC"
echo "  mode   : $MODE"
echo

# --- 1. skills ---------------------------------------------------------------
SKILL_DIR="$TARGET/.claude/skills"
mkdir -p "$SKILL_DIR"
INSTALLED=0
SKIPPED=0

for src in "$CVG_SRC"/skills/*/; do
  [ -f "$src/SKILL.md" ] || continue          # only real skills, not README.md
  name="$(basename "$src")"
  dest="$SKILL_DIR/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      rm -rf "$dest"
    else
      printf '  skip   %-32s (exists — use --force to replace)\n' "$name"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi
  if [ "$MODE" = "copy" ]; then
    cp -R "$src" "$dest"
  else
    ln -s "${src%/}" "$dest"
  fi
  printf '  ok     %-32s\n' "$name"
  INSTALLED=$((INSTALLED + 1))
done

# --- 2. the CLI --------------------------------------------------------------
BIN_NOTE=""
if [ "$DO_BIN" -eq 1 ]; then
  if [ -z "$BIN_DIR" ]; then
    for cand in "$HOME/.local/bin" /usr/local/bin; do
      if [ -d "$cand" ] && [ -w "$cand" ]; then BIN_DIR="$cand"; break; fi
    done
    # ~/.local/bin is the conventional user-writable spot; create it if nothing else fits
    [ -z "$BIN_DIR" ] && { BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"; }
  fi
  mkdir -p "$BIN_DIR"
  if [ -e "$BIN_DIR/cvg" ] && [ "$FORCE" -eq 0 ] && [ ! -L "$BIN_DIR/cvg" ]; then
    BIN_NOTE="  skip   cvg (a real file already sits at $BIN_DIR/cvg — use --force)"
  else
    rm -f "$BIN_DIR/cvg"
    ln -s "$CVG_SRC/bin/cvg" "$BIN_DIR/cvg"
    BIN_NOTE="  ok     cvg → $BIN_DIR/cvg"
  fi
  echo
  echo "$BIN_NOTE"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "  note   $BIN_DIR is not on your PATH — add it to use \`cvg\` directly" ;;
  esac
fi

# --- 3. verify ---------------------------------------------------------------
echo
VALIDATOR="$SKILL_DIR/skill-creator/scripts/quick_validate.py"
if [ -f "$VALIDATOR" ] && python3 "$VALIDATOR" "$SKILL_DIR/task-spec" >/dev/null 2>&1; then
  echo "verified: the installed skills parse (task-spec is valid)"
else
  echo "WARNING: could not verify the install — run:"
  echo "  python3 $VALIDATOR $SKILL_DIR/task-spec"
fi

echo
echo "installed $INSTALLED skill(s), skipped $SKIPPED."
cat <<EOF

Next:
  1. restart Claude Code so it picks up .claude/skills/
  2. provision the signing key (once per repo) so the gate can seal specs:
       bash .claude/skills/task-spec/configs/setup-taskspec-signing-key.sh
  3. pick your lane and start the descent:
       cvg lane "what you are about to build"

INSTALL=OK
EOF
