#!/bin/bash
# run-tests.sh — Pass 4 consensus-gate regression. Proves the gate validates the
# STAMPED objection-log artifact (structure + semantics + provenance hashes),
# discriminating: a good log passes; each injected defect fails for its reason.
# bash 3.2 safe. Python is stdlib-only (the gate + the generator).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
GATE="$HERE/../scripts/check-consensus-gate.sh"
GEN="$HERE/gen-log.py"
TREE="$HERE/fixtures/tree"
TOTAL=0; FAILED=0

newtree() { # -> prints a fresh temp sketch dir with the fixture swimlane
  local t; t="$(mktemp -d)"; mkdir -p "$t/sketch"; cp -r "$TREE"/swimlane-* "$t/sketch/"; printf '%s' "$t/sketch"
}
gate() { bash "$GATE" --dir "$1" 2>&1; }

check() { # <name> <sketch> <want_exit> <must> <must_not>
  TOTAL=$((TOTAL + 1))
  local out rc; out="$(gate "$2")"; rc=$?
  local okrow=1 why=""
  [ "$rc" -ne "$3" ] && { okrow=0; why="exit $rc want $3"; }
  [ -n "$4" ] && ! printf '%s\n' "$out" | grep -qE "$4" && { okrow=0; why="$why; missing: $4"; }
  [ -n "$5" ] && printf '%s\n' "$out" | grep -qE "$5" && { okrow=0; why="$why; forbidden: $5"; }
  if [ "$okrow" -eq 1 ]; then printf 'ok    %-22s (exit %s)\n' "$1" "$rc"
  else printf 'FAIL  %-22s %s\n' "$1" "$why"; printf '%s\n' "$out" | sed 's/^/      | /'; FAILED=$((FAILED + 1)); fi
}

# good
S="$(newtree)"; python3 "$GEN" "$S" good >/dev/null;          check good            "$S" 0 'CHECK_CONSENSUS=OK'   'FAIL'
# each injected defect
S="$(newtree)"; python3 "$GEN" "$S" same-family >/dev/null;    check same-family     "$S" 1 'self-review'          '^CHECK_CONSENSUS=OK'
S="$(newtree)"; python3 "$GEN" "$S" unresolved >/dev/null;     check unresolved      "$S" 1 'FIX or ACCEPT'        '^CHECK_CONSENSUS=OK'
S="$(newtree)"; python3 "$GEN" "$S" accept-no-owner >/dev/null; check accept-no-owner "$S" 1 'ACCEPT requires'      '^CHECK_CONSENSUS=OK'
S="$(newtree)"; python3 "$GEN" "$S" no-fork >/dev/null;        check no-fork         "$S" 1 'fork.choice'          '^CHECK_CONSENSUS=OK'
S="$(newtree)"; python3 "$GEN" "$S" no-objections >/dev/null;  check no-objections   "$S" 1 'blessed everything'   '^CHECK_CONSENSUS=OK'
# provenance: tamper a plan AFTER stamping -> hash mismatch
S="$(newtree)"; python3 "$GEN" "$S" good >/dev/null; printf '\nedited after review\n' >> "$S"/swimlane-alpha/swimlane-alpha-leg-01-tool.md
check tampered-plan   "$S" 1 'changed since the review' '^CHECK_CONSENSUS=OK'
# PRD fork line removed (stamp AFTER edit so hashes still match) -> fork-line fail
S="$(newtree)"; grep -v '^FORK:' "$S"/swimlane-alpha/swimlane-alpha.plan.md > "$S"/tmp && mv "$S"/tmp "$S"/swimlane-alpha/swimlane-alpha.plan.md
python3 "$GEN" "$S" good >/dev/null; check no-prd-fork "$S" 1 'fork not declared at the top' '^CHECK_CONSENSUS=OK'
# no log -> EMPTY (exit 2)
S="$(newtree)"; check no-log "$S" 2 'CHECK_CONSENSUS=EMPTY' '^CHECK_CONSENSUS=OK'
# usage error
TOTAL=$((TOTAL + 1)); OUT="$(bash "$GATE" --bogus 2>&1)"; RC=$?
if [ "$RC" -eq 2 ] && printf '%s\n' "$OUT" | grep -q '^CHECK_CONSENSUS=USAGE_ERROR$'; then printf 'ok    %-22s (exit %s)\n' usage-error "$RC"
else printf 'FAIL  %-22s exit %s\n' usage-error "$RC"; FAILED=$((FAILED + 1)); fi

# dispatch pipe (fake cross-family engine → stamp → gate) — proves end-to-end
DISPATCH="$HERE/../scripts/dispatch-review.sh"
FAKE="$(mktemp -d)/fake-codex"
cat > "$FAKE" <<'SH'
#!/bin/bash
[ "$1" = "--version" ] && { echo "fake-codex 9.9"; exit 0; }
cat >/dev/null 2>&1
echo '{"verdict":"REVISE","model":"fake-codex","objections":[{"id":"C1","severity":"high","attack_class":"cross-lane-interface","swimlane":"swimlane-alpha","location":{"plan_file":"x","section":"Seam"},"evidence":"gap","resolution":{"disposition":"FIX","fixed_in":"x"}}],"fork":{"choice":"B","reason":"cheap evals"}}'
SH
chmod +x "$FAKE"
S="$(newtree)"
TOTAL=$((TOTAL + 1)); OUT="$(CVG_CODEX_CMD="$FAKE" bash "$DISPATCH" --adversary codex --dir "$S" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^REVIEW=OK$' && [ -f "$S/.consensus/objection-log.json" ]; then
  printf 'ok    %-22s (exit %s)\n' dispatch-stamps "$RC"
else printf 'FAIL  %-22s exit %s\n' dispatch-stamps "$RC"; printf '%s\n' "$OUT" | sed 's/^/      | /'; FAILED=$((FAILED + 1)); fi
check dispatch-then-gate "$S" 0 'CHECK_CONSENSUS=OK' 'FAIL'
# unknown adversary -> usage error
TOTAL=$((TOTAL + 1)); OUT="$(bash "$DISPATCH" --adversary bogus --dir "$S" 2>&1)"; RC=$?
if [ "$RC" -eq 2 ] && printf '%s\n' "$OUT" | grep -q '^REVIEW=USAGE_ERROR$'; then printf 'ok    %-22s (exit %s)\n' dispatch-bad-adv "$RC"
else printf 'FAIL  %-22s exit %s\n' dispatch-bad-adv "$RC"; FAILED=$((FAILED + 1)); fi
# watchdog: a HUNG engine (sleeps past the cap) must fail-closed to TIMEOUT, never hang the referee.
# Proves the pure-bash watchdog holds the mandatory-timeout invariant WITHOUT coreutils (the live
# codex exec sat at 0% CPU forever). cap=1s vs a 30s sleeper → REVIEW=TIMEOUT in ~1s.
SLEEPER="$(mktemp -d)/fake-sleeper"
cat > "$SLEEPER" <<'SH'
#!/bin/bash
[ "$1" = "--version" ] && { echo "fake-sleeper 0.0"; exit 0; }
sleep 30
echo '{"verdict":"REVISE","objections":[]}'
SH
chmod +x "$SLEEPER"
S="$(newtree)"
TOTAL=$((TOTAL + 1)); OUT="$(CVG_CODEX_CMD="$SLEEPER" CVG_TIMEOUT_SECS=1 bash "$DISPATCH" --adversary codex --dir "$S" 2>&1)"; RC=$?
if [ "$RC" -eq 21 ] && printf '%s\n' "$OUT" | grep -q '^REVIEW=TIMEOUT$'; then printf 'ok    %-22s (exit %s)\n' dispatch-timeout "$RC"
else printf 'FAIL  %-22s exit %s\n' dispatch-timeout "$RC"; printf '%s\n' "$OUT" | sed 's/^/      | /'; FAILED=$((FAILED + 1)); fi

# multi-engine adversary: dispatch codex,kimi (two fakes, two FAMILIES) → ONE merged log → gate.
# Proves the ATTACK half of the auto-loop: two cross-family views, deduped+renumbered, provenance by referee.
MULTI="$HERE/../scripts/dispatch-review-multi.sh"
FAKEK="$(mktemp -d)/fake-kimi"
cat > "$FAKEK" <<'SH'
#!/bin/bash
[ "$1" = "--version" ] && { echo "fake-kimi 9.9"; exit 0; }
cat >/dev/null 2>&1
echo '{"verdict":"REVISE","model":"fake-kimi","objections":[{"id":"C1","severity":"medium","attack_class":"grain","swimlane":"swimlane-alpha","location":{"plan_file":"y","section":"Grain"},"evidence":"grain gap","resolution":{"disposition":"FIX","fixed_in":"y"}}],"fork":{"choice":"B","reason":"cheap"}}'
SH
chmod +x "$FAKEK"
S="$(newtree)"
TOTAL=$((TOTAL + 1)); OUT="$(CVG_CODEX_CMD="$FAKE" CVG_KIMI_CMD="$FAKEK" bash "$MULTI" --adversary codex,kimi --dir "$S" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^REVIEW=OK$' \
   && python3 -c "import json,sys; d=json.load(open('$S/.consensus/objection-log.json')); sys.exit(0 if len(d.get('adversaries',[]))==2 and len(d['objections'])==2 and d.get('cross_family') and d['objections'][1]['id']=='C2' else 1)"; then
  printf 'ok    %-22s (exit %s)\n' dispatch-multi "$RC"
else printf 'FAIL  %-22s exit %s\n' dispatch-multi "$RC"; printf '%s\n' "$OUT" | sed 's/^/      | /'; FAILED=$((FAILED + 1)); fi
check multi-then-gate "$S" 0 'CHECK_CONSENSUS=OK' 'FAIL'
# fail-closed: a single SAME-family engine (claude only) → no cross-family → ERROR, never a pass
S="$(newtree)"; TOTAL=$((TOTAL + 1))
OUT="$(CVG_CLAUDE_CMD="$FAKE" bash "$MULTI" --adversary claude --dir "$S" 2>&1)"; RC=$?
if [ "$RC" -eq 22 ] && printf '%s\n' "$OUT" | grep -q '^REVIEW=ERROR$'; then printf 'ok    %-22s (exit %s)\n' multi-no-xfamily "$RC"
else printf 'FAIL  %-22s exit %s\n' multi-no-xfamily "$RC"; printf '%s\n' "$OUT" | sed 's/^/      | /'; FAILED=$((FAILED + 1)); fi

echo
if [ "$FAILED" -eq 0 ]; then echo "PASS — all $TOTAL rows green."; exit 0
else echo "FAIL — $FAILED of $TOTAL rows red." >&2; exit 1; fi
