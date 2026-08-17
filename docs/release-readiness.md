# v0.2.0 release readiness ledger

Status: **The three-repository release stack is finalized. Converge publication
is owned by the immutable `v0.2.0` tag workflow.**

This ledger separates implementation, local verification, hosted verification,
and publication. Planned or queued checks are never reported as green.

## Exact release stack

| Repository | Candidate | Local gate | Hosted/publication |
|---|---|---|---|
| Task-Spec | `v3.8.0` at `0e6180cfc3009bd4ef9cf7ab050b463e10d4af91` | `CHECK=READY`, `CONFORMANCE=L2` | Published; Ubuntu/macOS installation green |
| Seamwise | `v0.2.0` at `5a398169c3fefcb65eb1a47c0cb4f967dfdc0515` | `RELEASE=READY`, 111 tests | Published; exact-commit and packaged Ubuntu/macOS gates green; release checksums and clean wheel installation verified |
| Converge | `v0.2.0`; release work merged through PRs #13–#15 | `release-check` green; deterministic and authenticated Codex E2E accepted against the published engine commits | Exact feature SHA `1fa054546b5678838af21969816b94f8dab4ed1b` passed all eight push jobs in run `32048296517`; PR #15 merged as `a430b6b9761c4334f372cb0af0493eae22fbb76f` |

## Closed locally

- Seamwise emits only reviewed `TaskPlan/v1` plus digest-bound lineage.
- Seamwise contains no Task-Spec runtime, materializer, or dispatch authority.
- Converge contains no TaskPlan generator or Task-Spec renderer.
- `cvg decompose` delegates to Seamwise and `cvg tasks plan` delegates to Task-Spec.
- Composition receipts retain `dispatch_authorized:false`.
- Converge packaging contains exactly eleven Converge skills.
- Existing Converge `v0.1.0` remains immutable historical evidence.

## Publication policy

- The owner accepted the exact-SHA hosted evidence and waived a redundant
  pre-tag CI run on 2026-08-17. Zero-step PR jobs were treated as runner
  infrastructure, not repository failures.
- Pushing `v0.2.0` still invokes the release workflow. Publication occurs only
  after its Ubuntu/macOS verification, asset build, checksums, and clean package
  boundary succeed.

## Scope

The release supports one composed task at a time. Manager fleet scheduling,
production reliability, live tracker operation, and autonomous human decisions
remain explicitly out of scope. Cockpit remains a read-only observer.
