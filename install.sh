#!/usr/bin/env bash
# install.sh — make Converge usable from a consuming repo.
#
# Two things get installed, and they are deliberately separate:
#
#   1. the SKILLS  → <target>/.agents/skills/*   for Codex + Kimi
#                  → <target>/.claude/skills/*   for Claude Code
#   2. the CLI     → `cvg` on your PATH          so the gates are runnable by hand
#
# Copy (default) pins the complete 0.1.0 tool surface so a consuming repository
# does not depend on this checkout. `--symlink` is the explicit development mode.
#
# This script installs. It never configures, never writes a credential, and
# never configures credentials. Re-running it is safe.
#
# Bash 3.2 compatible (stock macOS).
set -euo pipefail

CVG_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PWD"
MODE="copy"
BIN_DIR=""
DO_BIN=1
FORCE=0

usage() {
  cat <<EOF
usage: install.sh [--target DIR] [--copy|--symlink] [--bin-dir DIR] [--no-bin] [--force]

  --target DIR   repo to install into            (default: current directory)
  --copy         copy the complete tool surface  (default; pins this version)
  --symlink      link to this checkout            (development only)
  --bin-dir DIR  where to install \`cvg\`          (default: first writable of
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
    --symlink) MODE="symlink"; shift ;;
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
INSTALLED=0
SKIPPED=0

for SKILL_DIR in "$TARGET/.agents/skills" "$TARGET/.claude/skills"; do
  mkdir -p "$SKILL_DIR"
  case "$SKILL_DIR" in
    */.agents/skills) printf '  shared skills (Codex + Kimi):\n' ;;
    */.claude/skills) printf '  Claude Code skills:\n' ;;
  esac
  for src in "$CVG_SRC"/skills/*/; do
    [ -f "$src/SKILL.md" ] || continue
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
      # A pinned package must not carry developer-machine bytecode, caches, or
      # metadata. Python .pyc files embed their source path and would make the
      # supposedly clean install depend on this checkout.
      find "$dest" -type d \( -name __pycache__ -o -name .pytest_cache -o -name .ruff_cache \) -prune \
        | while IFS= read -r cache_dir; do rm -rf "$cache_dir"; done
      find "$dest" -type f \( -name '*.pyc' -o -name '*.pyo' -o -name .DS_Store \) -delete
    else
      ln -s "${src%/}" "$dest"
    fi
    printf '  ok     %-32s\n' "$name"
    INSTALLED=$((INSTALLED + 1))
  done
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
    if [ "$MODE" = "copy" ]; then
      cp "$CVG_SRC/bin/cvg" "$BIN_DIR/cvg"
      chmod +x "$BIN_DIR/cvg"
      cp "$CVG_SRC/bin/_ui.sh" "$BIN_DIR/.cvg-ui.sh"
      chmod 644 "$BIN_DIR/.cvg-ui.sh"
      BIN_NOTE="  ok     cvg pinned at $BIN_DIR/cvg"
    else
      ln -s "$CVG_SRC/bin/cvg" "$BIN_DIR/cvg"
      BIN_NOTE="  ok     cvg → $BIN_DIR/cvg"
    fi
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
VALIDATOR="$TARGET/.agents/skills/skill-creator/scripts/quick_validate.py"
if [ -f "$VALIDATOR" ] && python3 "$VALIDATOR" "$TARGET/.agents/skills/task-spec" >/dev/null 2>&1; then
  echo "verified: the installed skills parse (task-spec is valid)"
else
  echo "WARNING: could not verify the install — run:"
  echo "  python3 $VALIDATOR $SKILL_DIR/task-spec"
fi

echo
echo "installed $INSTALLED skill(s), skipped $SKIPPED."
cat <<EOF

Next:
  1. initialize the tracked Converge control plane:
       cvg init
  2. provision the repo-private signing key:
       cvg setup signing
  3. restart Codex, Kimi, or Claude Code so it discovers the installed skills
  4. inspect readiness, then pick your lane:
       cvg setup
       cvg lane "what you are about to build"

INSTALL=OK
EOF
