#!/usr/bin/env bash
# _engine_lib.sh — shared contract for Pass 8 execution engines.
#
# An engine adapter is the ONLY place that knows how a particular CLI is spelled.
# The loop kernel knows nothing about any vendor; it calls this contract:
#
#   bash engines/<name>.sh --available
#       exit 0 if the engine can actually run on this host. Nothing else.
#
#   bash engines/<name>.sh --prompt-file F --workdir D [--timeout SECONDS]
#       run ONE attempt with a FRESH context, cwd = workdir. The transcript goes
#       to stdout. If the engine reports usage, the adapter emits one line
#       `ENGINE_TOKENS=<n>` so the kernel can debit its token budget.
#
# WHY EACH ATTEMPT IS A NEW PROCESS
#   A retry inside one session re-reads every prior failure, so cost grows
#   quadratically while attention degrades — and content pushed deep into a long
#   context is attended to least. A fresh process per attempt keeps each
#   iteration flat and forces state to live on disk, where it can be reviewed.
#
# WHY THE TIMEOUT IS NOT OPTIONAL
#   A hung engine must not hang the loop. This was observed live in Pass 4:
#   `codex exec` blocking at 0% CPU on a model round-trip. macOS ships neither
#   timeout(1) nor gtimeout, so a pure-bash watchdog enforces the same cap with
#   zero dependencies. A timeout normalizes to exit 124, the way timeout(1) does.
#
# Bash 3.2 compatible (stock macOS).

ENGINE_TIMEOUT="${ENGINE_TIMEOUT:-900}"

_eng_timeout_bin=""
if command -v timeout >/dev/null 2>&1; then _eng_timeout_bin="timeout"
elif command -v gtimeout >/dev/null 2>&1; then _eng_timeout_bin="gtimeout"; fi

# to <seconds> <cmd...> — run under a hard wall-clock cap; 124 on timeout.
to() {
  _to_secs="$1"; shift
  if [ -n "$_eng_timeout_bin" ]; then "$_eng_timeout_bin" "$_to_secs" "$@"; return $?; fi
  _to_flag="$(mktemp)"; _to_rc=0
  "$@" &
  _to_pid=$!
  ( sleep "$_to_secs"
    if kill -0 "$_to_pid" 2>/dev/null; then
      printf T > "$_to_flag"; kill -TERM "$_to_pid" 2>/dev/null
      sleep 2; kill -KILL "$_to_pid" 2>/dev/null
    fi ) &
  _to_wd=$!
  wait "$_to_pid" 2>/dev/null || _to_rc=$?
  kill "$_to_wd" 2>/dev/null || true; wait "$_to_wd" 2>/dev/null || true
  if [ -s "$_to_flag" ]; then rm -f "$_to_flag"; return 124; fi
  rm -f "$_to_flag"; return "$_to_rc"
}

# Parse the uniform adapter arguments into ENG_* variables.
eng_parse_args() {
  ENG_MODE="run"; ENG_PROMPT=""; ENG_WORKDIR="$PWD"; ENG_TIMEOUT="$ENGINE_TIMEOUT"
  while [ $# -gt 0 ]; do
    case "$1" in
      --available)     ENG_MODE="available"; shift ;;
      --prompt-file)   ENG_PROMPT="${2:?--prompt-file requires a path}"; shift 2 ;;
      --prompt-file=*) ENG_PROMPT="${1#--prompt-file=}"; shift ;;
      --workdir)       ENG_WORKDIR="${2:?--workdir requires a path}"; shift 2 ;;
      --workdir=*)     ENG_WORKDIR="${1#--workdir=}"; shift ;;
      --timeout)       ENG_TIMEOUT="${2:?--timeout requires seconds}"; shift 2 ;;
      --timeout=*)     ENG_TIMEOUT="${1#--timeout=}"; shift ;;
      *) printf 'ERROR: unknown engine argument %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [ "$ENG_MODE" = "run" ]; then
    [ -n "$ENG_PROMPT" ] && [ -f "$ENG_PROMPT" ] || {
      printf 'ERROR: --prompt-file is required and must exist\n' >&2; exit 2; }
    [ -d "$ENG_WORKDIR" ] || { printf 'ERROR: --workdir does not exist\n' >&2; exit 2; }
  fi
}

# Report a timeout the same way for every engine so the kernel needs no special
# cases, and so a hang is never mistaken for a clean empty attempt.
eng_finish() {
  _rc="$1"
  if [ "$_rc" -eq 124 ]; then
    printf '\n[engine timed out after %ss — the attempt was killed]\n' "$ENG_TIMEOUT"
    return 124
  fi
  return "$_rc"
}
