#!/usr/bin/env bash
# adapters/fake.sh — an on-disk, NO-NETWORK tracker for tests + the reference impl.
#
# Implements the same five-verb contract as github.sh / linear.sh / jira.sh (see
# references/adapter-contract.md) against a local store under $TSI_FAKE_STORE, so
# register.sh's FULL live path — preflight, idempotent upsert, blocked-by link,
# list-ready, write-result — is exercised offline, deterministically, with no
# creds and no network. It is the smallest complete adapter: read it to learn the
# contract before writing a real one.
#
# NOT for production. register.sh / verify-registration.sh accept `--tracker fake`
# ONLY so the orchestration itself is testable; a real board is github|linear|jira.
#
# Store layout ($TSI_FAKE_STORE, default ./.tsi-fake-store):
#   issues.tsv   num \t extid \t title \t state(open|done)
#   links.tsv    from_extid \t to_extid          (from is blocked-by to)
#   counter      next issue number
#   bodies/<n>.md
#
# Deterministic ids: FAKE-1, FAKE-2, … in creation order. Idempotency key: the
# spec id, stored as the issue's extid (column 2) — the same "look up by id,
# update else create" rule every adapter upholds.
#
# Test hooks: TSI_FAKE_FAIL_PREFLIGHT=1 forces preflight to fail (to exercise the
# fail-closed path in register.sh).

set -euo pipefail

STORE="${TSI_FAKE_STORE:-./.tsi-fake-store}"
ISSUES="$STORE/issues.tsv"
LINKS="$STORE/links.tsv"
COUNTER="$STORE/counter"

tsi_fake_die() { echo "ERROR (fake adapter): $*" >&2; exit 1; }

_fake_init() {
  mkdir -p "$STORE/bodies"
  [[ -f "$ISSUES" ]]  || : > "$ISSUES"
  [[ -f "$LINKS" ]]   || : > "$LINKS"
  [[ -f "$COUNTER" ]] || echo 0 > "$COUNTER"
}

# extid -> "num<TAB>state" on stdout (empty if not found).
_fake_find() {
  awk -F'\t' -v e="$1" '$2==e{print $1"\t"$4; exit}' "$ISSUES"
}

# ---------------------------------------------------------------------------
# VERB: preflight — always reachable (no creds). Honors the test fail hook.
# ---------------------------------------------------------------------------
fake_preflight() {
  _fake_init
  if [[ "${TSI_FAKE_FAIL_PREFLIGHT:-0}" == "1" ]]; then
    echo "preflight failed: TSI_FAKE_FAIL_PREFLIGHT=1 (test hook)" >&2
    echo "remediation: unset TSI_FAKE_FAIL_PREFLIGHT" >&2
    return 1
  fi
  echo "preflight ok: fake tracker at $STORE"
  return 0
}

# ---------------------------------------------------------------------------
# VERB: upsert --id ID --title T --body-file F [--label L ...]
# ---------------------------------------------------------------------------
# Find-by-extid then update, else create. Echoes the issue ref (FAKE-N) on
# stdout; the created/updated note goes to stderr (register.sh greps it).
fake_upsert() {
  _fake_init
  local id="" title="" body_file="" labels="" prio=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)        id="$2"; shift 2 ;;
      --title)     title="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --label)     labels="${labels}${labels:+ }$2"; shift 2 ;;
      --priority)  prio="$2"; shift 2 ;;
      *) tsi_fake_die "upsert: unknown arg '$1'" ;;
    esac
  done
  # Record the triage the driver passed so tests can assert the wiring offline.
  mkdir -p "$STORE/meta"
  printf 'labels=%s\npriority=%s\n' "$labels" "$prio" > "$STORE/meta/$id.txt"
  [[ -n "$id" ]]    || tsi_fake_die "upsert: --id required"
  [[ -n "$title" ]] || tsi_fake_die "upsert: --title required"

  local found num
  found="$(_fake_find "$id")"
  if [[ -n "$found" ]]; then
    num="$(printf '%s' "$found" | cut -f1)"
    local tmp="$ISSUES.tmp.$$"
    awk -F'\t' -v e="$id" -v t="$title" 'BEGIN{OFS="\t"} $2==e{$3=t} {print}' "$ISSUES" > "$tmp" && mv "$tmp" "$ISSUES"
    [[ -n "$body_file" && -f "$body_file" ]] && cp "$body_file" "$STORE/bodies/${num#FAKE-}.md"
    echo "updated $num ($id)" >&2
    echo "$num"
  else
    local n
    n="$(( $(cat "$COUNTER") + 1 ))"
    echo "$n" > "$COUNTER"
    num="FAKE-$n"
    printf '%s\t%s\t%s\t%s\n' "$num" "$id" "$title" "open" >> "$ISSUES"
    [[ -n "$body_file" && -f "$body_file" ]] && cp "$body_file" "$STORE/bodies/$n.md"
    echo "created $num ($id)" >&2
    echo "$num"
  fi
}

# ---------------------------------------------------------------------------
# VERB: link --from ID --to ID  (FROM is blocked-by TO). Idempotent (dedupes).
# ---------------------------------------------------------------------------
fake_link() {
  _fake_init
  local from_id="" to_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_id="$2"; shift 2 ;;
      --to)   to_id="$2"; shift 2 ;;
      *) tsi_fake_die "link: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$from_id" && -n "$to_id" ]] || tsi_fake_die "link: --from and --to required"
  [[ -n "$(_fake_find "$from_id")" ]] || tsi_fake_die "link: from-issue not found for $from_id"
  [[ -n "$(_fake_find "$to_id")" ]]   || tsi_fake_die "blocked-by target not found for $to_id"
  if ! awk -F'\t' -v a="$from_id" -v b="$to_id" '$1==a&&$2==b{f=1} END{exit f?0:1}' "$LINKS"; then
    printf '%s\t%s\n' "$from_id" "$to_id" >> "$LINKS"
  fi
  echo "linked: $from_id blocked-by $to_id" >&2
}

# ---------------------------------------------------------------------------
# VERB: list-ready — open issues with no OPEN blocker. Echoes refs, one per line.
# ---------------------------------------------------------------------------
fake_list_ready() {
  _fake_init
  local num ext title state dep dstate blocked
  while IFS=$'\t' read -r num ext title state; do
    [[ -n "$num" ]] || continue
    [[ "$state" == "open" ]] || continue
    blocked=0
    for dep in $(awk -F'\t' -v e="$ext" '$1==e{print $2}' "$LINKS"); do
      dstate="$(awk -F'\t' -v e="$dep" '$2==e{print $4; exit}' "$ISSUES")"
      if [[ "$dstate" == "open" ]]; then blocked=1; break; fi
    done
    [[ "$blocked" -eq 0 ]] && echo "$num"
  done < "$ISSUES"
  # Contract: list-ready exits 0 on success even if the last issue was blocked
  # (a trailing false `[[ ]] && echo` would otherwise leave a non-zero status,
  # and a caller that does `list-ready > f || : > f` would discard the output).
  return 0
}

# ---------------------------------------------------------------------------
# VERB: write-result --issue REF --status pass|fail [--pr URL] [--reason TEXT]
# ---------------------------------------------------------------------------
# The LOOP's write side (Pass 8), not registration. On pass, marks the issue done.
fake_write_result() {
  _fake_init
  local issue="" status="" pr="" reason=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)  issue="$2"; shift 2 ;;
      --status) status="$2"; shift 2 ;;
      --pr)     pr="$2"; shift 2 ;;
      --reason) reason="$2"; shift 2 ;;
      *) tsi_fake_die "write-result: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$issue" ]] || tsi_fake_die "write-result: --issue required"
  case "$status" in pass|fail) ;; *) tsi_fake_die "write-result: --status must be pass|fail" ;; esac

  # Accept a raw ref (FAKE-N) or a spec extid.
  local num
  if awk -F'\t' -v e="$issue" '$1==e{f=1} END{exit f?0:1}' "$ISSUES"; then
    num="$issue"
  else
    num="$(_fake_find "$issue" | cut -f1)"
  fi
  [[ -n "$num" ]] || tsi_fake_die "write-result: issue not found: $issue"

  if [[ "$status" == "pass" ]]; then
    local tmp="$ISSUES.tmp.$$"
    awk -F'\t' -v n="$num" 'BEGIN{OFS="\t"} $1==n{$4="done"} {print}' "$ISSUES" > "$tmp" && mv "$tmp" "$ISSUES"
    echo "completed $num (pass)${pr:+ PR: $pr}"
  else
    echo "commented $num (fail)${reason:+ reason: $reason}"
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
_fake_main() {
  local verb="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$verb" in
    preflight)    fake_preflight "$@" ;;
    upsert)       fake_upsert "$@" ;;
    link)         fake_link "$@" ;;
    list-ready)   fake_list_ready "$@" ;;
    write-result) fake_write_result "$@" ;;
    ""|-h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
      ;;
    *) tsi_fake_die "unknown verb '$verb' (want: preflight|upsert|link|list-ready|write-result)" ;;
  esac
}

_fake_main "$@"
