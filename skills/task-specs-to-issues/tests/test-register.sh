#!/usr/bin/env bash
# test-register.sh — offline end-to-end proof of the REGISTER driver.
#
# Drives register.sh + verify-registration.sh through the `fake` no-network
# adapter over a self-contained fixture backlog, so the ENTIRE live path —
# preflight, idempotent upsert, blocked-by link, list-ready, receipt write-back,
# cycle/dangling refusal, un-gated skip, fail-closed preflight — is exercised
# deterministically with no creds. This is what lets the skill be signed off
# without a real Linear/GitHub/Jira board.
#
# Every fixture is created under a temp dir and the fake store is a temp dir, so
# the test never touches the repo or the network. Ends in a single machine token:
#   REGISTER_TESTS=PASS | REGISTER_TESTS=FAIL
# Exit 0 all-pass, 1 otherwise.
#
# bash-3.2-safe. No -e (assertions must not abort the run); -uo pipefail kept.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SELF_DIR/.." && pwd)"
REGISTER="$SKILL_DIR/scripts/register.sh"
VERIFY="$SKILL_DIR/scripts/verify-registration.sh"
PARSE="$SKILL_DIR/scripts/_parse.sh"
FAKE="$SKILL_DIR/scripts/adapters/fake.sh"
REPO_ROOT="$(cd "$SELF_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "")"
TS_LIB="$REPO_ROOT/skills/task-spec/scripts/_lib.sh"

DATE="20260723"   # fixed — ids need no real date, only a valid T-YYYYMMDD- prefix

PASS=0; FAIL=0
ok()  { echo "  ok   — $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL — $1"; FAIL=$((FAIL+1)); }
# has "desc" HAYSTACK NEEDLE  — assert substring present
has() { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1 (missing: '$3')"; fi; }
# hasnt "desc" HAYSTACK NEEDLE — assert substring absent
hasnt() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1 (unexpected: '$3')"; else ok "$1"; fi; }
# rc_is "desc" GOT WANT
rc_is() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (rc=$2, wanted $3)"; fi; }
rc_nonzero() { if [[ "$2" -ne 0 ]]; then ok "$1"; else bad "$1 (expected non-zero exit)"; fi; }

WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/tsi-test.$$")"
mkdir -p "$WORK"
trap 'rm -rf "$WORK" 2>/dev/null || true' EXIT

# make_spec DIR ID SIGNED DEPS  — write a minimal but parseable signed/un-gated spec.
make_spec() {
  local dir="$1" id="$2" signed="$3" deps="$4"
  cat > "$dir/$id.md" <<SPEC
---
id: $id
title: fixture $id
status: ready
signed_off: $signed
depends_on: $deps
effort: S
severity: feature
priority: P2
---

## Goal
Test fixture $id for the register offline e2e.

## Exit Check
\`\`\`bash
eval_1
\`\`\`
SPEC
}

# build_diamond DIR — 5 signed specs in a diamond + 1 un-gated. Ready set = [root].
#   root -> mid -> {leafa, leafb} -> top   (5 blocked-by edges)
build_diamond() {
  local d="$1"; mkdir -p "$d"
  make_spec "$d" "T-$DATE-reg-root"    true  "[]"
  make_spec "$d" "T-$DATE-reg-mid"     true  "[T-$DATE-reg-root]"
  make_spec "$d" "T-$DATE-reg-leafa"   true  "[T-$DATE-reg-mid]"
  make_spec "$d" "T-$DATE-reg-leafb"   true  "[T-$DATE-reg-mid]"
  make_spec "$d" "T-$DATE-reg-top"     true  "[T-$DATE-reg-leafa, T-$DATE-reg-leafb]"
  make_spec "$d" "T-$DATE-reg-ungated" false "[]"
}

has_link() {  # has_link STORE FROM_ID TO_ID
  awk -F'\t' -v a="$2" -v b="$3" '$1==a&&$2==b{f=1} END{exit f?0:1}' "$1/links.tsv"
}
rows() { [[ -f "$1" ]] && awk 'END{print NR+0}' "$1" || echo 0; }

echo "=================================================================="
echo "test-register.sh — offline e2e via the fake adapter"
echo "=================================================================="

# -----------------------------------------------------------------------------
echo; echo "[A] dry-run makes NO board and NO receipts"
D="$WORK/a/tasks"; S="$WORK/a/store"; build_diamond "$D"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" --dry-run 2>&1)"; RC=$?
rc_is "dry-run exits 0" "$RC" "0"
has "dry-run plans 5 upserts" "$OUT" "PLAN: upsert 5 issue(s), set 5 blocked-by link(s)."
has "dry-run ready set = root" "$OUT" "ready set (no blocker): T-$DATE-reg-root"
has "dry-run announces receipt stamping" "$OUT" "would stamp receipt: tracker_ref: fake:"
has "dry-run emits REGISTER=DRY_RUN token" "$OUT" "REGISTER=DRY_RUN"
if [[ ! -f "$S/issues.tsv" ]]; then ok "dry-run wrote no board"; else bad "dry-run wrote a board"; fi
if grep -lq '^tracker_ref:' "$D"/*.md 2>/dev/null; then bad "dry-run mutated specs"; else ok "dry-run stamped no receipts"; fi

# -----------------------------------------------------------------------------
echo; echo "[B] live register: 1:1 mapping, faithful graph, receipts stamped"
D="$WORK/b/tasks"; S="$WORK/b/store"; build_diamond "$D"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "live register exits 0" "$RC" "0"
has "created 5 / updated 0" "$OUT" "created 5, updated 0"
has "5 blocked-by links" "$OUT" "5 blocked-by link(s)."
has "stamped 5 receipts" "$OUT" "stamped 5 tracker_ref receipt(s)"
has "un-gated reported" "$OUT" "skipped (un-gated): T-$DATE-reg-ungated"
has "live emits REGISTER=OK token" "$OUT" "REGISTER=OK"
if [[ "$(rows "$S/issues.tsv")" == "5" ]]; then ok "issues.tsv has exactly 5 rows (1:1)"; else bad "issues.tsv rows=$(rows "$S/issues.tsv")"; fi
if [[ "$(rows "$S/links.tsv")" == "5" ]]; then ok "links.tsv has exactly 5 rows"; else bad "links.tsv rows=$(rows "$S/links.tsv")"; fi
if has_link "$S" "T-$DATE-reg-mid" "T-$DATE-reg-root"; then ok "edge mid blocked-by root"; else bad "edge mid->root missing"; fi
if has_link "$S" "T-$DATE-reg-top" "T-$DATE-reg-leafa"; then ok "edge top blocked-by leafa"; else bad "edge top->leafa missing"; fi
if has_link "$S" "T-$DATE-reg-top" "T-$DATE-reg-leafb"; then ok "edge top blocked-by leafb"; else bad "edge top->leafb missing"; fi
# un-gated must NOT be on the board
if awk -F'\t' -v e="T-$DATE-reg-ungated" '$2==e{f=1} END{exit f?0:1}' "$S/issues.tsv"; then bad "un-gated leaked onto the board"; else ok "un-gated absent from the board"; fi

# -----------------------------------------------------------------------------
echo; echo "[C] ready set = the single root (blocked-by frontier)"
READY="$(TSI_FAKE_STORE="$S" bash "$FAKE" list-ready | tr -d ' ' | paste -sd, -)"
if [[ "$READY" == "FAKE-1" ]]; then ok "list-ready = [FAKE-1] (root, upserted first)"; else bad "list-ready='$READY' (want FAKE-1)"; fi

# -----------------------------------------------------------------------------
echo; echo "[D] receipts written back into the signed specs (not the un-gated one)"
if grep -q '^tracker_ref: fake:FAKE-' "$D/T-$DATE-reg-root.md"; then ok "root spec carries a tracker_ref receipt"; else bad "root spec has no receipt"; fi
if grep -q '^tracker_ref: fake:FAKE-' "$D/T-$DATE-reg-top.md"; then ok "top spec carries a tracker_ref receipt"; else bad "top spec has no receipt"; fi
if grep -q '^tracker_ref:' "$D/T-$DATE-reg-ungated.md"; then bad "un-gated spec was stamped"; else ok "un-gated spec left un-stamped"; fi

# -----------------------------------------------------------------------------
echo; echo "[E] idempotent re-run: update-in-place, no duplicates"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "re-run exits 0" "$RC" "0"
has "re-run updates, creates nothing" "$OUT" "created 0, updated 5"
if [[ "$(rows "$S/issues.tsv")" == "5" ]]; then ok "still 5 issues after re-run (no dupes)"; else bad "issues.tsv rows=$(rows "$S/issues.tsv")"; fi
if [[ "$(rows "$S/links.tsv")" == "5" ]]; then ok "still 5 links after re-run"; else bad "links.tsv rows=$(rows "$S/links.tsv")"; fi
# receipt count for the same board must not grow past 5 (one per signed spec)
NREC="$(grep -lc '^tracker_ref:' "$D"/*.md 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')"
if [[ "$NREC" == "5" ]]; then ok "exactly 5 specs carry a receipt (one per signed spec)"; else bad "receipt count=$NREC"; fi

# -----------------------------------------------------------------------------
echo; echo "[F] verify-registration gate → REGISTERED"
OUT="$(TSI_FAKE_STORE="$S" bash "$VERIFY" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "verify exits 0" "$RC" "0"
has "verify VERDICT REGISTERED" "$OUT" "VERDICT: REGISTERED"
has "verify sees 5 signed-off specs" "$OUT" "5 signed-off"
has "verify emits CHECK_REGISTER=OK token" "$OUT" "CHECK_REGISTER=OK"

# -----------------------------------------------------------------------------
echo; echo "[G] a dependency cycle is REFUSED (fail-closed, no board written)"
D="$WORK/g/tasks"; S="$WORK/g/store"; mkdir -p "$D"
make_spec "$D" "T-$DATE-reg-a" true "[T-$DATE-reg-b]"
make_spec "$D" "T-$DATE-reg-b" true "[T-$DATE-reg-a]"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_nonzero "cycle → non-zero exit" "$RC"
has "cycle message printed" "$OUT" "dependency cycle"
has "cycle emits REGISTER=FAIL token" "$OUT" "REGISTER=FAIL"
if [[ ! -f "$S/issues.tsv" ]]; then ok "cycle wrote no board"; else bad "cycle wrote a board"; fi

# -----------------------------------------------------------------------------
echo; echo "[H] a dangling dependency (dep is un-gated) is REFUSED"
D="$WORK/h/tasks"; S="$WORK/h/store"; mkdir -p "$D"
make_spec "$D" "T-$DATE-reg-solo"    true  "[T-$DATE-reg-missing]"
make_spec "$D" "T-$DATE-reg-missing" false "[]"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_nonzero "dangling dep → non-zero exit" "$RC"
has "dangling message printed" "$OUT" "blocked-by target not found"

# -----------------------------------------------------------------------------
echo; echo "[I] --no-stamp-refs: board written, specs left untouched"
D="$WORK/i/tasks"; S="$WORK/i/store"; build_diamond "$D"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" --no-stamp-refs 2>&1)"; RC=$?
rc_is "--no-stamp-refs exits 0" "$RC" "0"
has "board still created" "$OUT" "created 5, updated 0"
hasnt "no receipt-stamp line emitted" "$OUT" "stamped"
if grep -lq '^tracker_ref:' "$D"/*.md 2>/dev/null; then bad "--no-stamp-refs mutated specs"; else ok "--no-stamp-refs left specs clean"; fi

# -----------------------------------------------------------------------------
echo; echo "[J] fail-closed: preflight failure writes NO issues"
D="$WORK/j/tasks"; S="$WORK/j/store"; build_diamond "$D"
OUT="$(TSI_FAKE_STORE="$S" TSI_FAKE_FAIL_PREFLIGHT=1 bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_nonzero "preflight fail → non-zero exit" "$RC"
has "half-register refused" "$OUT" "not half-registering"
if [[ ! -s "$S/issues.tsv" ]]; then ok "preflight fail wrote no issues"; else bad "board written despite preflight fail"; fi

# -----------------------------------------------------------------------------
echo; echo "[K] HMAC-safety: the receipt stamp leaves the sign-off payload invariant"
if [[ -f "$TS_LIB" && -f "$PARSE" ]]; then
  RES="$(
    set +e
    source "$TS_LIB" 2>/dev/null
    source "$PARSE"  2>/dev/null
    SPEC="$WORK/k.md"
    cat > "$SPEC" <<'SIGNED'
---
id: T-20260723-reg-sealed
title: sealed fixture
status: ready
signed_off: true
signed_off_by: test
signed_off_at: 2026-07-23T00:00:00Z
depends_on: []
---

## Goal
A spec whose body must not change when a receipt is stamped.

## Exit Check
```bash
eval_1
```
SIGNED
    BEFORE="$(ts_signoff_payload "$SPEC")"
    tsi_set_tracker_ref "$SPEC" "fake:FAKE-1" >/dev/null 2>&1
    AFTER="$(ts_signoff_payload "$SPEC")"
    if [[ "$BEFORE" == "$AFTER" ]] && grep -q '^tracker_ref: fake:FAKE-1' "$SPEC"; then
      echo "INVARIANT_OK"
    else
      echo "INVARIANT_BROKEN"
    fi
  )"
  if [[ "$RES" == *INVARIANT_OK* ]]; then
    ok "sign-off MAC payload (id + body_digest + signed_off*) invariant under receipt stamp"
  else
    bad "receipt stamp changed the sign-off payload — the seal would break ($RES)"
  fi
else
  echo "  skip — task-spec _lib.sh not found; HMAC-safety proof skipped"
fi

# -----------------------------------------------------------------------------
echo; echo "[L] YAML-quoted scalars are unquoted before they reach the tracker"
# Regression: the first live Linear registration shipped a title wrapped in
# literal quote marks because tsi_field stripped the key but not YAML's delimiters.
D="$WORK/l/tasks"; S="$WORK/l/store"; mkdir -p "$D"
cat > "$D/T-$DATE-reg-quoted.md" <<'QSPEC'
---
id: T-20260723-reg-quoted
title: "Quoted title — should arrive clean"
status: ready
signed_off: true
depends_on: []
---

## Goal
Quoted-scalar regression fixture.
QSPEC
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "quoted-title spec registers" "$RC" "0"
QTITLE="$(awk -F'\t' 'NR==1{print $3}' "$S/issues.tsv" 2>/dev/null)"
if printf '%s' "$QTITLE" | grep -q '^"'; then
  bad "title reached the tracker with literal YAML quotes: <$QTITLE>"
else
  ok "title arrives unquoted on the board: <$QTITLE>"
fi

# -----------------------------------------------------------------------------
echo; echo "[M] the issue body is well-shaped, and triage reaches the adapter"
D="$WORK/m/tasks"; S="$WORK/m/store"; build_diamond "$D"
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "rich-body register exits 0" "$RC" "0"
BODY="$(cat "$S/bodies/1.md" 2>/dev/null)"
hasnt "body does not repeat the title as an H1" "$BODY" "## fixture T-$DATE-reg-root"
hasnt "body has no raw empty touches_paths" "$BODY" "touches_paths: []"
has "body carries the done-condition section" "$BODY" "### Definition of done"
has "body carries a dependencies section" "$BODY" "### Dependencies"
has "a root body says so explicitly" "$BODY" "**None** — this is a root"
has "body cites the spec as source of truth" "$BODY" "source of truth"
if grep -l '```mermaid' "$S"/bodies/*.md >/dev/null 2>&1; then
  ok "a dependent issue renders a mermaid dependency graph"
else
  bad "no mermaid graph rendered for any dependent issue"
fi
META="$(cat "$S/meta/T-$DATE-reg-root.txt" 2>/dev/null)"
has "triage: cvg marker label passed to the adapter" "$META" "cvg"
has "triage: effort label passed" "$META" "effort:S"
has "triage: severity label is namespaced" "$META" "severity:feature"
has "triage: priority passed" "$META" "priority=P2"
# Derived labels must re-sync on UPDATE too — an issue created before a label
# existed could otherwise never acquire it (CVG-1 hit exactly that).
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "re-register (update path) exits 0" "$RC" "0"
has "update path still passes derived labels" "$(cat "$S/meta/T-$DATE-reg-root.txt" 2>/dev/null)" "effort:S"

# The repo link (cvg setup repo -> spec_base_url -> TSI_SPEC_BASE_URL) must turn
# the footer spec path into a real markdown link; without it, plain code text.
BODY_PLAIN="$(bash -c "source '$PARSE'; tsi_issue_body '$D/T-$DATE-reg-root.md' ''")"
BODY_LINKED="$(TSI_SPEC_BASE_URL=https://github.com/o/r/blob/main \
  bash -c "source '$PARSE'; tsi_issue_body '$D/T-$DATE-reg-root.md' ''")"
hasnt "no repo link configured -> plain path" "$BODY_PLAIN" "](https://github.com/o/r/blob/main"
has   "repo link configured -> footer is a real link" "$BODY_LINKED" "](https://github.com/o/r/blob/main/"

# -----------------------------------------------------------------------------
echo; echo "[N] register: false opts a signed-off spec OUT of a shared board"
# A test fixture is legitimately signed off (the harness gates it) but must never
# reach a live tracker — one such fixture is a deliberate budget-buster.
D="$WORK/n/tasks"; S="$WORK/n/store"; mkdir -p "$D"
make_spec "$D" "T-$DATE-reg-real" true "[]"
cat > "$D/T-$DATE-reg-fixture.md" <<QSPEC
---
id: T-$DATE-reg-fixture
title: budget-buster fixture
status: ready
signed_off: true
register: false  # e2e fixture — gated for the harness, never for a shared board
depends_on: []
---

## Goal
Designed to exhaust budget and park.
QSPEC
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "opt-out register exits 0" "$RC" "0"
has "opted-out spec is reported" "$OUT" "register: false"
has "only the real spec registers" "$OUT" "created 1, updated 0"
if awk -F'\t' -v e="T-$DATE-reg-fixture" '$2==e{f=1} END{exit f?0:1}' "$S/issues.tsv"; then
  bad "fixture leaked onto the board"
else
  ok "fixture absent from the board"
fi

echo; echo "[O] YAML inline comments and quotes are stripped from scalars"
# `register: false  # fixture` must parse as "false", not "false  # fixture" —
# that exact bug let an opted-out fixture register anyway.
RES="$(bash -c "source '$PARSE'
printf 'reg=<%s> sev=<%s> ref=<%s>' \\
  \"\$(tsi_field '$D/T-$DATE-reg-fixture.md' register)\" \\
  \"\$(tsi_field '$D/T-$DATE-reg-real.md' severity)\" \\
  \"\$(tsi_field '$D/T-$DATE-reg-real.md' id)\"")"
has "inline comment stripped from register" "$RES" "reg=<false>"
has "severity has no trailing comment" "$RES" "sev=<feature>"

echo; echo "[P] spec attributes reach the adapter for the rich marker panel"
D="$WORK/p/tasks"; S="$WORK/p/store"; build_diamond "$D"
OUT="$(TSI_SPEC_BASE_URL=https://github.com/o/r/blob/main TSI_FAKE_STORE="$S" \
  bash "$REGISTER" --tracker fake --tasks-dir "$D" 2>&1)"; RC=$?
rc_is "attr-carrying register exits 0" "$RC" "0"
META="$(cat "$S/meta/T-$DATE-reg-root.txt" 2>/dev/null)"
has "attr: Spec id"        "$META" "Spec=T-$DATE-reg-root"
has "attr: Size"           "$META" "Size=S"
has "attr: sign-off tier"  "$META" "Sign-off="
has "spec-url reaches the adapter" "$META" "specurl=https://github.com/o/r/blob/main/"
# `group:child` names stay flat in the DRIVER; only the Linear adapter nests them.
has "driver still emits flat group:child labels" "$META" "effort:S"

echo; echo "[Q] a multi-part Goal keeps its paragraph structure"
# Specs hard-wrap prose and mark parts with a bold lead on a new line but no
# blank line. Markdown fuses that into one paragraph, and the renderer used to
# collapse newlines on top — arriving as an unreadable wall of text.
D="$WORK/q/tasks"; mkdir -p "$D"
cat > "$D/T-$DATE-reg-multi.md" <<'MSPEC'
---
id: T-20260723-reg-multi
title: multi-part goal
status: ready
signed_off: true
depends_on: []
---

## Goal

**(a) First part.** This sentence is hard-wrapped
across two source lines.
**(b) Second part.** This one too, and it must NOT
fuse into the first.
MSPEC
GB="$(bash -c "source '$PARSE'; tsi_goal_block '$D/T-$DATE-reg-multi.md'")"
has "part (a) is a quoted paragraph" "$GB" "> **(a) First part.** This sentence is hard-wrapped across two source lines."
has "part (b) is its OWN paragraph"  "$GB" "> **(b) Second part.** This one too, and it must NOT fuse into the first."
if printf '%s' "$GB" | grep -q '^>$'; then ok "paragraphs separated by a blockquote break"; else bad "no paragraph separator between (a) and (b)"; fi

echo; echo "[R] native-field seeding (T1): assignee / state / subscribers reach the adapter"
D="$WORK/r/tasks"; S="$WORK/r/store"; mkdir -p "$D"
cat > "$D/T-$DATE-reg-nf-root.md" <<'RSPEC'
---
id: T-20260723-reg-nf-root
title: nf root
status: ready
signed_off: true
depends_on: []
effort: M
execution_backend: claude
agent: python-developer
signed_off_by: luan@owshq.com
projection:
  cycle: "Cycle 7"
  sla: standard
  milestone: Transform
---

## Goal
Root.

## Exit Check
```bash
eval_1
```
RSPEC
cat > "$D/T-$DATE-reg-nf-child.md" <<'RSPEC'
---
id: T-20260723-reg-nf-child
title: nf child
status: ready
signed_off: true
depends_on: [T-20260723-reg-nf-root]
effort: S
execution_backend: codex
agent: any
signed_off_by: luan@owshq.com, ana@owshq.com
projection:
  parent: T-20260723-reg-nf-root
  cycle: "3"
---

## Goal
Child.

## Exit Check
```bash
eval_1
```
RSPEC
OUT="$(TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" --no-stamp-refs 2>&1)"; RC=$?
rc_is "native-field register exits 0" "$RC" "0"
RM="$(cat "$S/meta/T-$DATE-reg-nf-root.txt" 2>/dev/null)"
CM="$(cat "$S/meta/T-$DATE-reg-nf-child.txt" 2>/dev/null)"
has "assignee: agent role wins over backend"     "$RM" "assignee=agent:python-developer"
has "assignee: agent=any falls back to backend"  "$CM" "assignee=backend:codex"
has "state: a root opens in Todo"                "$RM" "state=Todo"
has "state: a blocked spec waits in Backlog"     "$CM" "state=Backlog"
has "subscribers: the single signer"             "$RM" "subscribers=luan@owshq.com"
has "subscribers: a comma-list is split"         "$CM" "subscribers=luan@owshq.com ana@owshq.com"

echo; echo "[S] projection: block (T2) — cycle/parent/sla honored; structural fields gated OFF"
has "cycle reaches the adapter"                  "$RM" "cycle=Cycle 7"
has "sla reaches the adapter"                    "$RM" "sla=standard"
has "parent (a spec id) reaches the adapter"     "$CM" "parent=T-$DATE-reg-nf-root"
if printf '%s' "$RM" | grep -q '^project=$'; then ok "project empty when projection disabled"; else bad "project not empty while disabled"; fi
if printf '%s' "$RM" | grep -q '^milestone=$'; then ok "milestone empty when projection disabled"; else bad "milestone not empty while disabled"; fi
if [[ -f "$S/structure.tsv" ]]; then bad "structure created while projection disabled"; else ok "no structure created (base path byte-identical)"; fi

echo; echo "[T] structure projection (T3) — Step-0 ensures Initiative->Project->Milestones + health"
D="$WORK/t/tasks"; S="$WORK/t/store"; mkdir -p "$D"
cat > "$D/T-$DATE-reg-str-a.md" <<'TSPEC'
---
id: T-20260723-reg-str-a
title: str a
status: ready
signed_off: true
depends_on: []
projection:
  milestone: Transform
---

## Goal
A.

## Exit Check
```bash
eval_1
```
TSPEC
make_spec "$D" "T-$DATE-reg-str-b" true "[T-$DATE-reg-str-a]"
PENV=(CVG_PROJECTION_ENABLED=1 TSI_PROJECTION_PROJECT='Test Backbone' TSI_PROJECTION_INITIATIVE='Q Init' TSI_PROJECTION_MILESTONES='Capture,Transform,Serve')
OUT="$(env "${PENV[@]}" TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" --no-stamp-refs 2>&1)"; RC=$?
rc_is "structure-enabled register exits 0" "$RC" "0"
has "Step-0 announced structure" "$OUT" "[structure] projection enabled"
has "health note posted"         "$OUT" "[health]"
ST="$(cat "$S/structure.tsv" 2>/dev/null)"
has "project ensured"             "$ST" "Test Backbone"
has "initiative ensured"          "$ST" "Q Init"
has "phase milestone Capture"     "$ST" "Capture"
has "phase milestone Transform"   "$ST" "Transform"
has "phase milestone Serve"       "$ST" "Serve"
AM="$(cat "$S/meta/T-$DATE-reg-str-a.txt" 2>/dev/null)"
if printf '%s' "$AM" | grep -q '^project=FAKE-PROJECT-Test-Backbone$'; then ok "run-wide project threaded into the issue"; else bad "run-wide project not threaded"; fi
if printf '%s' "$AM" | grep -q '^milestone=FAKE-MILE-.*Transform$'; then ok "per-spec milestone threaded into the issue"; else bad "per-spec milestone not threaded"; fi
has "health carries the registered total" "$(cat "$S/health.tsv" 2>/dev/null)" "total=2"
# Idempotency: a second enabled run reuses the SAME structure (ensure-by-name).
env "${PENV[@]}" TSI_FAKE_STORE="$S" bash "$REGISTER" --tracker fake --tasks-dir "$D" --no-stamp-refs >/dev/null 2>&1; RC=$?
rc_is "second structure-enabled register exits 0" "$RC" "0"
NPROJ="$(awk -F'\t' '$1=="project"{n++} END{print n+0}' "$S/structure.tsv")"
rc_is "project ensured exactly once (idempotent by name)" "$NPROJ" "1"

# -----------------------------------------------------------------------------
echo
echo "=================================================================="
echo "RESULTS: $PASS passed, $FAIL failed"
if [[ "$FAIL" -eq 0 ]]; then
  echo "REGISTER_TESTS=PASS"
  exit 0
else
  echo "REGISTER_TESTS=FAIL"
  exit 1
fi
