#!/usr/bin/env bash
# test-cvg-tasks-plan.sh — the Pass 5 dry run must derive, never invent.
#
# WHY THIS EXISTS
# `cvg tasks plan` answers "what are you about to create, and why" before Pass 5
# writes anything. The danger in a preview is not that it is wrong — it is that it
# is PLAUSIBLE: a dry run that fills gaps with reasonable-looking tasks hides the
# exact defect worth catching, because a leg that never said what it becomes is a
# Pass 3 gap and must read as one. So the load-bearing rows here are the negative
# ones: a leg with no Yields section decomposes to NOTHING and says so.
#
# Also pinned: read-onlyness (a dry run that writes is a contradiction), the
# machine token on every surface, legacy-layout support, and discoverability.
#
# Hermetic: throwaway plan trees. No engine, no network, no credentials.
# Token: TASKS_PLAN_TESTS=PASS | TASKS_PLAN_TESTS=FAIL
# bash 3.2 safe. Deps: python3.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/.." && pwd)"
CVG="$REPO/bin/cvg"

rows=0; failed=0
ok()  { printf '  ok   — %s\n' "$1"; rows=$((rows+1)); }
bad() { printf '  FAIL — %s\n' "$1"; rows=$((rows+1)); failed=$((failed+1)); }

echo "=================================================================="
echo "test-cvg-tasks-plan.sh — the dry run derives, it never invents"
echo "=================================================================="

TMP="$(mktemp -d -t cvg-tasks-plan.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# ---- a lane whose legs declare their own units ------------------------------
mk_leg() { # mk_leg <dir> <nn> <tech> <yields-count>
  local d="$1" nn="$2" tech="$3" n="$4" i
  {
    printf -- '---\nleg: swimlane-alpha-leg-%s\ntech: %s\nswimlane: swimlane-alpha\n' "$nn" "$tech"
    printf 'parent: _lane.md\nstatus: proposed\ndepends_on: ["swimlane-alpha-leg-00"]\ntype: leg\n---\n\n'
    printf '# swimlane-alpha-leg-%s-%s — a leg\n\n## Responsibility\n\n' "$nn" "$tech"
    printf 'Publish the %s surface so the next lane has one thing to read.\n\n' "$tech"
    printf '## Proves\n\n- Given x, when y, then z.\n\n## Appetite\n\nsmall\n\n'
    printf '## Yields at Pass 5B (named units, not specified here)\n\n'
    # Content-bearing bullets, because that is what a real leg writes. The
    # earlier "One unit doing job N of <tech>" was all scaffolding words, so the
    # only survivors were an index and the tech label — which made a slug-quality
    # assertion impossible to state honestly.
    for i in $(seq 1 "$n"); do
      printf -- '- One unit publishing artifact %s of the %s contract.\n' "$i" "$tech"
    done
    printf '\n## Re-verify when\n\nThe contract moves.\n'
  } > "$d/leg-$nn-$tech.md"
}

TREE="$TMP/swimlanes"; LANE="$TREE/alpha"; mkdir -p "$LANE"
printf '# Swimlane · alpha\n\nlane-meta: thread=yes · risk=low · owner=team\n' > "$LANE/_lane.md"
mk_leg "$LANE" 01 first 2
mk_leg "$LANE" 02 second 1

run() { # run <expected-exit> <args...>; sets OUT
  local want="$1"; shift
  local rc=0
  OUT="$(bash "$CVG" tasks plan --dir "$@" 2>&1)" || rc=$?
  RC="$rc"
  [ "$rc" = "$want" ]
}
last() { printf '%s\n' "$OUT" | tail -1; }

# ---------------------------------------------------------------------------
echo
echo "[1] it derives one proposed spec per declared unit"
# ---------------------------------------------------------------------------
if run 0 "$TREE" && [ "$(last)" = "TASKS_PLAN=OK" ]; then
  ok "a lane with declared units previews at exit 0 + TASKS_PLAN=OK"
else
  bad "expected exit 0 + TASKS_PLAN=OK (got $RC / $(last))"
fi
N="$(printf '%s\n' "$OUT" | grep -c 'would create \[')"
if [ "$N" -eq 3 ]; then
  ok "3 units declared across 2 legs → 3 proposed specs (no invention, no loss)"
else
  bad "expected 3 proposed specs, counted $N"
fi
case "$OUT" in
  *"why      : Publish the first surface"*) ok "each leg's WHY comes from its own Responsibility" ;;
  *) bad "the preview does not carry the leg's stated reason" ;;
esac
case "$OUT" in
  *'swimlane-alpha-leg-01'*) ok "the stable leg key is shown, so a spec can cite it" ;;
  *) bad "the leg's stable key is missing from the preview" ;;
esac
case "$OUT" in
  *'cvg tasks new '*) ok "it prints the exact commands it would run" ;;
  *) bad "the preview should name the commands it becomes" ;;
esac

# Slugs must describe the unit, not its position. `…-1/-2/-3` told a worker nothing
# about which of three it had been handed, and the index is an artifact of
# iteration order rather than identity. Rationale in a bullet must not leak into
# the name either — parentheticals, bold asides and backticked refs are stripped.
case "$OUT" in
  *"alpha-doing-job-1-first"*|*"alpha-job-1-first"*|*"alpha-1-first"*)
    bad "slug kept the template's noise words" ;;
  *) ok "slugs drop scaffolding words like 'one unit doing'" ;;
esac
if printf '%s\n' "$OUT" | grep -qE 'cvg tasks new alpha-[a-z0-9-]*[a-z]{3}'; then
  ok "slugs are derived from the unit's own words, not an index"
else
  bad "slugs do not look derived from the unit text"
fi
if printf '%s\n' "$OUT" | grep -oE 'cvg tasks new [a-z0-9-]+' | sort | uniq -d | grep -q .; then
  bad "two proposed specs share one slug"
else
  ok "no two proposed specs share a slug (collisions get a suffix, not a clash)"
fi
if printf '%s\n' "$OUT" | grep -oE 'cvg tasks new [a-z0-9-]+' | grep -qE '[a-z]-$|--'; then
  bad "a slug was truncated mid-word or holds an empty segment"
else
  ok "no slug is severed mid-word (length is managed by whole words)"
fi

# ---------------------------------------------------------------------------
echo
echo "[2] THE LOAD-BEARING ROW: a leg with no Yields decomposes to NOTHING"
# ---------------------------------------------------------------------------
mk_leg "$LANE" 03 third 0   # writes the header with zero bullets
python3 - "$LANE/leg-03-third.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
# strip the Yields section entirely — the shape a Pass 3 gap actually has
s = re.sub(r"^## Yields at Pass 5B[^\n]*\n\n", "", s, flags=re.M)
open(p, "w", encoding="utf-8").write(s)
PY
if run 0 "$TREE"; then
  case "$OUT" in
    *"WOULD CREATE: nothing"*)
      ok "a leg with no Yields section reports NOTHING rather than a plausible guess" ;;
    *) bad "a Yields-less leg must not be filled in with invented tasks" ;;
  esac
  case "$OUT" in
    *"Pass 3 gap"*) ok "and it names the cause: the gap is upstream, not here" ;;
    *) bad "the empty case should point at Pass 3" ;;
  esac
else
  bad "one Yields-less leg must not fail the whole preview (got $RC)"
fi

# ---------------------------------------------------------------------------
echo
echo "[3] every leg missing Yields → EMPTY, exit 1 (nothing to plan)"
# ---------------------------------------------------------------------------
BARE="$TMP/bare/swimlanes/alpha"; mkdir -p "$BARE"
printf '# Swimlane · alpha\n\nlane-meta: thread=yes · risk=low · owner=team\n' > "$BARE/_lane.md"
mk_leg "$BARE" 01 only 0
python3 - "$BARE/leg-01-only.md" <<'PY'
import re, sys
p=sys.argv[1]; s=open(p,encoding="utf-8").read()
open(p,"w",encoding="utf-8").write(re.sub(r"^## Yields at Pass 5B[^\n]*\n\n","",s,flags=re.M))
PY
if run 1 "$TMP/bare/swimlanes" && [ "$(last)" = "TASKS_PLAN=EMPTY" ]; then
  ok "nothing derivable → exit 1 + TASKS_PLAN=EMPTY (not a false OK)"
else
  bad "expected exit 1 + TASKS_PLAN=EMPTY (got $RC / $(last))"
fi

# ---------------------------------------------------------------------------
echo
echo "[4] legacy layout still previews (no workspace stranded)"
# ---------------------------------------------------------------------------
LEG="$TMP/legacy/swimlanes/swimlane-beta"; mkdir -p "$LEG"
printf '# Swimlane · beta\n\nlane-meta: thread=no · risk=low · owner=team\n' > "$LEG/swimlane-beta.plan.md"
{
  printf -- '---\nleg: swimlane-beta-leg-01\ntech: old\nstatus: proposed\nparent: swimlane-beta.plan.md\n---\n\n'
  printf '## Responsibility\n\nDo the old-shaped thing.\n\n## Appetite\n\nsmall\n\n'
  printf '## Yields at Pass 5B\n\n- One legacy unit.\n'
} > "$LEG/swimlane-beta-leg-01-old.md"
if run 0 "$TMP/legacy/swimlanes" && printf '%s\n' "$OUT" | grep -q 'swimlane-beta-leg-01'; then
  ok "the legacy PRD + long leg filename still preview"
else
  bad "legacy layout was stranded by the preview (got $RC)"
fi

# ---------------------------------------------------------------------------
echo
echo "[5] usage + filter contracts, each ending in the token"
# ---------------------------------------------------------------------------
if run 2 "$TMP/nope" && [ "$(last)" = "TASKS_PLAN=USAGE_ERROR" ]; then
  ok "a missing tree → exit 2 + TASKS_PLAN=USAGE_ERROR"
else
  bad "missing tree should be a usage error (got $RC / $(last))"
fi
rc=0; OUT="$(bash "$CVG" tasks plan --dir "$TREE" --lane alpha 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$OUT" | grep -c 'lane · ')" -eq 1 ]; then
  ok "--lane narrows to one swimlane"
else
  bad "--lane filter did not narrow (exit $rc)"
fi
rc=0; OUT="$(bash "$CVG" tasks plan --dir "$TREE" --lane ghost 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && [ "$(last)" = "TASKS_PLAN=USAGE_ERROR" ]; then
  ok "an unknown lane is refused by name, not silently empty"
else
  bad "unknown lane should exit 2 (got $rc / $(last))"
fi

# ---------------------------------------------------------------------------
echo
echo "[6] a dry run that writes is a contradiction"
# ---------------------------------------------------------------------------
B="$(find "$TMP" -type f | sort | md5 2>/dev/null || find "$TMP" -type f | sort | md5sum)"
bash "$CVG" tasks plan --dir "$TREE" >/dev/null 2>&1 || true
A="$(find "$TMP" -type f | sort | md5 2>/dev/null || find "$TMP" -type f | sort | md5sum)"
if [ "$B" = "$A" ]; then
  ok "read-only — the preview wrote nothing"
else
  bad "the dry run mutated the tree"
fi
# Capture FRESH output: $OUT still held the unknown-lane error from [5], so this
# row was asserting against the wrong surface — a test that passes or fails for a
# reason unrelated to its claim.
OUT="$(bash "$CVG" tasks plan --dir "$TREE" 2>&1)"
case "$OUT" in
  *"nothing is written"*|*"DRY RUN"*) ok "it says up front that nothing is written" ;;
  *) bad "the preview should announce that it writes nothing" ;;
esac

# ---------------------------------------------------------------------------
echo
echo "[7] discoverable, and honest about what it does NOT do"
# ---------------------------------------------------------------------------
HELP="$(bash "$CVG" help 2>&1 || true)"
case "$HELP" in
  *"tasks plan"*) ok "cvg help lists tasks plan" ;;
  *) bad "cvg help does not mention tasks plan" ;;
esac
if bash "$CVG" agent-context 2>&1 | python3 -c '
import json,sys
m=json.load(sys.stdin)
c=[x for x in m["commands"] if x["name"].startswith("tasks plan")]
assert len(c)==1, "expected one tasks plan entry"
assert "TASKS_PLAN=OK|EMPTY|USAGE_ERROR" in c[0]["emits_tokens"]
assert c[0]["mutating"] is False, "a dry run must be declared read-only"
' 2>/dev/null; then
  ok "agent-context declares it read-only with its token set"
else
  bad "agent-context entry missing or wrong"
fi
OUT="$(bash "$CVG" tasks plan --dir "$TREE" 2>&1)"
case "$OUT" in
  *"no HMAC seal"*) ok "it states that validate/gate/stamp remain the real gates" ;;
  *) bad "the preview must not imply it sized or sealed anything" ;;
esac

echo
echo "=================================================================="
printf 'rows: %s   failed: %s\n' "$rows" "$failed"
if [ "$failed" -eq 0 ]; then echo "TASKS_PLAN_TESTS=PASS"; exit 0; fi
echo "TASKS_PLAN_TESTS=FAIL"; exit 1
