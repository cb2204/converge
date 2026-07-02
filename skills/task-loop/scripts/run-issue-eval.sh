#!/usr/bin/env bash
# run-issue-eval.sh — resolve --issue N to its task-spec and run THAT task's own eval.
#
# This is the GATE of Pass 8 (The Loop). It takes ONE issue, finds the matching
# tasks/T-*.md, extracts the Success Criteria eval bodies + the Exit Check, runs
# each in an isolated `set -euo pipefail` subshell, and prints:
#   GREEN  — the Exit Check exited 0 (all evals passed)
#   RED    — the Exit Check exited non-zero (with the failing eval's output)
#
# It never picks the task — --issue N is required and comes from outside.
#
# Usage:
#   bash run-issue-eval.sh --issue <id|slug|path> [--tasks-dir DIR] [--quiet]
#
# Resolution of --issue accepts, in order:
#   1. an exact path to a T-*.md file
#   2. a full task id            (T-20260625-bronze-views)
#   3. a bare slug / tail        (bronze-views  →  T-*-bronze-views.md)
#   4. a tracker ref             (matches linear_ref: / tracker_issue: N)
#
# Delegation: if .claude/skills/task-spec/scripts/run-task-spec.sh exists it is
# reused (it already carries a heredoc-safe eval extractor). Otherwise this
# script extracts and runs the bash blocks directly. Both paths honor the same
# contract: exit 0 ⇒ GREEN, non-zero ⇒ RED.
#
# Exit codes:
#   0 — GREEN  (Exit Check exited 0)
#   1 — RED    (Exit Check exited non-zero)
#   2 — could not resolve / read the issue (a usage or upstream-gap error)
#
# bash-3.2-safe (macOS system bash): no mapfile, no `declare -A`, awk/grep/sed only.

set -euo pipefail

# ----- Resolve this script's dir + the skill root -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- Error helper (mirrors the task-spec skill's ts_die style) -----
err() {
  echo "ERROR: $*" >&2
  exit 2
}

# ----- Args -----
ISSUE=""
TASKS_DIR=""
QUIET=false

while [ $# -gt 0 ]; do
  case "$1" in
    --issue)
      [ $# -ge 2 ] || err "--issue requires a value"
      ISSUE="$2"; shift 2 ;;
    --issue=*)
      ISSUE="${1#--issue=}"; shift ;;
    --tasks-dir)
      [ $# -ge 2 ] || err "--tasks-dir requires a value"
      TASKS_DIR="$2"; shift 2 ;;
    --tasks-dir=*)
      TASKS_DIR="${1#--tasks-dir=}"; shift ;;
    --quiet|-q)
      QUIET=true; shift ;;
    --help|-h)
      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      err "unknown argument: $1 (usage: run-issue-eval.sh --issue <id>)" ;;
  esac
done

# The loop NEVER picks the task — absence of --issue is an error, not triage.
if [ -z "$ISSUE" ]; then
  err "--issue N is required. This loop never picks a task; a human or CI passes the issue. (Choosing which issue to run is the future CI/CD Manager's job.)"
fi

# ----- Locate the repo root + tasks dir -----
GIT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$GIT_ROOT" ]; then
  GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
fi
[ -n "$GIT_ROOT" ] || err "not inside a git repository"

if [ -z "$TASKS_DIR" ]; then
  TASKS_DIR="${TASKSPEC_BACKLOG_DIR:-tasks}"
fi
# Make absolute against the repo root when a bare/relative dir was given.
case "$TASKS_DIR" in
  /*) : ;;
  *)  TASKS_DIR="$GIT_ROOT/$TASKS_DIR" ;;
esac

# ----- Resolve --issue to a task-spec file -----
# Portable, bash-3.2-safe: no arrays required for the happy paths.
resolve_task_file() {
  _issue="$1"

  # (1) exact path to a file
  if [ -f "$_issue" ]; then
    echo "$(cd "$(dirname "$_issue")" && pwd)/$(basename "$_issue")"
    return 0
  fi

  if [ ! -d "$TASKS_DIR" ]; then
    return 1
  fi

  # (2) full id → TASKS_DIR/<id>.md
  if [ -f "$TASKS_DIR/$_issue.md" ]; then
    echo "$TASKS_DIR/$_issue.md"; return 0
  fi
  # id already carrying .md
  if [ -f "$TASKS_DIR/$_issue" ]; then
    echo "$TASKS_DIR/$_issue"; return 0
  fi

  # (3) bare slug / tail → the unique T-*-<slug>.md
  _hit=""
  _count=0
  for _f in "$TASKS_DIR"/T-*"$_issue"*.md; do
    [ -f "$_f" ] || continue
    _hit="$_f"
    _count=$((_count + 1))
  done
  if [ "$_count" -eq 1 ]; then
    echo "$_hit"; return 0
  fi
  if [ "$_count" -gt 1 ]; then
    echo "AMBIGUOUS" >&2
    for _f in "$TASKS_DIR"/T-*"$_issue"*.md; do
      [ -f "$_f" ] && echo "  - $_f" >&2
    done
    return 2
  fi

  # (4) tracker ref → a task whose linear_ref:/tracker_issue: frontmatter matches.
  # Match the value as a whole token so `12` does not match `123`.
  for _f in "$TASKS_DIR"/T-*.md; do
    [ -f "$_f" ] || continue
    _fm="$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$_f")"
    if printf '%s\n' "$_fm" \
      | grep -Eiq "^[[:space:]]*(tracker_issue|linear_ref)[[:space:]]*:[[:space:]]*#?${_issue}([[:space:]]|\$|,|\])"; then
      echo "$_f"; return 0
    fi
  done

  return 1
}

set +e
TASK_FILE="$(resolve_task_file "$ISSUE")"
RESOLVE_RC=$?
set -e

if [ "$RESOLVE_RC" -eq 2 ]; then
  err "issue '$ISSUE' is ambiguous — it matches more than one task-spec (see list above). Pass the full task id."
fi
if [ "$RESOLVE_RC" -ne 0 ] || [ -z "${TASK_FILE:-}" ] || [ ! -f "$TASK_FILE" ]; then
  # Degrade gracefully: say plainly there is no such task-spec, and show what IS here.
  echo "RED"
  echo "issue: $ISSUE"
  echo "reason: could not resolve --issue '$ISSUE' to a task-spec under $TASKS_DIR"
  if [ -d "$TASKS_DIR" ]; then
    _avail="$(ls "$TASKS_DIR"/T-*.md 2>/dev/null | sed "s#^$TASKS_DIR/##;s#\.md\$##" || true)"
    if [ -n "$_avail" ]; then
      echo "available task ids:"
      printf '%s\n' "$_avail" | sed 's/^/  - /'
    else
      echo "note: no tasks/T-*.md files exist yet (upstream Pass 5B has not produced any)."
    fi
  else
    echo "note: tasks dir '$TASKS_DIR' does not exist yet (upstream Pass 5B has not run)."
  fi
  echo "This loop never picks a task — pass an --issue that resolves to a real tasks/T-*.md."
  exit 2
fi

TASK_ID="$(basename "$TASK_FILE" .md)"

# ----- Read a couple of frontmatter facts for the report header -----
fm_value() {
  # $1 = key. Prints the first frontmatter value (trimmed), or empty.
  # `|| true` so a missing key (grep -> 1 under pipefail) is not a failure.
  { awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$TASK_FILE" \
    | grep -Ei "^[[:space:]]*$1[[:space:]]*:" \
    | head -1 \
    | sed -E "s/^[[:space:]]*$1[[:space:]]*:[[:space:]]*//" \
    | sed -E 's/[[:space:]]+$//'; } || true
}

TASK_TITLE="$(fm_value title)"
TASK_SIGNED="$(fm_value signed_off)"

if [ "$QUIET" != true ]; then
  echo "issue:  $ISSUE"
  echo "task:   $TASK_ID"
  [ -n "$TASK_TITLE" ] && echo "title:  $TASK_TITLE"
  echo "spec:   $TASK_FILE"
  echo "----------------------------------------------------------------------"
fi

# A signed_off:false spec is an upstream gap (Pass 5B gate not passed). We still
# RUN the eval (so RED is real), but we surface the warning so the caller knows.
if [ -n "$TASK_SIGNED" ] && printf '%s' "$TASK_SIGNED" | grep -qi '^false'; then
  echo "WARN: this task-spec is signed_off: false — running its eval anyway, but a" >&2
  echo "      PR should not be opened until Pass 5B signs it off." >&2
fi

# ----- Inline eval runner (fallback when run-task-spec.sh is absent) -----
# Extracts the fenced ```bash block from the "## Success Criteria" and
# "## Exit Check" sections, then runs `<success criteria>; <exit check>` in ONE
# isolated `set -euo pipefail` subshell rooted at the repo. Heredoc-aware so eval
# bodies that write fenced fixtures do not trip fence/section detection. Prints
# the subshell output; returns the Exit Check's exit code.
extract_bash_block() {
  # $1 = section header text, lowercased (e.g. "success criteria"); $2 = file
  awk -v want="$1" '
    function strip(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN { in_section=0; in_block=0; hd=""; top_fence=0 }
    {
      line=$0
      lower=tolower(strip(line))
      if (in_block) {
        if (hd != "") { if (strip(line) == hd) { hd="" } ; print line; next }
        if (line ~ /^```$/) { exit }
        if (match(line, /<<-?[ \t]*["'"'"']?[A-Za-z_][A-Za-z0-9_]*["'"'"']?/)) {
          d=substr(line, RSTART, RLENGTH)
          gsub(/^<<-?[ \t]*["'"'"']?/, "", d)
          gsub(/["'"'"']?$/, "", d)
          hd=d
        }
        print line; next
      }
      if (in_section) {
        if (line ~ /^```bash$/) { in_block=1; next }
        if (line ~ /^## /) { exit }
        next
      }
      if (top_fence) { if (line ~ /^```$/) top_fence=0 ; next }
      if (line ~ /^```/) { top_fence=1; next }
      if (lower == "## " want) { in_section=1 }
    }
  ' "$2"
}

run_eval_inline() {
  _file="$1"
  _sc="$(extract_bash_block "success criteria" "$_file")"
  _ec="$(extract_bash_block "exit check" "$_file")"
  if [ -z "$_sc" ]; then
    echo "no bash block found in Success Criteria" >&2
    return 1
  fi
  if [ -z "$_ec" ]; then
    echo "no bash block found in Exit Check" >&2
    return 1
  fi
  _tmp="$(mktemp -d)"
  trap 'rm -rf "$_tmp"' RETURN
  _script="$_tmp/eval.sh"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    printf 'GIT_ROOT="%s"\n' "$GIT_ROOT"
    echo 'export GIT_ROOT'
    printf 'cd "%s" || exit 1\n' "$GIT_ROOT"
    echo "$_sc"
    echo "$_ec"
  } > "$_script"
  # stdin from /dev/null so a body that reads stdin gets EOF, never hangs.
  bash "$_script" < /dev/null
}

# ----- Run the eval -----
RUNNER="$SCRIPT_DIR/../../task-spec/scripts/run-task-spec.sh"

EVAL_OUT=""
EVAL_RC=0

if [ -f "$RUNNER" ]; then
  # Reuse the task-spec runner: it already extracts eval_N() + Exit Check in a
  # heredoc-safe way and runs each under `set -euo pipefail`. Its exit code IS
  # the Exit Check verdict, which is exactly our GREEN/RED gate.
  set +e
  EVAL_OUT="$(bash "$RUNNER" "$TASK_FILE" 2>&1)"
  EVAL_RC=$?
  set -e
else
  # Fallback: no bundled runner — extract and run the bash blocks directly.
  set +e
  EVAL_OUT="$(run_eval_inline "$TASK_FILE")"
  EVAL_RC=$?
  set -e
fi

# ----- Verdict -----
if [ "$EVAL_RC" -eq 0 ]; then
  [ "$QUIET" != true ] && printf '%s\n' "$EVAL_OUT"
  echo "----------------------------------------------------------------------"
  echo "GREEN"
  echo "issue: $ISSUE  task: $TASK_ID"
  echo "The task's own eval (Exit Check) exited 0. This issue has converged."
  exit 0
else
  printf '%s\n' "$EVAL_OUT"
  echo "----------------------------------------------------------------------"
  echo "RED"
  echo "issue: $ISSUE  task: $TASK_ID"
  echo "The task's own eval exited non-zero. Do NOT open a PR."
  echo "Feed the failing output above back to --agent and revise inside touches_paths,"
  echo "or (if the budget is exhausted / it is an upstream gap) emit a blocked-task report:"
  echo "  .claude/skills/task-loop/references/blocked-task-report.md"
  exit 1
fi
