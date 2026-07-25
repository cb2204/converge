#!/usr/bin/env bash
# codex.sh — Pass 8 execution engine: OpenAI Codex CLI, headless.
#
# `--sandbox workspace-write` is the point: Codex confines writes to the working
# tree at the OS level, which makes fs.write a PREVENTED capability here rather
# than a merely DETECTED one. That difference is what the capability envelope's
# assurance field records, and it is why codex can satisfy a --require that
# generic cannot.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_engine_lib.sh"
eng_parse_args "$@"

CMD="${CVG_CODEX_CMD:-codex}"
[ "$ENG_MODE" = "available" ] && { command -v "$CMD" >/dev/null 2>&1; exit $?; }

RC=0
cd "$ENG_WORKDIR" || exit 4
to "$ENG_TIMEOUT" "$CMD" exec --sandbox workspace-write - < "$ENG_PROMPT" 2>&1 || RC=$?

eng_finish "$RC"
