#!/bin/bash
# test-cvg-json-envelope.sh — the agent-native output layer (cvg 0.9.0, 2026 SOTA):
# the uniform --json response envelope {ok,data,error,meta,…} on every command, and
# --dry-run on mutations. Proves, discriminating:
#   · the envelope carries every SOTA key + a versioned meta
#   · pass / fail / usage-error map to ok + exit_code + error correctly
#   · the underlying exit code is PRESERVED through the envelope
#   · --json is position-independent and leaves the DEFAULT path byte-parity-exact
#   · --dry-run on a mutation changes nothing (changed=false / dry_run=true)
#   · agent-context stays raw JSON (not double-enveloped)
# bash 3.2-safe. Python is stdlib-only. Uses the analytics proving ground as terrain.
# shellcheck disable=SC2015  # file-wide, intentional: `A && B || bad` — ok()/bad() ARE the branches (ok always returns 0)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CVG="$ROOT/bin/cvg"
PG="$ROOT/tests/uc-analytics/cvg"
BAD="$ROOT/skills/reqs-to-swimlane-plans/tests/fixtures/no-thread"
T=0; F=0
ok()  { T=$((T + 1)); printf 'ok    %s\n' "$1"; }
bad() { T=$((T + 1)); F=$((F + 1)); printf 'FAIL  %-34s %s\n' "$1" "$2"; }

# run cvg from the proving ground with CVG_HOME resolved; stdout only
jrun() { ( cd "$PG" && CVG_HOME="$ROOT" "$CVG" "$@" ) 2>/dev/null; }
# extract a python expression over the parsed envelope `d`
jget() { python3 -c "import json,sys
d=json.load(sys.stdin)
v=($1)
print('' if v is None else v)"; }

echo "== cvg --json envelope + --dry-run (agent-native SOTA) =="

# --- envelope shape ---
O="$(jrun --json capture)"
if printf '%s' "$O" | python3 -c "import json,sys
d=json.load(sys.stdin)
need=['ok','command','converge_pass','token','verdict','exit_code','changed','dry_run','data','error','warnings','meta']
assert all(k in d for k in need), [k for k in need if k not in d]
assert set(['ok','data','error','meta']).issubset(d)
assert d['meta']['schema_version']=='1.0' and d['meta']['tool']=='cvg' and d['meta']['cvg_version']
" 2>/dev/null; then ok "envelope shape + meta{schema_version,version}"; else bad "envelope shape" "missing keys/meta"; fi

# --- pass ---
O="$(jrun --json capture)"
[ "$(printf '%s' "$O" | jget "d['ok']")" = "True" ] \
  && [ "$(printf '%s' "$O" | jget "d['token']")" = "CHECK_BRD=PASS" ] \
  && [ "$(printf '%s' "$O" | jget "d['verdict']")" = "PASS" ] \
  && [ "$(printf '%s' "$O" | jget "d['exit_code']")" = "0" ] \
  && [ "$(printf '%s' "$O" | jget "d['changed']")" = "False" ] \
  && [ "$(printf '%s' "$O" | jget "d['error']")" = "" ] \
  && ok "pass: ok/token/verdict/exit0/changed=false/error=null" || bad "pass envelope" "field mismatch"

# --- fail (a discriminating no-thread swimlane fixture) ---
O="$(jrun --json decompose --dir "$BAD")"
[ "$(printf '%s' "$O" | jget "d['ok']")" = "False" ] \
  && [ "$(printf '%s' "$O" | jget "d['exit_code']")" = "1" ] \
  && [ "$(printf '%s' "$O" | jget "d['token']")" = "CHECK_PLAN=FAIL" ] \
  && [ "$(printf '%s' "$O" | jget "d['error']['code']")" = "FAIL" ] \
  && ok "fail: ok=false/exit1/token=FAIL/error.code" || bad "fail envelope" "field mismatch"

# --- usage error ---
O="$(jrun --json capture --bogus)"
[ "$(printf '%s' "$O" | jget "d['ok']")" = "False" ] \
  && [ "$(printf '%s' "$O" | jget "d['exit_code']")" = "2" ] \
  && [ "$(printf '%s' "$O" | jget "d['error']['code']")" = "USAGE_ERROR" ] \
  && ok "usage: ok=false/exit2/error.code=USAGE_ERROR" || bad "usage envelope" "field mismatch"

# --- exit code PRESERVED through the envelope (agents branch on it) ---
( cd "$PG" && CVG_HOME="$ROOT" "$CVG" --json capture --bogus ) >/dev/null 2>&1; RC=$?
[ "$RC" -eq 2 ] && ok "exit code preserved (--json → 2)" || bad "exit-code preserved" "got $RC want 2"

# --- position independence: --json before OR after the command ---
A="$(jrun --json capture | jget "d['token']")"
B="$(jrun capture --json | jget "d['token']")"
[ "$A" = "$B" ] && [ "$A" = "CHECK_BRD=PASS" ] && ok "--json position-independent" || bad "--json position" "before=$A after=$B"

# --- default path is byte-parity-exact (adding --json never changed default output) ---
DA="$( ( cd "$PG" && CVG_HOME="$ROOT" "$CVG" capture ) 2>&1 )"
DB="$( ( cd "$PG" && bash "$ROOT/skills/idea-to-brd/scripts/check-brd.sh" docs/brd-analytical-backbone.md ) 2>&1 )"
[ "$DA" = "$DB" ] && ok "default byte-parity held (gate untouched)" || bad "default byte-parity" "diverged"
# default emits NO json (first char is not '{')
FC="$( ( cd "$PG" && CVG_HOME="$ROOT" "$CVG" capture ) 2>/dev/null | head -c1 )"
[ "$FC" != "{" ] && ok "default output is plain (not JSON)" || bad "default plain" "emitted JSON by default"

# --- --dry-run on a mutation changes nothing ---
O="$(jrun --json --dry-run transition T-nope "done")"
[ "$(printf '%s' "$O" | jget "d['dry_run']")" = "True" ] \
  && [ "$(printf '%s' "$O" | jget "d['changed']")" = "False" ] \
  && [ "$(printf '%s' "$O" | jget "d['command']")" = "transition" ] \
  && ok "--dry-run(json) mutation: dry_run=true/changed=false" || bad "dry-run json" "field mismatch"
DR="$( ( cd "$PG" && CVG_HOME="$ROOT" "$CVG" --dry-run transition T-nope "done" ) 2>/dev/null )"
printf '%s' "$DR" | grep -q '^DRY_RUN=OK$' && ok "--dry-run(text) mutation → DRY_RUN=OK" || bad "dry-run text" "no DRY_RUN token"

# --- read-only command with --dry-run is a no-op (still runs, changed=false) ---
O="$(jrun --json --dry-run capture)"
[ "$(printf '%s' "$O" | jget "d['changed']")" = "False" ] \
  && [ "$(printf '%s' "$O" | jget "d['token']")" = "CHECK_BRD=PASS" ] \
  && ok "--dry-run read-only: runs, changed=false" || bad "dry-run read-only" "field mismatch"

# --- agent-context stays raw JSON under --json (not double-enveloped) ---
jrun --json agent-context | python3 -c "import json,sys
d=json.load(sys.stdin)
assert d.get('tool')=='cvg' and 'commands' in d and 'ok' not in d" 2>/dev/null \
  && ok "agent-context raw JSON (not enveloped)" || bad "agent-context under --json" "double-enveloped"

echo
if [ "$F" -eq 0 ]; then echo "PASS — all $T rows green."; exit 0
else echo "FAIL — $F of $T rows red." >&2; exit 1; fi
