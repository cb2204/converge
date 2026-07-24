#!/usr/bin/env bash
# End-to-end regression for Pass 6 · Bind. Uses disposable repositories only.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL_HOME="$(cd "$SKILL_DIR/../.." && pwd)"
CVG="$TOOL_HOME/bin/cvg"
SAFE="$TOOL_HOME/skills/task-spec/scripts/safe-to-delegate.sh"
FIXTURE="$TOOL_HOME/skills/task-spec/tests/fixtures/T-20260602-golden.md"
LOOP="$TOOL_HOME/skills/task-loop/scripts/run-issue-eval.sh"
OPEN_PR="$TOOL_HOME/skills/task-loop/scripts/open-issue-pr.sh"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok    %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL  %s\n' "$1" >&2; }

TMP_REPO="$(mktemp -d -t cvg-runtime-contract.XXXXXX)"
KEY_FILE="$(mktemp -t cvg-runtime-key.XXXXXX)"
# shellcheck disable=SC2329  # invoked by trap
cleanup() { rm -rf "$TMP_REPO"; rm -f "$KEY_FILE"; }
trap cleanup EXIT

git -C "$TMP_REPO" init --quiet
git -C "$TMP_REPO" config user.email runtime-contract@test.local
git -C "$TMP_REPO" config user.name "runtime contract test"
mkdir -p "$TMP_REPO/tasks" "$TMP_REPO/cvg/knowledge/failures" "$TMP_REPO/cvg/knowledge/references"
cp "$FIXTURE" "$TMP_REPO/tasks/T-20260602-golden.md"
printf '# readme\n' > "$TMP_REPO/README.md"
printf 'Known project-specific locking failure.\n' > "$TMP_REPO/cvg/knowledge/failures/locking.md"
printf 'Version-pinned external reference.\n' > "$TMP_REPO/cvg/knowledge/references/vendor-v1.md"
printf 'runtime-contract-test-key-material-32bytes\n' > "$KEY_FILE"

(
  cd "$TMP_REPO"
  TASKSPEC_SIGNING_KEY="$KEY_FILE" \
    bash "$SAFE" --stamp --stamp-by runtime-test tasks/T-20260602-golden.md >/dev/null
)

PROFILE="$TMP_REPO/cvg/execution/T-20260602-golden/execution-profile.yaml"

DRY_PROFILE="$TMP_REPO/cvg/execution/dry-run/execution-profile.yaml"
DRY_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" --json --dry-run bind \
    --task tasks/T-20260602-golden.md \
    --out cvg/execution/dry-run/execution-profile.yaml
)"
if [ ! -e "$DRY_PROFILE" ] && python3 -c 'import json,sys
d=json.load(sys.stdin)
assert d["dry_run"] is True and d["changed"] is False' <<<"$DRY_OUT"; then
  ok "cvg bind --dry-run changes nothing"
else
  bad "bind dry-run wrote an artifact or misreported state"
fi

set +e
BIND_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind \
    --task tasks/T-20260602-golden.md \
    --knowledge cvg/knowledge/failures/locking.md \
    --doc https://example.test/vendor/v1=cvg/knowledge/references/vendor-v1.md 2>&1
)"
BIND_RC=$?
set -e
if [ "$BIND_RC" -eq 0 ] && grep -q '^CHECK_RUNTIME_CONTRACT=PASS$' <<<"$BIND_OUT"; then
  ok "cvg bind emits a ready contract"
else
  bad "cvg bind failed: $BIND_OUT"
fi

if [ -f "$PROFILE" ] \
  && python3 - "$PROFILE" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
assert p["schema"] == "cvg.execution-profile.v1"
assert p["task"]["authorization"]["trust_tier"] == 1
assert p["topology"]["mode"] == "single"
assert p["canonical_sources"]["write_scope"].startswith("task_spec.")
assert len(p["enforcement"]["adapters"]) == 4
assert p["enforcement"]["receipt_writer"].endswith("write-execution-receipt.py")
assert p["context"]["approved_project_knowledge"][0]["sha256"]
assert p["context"]["external_docs"][0]["cache_path"].endswith("vendor-v1.md")
PY
then
  ok "profile is thin, Tier 1, pinned, and portable"
else
  bad "profile shape or semantics"
fi

PROFILE_HASH_1="$(shasum -a 256 "$PROFILE" | awk '{print $1}')"
(
  cd "$TMP_REPO"
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind \
    --task tasks/T-20260602-golden.md \
    --knowledge cvg/knowledge/failures/locking.md \
    --doc https://example.test/vendor/v1=cvg/knowledge/references/vendor-v1.md >/dev/null
)
PROFILE_HASH_2="$(shasum -a 256 "$PROFILE" | awk '{print $1}')"
if [ "$PROFILE_HASH_1" = "$PROFILE_HASH_2" ]; then
  ok "binding is deterministic"
else
  bad "binding changed without input changes"
fi

set +e
CHECK_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind --check \
    --task tasks/T-20260602-golden.md 2>&1
)"
CHECK_RC=$?
set -e
if [ "$CHECK_RC" -eq 0 ] && grep -q '^CHECK_RUNTIME_CONTRACT=PASS$' <<<"$CHECK_OUT"; then
  ok "cvg bind --check re-verifies freshness"
else
  bad "bind --check failed: $CHECK_OUT"
fi

JSON_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" --json bind --check \
    --task tasks/T-20260602-golden.md
)"
if python3 -c 'import json,sys
d=json.load(sys.stdin)
assert d["ok"] is True
assert d["converge_pass"] == 6
assert d["token"] == "CHECK_RUNTIME_CONTRACT=PASS"
assert d["changed"] is False' <<<"$JSON_OUT"; then
  ok "agent-native JSON envelope exposes Pass 6 verdict"
else
  bad "bind JSON envelope is incomplete"
fi

if (
  cd "$TMP_REPO"
  python3 "$SKILL_DIR/scripts/check-path-policy.py" \
    --profile "$PROFILE" --candidate README.md --candidate "$TMP_REPO/README.md" >/dev/null
); then
  ok "candidate guard allows relative and absolute in-repo paths"
else
  bad "candidate guard rejected allowed path"
fi

set +e
PATH_OUT="$(
  cd "$TMP_REPO" &&
  python3 "$SKILL_DIR/scripts/check-path-policy.py" \
    --profile "$PROFILE" --candidate src/forbidden.py 2>&1
)"
PATH_RC=$?
set -e
if [ "$PATH_RC" -eq 1 ] && grep -q '^CHECK_PATH_POLICY=FAIL$' <<<"$PATH_OUT"; then
  ok "candidate guard rejects forbidden path"
else
  bad "candidate guard did not fail closed"
fi

if (
  cd "$TMP_REPO"
  printf '{"tool_input":{"file_path":"README.md"}}\n' |
    CVG_EXECUTION_PROFILE="$PROFILE" \
    python3 "$SKILL_DIR/scripts/guard-tool-input.py" >/dev/null
); then
  ok "vendor hook bridge enforces tool-input paths"
else
  bad "tool-input hook bridge rejected allowed write"
fi

set +e
TOPOLOGY_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" python3 "$SKILL_DIR/scripts/bind-runtime-contract.py" \
    --repo "$TMP_REPO" --tool-home "$TOOL_HOME" \
    --task tasks/T-20260602-golden.md \
    --topology implementer-verifier \
    --out cvg/execution/rejected/execution-profile.yaml 2>&1
)"
TOPOLOGY_RC=$?
set -e
if [ "$TOPOLOGY_RC" -eq 1 ] \
  && grep -q 'substantive static justification' <<<"$TOPOLOGY_OUT"; then
  ok "non-single topology needs substantive evidence"
else
  bad "topology presence check was too weak"
fi

set +e
PARALLEL_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" python3 "$SKILL_DIR/scripts/bind-runtime-contract.py" \
    --repo "$TMP_REPO" --tool-home "$TOOL_HOME" \
    --task tasks/T-20260602-golden.md \
    --topology parallel \
    --justification "Two independent writers were selected from static repository seams." \
    --worker one:scoped-write:README.md \
    --worker two:scoped-write:README.md \
    --out cvg/execution/rejected-parallel/execution-profile.yaml 2>&1
)"
PARALLEL_RC=$?
set -e
if [ "$PARALLEL_RC" -eq 1 ] && grep -q 'ownership overlaps' <<<"$PARALLEL_OUT"; then
  ok "parallel ownership must be disjoint"
else
  bad "parallel overlap escaped the gate"
fi

PARALLEL_TASK="$TMP_REPO/tasks/T-20260602-parallel.md"
sed \
  -e 's|T-20260602-golden|T-20260602-parallel|g' \
  -e 's|  - README.md|  - src/**\
  - tests/**|' \
  -e 's|^- src/$|- docs/|' \
  "$FIXTURE" > "$PARALLEL_TASK"
mkdir -p "$TMP_REPO/src" "$TMP_REPO/tests"
printf 'source\n' > "$TMP_REPO/src/unit.py"
printf 'test\n' > "$TMP_REPO/tests/test_unit.py"
(
  cd "$TMP_REPO"
  TASKSPEC_SIGNING_KEY="$KEY_FILE" \
    bash "$SAFE" --stamp --stamp-by runtime-test tasks/T-20260602-parallel.md >/dev/null
)
set +e
PARALLEL_OK_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind \
    --task tasks/T-20260602-parallel.md \
    --topology parallel \
    --justification "Source and test legs have statically disjoint write ownership." \
    --worker source:scoped-write:src/** \
    --worker tests:scoped-write:tests/** 2>&1
)"
PARALLEL_OK_RC=$?
set -e
if [ "$PARALLEL_OK_RC" -eq 0 ] \
  && grep -q '^CHECK_RUNTIME_CONTRACT=PASS$' <<<"$PARALLEL_OK_OUT"; then
  ok "disjoint parallel topology binds and gates successfully"
else
  bad "valid parallel topology was rejected: $PARALLEL_OK_OUT"
fi

git -C "$TMP_REPO" add -A
git -C "$TMP_REPO" commit --quiet -m "runtime contract baseline"
git -C "$TMP_REPO" branch -M main
printf 'authorized task change\n' >> "$TMP_REPO/README.md"
if (
  cd "$TMP_REPO"
  python3 "$SKILL_DIR/scripts/check-path-policy.py" \
    --profile "$PROFILE" --base main >/dev/null
); then
  ok "postflight diff guard accepts an in-scope working-tree change"
else
  bad "postflight diff guard rejected an authorized change"
fi

printf 'out of scope\n' > "$TMP_REPO/outside.txt"
set +e
DIFF_OUT="$(
  cd "$TMP_REPO" &&
  python3 "$SKILL_DIR/scripts/check-path-policy.py" \
    --profile "$PROFILE" --base main 2>&1
)"
DIFF_RC=$?
set -e
if [ "$DIFF_RC" -eq 1 ] \
  && grep -q 'outside.txt' <<<"$DIFF_OUT" \
  && grep -q '^CHECK_PATH_POLICY=FAIL$' <<<"$DIFF_OUT"; then
  ok "postflight diff guard rejects an out-of-scope change"
else
  bad "postflight diff guard did not fail closed: $DIFF_OUT"
fi
git -C "$TMP_REPO" checkout -- README.md
unlink "$TMP_REPO/outside.txt"

set +e
STALE_OUT="$(
  printf '\nTamper.\n' >> "$TMP_REPO/tasks/T-20260602-golden.md"
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind --check \
    --task tasks/T-20260602-golden.md 2>&1
)"
STALE_RC=$?
set -e
if [ "$STALE_RC" -eq 1 ] \
  && grep -Eq 'stale profile|modified after stamping|not execution-ready' <<<"$STALE_OUT"; then
  ok "Task-Spec drift fails readiness"
else
  bad "stale profile was not rejected: $STALE_OUT"
fi

git -C "$TMP_REPO" checkout -- tasks/T-20260602-golden.md 2>/dev/null || true
# The task was not committed, so restore it from a freshly re-stamped fixture.
cp "$FIXTURE" "$TMP_REPO/tasks/T-20260602-golden.md"
(
  cd "$TMP_REPO"
  TASKSPEC_SIGNING_KEY="$KEY_FILE" \
    bash "$SAFE" --stamp --stamp-by runtime-test tasks/T-20260602-golden.md >/dev/null
  TASKSPEC_SIGNING_KEY="$KEY_FILE" CVG_HOME="$TOOL_HOME" "$CVG" bind \
    --task tasks/T-20260602-golden.md \
    --knowledge cvg/knowledge/failures/locking.md \
    --doc https://example.test/vendor/v1=cvg/knowledge/references/vendor-v1.md >/dev/null
)

set +e
LOOP_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" bash "$LOOP" \
    --issue T-20260602-golden --tasks-dir tasks 2>&1
)"
LOOP_RC=$?
set -e
if [ "$LOOP_RC" -eq 0 ] \
  && grep -q '^CHECK_RUNTIME_CONTRACT=PASS$' <<<"$LOOP_OUT" \
  && grep -q '^GREEN' <<<"$LOOP_OUT"; then
  ok "Pass 8 requires and consumes the Pass 6 contract"
else
  bad "task-loop contract integration failed: $LOOP_OUT"
fi

git -C "$TMP_REPO" add -A
git -C "$TMP_REPO" commit --quiet -m "rebind runtime contract"
printf 'authorized implementation\n' >> "$TMP_REPO/README.md"
set +e
SETTLE_OUT="$(
  cd "$TMP_REPO" &&
  TASKSPEC_SIGNING_KEY="$KEY_FILE" bash "$OPEN_PR" \
    --issue T-20260602-golden \
    --tasks-dir tasks \
    --base main \
    --dry-run 2>&1
)"
SETTLE_RC=$?
set -e
if [ "$SETTLE_RC" -eq 0 ] \
  && grep -q "^GREEN — issue" <<<"$SETTLE_OUT" \
  && grep -q '^CHECK_PATH_POLICY=PASS$' <<<"$SETTLE_OUT"; then
  ok "Pass 8 settlement requires both green eval and green path policy"
else
  bad "Pass 8 settlement integration failed: $SETTLE_OUT"
fi
git -C "$TMP_REPO" checkout -- README.md

mkdir -p "$TMP_REPO/cvg/receipts"
printf 'GREEN — eval passed\n' > "$TMP_REPO/cvg/receipts/eval-output.txt"
if (
  cd "$TMP_REPO"
  python3 "$SKILL_DIR/scripts/write-execution-receipt.py" \
    --profile "$PROFILE" \
    --result pass \
    --eval-output cvg/receipts/eval-output.txt \
    --path-policy pass \
    --agent test-runtime \
    --branch task/golden >/dev/null
) && python3 - "$TMP_REPO/cvg/receipts/T-20260602-golden.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
assert r["schema"] == "cvg.execution-receipt.v1"
assert r["result"] == "pass"
assert r["evaluation"]["path_policy"] == "pass"
assert r["task_spec"]["sha256"]
assert r["execution_profile"]["sha256"]
PY
then
  ok "Pass 8 receipt binds spec, profile, eval, and path-policy evidence"
else
  bad "execution receipt writer failed"
fi

if (
  cd "$TMP_REPO"
  python3 "$SKILL_DIR/scripts/propose-knowledge-candidate.py" \
    --profile "$PROFILE" \
    --receipt cvg/receipts/T-20260602-golden.json \
    --kind failure \
    --summary "README path checks require repository-relative candidates" \
    --evidence "The signed execution receipt proved the scoped guard and eval both passed." \
    >/dev/null
) && grep -q '^status: proposed$' \
  "$TMP_REPO/cvg/knowledge/candidates/T-20260602-golden.md"; then
  ok "execution receipt creates only a proposed knowledge candidate"
else
  bad "knowledge-accretion seam failed"
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf 'PASS — %s runtime-contract checks green.\n' "$PASS"
  exit 0
fi
printf 'FAIL — %s of %s runtime-contract checks red.\n' "$FAIL" "$((PASS + FAIL))" >&2
exit 1
