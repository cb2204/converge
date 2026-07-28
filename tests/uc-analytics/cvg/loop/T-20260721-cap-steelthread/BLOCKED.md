# Blocked Task Report — T-20260721-cap-steelthread

- **issue:** `T-20260721-cap-steelthread`
- **task-spec:** `T-20260721-cap-steelthread` (`cvg/tasks/T-20260721-cap-steelthread.md`)
- **branch (intended):** `loop/T-20260721-cap-steelthread-75343`
- **agent:** claude (`execution_backend: claude`)
- **verdict:** RED (Exit Check did not exit 0 **under the runner**)
- **iterations used / budget:** 1 of 15

> **The task's deliverable is complete and verified.** All three evals pass, from a
> cold cluster, when run with the CWD the spec's relative paths are written against.
> The RED is produced entirely by the eval **runner's** working directory. No change
> inside `fs.write` scope can fix it. See "Suspected upstream gap".

## Failing eval

- **failing eval id:** `eval_1`, `eval_2`, `eval_3` — all three, each in `0s`
- **what it asserts:** each eval opens with a `test -f cvg/capture/<file>` guard
  (`eval_3` also `grep`s `cvg/capture/pipelines/orders.py`). The runner executes them
  with `cd "$GIT_ROOT"`, where no `cvg/` directory exists, so every eval fails at its
  first line before touching Postgres. `0s` on all three is the signature of that:
  no probe ran, no query was issued.

## Last output

Verbatim, from `skills/task-spec/scripts/run-task-spec.sh` — captured **while the
cluster was fully provisioned and green** (see "Evidence"), which is what proves the
failure is CWD, not missing database state:

```
[fail] eval_1 (0s)
[fail] eval_2 (0s)
[fail] eval_3 (0s)
Exit Check: fail (0s)
```

The same eval bodies, byte-for-byte, with CWD = the workspace (`tests/uc-analytics`),
against a cluster reset to virgin state first (`wal_level=replica`, no capture role,
no `raw` schema, seeded 200 orders):

```
eval_1 (COLD, includes wal_level flip + restart) => 0
eval_2 => 0
eval_3 => 0
EXIT CHECK => 0
```

Only the working directory differs between those two runs:

```
workspace CWD: probe file FOUND
git-root CWD: probe file MISSING (this is the whole failure)
```

## Suspected upstream gap

- [x] **The eval harness is broken** — not the eval *bodies* (they are correct and
      pass), but the runner that chooses their working directory.

Two scripts in the loop disagree about where an eval's relative paths resolve:

| Script | Line | CWD it uses | Correct? |
|---|---|---|---|
| `skills/task-loop/scripts/run-issue-eval.sh` | 124–130, 347 | `WORKSPACE_ROOT` — walks up from `cvg/tasks`, then strips the `cvg` component | ✅ yes |
| `skills/task-spec/scripts/run-task-spec.sh` | 75, 205, 274 | `GIT_ROOT` — `git rev-parse --show-toplevel` | ❌ no |

`run-issue-eval.sh` computes `WORKSPACE_ROOT` correctly **and documents exactly why**
in its own comment (lines 120–123):

> *"The WORKSPACE is the parent of the tasks dir, and it is the only directory an
> eval's relative paths can sensibly be resolved against — a spec that creates
> `cvg/capture/orders.py` means relative to its own workspace, not to whatever repo
> happens to contain it."*

…and then, at line 361, **delegates to `run-task-spec.sh` whenever it exists**, which
discards that correct value and `cd`s to `GIT_ROOT` instead. The correct logic is
present in the repo but never reached. Here `GIT_ROOT` is the worktree root and the
workspace is nested at `tests/uc-analytics/`, so the two differ and every relative
path in the spec misses.

That the write scope is **workspace**-relative is independently confirmed by the
settlement guard: `check-path-policy.py` resolves `fs.write` scope against `--repo`
and its `diff_paths()` comment (lines 37–42) states the scope is "written relative to
the workspace". Invoked without `--repo` from the git root it hard-errors —
`required path does not exist: <git_root>/cvg/tasks/T-20260721-cap-steelthread.md` —
and only passes as `--repo tests/uc-analytics`. So the contract and the runner
disagree about the same root, and the contract's reading is the authoritative one.

### Why this cannot be settled from inside `touches_paths`

The contract's `fs.write` scope is four workspace-relative paths:

```
cvg/capture/principal.sql
cvg/capture/pipelines/orders.py
cvg/capture/probe_commit_to_answer.py
cvg/capture/tests/test_steelthread.py
```

For `test -f cvg/capture/probe_commit_to_answer.py` to succeed with CWD = git root, a
`cvg/capture/` tree must exist **at the git root** — which is outside the sealed scope,
invisible to the settlement guard (`git diff --relative` scopes it away), and would
duplicate product artifacts into the Converge tool repo. The only in-repo fix is one
line in the grader itself, which this task is forbidden to edit. Hence: blocked, not
settled, and no PR.

## Evidence — the deliverable itself is green

Asserted against the cluster (`uc-analytics-postgres`), after a virgin reset, by the
spec's own checks. Nothing in the working tree changed: `git status` is clean, and the
four artifacts were already committed at `f699e1d`.

**B-1** — a real change-record landed off the WAL, in the frozen shape:

```
order_id | _lsn       | _op    | _source_committed_at
205      | 0/1A11F90  | insert | 2026-07-27 20:06:50.468038+00
206      | 0/1A196E8  | insert | 2026-07-27 20:06:51.7302+00
```

Real WAL LSNs from `pg_logical_slot_peek_binary_changes` (pgoutput, decoded in
`pipelines/orders.py`), and `_source_committed_at` read from the pgoutput COMMIT
record — not a wall-clock stand-in. All five contract columns present.

**B-2 / B-3** — the principal and the fence, from `pg_roles`:

```
rolname        | rolreplication | can_read_orders | _control USAGE
capture_reader | t              | t               | f
```

A dedicated principal, distinct from the operational `postgres` app, holding
`REPLICATION` and `SELECT` on `public.orders`, with **no** `USAGE` on `_control`. The
ADR-0001 fence holds in the cluster, not merely by absence from the source;
`grep _control cvg/capture/pipelines/orders.py` also returns nothing.

Cold-start is self-sufficient: the probe flips `wal_level` to `logical`, restarts the
disposable fixture, waits for readiness, applies `principal.sql` idempotently, creates
the publication and logical slot, lands the batch, and only then advances the slot
checkpoint — so replay is possible and no change is consumed before it is durable.

## Which pass owns it

| Suspected gap | Owning pass |
|---|---|
| Eval runner resolves relative paths against `GIT_ROOT` instead of the workspace | **Pass 5** (`task-spec`) — owns `skills/task-spec/scripts/run-task-spec.sh` |

## Next action

Re-open **Pass 5** (`task-spec`) and fix the runner's working directory in
`skills/task-spec/scripts/run-task-spec.sh`: derive the workspace root the way
`run-issue-eval.sh` already does — the parent of the tasks dir, stripping a trailing
`cvg` component — and use it for the `cd` at lines 205 and 274 (the `GIT_ROOT`
assignment at line 75 should stay, since `GIT_ROOT` is also exported to eval bodies).

This is a harness fix, not a spec fix: the spec's relative paths are correct and its
evals assert real database state exactly as intended. Once the runner `cd`s to the
workspace, this task goes green on re-dispatch with no change to any artifact under
`cvg/capture/` — already demonstrated above.

Then re-dispatch `--issue T-20260721-cap-steelthread`. Because the fix lands in the
grader and not in the sealed scope, the existing signature stays valid; no re-sign or
re-bind is required.

### Secondary observation (not the blocker)

The spec's **Why** paragraph ends *"Accepted only on `execution_backend: glm`"*, but
its frontmatter declares `execution_backend: claude` and the loop dispatched this
attempt to claude accordingly. One of the two is stale. Worth reconciling in Pass 5
while the spec is open, so a future dispatch is not routed on a contradiction.
