# v0.2.0 release readiness ledger

Status: **Task-Spec and Seamwise are published; Converge hosted gates, merge,
and publication remain**.

This ledger separates implementation, local verification, hosted verification,
and publication. Planned or queued checks are never reported as green.

## Exact release stack

| Repository | Candidate | Local gate | Hosted/publication |
|---|---|---|---|
| Task-Spec | `v3.8.0` at `0e6180cfc3009bd4ef9cf7ab050b463e10d4af91` | `CHECK=READY`, `CONFORMANCE=L2` | Published; Ubuntu/macOS installation green |
| Seamwise | `v0.2.0` at `5a398169c3fefcb65eb1a47c0cb4f967dfdc0515` | `RELEASE=READY`, 111 tests | Published; exact-commit and packaged Ubuntu/macOS gates green; release checksums and clean wheel installation verified |
| Converge | current `feat/e2e` release candidate | `release-check` green; deterministic and authenticated Codex E2E accepted against the published engine commits | PR #13; rerun all hosted checks after the evidence refresh |

## Closed locally

- Seamwise emits only reviewed `TaskPlan/v1` plus digest-bound lineage.
- Seamwise contains no Task-Spec runtime, materializer, or dispatch authority.
- Converge contains no TaskPlan generator or Task-Spec renderer.
- `cvg decompose` delegates to Seamwise and `cvg tasks plan` delegates to Task-Spec.
- Composition receipts retain `dispatch_authorized:false`.
- Converge packaging contains exactly eleven Converge skills.
- Existing Converge `v0.1.0` remains immutable historical evidence.

## Open hard gates

- Obtain all Converge hosted checks on the exact merge commit.
- Tag and publish Converge 0.2.0 with checksums and clean-install proof.

## Scope

The release supports one composed task at a time. Manager fleet scheduling,
production reliability, live tracker operation, and autonomous human decisions
remain explicitly out of scope. Cockpit remains a read-only observer.
