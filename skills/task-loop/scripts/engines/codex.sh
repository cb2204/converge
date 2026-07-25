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
# Positional prompt rather than stdin: `codex exec [PROMPT]` accepts it directly,
# and passing it as an argument removes a whole class of plumbing failure (a
# backgrounded job losing its redirect) that is invisible in the transcript —
# it looks like the model produced nothing.
# stdin MUST be explicitly closed. `codex exec` documents that "if stdin is
# piped and a prompt is also provided, stdin is appended as a <stdin> block" —
# so with an open-but-never-closed stdin it reads the positional prompt, does
# the work, and then BLOCKS forever waiting for an EOF that never arrives. The
# watchdog eventually kills it at 124 and the whole attempt reads as a timeout,
# which hides the fact that the model finished minutes earlier.
to "$ENG_TIMEOUT" "$CMD" exec --sandbox workspace-write "$(cat "$ENG_PROMPT")" </dev/null 2>&1 || RC=$?

eng_finish "$RC"
