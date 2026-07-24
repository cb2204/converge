#!/usr/bin/env bash
# Regression for the two legacy safety defects found during the Pass 6 audit.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$(mktemp -d -t cvg-legacy-harness.XXXXXX)"
trap 'rm -rf "$TARGET"' EXIT

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok    %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL  %s\n' "$1" >&2; }

TARGET_REPO="$TARGET" \
PROJECT_NAME="safety-test" \
PROJECT_DESCRIPTION="Disposable safety regression." \
TECH="python" \
bash "$SKILL_DIR/scripts/scaffold.sh" >/dev/null
TARGET_REPO="$TARGET" bash "$SKILL_DIR/scripts/install-closers.sh" >/dev/null

TARGET_REPO="$TARGET" bash "$SKILL_DIR/scripts/emit-cross-tool.sh" >/dev/null
printf '\nUSER-OWNED-LINE\n' >> "$TARGET/AGENTS.md"
TARGET_REPO="$TARGET" bash "$SKILL_DIR/scripts/emit-cross-tool.sh" > "$TARGET/emit.out"

if grep -q 'USER-OWNED-LINE' "$TARGET/AGENTS.md" \
  && [ -f "$TARGET/AGENTS.md.proposed" ] \
  && grep -q "^NOTE: preserved $TARGET/AGENTS.md; wrote $TARGET/AGENTS.md.proposed$" "$TARGET/emit.out"; then
  ok "emitter preserves a differing AGENTS.md and writes .proposed"
else
  bad "AGENTS.md was clobbered or no .proposed file was emitted"
fi

for path in \
  ".cursor/rules/agents-kbs-tech-stack.mdc" \
  ".github/copilot-instructions.md"
do
  printf '\nUSER-OWNED-LINE\n' >> "$TARGET/$path"
done
TARGET_REPO="$TARGET" bash "$SKILL_DIR/scripts/emit-cross-tool.sh" >/dev/null
if grep -q 'USER-OWNED-LINE' "$TARGET/.cursor/rules/agents-kbs-tech-stack.mdc" \
  && [ -f "$TARGET/.cursor/rules/agents-kbs-tech-stack.mdc.proposed" ] \
  && grep -q 'USER-OWNED-LINE' "$TARGET/.github/copilot-instructions.md" \
  && [ -f "$TARGET/.github/copilot-instructions.md.proposed" ]; then
  ok "Cursor and Copilot mirrors use the same non-clobber contract"
else
  bad "a cross-tool mirror was clobbered"
fi

set +e
GATE_OUT="$(TARGET_REPO="$TARGET" bash "$SKILL_DIR/scripts/quality-gate.sh" --strict 2>&1)"
GATE_RC=$?
set -e
if [ "$GATE_RC" -eq 7 ] \
  && grep -q 'TODO' <<<"$GATE_OUT" \
  && grep -q '^Verdict: BLOCK$' <<<"$GATE_OUT"; then
  ok "strict gate rejects TODO-seeded KB content"
else
  bad "strict gate approved an unfinished KB (rc=$GATE_RC)"
fi

if ! grep -q 'kimi:review' <<<"$GATE_OUT" \
  && grep -q 'external model review: retired' <<<"$GATE_OUT"; then
  ok "legacy gate is deterministic and vendor-decoupled"
else
  bad "legacy gate still embeds the Claude-to-Kimi call"
fi

if [ "$FAIL" -eq 0 ]; then
  printf 'PASS — %s legacy safety checks green.\n' "$PASS"
  exit 0
fi
printf 'FAIL — %s of %s legacy safety checks red.\n' "$FAIL" "$((PASS + FAIL))" >&2
exit 1
