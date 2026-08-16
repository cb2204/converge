# v0.2.0 release readiness ledger

Status: **local implementation in progress; publication gates remain open**.

This ledger separates implementation, local verification, hosted verification,
and publication. Planned or queued checks are never reported as green.

## Exact release stack

| Repository | Candidate | Local gate | Hosted/publication |
|---|---|---|---|
| Task-Spec | `v3.8.0` at `0e6180cfc3009bd4ef9cf7ab050b463e10d4af91` | `CHECK=READY`, `CONFORMANCE=L2` | Published; Ubuntu/macOS installation green |
| Seamwise | `v0.2.0` candidate at `3d144a90be5a35b090599088027e457661784785` | `RELEASE=READY`, 111 tests | PR #1; hosted checks require `RELEASE_STACK_READ_TOKEN` |
| Converge | current `feat/e2e` candidate | release verification pending | PR #13; hosted checks require released Seamwise and the read token |

## Closed locally

- Seamwise emits only reviewed `TaskPlan/v1` plus digest-bound lineage.
- Seamwise contains no Task-Spec runtime, materializer, or dispatch authority.
- Converge contains no TaskPlan generator or Task-Spec renderer.
- `cvg decompose` delegates to Seamwise and `cvg tasks plan` delegates to Task-Spec.
- Composition receipts retain `dispatch_authorized:false`.
- Converge packaging contains exactly eleven Converge skills.
- Existing Converge `v0.1.0` remains immutable historical evidence.

## Open hard gates

- Provision a fine-grained read-only `RELEASE_STACK_READ_TOKEN` for Seamwise and Converge CI.
- Obtain hosted Ubuntu/macOS green on Seamwise PR #1, merge, tag, and publish Seamwise 0.2.0.
- Pin the exact Seamwise merge commit in Converge.
- Regenerate deterministic and authenticated Codex evidence against the stable candidates.
- Obtain all Converge hosted checks on the exact merge commit.
- Tag and publish Converge 0.2.0 with checksums and clean-install proof.

## Scope

The release supports one composed task at a time. Manager fleet scheduling,
production reliability, live tracker operation, and autonomous human decisions
remain explicitly out of scope. Cockpit remains a read-only observer.
