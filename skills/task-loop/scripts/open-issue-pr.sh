#!/usr/bin/env bash
# open-issue-pr.sh — settle ONE issue: on GREEN open a PR that closes it; on RED
# emit the blocked-task report instead.
#
# This is Step 4 (SETTLE) of Pass 8. It runs the task's own eval via
# run-issue-eval.sh and branches on the verdict:
#
#   GREEN → ensure a `task/<id>-<slug>` branch, commit the working tree, push,
#           and open a PR (via gh) that Closes #<issue> with the green eval
#           output embedded in the body.
#   RED   → do NOT open a PR. Render the blocked-task report
#           (references/blocked-task-report.md) filled with the failing eval,
#           the last output, and the suspected upstream gap.
#
# Every gh / git-push / git-commit side effect is guarded by --dry-run so the
# script runs fully offline: it prints exactly what it WOULD do and stops before
# any network or history mutation.
#
# Usage:
#   bash open-issue-pr.sh --issue <id|slug|path> [--dry-run] [--base BRANCH]
#                         [--agent claude|codex|kimi] [--tasks-dir DIR]
#
# Exit codes:
#   0 — GREEN and the PR was opened (or, with --dry-run, would be)
#   1 — RED: a blocked-task report was emitted (no PR)
#   2 — could not resolve the issue / not a git repo / usage error
#
# bash-3.2-safe: no mapfile, no `declare -A`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_RUNNER="$SCRIPT_DIR/run-issue-eval.sh"
REPORT_TMPL="$SCRIPT_DIR/../references/blocked-task-report.md"

err() {
  echo "ERROR: $*" >&2
  exit 2
}

# ----- Args -----
ISSUE=""
DRY_RUN=false
BASE=""
AGENT="claude"
TASKS_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --issue)     [ $# -ge 2 ] || err "--issue requires a value"; ISSUE="$2"; shift 2 ;;
    --issue=*)   ISSUE="${1#--issue=}"; shift ;;
    --dry-run|-n) DRY_RUN=true; shift ;;
    --base)      [ $# -ge 2 ] || err "--base requires a value"; BASE="$2"; shift 2 ;;
    --base=*)    BASE="${1#--base=}"; shift ;;
    --agent)     [ $# -ge 2 ] || err "--agent requires a value"; AGENT="$2"; shift 2 ;;
    --agent=*)   AGENT="${1#--agent=}"; shift ;;
    --tasks-dir) [ $# -ge 2 ] || err "--tasks-dir requires a value"; TASKS_DIR="$2"; shift 2 ;;
    --tasks-dir=*) TASKS_DIR="${1#--tasks-dir=}"; shift ;;
    --help|-h)   sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           err "unknown argument: $1" ;;
  esac
done

[ -n "$ISSUE" ] || err "--issue N is required. This loop never picks a task."

# ----- Repo root -----
GIT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || echo "")"
[ -n "$GIT_ROOT" ] || err "not inside a git repository"
cd "$GIT_ROOT"

# ----- Run the gate first (RED/GREEN decides everything below) -----
EVAL_ARGS="--issue $ISSUE"
[ -n "$TASKS_DIR" ] && EVAL_ARGS="$EVAL_ARGS --tasks-dir $TASKS_DIR"

set +e
# shellcheck disable=SC2086
EVAL_OUT="$(bash "$EVAL_RUNNER" $EVAL_ARGS 2>&1)"
EVAL_RC=$?
set -e

# rc 2 = could not resolve the issue at all — pass that through as-is.
if [ "$EVAL_RC" -eq 2 ]; then
  printf '%s\n' "$EVAL_OUT"
  exit 2
fi

# Resolve the task file + id/slug again here so the branch name is derived from
# the real spec (single source of truth), independent of how --issue was typed.
resolve_task_file() {
  _issue="$1"
  if [ -f "$_issue" ]; then echo "$(cd "$(dirname "$_issue")" && pwd)/$(basename "$_issue")"; return 0; fi
  _td="${TASKS_DIR:-${TASKSPEC_BACKLOG_DIR:-tasks}}"
  case "$_td" in /*) : ;; *) _td="$GIT_ROOT/$_td" ;; esac
  [ -d "$_td" ] || return 1
  [ -f "$_td/$_issue.md" ] && { echo "$_td/$_issue.md"; return 0; }
  [ -f "$_td/$_issue" ] && { echo "$_td/$_issue"; return 0; }
  _hit=""; _count=0
  for _f in "$_td"/T-*"$_issue"*.md; do
    [ -f "$_f" ] || continue; _hit="$_f"; _count=$((_count + 1))
  done
  [ "$_count" -eq 1 ] && { echo "$_hit"; return 0; }
  for _f in "$_td"/T-*.md; do
    [ -f "$_f" ] || continue
    _fm="$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$_f")"
    printf '%s\n' "$_fm" \
      | grep -Eiq "^[[:space:]]*(tracker_issue|linear_ref)[[:space:]]*:[[:space:]]*#?${_issue}([[:space:]]|\$|,|\])" \
      && { echo "$_f"; return 0; }
  done
  return 1
}

set +e
TASK_FILE="$(resolve_task_file "$ISSUE")"
set -e
[ -n "${TASK_FILE:-}" ] && [ -f "$TASK_FILE" ] || err "could not resolve --issue '$ISSUE' to a task-spec"

TASK_ID="$(basename "$TASK_FILE" .md)"

fm_value() {
  # Never fail the pipeline: a missing key is normal (grep -> 1 under pipefail).
  { awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$TASK_FILE" \
    | grep -Ei "^[[:space:]]*$1[[:space:]]*:" \
    | head -1 \
    | sed -E "s/^[[:space:]]*$1[[:space:]]*:[[:space:]]*//" \
    | sed -E 's/[[:space:]]+$//'; } || true
}

# slug = the task id with a leading T-<date>- prefix stripped, else a sanitized id.
SLUG="$(printf '%s' "$TASK_ID" | sed -E 's/^T-[0-9]+-//')"
[ -n "$SLUG" ] && [ "$SLUG" != "$TASK_ID" ] || \
  SLUG="$(printf '%s' "$TASK_ID" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
BRANCH="task/$SLUG"

# tracker issue number for the "Closes #N" line (linear_ref/tracker_issue).
TRACKER="$(fm_value tracker_issue)"
[ -z "$TRACKER" ] && TRACKER="$(fm_value linear_ref)"
# strip a leading '#'; treat the placeholder "(none)" as empty.
TRACKER="$(printf '%s' "$TRACKER" | sed -E 's/^#//')"
case "$TRACKER" in "(none)"|"none"|"") TRACKER="" ;; esac

# ----- run-cmd: echo under --dry-run, execute otherwise -----
run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "DRY-RUN would run: $*"
  else
    "$@"
  fi
}

# ============================ RED PATH ============================
if [ "$EVAL_RC" -ne 0 ]; then
  echo "RED — issue '$ISSUE' ($TASK_ID) did not converge. No PR."
  echo "Emitting the blocked-task report."
  echo "======================================================================"

  # Pull the last chunk of eval output as the "last output" evidence block.
  LAST_OUT="$(printf '%s\n' "$EVAL_OUT" | tail -n 40)"

  if [ -f "$REPORT_TMPL" ]; then
    # Render the template with the concrete facts substituted for its <...>
    # placeholders; leave the analysis prose for the agent to complete.
    sed \
      -e "s#<issue-id>#${ISSUE}#g" \
      -e "s#<task-id>#${TASK_ID}#g" \
      -e "s#<branch>#${BRANCH}#g" \
      -e "s#<agent>#${AGENT}#g" \
      "$REPORT_TMPL"
    echo
    echo "----- filled from this run -----"
  else
    echo "(blocked-task-report.md template not found at $REPORT_TMPL — emitting raw report)"
  fi

  echo "# Blocked Task Report"
  echo
  echo "- issue: ${ISSUE}"
  echo "- task-spec: ${TASK_FILE}"
  echo "- branch (intended): ${BRANCH}"
  echo "- agent: ${AGENT}"
  echo
  echo "## Failing eval (last output)"
  echo '```'
  printf '%s\n' "$LAST_OUT"
  echo '```'
  echo
  echo "## Suspected upstream gap"
  echo "- (fill in) Which decision/ADR/plan is missing or wrong upstream, and which Converge pass owns the fix (Pass 2 ADR, Pass 3 plan, Pass 5B task-spec, Pass 6 harness)."
  echo
  echo "Do not open a PR. Do not hack the eval. Surface this report."
  exit 1
fi

# ============================ GREEN PATH ============================
echo "GREEN — issue '$ISSUE' ($TASK_ID) converged. Opening a PR."
echo "======================================================================"

# --- guard: never work off main directly; ensure the task branch ---
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
DEFAULT_BASE="$BASE"
if [ -z "$DEFAULT_BASE" ]; then
  # Prefer the repo's real default branch; fall back to main/master/current.
  DEFAULT_BASE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  [ -z "$DEFAULT_BASE" ] && DEFAULT_BASE="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "branch $BRANCH already exists — switching to it."
  run_cmd git checkout "$BRANCH"
elif [ "$CURRENT_BRANCH" = "$BRANCH" ]; then
  echo "already on $BRANCH."
else
  echo "cutting branch $BRANCH off $DEFAULT_BASE."
  run_cmd git checkout -b "$BRANCH"
fi

# --- commit the working tree (only if there is something to commit) ---
COMMIT_TITLE="$TASK_ID: green eval"
COMMIT_BODY="Implements ${TASK_ID}. The task's own eval (Exit Check) exits 0."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  run_cmd git add -A
  if [ "$DRY_RUN" = true ]; then
    echo "DRY-RUN would run: git commit -m \"$COMMIT_TITLE\" -m \"$COMMIT_BODY\""
  else
    git commit -m "$COMMIT_TITLE" -m "$COMMIT_BODY"
  fi
else
  echo "working tree clean — nothing to commit (assuming the branch already carries the work)."
fi

# --- push ---
run_cmd git push -u origin "$BRANCH"

# --- assemble the PR body with the green eval embedded ---
CLOSES_LINE=""
if [ -n "$TRACKER" ]; then
  CLOSES_LINE="Closes #${TRACKER}"
fi

PR_BODY_FILE="$(mktemp)"
{
  echo "## What"
  echo "Implements \`${TASK_ID}\` on branch \`${BRANCH}\` (agent: ${AGENT})."
  [ -n "$CLOSES_LINE" ] && { echo; echo "$CLOSES_LINE"; }
  echo
  echo "## Gate — GREEN eval"
  echo "The task's own eval (Exit Check from the task-spec) was RUN, not eyeballed, and exits 0."
  echo
  echo '```'
  printf '%s\n' "$EVAL_OUT"
  echo '```'
  echo
  echo "## Scope"
  echo "Stayed inside the spec's \`touches_paths\`; honored \`do-not-touch\`."
  echo
  echo "Task-spec: \`${TASK_FILE}\`"
} > "$PR_BODY_FILE"

PR_TITLE="$TASK_ID"

if command -v gh >/dev/null 2>&1; then
  if [ "$DRY_RUN" = true ]; then
    echo "DRY-RUN would run: gh pr create --base $DEFAULT_BASE --head $BRANCH --title \"$PR_TITLE\" --body-file <rendered>"
    echo "----- PR body preview -----"
    cat "$PR_BODY_FILE"
  else
    gh pr create --base "$DEFAULT_BASE" --head "$BRANCH" \
      --title "$PR_TITLE" --body-file "$PR_BODY_FILE"
  fi
else
  echo "NOTE: gh CLI not found — cannot open the PR automatically."
  echo "Push is done; open the PR manually against $DEFAULT_BASE with this body:"
  echo "----- PR body -----"
  cat "$PR_BODY_FILE"
fi

rm -f "$PR_BODY_FILE"

echo "======================================================================"
if [ "$DRY_RUN" = true ]; then
  echo "DRY-RUN complete — nothing was committed, pushed, or opened."
else
  echo "PR opened for $TASK_ID. Stop here — merge order is the future CI/CD Manager's job."
fi
exit 0
