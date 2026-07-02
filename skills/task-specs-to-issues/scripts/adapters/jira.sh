#!/usr/bin/env bash
# adapters/jira.sh — Jira backend for task-specs-to-issues.  *** PARTIAL STUB ***
#
# STATUS: PARTIAL. preflight is live; upsert/link/list-ready/write-result carry
# the REAL Jira Cloud REST v3 request shapes (curl bodies) but are gated behind
# an explicit TSI_JIRA_ENABLE=1 so a half-finished adapter can never silently
# half-register a board. This file documents the exact endpoints and payloads a
# maintainer completes to promote it to first-class — the same five-verb
# contract as github.sh / linear.sh (see references/adapter-contract.md).
#
# Auth (Jira Cloud): HTTP Basic with `email:api_token`, base64-encoded.
#   JIRA_BASE_URL    — e.g. https://your-org.atlassian.net
#   JIRA_EMAIL       — the account email
#   JIRA_API_TOKEN   — an Atlassian API token
#   JIRA_PROJECT_KEY — the project the issues live under, e.g. ENG
#
# Idempotency key: the spec id in a `task-spec:<id>` LABEL plus a summary tag
# `[task-spec:<id>]`, looked up first with JQL (see references/idempotency-keys.md).
#
# Dependency edges use Jira issue links of type "Blocks": the dependency issue
# "blocks" the dependent, which Jira surfaces as "is blocked by" on the dependent.

set -euo pipefail

JIRA_LABEL_PREFIX="${JIRA_LABEL_PREFIX:-task-spec}"

tsi_jira_die() { echo "ERROR (jira adapter): $*" >&2; exit 1; }

_jira_require_tools() {
  command -v curl >/dev/null 2>&1 || tsi_jira_die "curl not found on PATH"
  command -v jq >/dev/null 2>&1 || tsi_jira_die "jq not found on PATH"
}

_jira_auth_header() {
  [[ -n "${JIRA_EMAIL:-}" && -n "${JIRA_API_TOKEN:-}" ]] \
    || tsi_jira_die "JIRA_EMAIL / JIRA_API_TOKEN unset"
  printf 'Authorization: Basic %s' \
    "$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64 | tr -d '\n')"
}

# Guard: refuse any WRITE verb unless the maintainer has explicitly promoted the
# adapter. Keeps "partial" honest — the shapes are here to read, not to fire.
_jira_require_enabled() {
  if [[ "${TSI_JIRA_ENABLE:-0}" != "1" ]]; then
    echo "jira adapter is PARTIAL: set TSI_JIRA_ENABLE=1 to run write verbs" >&2
    echo "review the REST shapes in this file and complete/validate before enabling" >&2
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# VERB: preflight — LIVE. Confirm creds resolve against /myself.
# ---------------------------------------------------------------------------
jira_preflight() {
  _jira_require_tools
  for v in JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN JIRA_PROJECT_KEY; do
    if [[ -z "${!v:-}" ]]; then
      echo "preflight failed: $v unset" >&2
      echo "remediation: export JIRA_BASE_URL / JIRA_EMAIL / JIRA_API_TOKEN / JIRA_PROJECT_KEY, then re-run" >&2
      return 1
    fi
  done
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "$(_jira_auth_header)" -H "Accept: application/json" \
    "${JIRA_BASE_URL%/}/rest/api/3/myself")" || { echo "preflight failed: transport error" >&2; return 1; }
  if [[ "$code" != "200" ]]; then
    echo "preflight failed: /myself -> HTTP $code (check email/token)" >&2
    return 1
  fi
  echo "preflight ok: jira ${JIRA_BASE_URL} project ${JIRA_PROJECT_KEY}"
  return 0
}

# ---------------------------------------------------------------------------
# VERB: upsert --id ID --title T --body-file F [--label L ...]   (PARTIAL)
# ---------------------------------------------------------------------------
# Find-by-JQL on the task-spec label, then update, else create. Echoes the Jira
# issue key (e.g. ENG-42).
jira_upsert() {
  _jira_require_tools; _jira_require_enabled
  local id="" title="" body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) id="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --label) shift 2 ;;
      *) tsi_jira_die "upsert: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$id" && -n "$title" && -f "$body_file" ]] || tsi_jira_die "upsert: --id --title --body-file required"

  local label="${JIRA_LABEL_PREFIX}:${id}" body existing
  body="$(cat "$body_file")"

  # 1) FIND: JQL search on the idempotency label.
  #    GET /rest/api/3/search?jql=project=KEY AND labels="task-spec:<id>"
  existing="$(curl -sS -G "${JIRA_BASE_URL%/}/rest/api/3/search" \
    -H "$(_jira_auth_header)" -H "Accept: application/json" \
    --data-urlencode "jql=project=${JIRA_PROJECT_KEY} AND labels=\"${label}\"" \
    --data-urlencode "fields=key" \
    | jq -r '.issues[0].key // empty')"

  if [[ -n "$existing" ]]; then
    # 2a) UPDATE: PUT /rest/api/3/issue/<key>
    curl -sS -X PUT "${JIRA_BASE_URL%/}/rest/api/3/issue/${existing}" \
      -H "$(_jira_auth_header)" -H "Content-Type: application/json" \
      --data "$(jq -n --arg title "$title" --arg body "$body" '
        { fields: {
            summary: $title,
            description: { type:"doc", version:1,
              content:[ { type:"paragraph", content:[ { type:"text", text:$body } ] } ] }
        } }')" >/dev/null
    echo "updated $existing ($id)" >&2
    echo "$existing"
  else
    # 2b) CREATE: POST /rest/api/3/issue
    local key
    key="$(curl -sS -X POST "${JIRA_BASE_URL%/}/rest/api/3/issue" \
      -H "$(_jira_auth_header)" -H "Content-Type: application/json" \
      --data "$(jq -n --arg proj "$JIRA_PROJECT_KEY" --arg title "[task-spec:${id}] ${title}" \
                     --arg body "$body" --arg label "$label" '
        { fields: {
            project: { key: $proj },
            issuetype: { name: "Task" },
            summary: $title,
            labels: [ $label ],
            description: { type:"doc", version:1,
              content:[ { type:"paragraph", content:[ { type:"text", text:$body } ] } ] }
        } }')" \
      | jq -r '.key')"
    echo "created $key ($id)" >&2
    echo "$key"
  fi
}

# ---------------------------------------------------------------------------
# VERB: link --from ID --to ID   (PARTIAL)
# ---------------------------------------------------------------------------
# depends_on(FROM -> TO) becomes a "Blocks" link: TO blocks FROM (Jira shows
# FROM "is blocked by" TO).  POST /rest/api/3/issueLink
jira_link() {
  _jira_require_tools; _jira_require_enabled
  local from_id="" to_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_id="$2"; shift 2 ;;
      --to) to_id="$2"; shift 2 ;;
      *) tsi_jira_die "link: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$from_id" && -n "$to_id" ]] || tsi_jira_die "link: --from and --to required"

  local from_key to_key
  from_key="$(_jira_find_key "$from_id")"; [[ -n "$from_key" ]] || tsi_jira_die "link: from-issue not found for $from_id"
  to_key="$(_jira_find_key "$to_id")";     [[ -n "$to_key" ]]   || tsi_jira_die "blocked-by target not found for $to_id"

  curl -sS -X POST "${JIRA_BASE_URL%/}/rest/api/3/issueLink" \
    -H "$(_jira_auth_header)" -H "Content-Type: application/json" \
    --data "$(jq -n --arg out "$to_key" --arg in "$from_key" '
      { type: { name: "Blocks" },
        outwardIssue: { key: $out },
        inwardIssue:  { key: $in } }')" >/dev/null
  echo "linked: $from_id blocked-by $to_id" >&2
}

# Helper: resolve a spec id -> Jira key via the idempotency label.
_jira_find_key() {
  local id="$1" label="${JIRA_LABEL_PREFIX}:$1"
  curl -sS -G "${JIRA_BASE_URL%/}/rest/api/3/search" \
    -H "$(_jira_auth_header)" -H "Accept: application/json" \
    --data-urlencode "jql=project=${JIRA_PROJECT_KEY} AND labels=\"${label}\"" \
    --data-urlencode "fields=key" \
    | jq -r '.issues[0].key // empty'
}

# ---------------------------------------------------------------------------
# VERB: list-ready   (PARTIAL)
# ---------------------------------------------------------------------------
# Ready = registered, not Done, and no unresolved "is blocked by" link. JQL can
# express most of this; the blocker-resolution check is done client-side over the
# `issuelinks` field. Echoes issue keys, one per line.
jira_list_ready() {
  _jira_require_tools; _jira_require_enabled
  curl -sS -G "${JIRA_BASE_URL%/}/rest/api/3/search" \
    -H "$(_jira_auth_header)" -H "Accept: application/json" \
    --data-urlencode "jql=project=${JIRA_PROJECT_KEY} AND labels IN (${JIRA_LABEL_PREFIX}) AND statusCategory != Done" \
    --data-urlencode "fields=key,issuelinks" \
    | jq -r '
      .issues[]
      | select(
          [ .fields.issuelinks[]?
            | select(.type.inward == "is blocked by")
            | .inwardIssue.fields.status.statusCategory.key
            | select(. != "done")
          ] | length == 0
        )
      | .key'
}

# ---------------------------------------------------------------------------
# VERB: write-result --issue KEY --status pass|fail [--pr URL] [--reason TEXT]  (PARTIAL)
# ---------------------------------------------------------------------------
# The LOOP's write side. Adds a comment; on pass, transitions to Done. The
# transition id is project-specific — resolve via GET /issue/<key>/transitions.
jira_write_result() {
  _jira_require_tools; _jira_require_enabled
  local issue="" status="" pr="" reason=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue) issue="$2"; shift 2 ;;
      --status) status="$2"; shift 2 ;;
      --pr) pr="$2"; shift 2 ;;
      --reason) reason="$2"; shift 2 ;;
      *) tsi_jira_die "write-result: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$issue" ]] || tsi_jira_die "write-result: --issue required"
  case "$status" in pass|fail) ;; *) tsi_jira_die "write-result: --status must be pass|fail" ;; esac

  local comment
  if [[ "$status" == "pass" ]]; then comment="eval GREEN — done.${pr:+ PR: $pr}"; else comment="eval RED — parked.${reason:+ reason: $reason}"; fi
  # POST /rest/api/3/issue/<key>/comment
  curl -sS -X POST "${JIRA_BASE_URL%/}/rest/api/3/issue/${issue}/comment" \
    -H "$(_jira_auth_header)" -H "Content-Type: application/json" \
    --data "$(jq -n --arg body "$comment" '
      { body: { type:"doc", version:1,
        content:[ { type:"paragraph", content:[ { type:"text", text:$body } ] } ] } }')" >/dev/null

  if [[ "$status" == "pass" ]]; then
    # POST /rest/api/3/issue/<key>/transitions  (transition id resolved above)
    echo "TODO: resolve + POST the Done transition for $issue (project-specific id)" >&2
    echo "done $issue (pass)"
  else
    echo "commented $issue (fail)"
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
_jira_main() {
  local verb="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$verb" in
    preflight)    jira_preflight "$@" ;;
    upsert)       jira_upsert "$@" ;;
    link)         jira_link "$@" ;;
    list-ready)   jira_list_ready "$@" ;;
    write-result) jira_write_result "$@" ;;
    ""|-h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
      ;;
    *) tsi_jira_die "unknown verb '$verb' (want: preflight|upsert|link|list-ready|write-result)" ;;
  esac
}

_jira_main "$@"
