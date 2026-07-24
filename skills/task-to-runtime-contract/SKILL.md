---
name: task-to-runtime-contract
description: Bind one signed Converge Task-Spec to an enforceable, task-scoped runtime contract. Use for Pass 6 · Bind, before a Manager dispatches a task or task-loop executes it, when the executor needs a hash-bound evidence slice, explicit topology, portable path guards, vendor adapter manifests, pinned documentation, and a deterministic CHECK_RUNTIME_CONTRACT verdict. Replaces the legacy standing-agent-fleet harness workflow; do not use to author Task-Specs, select work across tasks, or execute the task.
metadata:
  version: "1.0.0"
---

# task-to-runtime-contract — Pass 6 · Bind

Turn one signed Task-Spec into the smallest enforceable runtime contract needed
to execute it. The Task-Spec remains canonical; the execution profile records
only derived evidence, net-new topology decisions, hashes, and enforcement
artifacts.

## Boundary

- **Pass 5B owns** behavior, evaluations, write scope, budgets, backend hints,
  and sign-off.
- **Pass 6 owns** evidence binding, initial intra-task topology, pinned context,
  enforcement adapters, and readiness.
- **Pass 7 owns** task selection and concurrency across tasks.
- **Pass 8 owns** one assigned task, its bounded RED/GREEN loop, and one PR or
  blocked report.

Never copy Task-Spec fields into a second competing contract. Point back to
their canonical field names and bind the source file by SHA-256.

## Workflow

### 1. Resolve and verify the task

Require one runnable leaf Task-Spec. Run the existing sign-off gate. Tier 1 is
the default; use `--supervised` only when a human will remain in the execution
loop.

```bash
cvg bind --task tasks/T-YYYYMMDD-example.md
```

Stop on an unsigned task, invalid eval, decomposition node, or failed signature.

### 2. Select the initial topology

Default to `single`. Escalate only for a static reason visible before runtime:

- `single-explorer`: broad read-only discovery would pollute implementation
  context.
- `implementer-verifier`: independent verification is required by risk or
  acceptance policy.
- `parallel`: at least two disjoint write partitions exist.

Every non-single topology requires a concrete justification. Parallel mode also
requires explicit, non-overlapping worker ownership declarations. See
[`references/topology-and-permissions.md`](references/topology-and-permissions.md).

### 3. Bind only the evidence required for this task

The binder automatically includes cited ADR paths. Add project knowledge or
external documentation only when the task needs it:

```bash
cvg bind \
  --task tasks/T-YYYYMMDD-example.md \
  --knowledge cvg/knowledge/failures/postgres-locking.md \
  --doc https://example.dev/v1/reference=cvg/knowledge/references/example-v1.md
```

External documentation must have a local cached copy. The profile records its
URL and content hash so offline and version-pinned execution remain possible.

### 4. Generate and gate

The command writes:

```text
cvg/execution/<task-id>/
├── execution-profile.yaml
└── adapters/
    ├── generic.json
    ├── claude.json
    ├── codex.json
    └── kimi.json
```

`execution-profile.yaml` uses the JSON subset of YAML 1.2 so every consumer can
parse it with a standard JSON parser. Run the gate again at any time:

```bash
cvg bind --check --task tasks/T-YYYYMMDD-example.md
```

The final line is exactly:

```text
CHECK_RUNTIME_CONTRACT=PASS
```

or:

```text
CHECK_RUNTIME_CONTRACT=FAIL
```

### 5. Enforce during execution

Before writes, vendor hooks may pass a candidate path to:

```bash
python3 skills/task-to-runtime-contract/scripts/check-path-policy.py \
  --profile cvg/execution/<task-id>/execution-profile.yaml \
  --candidate path/to/file
```

Before settlement, always run the same guard against the git diff:

```bash
python3 skills/task-to-runtime-contract/scripts/check-path-policy.py \
  --profile cvg/execution/<task-id>/execution-profile.yaml \
  --base origin/main
```

The portable settlement gate is mandatory even when a vendor supplies a
stronger pre-tool hook or sandbox.

### 6. Accrete earned knowledge

Pass 8 writes a structured execution receipt through
`write-execution-receipt.py`. A receipt may then produce a proposed knowledge
candidate:

```bash
python3 skills/task-to-runtime-contract/scripts/propose-knowledge-candidate.py \
  --profile cvg/execution/<task-id>/execution-profile.yaml \
  --receipt cvg/receipts/<task-id>.json \
  --kind failure \
  --summary "The stable, project-specific lesson" \
  --evidence "The exact receipt-backed observation"
```

Candidates remain under `cvg/knowledge/candidates/`. They never become
canonical without owner or reviewer promotion. `pass-to-lesson` remains the
human teaching projection, not the machine-knowledge writer.

## Gate checklist

- The Task-Spec is a signed runnable leaf and its current hash matches.
- Required ADRs, approved knowledge, and cached external docs exist and match
  their recorded hashes.
- A non-single topology has a substantive static justification.
- Parallel write ownership is explicit, in scope, and disjoint.
- Portable guards and all declared adapter manifests exist.
- Generated artifacts contain no unresolved placeholders.
- The final machine token is `CHECK_RUNTIME_CONTRACT=PASS`.

## References

- [`references/runtime-contract.md`](references/runtime-contract.md) — profile
  schema, freshness, and evidence rules.
- [`references/topology-and-permissions.md`](references/topology-and-permissions.md)
  — topology choices, capability classes, and enforcement.
- [`references/vendor-adapters.md`](references/vendor-adapters.md) — portable
  core versus Claude, Codex, and Kimi adapter responsibilities.
- [`references/knowledge-accretion.md`](references/knowledge-accretion.md) —
  candidate and promotion boundary.
