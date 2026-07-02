#!/usr/bin/env bash
# adapters/github.sh — GitHub Issues backend for task-specs-to-issues.
#
# The tracker is a pluggable backend behind ONE five-verb contract (see
# references/adapter-contract.md). This adapter is pure `gh` + `jq`: no GitHub
# library, no REST curl — `gh` already carries auth and the repo context.
#
# Verbs (dispatched from the first positional arg):
#   preflight                       — assert `gh auth status` succeeds (exit 0/1)
#   upsert   --id ID --title T --body-file F [--label L ...]
#                                   — find-by-marker-else-create; echoes the
#                                     issue number on stdout. Idempotent.
#   link     --from ID --to ID      — set `blocked-by`: a task-list checkbox on
#                                     the FROM issue that references the TO issue
#   list-ready                      — issue numbers with NO open blocked-by
#   write-result --issue N --status pass|fail [--pr URL] [--reason TEXT]
#                                   — the LOOP's write side (Pass 8), not used at
#                                     registration; comments + labels the issue
#
# Idempotency key: an HTML marker `<!-- task-spec: ID -->` embedded in the issue
# body, plus a `task-spec` label. Lookup greps the marker so a re-run updates in
# place instead of creating a duplicate. See references/idempotency-keys.md.
#
# This adapter TALKS TO THE NETWORK. register.sh --dry-run never invokes it;
# the driver prints what it WOULD call instead. Every verb here assumes a live,
# authenticated `gh`.

set -euo pipefail

# The marker label every registered issue carries (also used as the list filter).
TSI_GH_LABEL="${TSI_GH_LABEL:-task-spec}"

tsi_gh_die() { echo "ERROR (github adapter): $*" >&2; exit 1; }

# Marker string embedded in an issue body to carry the spec id (the ident key).
_gh_marker() { printf '<!-- task-spec: %s -->' "$1"; }

# Require the tools this adapter is built on.
_gh_require_tools() {
  command -v gh >/dev/null 2>&1 || tsi_gh_die "gh CLI not found on PATH"
  command -v jq >/dev/null 2>&1 || tsi_gh_die "jq not found on PATH"
}

# ---------------------------------------------------------------------------
# VERB: preflight
# ---------------------------------------------------------------------------
# Confirm the backend is reachable BEFORE any write, so we never half-register.
gh_preflight() {
  _gh_require_tools
  if ! gh auth status >/dev/null 2>&1; then
    echo "preflight failed: gh not authenticated" >&2
    echo "remediation: run 'gh auth login' (or export GH_TOKEN=...), then re-run" >&2
    return 1
  fi
  echo "preflight ok: gh authenticated"
  return 0
}

# ---------------------------------------------------------------------------
# Internal: find the issue number carrying a given spec id's marker.
# Echoes the number, or nothing if not found. Searches OPEN and CLOSED so a
# closed (done) issue is still updated in place rather than re-created.
# ---------------------------------------------------------------------------
_gh_find_by_id() {
  local id="$1" marker
  marker="$(_gh_marker "$id")"
  gh issue list \
    --label "$TSI_GH_LABEL" \
    --state all \
    --search "$marker in:body" \
    --json number,body \
    --limit 200 \
    | jq -r --arg m "$marker" '.[] | select(.body | contains($m)) | .number' \
    | head -1
}

# ---------------------------------------------------------------------------
# VERB: upsert --id ID --title T --body-file F [--label L ...]
# ---------------------------------------------------------------------------
# Look up by the id marker first; UPDATE if found, CREATE if not. Guarantees the
# marker + the task-spec label are present so the next lookup matches. Echoes the
# resulting issue number.
gh_upsert() {
  _gh_require_tools
  local id="" title="" body_file="" labels="$TSI_GH_LABEL"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)        id="$2"; shift 2 ;;
      --title)     title="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --label)     labels="${labels},$2"; shift 2 ;;
      *) tsi_gh_die "upsert: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$id" ]]        || tsi_gh_die "upsert: --id required"
  [[ -n "$title" ]]     || tsi_gh_die "upsert: --title required"
  [[ -f "$body_file" ]] || tsi_gh_die "upsert: --body-file '$body_file' not readable"

  # Ensure the marker is in the body so future lookups match even if the caller
  # forgot it. Append it once (it is an HTML comment — invisible in rendered MD).
  local marker body_tmp
  marker="$(_gh_marker "$id")"
  body_tmp="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/tsi-gh-body.$$")"
  cat "$body_file" > "$body_tmp"
  if ! grep -qF "$marker" "$body_tmp"; then
    printf '\n\n%s\n' "$marker" >> "$body_tmp"
  fi

  # Make sure the marker label exists (idempotent; ignore "already exists").
  gh label create "$TSI_GH_LABEL" --color ededed --description "Registered task-spec" >/dev/null 2>&1 || true

  local existing
  existing="$(_gh_find_by_id "$id" || true)"
  local number
  if [[ -n "$existing" ]]; then
    gh issue edit "$existing" \
      --title "$title" \
      --body-file "$body_tmp" >/dev/null
    # Ensure labels are attached (idempotent).
    local L; IFS=',' read -r -a _labels <<< "$labels" 2>/dev/null || _labels=("$TSI_GH_LABEL")
    for L in "${_labels[@]}"; do
      [[ -n "$L" ]] && gh issue edit "$existing" --add-label "$L" >/dev/null 2>&1 || true
    done
    number="$existing"
    echo "updated #$number ($id)" >&2
  else
    number="$(gh issue create \
      --title "$title" \
      --body-file "$body_tmp" \
      --label "$labels" \
      | grep -oE '[0-9]+$' | head -1)"
    echo "created #$number ($id)" >&2
  fi
  rm -f "$body_tmp" 2>/dev/null || true
  echo "$number"
}

# ---------------------------------------------------------------------------
# VERB: link --from ID --to ID
# ---------------------------------------------------------------------------
# Encode a `depends_on` edge as `blocked-by`. GitHub has no native blocked-by
# API, so the convention (readable, greppable, and honored by list-ready below)
# is a task-list line in a `### Blocked by` section of the FROM issue body that
# references the TO issue by number: `- [ ] blocked by #<to> (task-spec: <toId>)`.
# Idempotent: the line is only appended if absent.
gh_link() {
  _gh_require_tools
  local from_id="" to_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_id="$2"; shift 2 ;;
      --to)   to_id="$2"; shift 2 ;;
      *) tsi_gh_die "link: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$from_id" && -n "$to_id" ]] || tsi_gh_die "link: --from and --to required"

  local from_num to_num
  from_num="$(_gh_find_by_id "$from_id" || true)"
  to_num="$(_gh_find_by_id "$to_id" || true)"
  [[ -n "$from_num" ]] || tsi_gh_die "link: from-issue not found for $from_id"
  [[ -n "$to_num" ]]   || tsi_gh_die "blocked-by target not found for $to_id"

  local body line
  body="$(gh issue view "$from_num" --json body -q .body)"
  line="- [ ] blocked by #${to_num} (task-spec: ${to_id})"
  if printf '%s' "$body" | grep -qF "blocked by #${to_num} "; then
    echo "link exists: #$from_num blocked-by #$to_num" >&2
    return 0
  fi
  if ! printf '%s' "$body" | grep -qF "### Blocked by"; then
    body="${body}"$'\n\n### Blocked by\n'
  fi
  body="${body}"$'\n'"${line}"
  printf '%s' "$body" | gh issue edit "$from_num" --body-file - >/dev/null
  echo "linked: #$from_num blocked-by #$to_num" >&2
}

# ---------------------------------------------------------------------------
# VERB: list-ready
# ---------------------------------------------------------------------------
# The loop's READ side: issues with NO OPEN blocker. An issue is "ready" when it
# is open, carries the task-spec label, and has no `blocked by #N` line whose
# target issue N is still open. Echoes ready issue numbers, one per line.
gh_list_ready() {
  _gh_require_tools
  # Build a set of open issue numbers (the ones a blocker could still point at).
  local open_json
  open_json="$(gh issue list --label "$TSI_GH_LABEL" --state open --json number,body --limit 200)"

  # For each open issue, extract its blocker targets and check if any is open.
  printf '%s' "$open_json" | jq -r '.[].number' | while read -r n; do
    [[ -n "$n" ]] || continue
    local nbody blockers blocked
    nbody="$(printf '%s' "$open_json" | jq -r --argjson n "$n" '.[] | select(.number==$n) | .body')"
    blockers="$(printf '%s' "$nbody" | grep -oE 'blocked by #[0-9]+' | grep -oE '[0-9]+' || true)"
    blocked=0
    if [[ -n "$blockers" ]]; then
      local b
      for b in $blockers; do
        # If blocker b is still in the OPEN set, this issue is blocked.
        if printf '%s' "$open_json" | jq -e --argjson b "$b" 'any(.[]; .number==$b)' >/dev/null; then
          blocked=1
          break
        fi
      done
    fi
    [[ "$blocked" -eq 0 ]] && echo "$n"
  done
}

# ---------------------------------------------------------------------------
# VERB: write-result --issue N --status pass|fail [--pr URL] [--reason TEXT]
# ---------------------------------------------------------------------------
# The LOOP writes this (Pass 8), NOT registration. A green eval closes the issue
# with a linked PR; a red eval leaves it open with a failure comment. Included
# here so the adapter's five-verb surface is complete and the loop can reuse it.
gh_write_result() {
  _gh_require_tools
  local issue="" status="" pr="" reason=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)  issue="$2"; shift 2 ;;
      --status) status="$2"; shift 2 ;;
      --pr)     pr="$2"; shift 2 ;;
      --reason) reason="$2"; shift 2 ;;
      *) tsi_gh_die "write-result: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$issue" ]] || tsi_gh_die "write-result: --issue required"
  case "$status" in
    pass|fail) ;;
    *) tsi_gh_die "write-result: --status must be pass|fail" ;;
  esac

  if [[ "$status" == "pass" ]]; then
    gh issue comment "$issue" --body "eval GREEN — closing.${pr:+ PR: $pr}" >/dev/null
    gh issue close "$issue" >/dev/null
    echo "closed #$issue (pass)"
  else
    gh issue comment "$issue" --body "eval RED — parked.${reason:+ reason: $reason}" >/dev/null
    echo "commented #$issue (fail)"
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
_gh_main() {
  local verb="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$verb" in
    preflight)    gh_preflight "$@" ;;
    upsert)       gh_upsert "$@" ;;
    link)         gh_link "$@" ;;
    list-ready)   gh_list_ready "$@" ;;
    write-result) gh_write_result "$@" ;;
    ""|-h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
      ;;
    *) tsi_gh_die "unknown verb '$verb' (want: preflight|upsert|link|list-ready|write-result)" ;;
  esac
}

_gh_main "$@"
