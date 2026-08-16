# Composed flow

Status: canonical operating guide for Converge 0.2.0.

## Before starting

Use a Git repository, commit the Seamwise recipe, and resolve the exact engines:

```bash
export CVG_TASKSPEC_BIN=/absolute/path/to/task-spec/bin/taskspec
export CVG_SEAMWISE_BIN=/absolute/path/to/seamwise/bin/seamwise
git add recipe.yaml
git commit -m "pin composed delivery recipe"
```

The release pairing is Task-Spec 3.8.0, Seamwise 0.2.0, and Converge
0.2.0. `cvg compose status` is always safe and read-only.

## 1. Prepare

```bash
cvg compose prepare --source recipe.yaml
```

Expected state: `COMPOSE=NEEDS_REVIEW`.

Converge asks Seamwise to initialize, map, and plan. It verifies that prepare
did not emit a TaskPlan. A changed recipe cannot silently replace an existing
mapped source.

## 2. Review

Read `seamwise/delivery-plan.yaml`, the source evidence, every seam owner,
dependency, rollback, and unresolved objection. Then record a real decision:

```bash
cvg compose review \
  --reviewer "repository-owner" \
  --reason "Ownership, topology, dependencies, and rollback paths are accepted."
```

Expected state: `COMPOSE=PREVIEW_READY`.

Review performs no compilation. The reviewer and reason become part of the
hash-bound Seamwise review receipt.

## 3. Preview

```bash
cvg compose preview
```

Expected state: `COMPOSE=PREVIEW_READY`.

Converge asks Seamwise for exactly two projections, verifies their lineage,
then calls `taskspec plan`. No Task-Spec Markdown is written. A missing review,
tampered plan, lineage mismatch, invalid dependency, or contract drift blocks.

## 4. Materialize

```bash
cvg compose materialize
```

Expected state: `COMPOSE=MATERIALIZED`.

Task-Spec is the only engine called to materialize leaves. Converge checks the
exact TaskPlan digest, task IDs, output paths, and bytes before writing its own
composition receipt. Repeating the command is byte-idempotent when the receipt
and tasks are current.

## 5. Authorize each leaf

Materialization is deliberately not authorization:

```bash
grep '^signed_off:' cvg/tasks/T-20260815-health-status.md
taskspec gate --stamp cvg/tasks/T-20260815-health-status.md
```

The first command must show `signed_off: false`. Only the second may create the
Task-Spec authorization seal.

## 6. Bind

```bash
cvg bind --task cvg/tasks/T-20260815-health-status.md
git add cvg/tasks cvg/execution
git commit -m "authorize and bind composed task"
```

Expected gate: `CHECK_RUNTIME_CONTRACT=PASS`. Binding freezes the task revision,
evidence slice, runtime capabilities, and repository write fence.

## 7. Loop

```bash
cvg loop --issue T-20260815-health-status --agent codex
```

The loop never chooses its own work. It executes one assigned task under
iteration, time, token, and path limits. An engine error, timeout, exhausted
budget, or uncommitted out-of-scope write is not success.

## 8. Accept and settle

The loop asks Task-Spec to independently accept the exact handoff and task
revision. Sign-off requires:

```text
TASK_LOOP=LOCAL_SETTLED
ACCEPTED=1
```

`TASK_LOOP=SETTLED` is also valid when external publication is allowed. Model
narration, a green-looking diff, or a Converge composition receipt alone is not
acceptance evidence.

## State and recovery table

| State | Meaning | One safe next action |
|---|---|---|
| `COMPOSE=BLOCKED` | No prepared plan or evidence failed verification | Follow the `NEXT=` action; never bypass the failed contract |
| `COMPOSE=NEEDS_REVIEW` | Delivery plan exists without current human acceptance | Review the plan, then run `cvg compose review` |
| `COMPOSE=PREVIEW_READY` | Review is current; preview or materialization is next | Run the exact `NEXT=` action from status |
| `COMPOSE=MATERIALIZED` | Tasks and receipts re-hash successfully | Run `taskspec gate --stamp` on one intended leaf |
| `COMPOSE=ENGINE_UNAVAILABLE` | Binary, version, JSON, or capabilities are incompatible | Install or select the exact supported engine |

An interrupted materialization may leave the Task-Spec receipt without the
final Converge receipt. Rerun `cvg compose materialize`; Task-Spec proves the
existing bytes are unchanged and Converge completes the final binding.

## JSON automation

```bash
cvg compose status --json
cvg --json compose preview
```

Both forms emit one `ConvergeCLIResult/v1` document and preserve the underlying
exit code. Do not parse prose; branch on `token`, `exit_code`, `changed`, and
`dry_run`.
