#!/usr/bin/env bash
# adapters/linear.sh — Linear backend for task-specs-to-issues (DEFAULT tracker).
#
# Same five-verb contract as adapters/github.sh (see references/adapter-contract.md):
#   preflight | upsert | link | list-ready | write-result
#
# Talks to the Linear GraphQL API at https://api.linear.app/graphql with two env
# vars:
#   LINEAR_API_KEY   — a personal API key (lin_api_...). Sent as the raw
#                      Authorization header value (Linear's scheme, NOT Bearer).
#   LINEAR_TEAM_ID   — the team the issues live under: a team KEY (e.g. CVG,
#                      straight from the Linear URL .../team/CVG/...) OR the UUID.
#                      A key is resolved to its UUID automatically.
#
# Idempotency key: the spec id is stored as the issue's `externalId` (a
# first-class Linear field designed for exactly this — see
# references/idempotency-keys.md). Upsert looks the issue up by externalId first.
#
# Dependency edges use Linear's native `issueRelation` of type `blocks`: the
# dependency issue `blocks` the dependent issue, which Linear surfaces as
# "blocked by" on the dependent side — a faithful mirror of `depends_on`.
#
# Every GraphQL call is isolated in a clearly-marked `_linear_gql*` function so
# the network surface is auditable in one place. This adapter TALKS TO THE
# NETWORK; register.sh --dry-run never invokes it.

set -euo pipefail

LINEAR_API_URL="${LINEAR_API_URL:-https://api.linear.app/graphql}"

tsi_ln_die() { echo "ERROR (linear adapter): $*" >&2; exit 1; }

_ln_require_tools() {
  command -v curl >/dev/null 2>&1 || tsi_ln_die "curl not found on PATH"
  command -v jq >/dev/null 2>&1 || tsi_ln_die "jq not found on PATH"
}

# ===========================================================================
# GraphQL transport — the ONLY functions that touch the network.
# ===========================================================================
# _linear_gql QUERY VARIABLES_JSON
#   POSTs a GraphQL request. QUERY is the query/mutation string; VARIABLES_JSON
#   is a JSON object (default {}). Echoes the raw response JSON. Fails hard on a
#   transport error or a GraphQL `errors` array.
_linear_gql() {
  local query="$1"
  # NB: do NOT write `${2:-{}}` — bash closes the expansion at the FIRST `}`, so an
  # explicit `{}` comes back as `{}}` (invalid JSON -> jq fails -> empty POST body).
  # That trap silently broke every Linear call until it was caught against the live API.
  local variables="${2:-}"
  [ -n "$variables" ] || variables='{}'
  [[ -n "${LINEAR_API_KEY:-}" ]] || tsi_ln_die "LINEAR_API_KEY unset"
  local payload resp
  payload="$(jq -n --arg q "$query" --argjson v "$variables" '{query:$q, variables:$v}')"
  resp="$(curl -sS -X POST "$LINEAR_API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: ${LINEAR_API_KEY}" \
    --data "$payload")" || tsi_ln_die "GraphQL transport error"
  if printf '%s' "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    echo "$resp" | jq -r '.errors[]?.message' >&2
    tsi_ln_die "GraphQL returned errors"
  fi
  printf '%s' "$resp"
}

# ---------------------------------------------------------------------------
# Team resolution — accept a team KEY (e.g. CVG, straight from the Linear URL)
# OR a UUID. Issue mutations need the team's UUID, but humans have the key, so we
# resolve key -> UUID transparently. cvg exports an already-resolved UUID (looked
# up once during setup), so this only hits the network on the standalone path.
# ---------------------------------------------------------------------------
_ln_is_uuid() {
  printf '%s' "$1" | grep -qiE '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
}

# Echo the team UUID for $LINEAR_TEAM_ID (a UUID passes through; a key is looked
# up via teams(filter:{key:{eq}})). Empty if unset or unresolvable.
_ln_resolve_team_id() {
  local tid="${LINEAR_TEAM_ID:-}"
  [[ -n "$tid" ]] || { printf ''; return 0; }
  if _ln_is_uuid "$tid"; then printf '%s' "$tid"; return 0; fi
  local resp
  resp="$(_linear_gql 'query($k:String!){ teams(filter:{ key:{ eq:$k } }){ nodes{ id key name } } }' \
    "$(jq -n --arg k "$tid" '{k:$k}')")" || { printf ''; return 1; }
  printf '%s' "$resp" | jq -r '.data.teams.nodes[0].id // empty'
}

# ---------------------------------------------------------------------------
# VERB: teams — list every team as  key<TAB>name<TAB>uuid  (the setup picker).
# ---------------------------------------------------------------------------
ln_teams() {
  _ln_require_tools
  [[ -n "${LINEAR_API_KEY:-}" ]] || tsi_ln_die "LINEAR_API_KEY unset"
  local resp
  resp="$(_linear_gql 'query{ teams{ nodes{ key name id } } }' '{}')"
  printf '%s' "$resp" | jq -r '.data.teams.nodes[]? | "\(.key)\t\(.name)\t\(.id)"'
}

# ---------------------------------------------------------------------------
# VERB: preflight — key present AND the team resolves (a live auth check).
# ---------------------------------------------------------------------------
ln_preflight() {
  _ln_require_tools
  if [[ -z "${LINEAR_API_KEY:-}" ]]; then
    echo "preflight failed: LINEAR_API_KEY unset" >&2
    echo "remediation: export LINEAR_API_KEY=lin_api_... (and LINEAR_TEAM_ID), then re-run" >&2
    return 1
  fi
  if [[ -z "${LINEAR_TEAM_ID:-}" ]]; then
    echo "preflight failed: LINEAR_TEAM_ID unset" >&2
    echo "remediation: export LINEAR_TEAM_ID=<team-uuid>, then re-run" >&2
    return 1
  fi
  local resp name
  resp="$(_linear_gql 'query($id:String!){ team(id:$id){ id name } }' \
    "$(jq -n --arg id "$LINEAR_TEAM_ID" '{id:$id}')")" || return 1
  name="$(printf '%s' "$resp" | jq -r '.data.team.name // empty')"
  [[ -n "$name" ]] || { echo "preflight failed: team $LINEAR_TEAM_ID not found" >&2; return 1; }
  echo "preflight ok: linear team '$name'"
  return 0
}

# ---------------------------------------------------------------------------
# Internal: resolve a spec id -> Linear issue node id via externalId.
# Echoes the issue id (empty if not found).
# ---------------------------------------------------------------------------
_ln_find_by_external_id() {
  local ext="$1" resp
  resp="$(_linear_gql \
    'query($ext:String!,$team:ID!){ issues(filter:{ externalId:{ eq:$ext }, team:{ id:{ eq:$team } } }){ nodes{ id identifier } } }' \
    "$(jq -n --arg ext "$ext" --arg team "$LINEAR_TEAM_ID" '{ext:$ext, team:$team}')")"
  printf '%s' "$resp" | jq -r '.data.issues.nodes[0].id // empty'
}

# ---------------------------------------------------------------------------
# VERB: upsert --id ID --title T --body-file F [--label L ...]
# ---------------------------------------------------------------------------
# Find-by-externalId then update, else create. Echoes the issue node id.
ln_upsert() {
  _ln_require_tools
  [[ -n "${LINEAR_TEAM_ID:-}" ]] || tsi_ln_die "LINEAR_TEAM_ID unset"
  local id="" title="" body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)        id="$2"; shift 2 ;;
      --title)     title="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --label)     shift 2 ;;  # labels map to Linear labelIds; omitted in this core path
      *) tsi_ln_die "upsert: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$id" ]]        || tsi_ln_die "upsert: --id required"
  [[ -n "$title" ]]     || tsi_ln_die "upsert: --title required"
  [[ -f "$body_file" ]] || tsi_ln_die "upsert: --body-file '$body_file' not readable"

  local body existing
  body="$(cat "$body_file")"
  existing="$(_ln_find_by_external_id "$id" || true)"

  # stdout returns the HUMAN identifier (e.g. ENG-42) when available so the
  # register report and the tracker_ref receipt read cleanly (`linear:ENG-42`),
  # falling back to the node id. Link resolution never depends on this value — it
  # re-resolves by externalId — so returning the identifier is safe.
  if [[ -n "$existing" ]]; then
    local uresp ident
    uresp="$(_linear_gql \
      'mutation($id:String!,$title:String!,$desc:String!){ issueUpdate(id:$id, input:{ title:$title, description:$desc }){ success issue{ id identifier } } }' \
      "$(jq -n --arg id "$existing" --arg title "$title" --arg desc "$body" '{id:$id,title:$title,desc:$desc}')")"
    ident="$(printf '%s' "$uresp" | jq -r '.data.issueUpdate.issue.identifier // empty')"
    ident="${ident:-$existing}"
    echo "updated $ident ($id)" >&2
    echo "$ident"
  else
    local resp new
    resp="$(_linear_gql \
      'mutation($team:String!,$ext:String!,$title:String!,$desc:String!){ issueCreate(input:{ teamId:$team, externalId:$ext, title:$title, description:$desc }){ success issue{ id identifier } } }' \
      "$(jq -n --arg team "$LINEAR_TEAM_ID" --arg ext "$id" --arg title "$title" --arg desc "$body" \
        '{team:$team,ext:$ext,title:$title,desc:$desc}')")"
    new="$(printf '%s' "$resp" | jq -r '.data.issueCreate.issue.identifier // .data.issueCreate.issue.id')"
    echo "created $new ($id)" >&2
    echo "$new"
  fi
}

# ---------------------------------------------------------------------------
# VERB: link --from ID --to ID
# ---------------------------------------------------------------------------
# depends_on(FROM -> TO) becomes: TO `blocks` FROM (Linear surfaces this as FROM
# "blocked by" TO). Idempotent because Linear dedupes identical relations.
ln_link() {
  _ln_require_tools
  local from_id="" to_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_id="$2"; shift 2 ;;
      --to)   to_id="$2"; shift 2 ;;
      *) tsi_ln_die "link: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$from_id" && -n "$to_id" ]] || tsi_ln_die "link: --from and --to required"

  local from to
  from="$(_ln_find_by_external_id "$from_id" || true)"
  to="$(_ln_find_by_external_id "$to_id" || true)"
  [[ -n "$from" ]] || tsi_ln_die "link: from-issue not found for $from_id"
  [[ -n "$to" ]]   || tsi_ln_die "blocked-by target not found for $to_id"

  # issueId=$to blocks relatedIssueId=$from  →  $from is "blocked by" $to.
  _linear_gql \
    'mutation($issue:String!,$related:String!){ issueRelationCreate(input:{ issueId:$issue, relatedIssueId:$related, type:blocks }){ success } }' \
    "$(jq -n --arg issue "$to" --arg related "$from" '{issue:$issue,related:$related}')" >/dev/null
  echo "linked: $from_id blocked-by $to_id" >&2
}

# ---------------------------------------------------------------------------
# VERB: list-ready — issues with no OPEN `blocks` relation pointing at them.
# ---------------------------------------------------------------------------
# Pulls the team's registered issues with their inverse relations; an issue is
# ready when none of the issues that block it is still incomplete. Echoes
# identifiers (e.g. ENG-42), one per line.
ln_list_ready() {
  _ln_require_tools
  [[ -n "${LINEAR_TEAM_ID:-}" ]] || tsi_ln_die "LINEAR_TEAM_ID unset"
  local resp
  resp="$(_linear_gql \
    'query($team:ID!){ issues(filter:{ team:{ id:{ eq:$team } }, externalId:{ null:false } }){ nodes{ identifier externalId state{ type } inverseRelations{ nodes{ type issue{ state{ type } } } } } } }' \
    "$(jq -n --arg team "$LINEAR_TEAM_ID" '{team:$team}')")"
  # ready = not completed/canceled AND no incoming `blocks` from an unfinished issue.
  printf '%s' "$resp" | jq -r '
    .data.issues.nodes[]
    | select(.state.type != "completed" and .state.type != "canceled")
    | select(
        [ .inverseRelations.nodes[]?
          | select(.type == "blocks")
          | .issue.state.type
          | select(. != "completed" and . != "canceled")
        ] | length == 0
      )
    | .identifier'
}

# ---------------------------------------------------------------------------
# VERB: write-result --issue ID --status pass|fail [--pr URL] [--reason TEXT]
# ---------------------------------------------------------------------------
# The LOOP's write side (Pass 8), not registration. Comments on the issue; on a
# pass, moves it to the team's first `completed`-type state.
ln_write_result() {
  _ln_require_tools
  local issue="" status="" pr="" reason=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)  issue="$2"; shift 2 ;;
      --status) status="$2"; shift 2 ;;
      --pr)     pr="$2"; shift 2 ;;
      --reason) reason="$2"; shift 2 ;;
      *) tsi_ln_die "write-result: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$issue" ]] || tsi_ln_die "write-result: --issue required"
  case "$status" in pass|fail) ;; *) tsi_ln_die "write-result: --status must be pass|fail" ;; esac

  local node
  node="$(_ln_find_by_external_id "$issue" || true)"
  [[ -n "$node" ]] || node="$issue"  # accept a raw node id too

  local comment
  if [[ "$status" == "pass" ]]; then
    comment="eval GREEN — done.${pr:+ PR: $pr}"
  else
    comment="eval RED — parked.${reason:+ reason: $reason}"
  fi
  _linear_gql \
    'mutation($id:String!,$body:String!){ commentCreate(input:{ issueId:$id, body:$body }){ success } }' \
    "$(jq -n --arg id "$node" --arg body "$comment" '{id:$id,body:$body}')" >/dev/null

  if [[ "$status" == "pass" ]]; then
    local st
    st="$(_linear_gql \
      'query($team:ID!){ team(id:$team){ states(filter:{ type:{ eq:"completed" } }){ nodes{ id } } } }' \
      "$(jq -n --arg team "$LINEAR_TEAM_ID" '{team:$team}')" \
      | jq -r '.data.team.states.nodes[0].id // empty')"
    if [[ -n "$st" ]]; then
      _linear_gql \
        'mutation($id:String!,$state:String!){ issueUpdate(id:$id, input:{ stateId:$state }){ success } }' \
        "$(jq -n --arg id "$node" --arg state "$st" '{id:$id,state:$state}')" >/dev/null
    fi
    echo "completed $issue (pass)"
  else
    echo "commented $issue (fail)"
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
_ln_main() {
  local verb="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  # Resolve a team KEY (e.g. CVG) to its UUID for the verbs that need a team, so a
  # human can pass the key straight from the Linear URL. A UUID passes through.
  case "$verb" in
    preflight|upsert|link|list-ready|write-result)
      if [[ -n "${LINEAR_TEAM_ID:-}" ]] && ! _ln_is_uuid "$LINEAR_TEAM_ID"; then
        local _r; _r="$(_ln_resolve_team_id 2>/dev/null || true)"
        [[ -n "$_r" ]] && LINEAR_TEAM_ID="$_r"
      fi
      ;;
  esac
  case "$verb" in
    preflight)    ln_preflight "$@" ;;
    upsert)       ln_upsert "$@" ;;
    link)         ln_link "$@" ;;
    list-ready)   ln_list_ready "$@" ;;
    write-result) ln_write_result "$@" ;;
    teams)        ln_teams "$@" ;;
    resolve-team) _ln_resolve_team_id ;;
    ""|-h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
      ;;
    *) tsi_ln_die "unknown verb '$verb' (want: preflight|upsert|link|list-ready|write-result|teams|resolve-team)" ;;
  esac
}

_ln_main "$@"
