#!/usr/bin/env bash
# emit-cross-tool.sh — Emit the three cross-tool files from the canonical
# .claude/ layout:
#
#   1. AGENTS.md                                  (repo root, cross-tool index)
#   2. .cursor/rules/agents-kbs-tech-stack.mdc    (Cursor shim)
#   3. .github/copilot-instructions.md            (Copilot pointer)
#
# All three are generated proposals. A missing file is created; an identical
# file is left alone; a differing existing file is preserved and the new
# rendering is written to a `.proposed` sibling. Run this after:
#
#   - adding/removing a tech (scaffold.sh / install-closers.sh)
#   - renaming the project (changing kb/_index.yaml `project:`)
#   - bumping doctrine
#
# Inputs:
#   TARGET_REPO  absolute path to the target repo
#
# Exit codes:
#   0  emitted
#   1  TARGET_REPO unset or invalid
#   2  .claude/ scaffolding incomplete (no _index.yaml or no agents dir)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEMPLATES="${SKILL_ROOT}/templates"

if [[ -z "${TARGET_REPO:-}" ]]; then
  echo "ERROR: TARGET_REPO must be set (absolute path to the target repo)" >&2
  exit 1
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "ERROR: TARGET_REPO does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

INDEX_PATH="${TARGET_REPO}/.claude/kb/_index.yaml"
AGENTS_DIR="${TARGET_REPO}/.claude/agents"

if [[ ! -e "${INDEX_PATH}" ]]; then
  echo "ERROR: ${INDEX_PATH} does not exist — scaffold at least one tech first." >&2
  exit 2
fi

if [[ ! -d "${AGENTS_DIR}" ]]; then
  echo "ERROR: ${AGENTS_DIR} does not exist — scaffold at least one tech first." >&2
  exit 2
fi

LAST_UPDATED="$(date -u +%Y-%m-%d)"

emit_safely() {
  local rendered="$1" destination="$2"
  mkdir -p "$(dirname "${destination}")"
  if [[ ! -e "${destination}" ]]; then
    cp "${rendered}" "${destination}"
    echo "✓ wrote ${destination}"
    return 0
  fi
  if cmp -s "${rendered}" "${destination}"; then
    echo "✓ unchanged ${destination}"
    return 0
  fi
  cp "${rendered}" "${destination}.proposed"
  echo "NOTE: preserved ${destination}; wrote ${destination}.proposed"
}

# ─── Build the AGENTS.md content via Python (needs yaml + filesystem walk) ──
RENDER_OUTPUT="$(python3 "${SCRIPT_DIR}/render-agents.py" "${INDEX_PATH}" "${AGENTS_DIR}" "${TEMPLATES}/AGENTS.md.tpl" "${LAST_UPDATED}")"

# ─── Write AGENTS.md ────────────────────────────────────────────────────────
AGENTS_MD="${TARGET_REPO}/AGENTS.md"
AGENTS_RENDERED="$(mktemp -t agents-rendered.XXXXXX)"
CURSOR_RENDERED="$(mktemp -t cursor-rendered.XXXXXX)"
COPILOT_RENDERED="$(mktemp -t copilot-rendered.XXXXXX)"
trap 'rm -f "${AGENTS_RENDERED}" "${CURSOR_RENDERED}" "${COPILOT_RENDERED}"' EXIT
printf '%s' "${RENDER_OUTPUT}" > "${AGENTS_RENDERED}"
emit_safely "${AGENTS_RENDERED}" "${AGENTS_MD}"

# ─── Write Cursor mdc ───────────────────────────────────────────────────────
CURSOR_DIR="${TARGET_REPO}/.cursor/rules"
mkdir -p "${CURSOR_DIR}"
CURSOR_MDC="${CURSOR_DIR}/agents-kbs-tech-stack.mdc"
cp "${TEMPLATES}/cursor-rules.mdc.tpl" "${CURSOR_RENDERED}"
emit_safely "${CURSOR_RENDERED}" "${CURSOR_MDC}"

# ─── Write Copilot instructions ─────────────────────────────────────────────
GH_DIR="${TARGET_REPO}/.github"
mkdir -p "${GH_DIR}"
COPILOT_MD="${GH_DIR}/copilot-instructions.md"
cp "${TEMPLATES}/copilot-instructions.md.tpl" "${COPILOT_RENDERED}"
emit_safely "${COPILOT_RENDERED}" "${COPILOT_MD}"

echo ""
echo "────────────────────────────────────────────────────────────────────────"
echo "Cross-tool index emitted without overwriting differing existing files:"
echo "  • ${AGENTS_MD}"
echo "  • ${CURSOR_MDC}"
echo "  • ${COPILOT_MD}"
echo ""
echo "Re-emit after adding/removing a tech, renaming the project, or"
echo "bumping doctrine. Review any .proposed sibling and merge intentionally."
echo "────────────────────────────────────────────────────────────────────────"
