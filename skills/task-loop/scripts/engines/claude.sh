#!/usr/bin/env bash
# claude.sh — Pass 8 execution engine: Claude Code, headless.
#
# Write-capable by design: this is the maker, not the checker. The confinement
# is the capability envelope, not the tool list — the postflight path guard
# rejects anything outside the contract's fs.write scope, and the eval it is
# graded on is HMAC-sealed and unreachable from that scope.
#
# The Task-Spec is deliberately NOT passed on the command line: the brief points
# at it by path so the agent reads the sealed file itself rather than a copy that
# could have been altered in transit.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_engine_lib.sh"
eng_parse_args "$@"

CMD="${CVG_CLAUDE_CMD:-claude}"
[ "$ENG_MODE" = "available" ] && { command -v "$CMD" >/dev/null 2>&1; exit $?; }

RC=0
cd "$ENG_WORKDIR" || exit 4
# acceptEdits keeps the run unattended without granting shell-level authority.
to "$ENG_TIMEOUT" "$CMD" -p "$(cat "$ENG_PROMPT")" \
  --permission-mode acceptEdits \
  --output-format json </dev/null 2>&1 || RC=$?

eng_finish "$RC"
