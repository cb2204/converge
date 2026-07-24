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
#
# YAML scalars may be quoted (`title: "Capture steel thread …"`). Quotes are
# DELIMITERS, not content, so tsi_field strips a matched surrounding pair — else
# they ship straight onto the tracker and the board shows a title wrapped in
# literal quote marks (exactly what the first live Linear registration produced).

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
  # The trailing `|| true` is load-bearing: an ABSENT field is not an error (see
  # the contract above), but `grep -m1` exits 1 when it matches nothing, and under
  # the callers' `set -e -o pipefail` a bare `x="$(tsi_field …)"` assignment would
  # propagate that and kill the run. Optional fields are the common case.
  tsi_frontmatter "$file" \
    | grep -m1 "^${name}:" \
    | sed -E "s/^${name}:[[:space:]]*//" \
    | sed -E 's/[[:space:]]*$//' \
    | sed -E -e 's/^"(.*)"$/\1/' -e "s/^'(.*)'$/\1/" \
    | tr -d '\r' || true
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

# ----- Section + behavior accessors (for the rich issue body) -----------------
# tsi_section FILE HEADING — the lines under `## HEADING` up to the next `## `.
tsi_section() {
  awk -v h="$2" '
    $0 ~ "^##[[:space:]]+" h { f=1; next }
    f && /^## / { exit }
    f { print }
  ' "$1"
}

# tsi_behaviors FILE — one `- **B-N** — text` per line, wrapped lines re-joined.
# Specs wrap long Given/When/Then prose across lines; a naive grep would truncate
# each scenario mid-sentence on the board.
tsi_behaviors() {
  awk '
    /^##[[:space:]]+Behavior/ { inb=1; next }
    inb && /^## / { if (buf != "") print buf; buf=""; exit }
    inb {
      if ($0 ~ /^[[:space:]]*-[[:space:]]*\*\*B-[0-9]+\*\*/) {
        if (buf != "") print buf
        buf = $0; next
      }
      if ($0 ~ /^[[:space:]]*$/) { if (buf != "") { print buf; buf="" } next }
      if (buf != "") { line=$0; sub(/^[[:space:]]+/, "", line); buf = buf " " line }
    }
    END { if (buf != "") print buf }
  ' "$1"
}

# tsi_paths FILE — the write surface: touches_paths ∪ creates_paths, de-duped,
# with the `(none)` sentinel and empty inline lists dropped.
tsi_paths() {
  printf '%s\n%s\n' "$(tsi_field "$1" touches_paths)" "$(tsi_field "$1" creates_paths)" \
    | sed -E 's/^\[//; s/\]$//' \
    | tr ',' '\n' \
    | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^$' | grep -vxF '(none)' | sort -u || true
}

# ----- The issue body renderer (tracker-agnostic Markdown) --------------------
# tsi_issue_body FILE ["dep-id dep-id ..."]
#
# Renders the spec as a well-shaped issue description. Markdown only, so every
# backend benefits; Linear converts pasted Markdown to rich text and renders a
# ```mermaid block as a real diagram (linear.app/docs/editor), which is why the
# dependency graph is emitted that way.
#
# Design rules learned from the first live registration:
#   - NEVER repeat the title as an H1 — the tracker already shows it.
#   - Omit empty sections entirely rather than printing `touches_paths: []`.
#   - Lead with the goal and the done-condition; those are what a picker-upper needs.
tsi_issue_body() {
  local f="$1" deps="${2:-}"
  # The dep list is split by an unquoted `for d in $deps`, so pin IFS to the
  # default rather than trust whatever a caller left in the environment.
  # (NB: this file is bash — sourcing it into zsh will NOT word-split, since zsh
  # needs SH_WORD_SPLIT. Preview it with `bash -c`, or every dep collapses into
  # one mermaid node and you'll chase a bug that isn't there.)
  local IFS=$' \t\n'
  local id eff prof backend sev prio goal paths beh dnt exitck n
  id="$(tsi_id "$f")"
  eff="$(tsi_field "$f" effort)"
  prof="$(tsi_field "$f" profile)"
  backend="$(tsi_field "$f" execution_backend)"
  sev="$(tsi_severity "$f")"
  prio="$(tsi_priority "$f")"
  goal="$(tsi_goal "$f")"

  # --- Summary (blockquote) ---
  if [ -n "$goal" ]; then
    printf '> %s\n\n' "$(printf '%s' "$goal" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g')"
  fi

  # --- At-a-glance table ---
  printf '| | |\n|---|---|\n'
  printf '| **Spec** | `%s` |\n' "$id"
  [ -n "$eff" ]     && printf '| **Size** | `%s` |\n' "$eff"
  [ -n "$prof" ]    && printf '| **Profile** | `%s` |\n' "$prof"
  [ -n "$backend" ] && printf '| **Executor** | `%s` |\n' "$backend"
  [ -n "$sev" ] && [ "$sev" != "(none)" ]   && printf '| **Severity** | `%s` |\n' "$sev"
  [ -n "$prio" ] && [ "$prio" != "(none)" ] && printf '| **Priority** | `%s` |\n' "$prio"
  printf '\n'

  # --- Definition of done (the contract) ---
  exitck="$(tsi_exit_check "$f")"
  if [ -n "$exitck" ]; then
    printf '### Definition of done\n\n'
    printf 'Only a **GREEN eval** moves this issue to Done — nothing else.\n\n'
    printf '```bash\n%s\n```\n\n' "$exitck"
  fi

  # --- Behaviors as a checklist ---
  beh="$(tsi_behaviors "$f")"
  if [ -n "$beh" ]; then
    printf '### Behavior — what gets verified\n\n'
    printf '%s\n' "$beh" | sed -E 's/^[[:space:]]*-[[:space:]]*/- [ ] /'
    printf '\n'
  fi

  # --- Write surface ---
  paths="$(tsi_paths "$f")"
  printf '### Write surface\n\n'
  if [ -n "$paths" ]; then
    printf '%s\n' "$paths" | sed -E 's/^/- `/; s/$/`/'
  else
    printf '_None declared — verification-only, or the surface lives in the spec._\n'
  fi
  printf '\n'

  # --- Dependencies (Linear renders mermaid) ---
  printf '### Dependencies\n\n'
  if [ -n "$deps" ]; then
    printf '```mermaid\ngraph LR\n'
    n=0
    for d in $deps; do
      n=$((n + 1))
      printf '  d%s["%s"] --> me["%s"]\n' "$n" "$d" "$id"
    done
    printf '  style me fill:#5e6ad2,stroke:#5e6ad2,color:#fff\n'
    printf '```\n\n'
    printf 'Blocked by: '
    for d in $deps; do printf '`%s` ' "$d"; done
    printf '\n\n'
  else
    printf '**None** — this is a root. It is takeable as soon as it is picked up.\n\n'
  fi

  # --- Guardrails ---
  dnt="$(tsi_section "$f" "Do-Not-Touch" | grep -v '^[[:space:]]*$' || true)"
  if [ -n "$dnt" ]; then
    printf '### Guardrails — do not touch\n\n'
    printf '%s\n\n' "$dnt"
  fi

  # --- Provenance footer ---
  # TSI_SPEC_BASE_URL (e.g. https://github.com/<org>/<repo>/blob/main) turns the
  # spec path into a REAL clickable link. The idempotency marker attachment is a
  # synthetic key by design and deliberately does NOT navigate anywhere — this is
  # the link a human actually wants.
  printf -- '---\n\n'
  if [ -n "${TSI_SPEC_BASE_URL:-}" ]; then
    printf 'Projected from [`%s`](%s/%s) by `cvg register` (REGISTER ①).\n' "$f" "${TSI_SPEC_BASE_URL%/}" "$f"
  else
    printf 'Projected from `%s` by `cvg register` (REGISTER ①).\n' "$f"
  fi
  printf '**The spec is the source of truth** — edits here are overwritten on the next\n'
  printf 'register; only a green eval closes this issue.\n'
}

# ----- Write-back: stamp the tracker_ref RECEIPT into a spec's frontmatter -----
# tsi_set_tracker_ref FILE VALUE
#
# Idempotently set `tracker_ref: VALUE` inside FILE's frontmatter (the region
# between the first two `---` lines) and NOWHERE else. This is the ONLY write
# this skill ever makes to a spec: a convenience BACKLINK (a receipt) to the
# tracker issue, stamped after a successful upsert.
#
# It is NOT the idempotency key — the marker carried ON the issue is (see
# references/idempotency-keys.md). It never touches the spec BODY, so a
# signed-off spec stays sealed: the sign-off HMAC covers `id + body_digest +
# the signed_off* values` (task-spec _lib.sh ts_signoff_payload), and
# body_digest is the sha256 of everything AFTER the closing `---`. A frontmatter
# receipt is outside that boundary by design, so the MAC still verifies.
#
# Resolution order (first match wins):
#   1) an existing `tracker_ref:` line in the frontmatter -> replace its value
#   2) else a deprecated `linear_ref:` line present        -> insert after it
#   3) else                                                -> append before `---`
#
# bash-3.2-safe: awk over a temp file, atomic mv. Returns 1 on a missing file, an
# empty/multi-line value, or a frontmatter with no closing '---' (never clobbers).
tsi_set_tracker_ref() {
  local file="$1" value="$2"
  [[ -f "$file" ]]  || { echo "tsi_set_tracker_ref: '$file' not found" >&2; return 1; }
  [[ -n "$value" ]] || { echo "tsi_set_tracker_ref: empty value" >&2; return 1; }
  case "$value" in
    *[$'\n\r']*) echo "tsi_set_tracker_ref: value must be single-line (got newline/CR)" >&2; return 1 ;;
  esac

  local has_tr=0 has_lr=0
  if tsi_frontmatter "$file" | grep -q '^tracker_ref:'; then has_tr=1; fi
  if tsi_frontmatter "$file" | grep -q '^linear_ref:';  then has_lr=1; fi

  local tmp="${file}.tmp.$$"
  awk -v val="$value" -v has_tr="$has_tr" -v has_lr="$has_lr" '
    BEGIN { fm=0; done=0 }
    /^---[[:space:]]*$/ {
      fm++
      if (fm==2 && !done) { print "tracker_ref: " val; done=1 }
      print; next
    }
    (fm==1 && !done && has_tr+0>0 && /^tracker_ref:/)                { print "tracker_ref: " val; done=1; next }
    (fm==1 && !done && has_tr+0==0 && has_lr+0>0 && /^linear_ref:/)  { print; print "tracker_ref: " val; done=1; next }
    { print }
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }

  # Conservative guard: the write only "took" if tmp now carries a tracker_ref
  # line (replace or insert). If the frontmatter had no closing '---', the awk
  # appended nothing — refuse rather than move a no-op/garbled file.
  if ! grep -q '^tracker_ref:' "$tmp"; then
    rm -f "$tmp"
    echo "tsi_set_tracker_ref: no frontmatter closing '---' in $file; not written" >&2
    return 1
  fi
  mv "$tmp" "$file"
}
