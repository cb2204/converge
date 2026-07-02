#!/usr/bin/env bash
# _parse.sh — shared frontmatter parser for the task-specs-to-issues skill.
#
# Bash-3.2-safe (macOS system /bin/bash 3.2.57): NO mapfile, NO `declare -A`,
# NO process-substitution-into-arrays. Only grep/sed/awk over the file, exactly
# like the task-spec skill's list-ready.sh / transition-status.sh. The whole
# point of this file is that register.sh and verify-registration.sh read a spec
# the SAME way, so the board can never disagree with the parser.
#
# Source this from a top-level script:
#   _PARSE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_parse.sh"
#   source "$_PARSE"
#
# Field accessors (each takes a spec file path, echoes ONE line, never fails
# the caller — an absent field echoes empty):
#   tsi_field       FILE NAME   — first `NAME:` value inside the frontmatter block
#   tsi_id          FILE        — spec id (the idempotency key)
#   tsi_title       FILE        — spec title (may contain spaces / unicode)
#   tsi_status      FILE        — status (ready|in-progress|blocked|done|parked)
#   tsi_signed_off  FILE        — signed_off value, normalized to true|false
#   tsi_severity    FILE        — severity label
#   tsi_priority    FILE        — priority label
#   tsi_effort      FILE        — effort label
#   tsi_depends_on  FILE        — SPACE-separated dependency ids (inline YAML list
#                                 `[a, b]` flattened; empty list -> empty string)
#   tsi_goal        FILE        — first paragraph under the `## Goal` heading
#   tsi_exit_check  FILE        — body of the ```bash block under `## Exit Check`
#
# Only the frontmatter (region between the first two `---` lines) is consulted
# for fields; a body line that happens to start with `name:` is never matched.

# ----- Error helper (mirrors task-spec's ts_die) -----
tsi_die() {
  echo "ERROR: $*" >&2
  exit 1
}

# ----- Configurable backlog dir (parity with task-spec's TASKSPEC_BACKLOG_DIR) -----
: "${TSI_TASKS_DIR:=tasks}"
export TSI_TASKS_DIR

# ----- Emit ONLY the frontmatter block (between the first two `---` lines) -----
# Line 1 must be `---`; the block ends at the next `---`. Nothing else is echoed.
tsi_frontmatter() {
  awk '
    BEGIN { c = 0 }
    /^---[[:space:]]*$/ { c++; if (c == 2) exit; next }
    c == 1 { print }
  ' "$1"
}

# ----- Generic field accessor -----
# Echoes the first `NAME:` value found in the frontmatter, trimmed of the
# leading key, surrounding whitespace, and a trailing CR (CRLF-safe). NAME is
# script-controlled (never user input), so a fixed-string grep anchor is safe.
tsi_field() {
  local file="$1" name="$2"
  tsi_frontmatter "$file" \
    | grep -m1 "^${name}:" \
    | sed -E "s/^${name}:[[:space:]]*//" \
    | sed -E 's/[[:space:]]*$//' \
    | tr -d '\r'
}

tsi_id()       { tsi_field "$1" id; }
tsi_title()    { tsi_field "$1" title; }
tsi_status()   { tsi_field "$1" status; }
tsi_severity() { tsi_field "$1" severity; }
tsi_priority() { tsi_field "$1" priority; }
tsi_effort()   { tsi_field "$1" effort; }

# ----- signed_off, normalized -----
# The gate is strict: register ONLY on the literal `true`. Anything else
# (false, (none), empty, a typo) normalizes to `false` so an un-gated spec can
# never leak onto the board through a loose truthiness test.
tsi_signed_off() {
  local v
  v="$(tsi_field "$1" signed_off | tr '[:upper:]' '[:lower:]')"
  if [[ "$v" == "true" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# ----- depends_on inline-list flattener -----
# Frontmatter carries `depends_on: [T-a, T-b]` (or `[]`). Flatten to a
# space-separated id list: strip the brackets, split on commas, trim each id.
# An empty list echoes nothing. bash-3.2-safe: pure sed/tr, no arrays.
tsi_depends_on() {
  local raw
  raw="$(tsi_field "$1" depends_on)"
  # Drop the surrounding [ ] (if present), turn commas into spaces, squeeze WS.
  echo "$raw" \
    | sed -E 's/^\[//; s/\]$//' \
    | tr ',' ' ' \
    | tr -s '[:space:]' ' ' \
    | sed -E 's/^ //; s/ $//'
}

# ----- Goal paragraph (issue body helper) -----
# The first non-empty paragraph after the `## Goal` heading — the human-readable
# summary the board shows. Stops at the next blank line or the next heading.
tsi_goal() {
  awk '
    BEGIN { seen = 0; started = 0 }
    /^##[[:space:]]+Goal[[:space:]]*$/ { seen = 1; next }
    seen == 1 {
      if ($0 ~ /^#/) { exit }
      if ($0 ~ /^[[:space:]]*$/) { if (started) exit; else next }
      started = 1
      print
    }
  ' "$1"
}

# ----- Exit Check block (the eval that travels onto the board) -----
# Extract the contents of the ```bash fenced block under `## Exit Check` — the
# runnable close condition the SKILL.md says must be copied VERBATIM into the
# issue body. Returns the code inside the fence (no fence lines).
tsi_exit_check() {
  awk '
    BEGIN { inx = 0; infence = 0 }
    /^##[[:space:]]+Exit Check[[:space:]]*$/ { inx = 1; next }
    inx == 1 && /^```/ {
      if (infence == 0) { infence = 1; next } else { exit }
    }
    inx == 1 && infence == 1 { print }
  ' "$1"
}

# ----- Enumerate spec files in a tasks dir (bash-3.2-safe, no globstar) -----
# Echoes one file path per line for every top-level `T-*.md`. Used by callers
# with a `while read` loop instead of an array so bash 3.2 is happy.
tsi_list_specs() {
  local dir="$1" f
  for f in "$dir"/T-*.md; do
    [[ -f "$f" ]] || continue
    echo "$f"
  done
}
