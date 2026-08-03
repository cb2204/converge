#!/usr/bin/env bash
# next-pass.sh — the conductor's derivation engine.
#
# Derives the descent's position from workspace EVIDENCE (files in cvg/),
# never from stored state: every pass leaves its artifact in a known folder,
# so "where are we" is always readable from the floor. Three verbs:
#
#   next [--lane FULL|NORMAL|FAST]   evidence board + NEXT_PASS=<N|DONE>
#   pre  <N> [--lane ...]            fail-closed door: PASS_PRE=OK|MISSING
#   post <N>                         artifact check:   PASS_POST=OK|INCOMPLETE
#
# THE ONE RULE: evidence presence is not a verdict. This script sequences;
# the cvg gates decide. It refuses forward motion, it never grants a PASS.
# Read-only by design — it must never mutate the workspace it reads.
#
# Pass 6 (Register) is opt-in: reported, never blocking.
# Tokens: NEXT_PASS= · PASS_PRE= · PASS_POST= · NEXT_PASS=USAGE_ERROR
# bash 3.2 safe. Deps: find, grep.

set -euo pipefail

usage() {
  cat <<'EOF'
usage: next-pass.sh next [--lane FULL|NORMAL|FAST]
       next-pass.sh pre  <pass-number> [--lane FULL|NORMAL|FAST]
       next-pass.sh post <pass-number>
EOF
}

# --- workspace resolution ----------------------------------------------------
# Explicit CVG_PROJECT_ROOT wins; otherwise walk up from PWD to the nearest
# directory carrying the .cvg control plane (same rule the cvg router uses).
resolve_ws() {
  if [ -n "${CVG_PROJECT_ROOT:-}" ] && [ -d "$CVG_PROJECT_ROOT/cvg" ]; then
    printf '%s\n' "$CVG_PROJECT_ROOT"
    return 0
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.cvg" ] && [ -d "$dir/cvg" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "no Converge workspace found walking up from '$PWD' — run cvg init first" >&2
  return 1
}

# --- the pass map ------------------------------------------------------------
pass_name() {
  case "$1" in
    0) printf 'Capture' ;;    1) printf 'Intent' ;;
    2) printf 'Structure' ;;  3) printf 'Decompose' ;;
    4) printf 'Consensus' ;;  5) printf 'Tasking' ;;
    6) printf 'Register' ;;   7) printf 'Bind' ;;
    8) printf 'Loop' ;;       *) return 1 ;;
  esac
}

prompt_file() {
  case "$1" in
    0) printf 'pass-0-capture.md' ;;   1) printf 'pass-1-intent.md' ;;
    2) printf 'pass-2-structure.md' ;; 3) printf 'pass-3-decompose.md' ;;
    4) printf 'pass-4-consensus.md' ;; 5) printf 'pass-5-tasking.md' ;;
    6) printf 'pass-6-register.md' ;;  7) printf 'pass-7-bind.md' ;;
    8) printf 'pass-8-loop.md' ;;      *) return 1 ;;
  esac
}

gate_cmd() {
  case "$1" in
    0) printf 'cvg capture' ;;
    1) printf 'cvg intent' ;;
    2) printf 'cvg structure' ;;
    3) printf 'cvg decompose' ;;
    4) printf 'cvg review --check' ;;
    5) printf 'cvg tasks gate --stamp <spec>' ;;
    6) printf 'cvg register --check' ;;
    7) printf 'cvg bind --check --task <spec>' ;;
    8) printf 'cvg tasks accept <spec>' ;;
    *) return 1 ;;
  esac
}

lane_order() {
  case "$1" in
    FULL)   printf '0 1 2 3 4 5 7 8' ;;
    NORMAL) printf '1 2 5 7 8' ;;
    FAST)   printf '5 7 8' ;;
    *) return 1 ;;
  esac
}

# --- evidence probes (presence only — instant, no gate execution) ------------
has_pass() {
  local n="$1"
  case "$n" in
    # Typed folder (canonical) OR the legacy flat prefix — a workspace created
    # before the layout change must still read as complete.
    0) [ -n "$(find "$WS/cvg/docs/brd" -maxdepth 1 -name '*.md' -print 2>/dev/null | head -1)" ] \
       || [ -n "$(find "$WS/cvg/docs" -maxdepth 1 -name 'brd-*.md' -print 2>/dev/null | head -1)" ] ;;
    1) [ -n "$(find "$WS/cvg/docs/tech-spec" -maxdepth 1 -name '*.md' -print 2>/dev/null | head -1)" ] \
       || [ -n "$(find "$WS/cvg/docs" -maxdepth 1 -name 'tech-spec-*.md' -print 2>/dev/null | head -1)" ] ;;
    2) [ -n "$(find "$WS/cvg/docs/adrs" -maxdepth 1 -name '*.md' -print 2>/dev/null | head -1)" ] ;;
    3) [ -n "$(find "$WS/cvg/sketch" -path '*swimlane-*' -type f -print 2>/dev/null | head -1)" ] ;;
    4) [ -f "$WS/cvg/sketch/.consensus/objection-log.json" ] ;;
    5) find "$WS/cvg/tasks" -name 'T-*.md' -print 2>/dev/null \
         | while IFS= read -r f; do
             grep -q '^signed_off: true' "$f" && echo hit && break
           done | grep -q hit ;;
    6) find "$WS/cvg/tasks" -name 'T-*.md' -print 2>/dev/null \
         | while IFS= read -r f; do
             grep -q '^tracker_ref:' "$f" && echo hit && break
           done | grep -q hit ;;
    7) [ -n "$(find "$WS/cvg/execution" -type f ! -name '.gitkeep' -print 2>/dev/null | head -1)" ] ;;
    8) [ -n "$(find "$WS/cvg/receipts" -type f ! -name 'README.md' -print 2>/dev/null | head -1)" ] ;;
    *) return 1 ;;
  esac
}

mark() { if has_pass "$1"; then printf '+'; else printf '.'; fi; }

# --- argument parsing --------------------------------------------------------
CMD="${1:-}"
[ $# -gt 0 ] && shift
LANE="FULL"
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lane)   [ $# -ge 2 ] || { usage >&2; printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2; }
              LANE="$2"; shift 2 ;;
    --lane=*) LANE="${1#--lane=}"; shift ;;
    [0-8])    TARGET="$1"; shift ;;
    *) usage >&2; printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2 ;;
  esac
done
ORDER="$(lane_order "$LANE" 2>/dev/null)" \
  || { echo "unknown lane '$LANE' — FULL, NORMAL, or FAST" >&2; printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2; }

WS="$(resolve_ws)" || { printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2; }

case "$CMD" in
  next)
    echo "conductor — descent position (lane $LANE) at $WS"
    NEXT=""
    for p in $ORDER; do
      printf '  [%s] pass %s · %s\n' "$(mark "$p")" "$p" "$(pass_name "$p")"
      if [ -z "$NEXT" ] && ! has_pass "$p"; then NEXT="$p"; fi
    done
    if has_pass 6; then echo '  [+] pass 6 · Register (opt-in, never blocks)'; fi
    if [ -z "$NEXT" ]; then
      echo 'every pass in the lane has evidence on the floor'
      printf 'NEXT_PASS=DONE\n'
    else
      echo "next: pass $NEXT · $(pass_name "$NEXT")"
      echo "  steer with : cvg/brain/_prompts/$(prompt_file "$NEXT")"
      echo "  close with : $(gate_cmd "$NEXT")"
      printf 'NEXT_PASS=%s\n' "$NEXT"
    fi
    ;;
  pre)
    [ -n "$TARGET" ] || { usage >&2; printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2; }
    MISSING=""
    for p in $ORDER; do
      [ "$p" = "$TARGET" ] && break
      has_pass "$p" || MISSING="${MISSING}${MISSING:+ }$p"
    done
    if [ -n "$MISSING" ]; then
      echo "pass $TARGET ($(pass_name "$TARGET")) may not start — missing evidence from:"
      for p in $MISSING; do
        echo "  pass $p · $(pass_name "$p") — steer with cvg/brain/_prompts/$(prompt_file "$p")"
      done
      printf 'PASS_PRE=MISSING\n'
      exit 1
    fi
    echo "pass $TARGET ($(pass_name "$TARGET")) may start — every prior lane pass left its evidence"
    printf 'PASS_PRE=OK\n'
    ;;
  post)
    [ -n "$TARGET" ] || { usage >&2; printf 'NEXT_PASS=USAGE_ERROR\n'; exit 2; }
    if has_pass "$TARGET"; then
      echo "pass $TARGET ($(pass_name "$TARGET")) left its artifact on the floor"
      echo "  authoritative verdict: $(gate_cmd "$TARGET")"
      printf 'PASS_POST=OK\n'
    else
      echo "pass $TARGET ($(pass_name "$TARGET")) left NO artifact in its folder"
      echo "  steer with: cvg/brain/_prompts/$(prompt_file "$TARGET")"
      printf 'PASS_POST=INCOMPLETE\n'
      exit 1
    fi
    ;;
  *)
    usage >&2
    printf 'NEXT_PASS=USAGE_ERROR\n'
    exit 2
    ;;
esac
