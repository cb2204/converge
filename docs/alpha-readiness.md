# Alpha readiness ledger

Status: **local release candidate complete; publication blocked by hosted infrastructure**.

This ledger separates implemented behavior from publication evidence. It must be
updated from actual gate output; a planned or queued check is never green.

## Exact release candidates

| Repository | Candidate | Local gate | Hosted gate | Publication |
|---|---|---|---|---|
| Task-Spec | `44c23e974b6448cdaf21e7514f297a757154beac` | `CHECK=READY`, `CONFORMANCE=L2` | macOS/Linux jobs failed with zero executed steps | Draft PR #2; not tagged |
| Seamwise | `29a087c63ee97cb07ab4635aaba87ecab48dc2f1` | `RELEASE=READY`, 111 tests | macOS/Linux jobs failed with zero executed steps | Draft PR #1; not tagged |
| Converge | current `feat/e2e` release worktree | full `release-check`, deterministic demo, and authenticated Codex demo green | not yet eligible | not tagged |

The Task-Spec and Seamwise hosted failures occurred in one to two seconds with
`steps: []`. That is consistent with the known GitHub billing/infrastructure
blocker. It is not a repository failure, and it is not release evidence. Once
billing is repaired, Seamwise and Converge also require a scoped
`RELEASE_STACK_READ_TOKEN` because the default job token cannot read sibling
private repositories.

## Closed locally

- Task-Spec 3.8 implements nested workspace, custom backlog and acceptance roots.
- Task-Spec emits deterministic `TaskMaterializationReceipt/v1` and exact reruns are unchanged.
- Seamwise emits only reviewed `TaskPlan/v1` plus digest-bound lineage.
- Seamwise contains no embedded Task Pack, local materializer, or dispatch authority.
- Converge contains exactly eleven skills and no Task-Spec or Seamwise implementation copy.
- `cvg compose` negotiates external engine capabilities and owns only sequencing and receipts.
- Universal `ConvergeCLIResult/v1` covers help, version, agent-context, existing commands, and compose.
- Deterministic compose tests reject missing review, plan tamper, stale task bytes, interrupted receipt finalization, and incompatible engines.
- Composition and Task-Spec materialization receipts both record `dispatch_authorized: false`.
- The 57-form JSON matrix passes 227 real invocations, including both global-flag positions, usage failures, dependency failures, exact exit codes, and state hashes.
- The deterministic composed demo reaches `TASK_LOOP=LOCAL_SETTLED` and `ACCEPTED=1` against the exact candidates.
- The authenticated Codex demo reaches the same terminal tokens; its 20 retained artifacts pass provenance, schema, redaction, and final-snapshot validation.
- The clean package contains 244 files and exactly eleven Converge skills.
- Cockpit passes 40 server/bridge tests, 62 client tests, TypeScript checks, and the production build.
- Documentation links, anchors, code blocks, version consistency, CLI coverage, and the canonical PDF pass locally.
- Existing Converge `v0.1.0` remains untouched and is documented as historical bundled architecture.

## Open hard gates

- Repair GitHub billing so jobs execute real steps.
- Provision a scoped read-only `RELEASE_STACK_READ_TOKEN` for Seamwise and Converge CI, without exposing a personal credential to unrelated workflow steps.
- Merge and tag Task-Spec 3.8.0 from a green exact commit.
- Pin the published Task-Spec commit in Seamwise CI, obtain hosted green, merge, and tag Seamwise 0.2.0-alpha.1.
- Pin both published dependency commits in Converge CI.
- Push `feat/e2e`, open the Converge PR, and wait for Ubuntu, macOS, Cockpit, JSON, docs, package, and composed-E2E checks.
- Merge with a merge commit, tag that exact merge commit, publish checksums, and verify a clean install from the tag.
- Close obsolete Dependabot PRs only after the embedded tree removal is present on the target branch.

## Alpha evidence matrix

| Axis | Required proof | Current status |
|---|---|---|
| Engine ownership | No duplicate implementation or authority | Locally closed |
| Review boundary | Prepare cannot review; review cannot compile | Locally closed |
| Materialization | Task-Spec only; receipt and task hashes validated | Locally closed |
| Authorization | Every leaf remains unsigned until explicit gate stamp | Locally closed |
| Recovery | Exact rerun and interrupted final-receipt recovery | Locally closed |
| JSON | 57 declared forms under one envelope | Locally closed: 227 calls green |
| Install/package | Coordinator, contracts, templates, exactly eleven skills | Locally closed: 244-file package allowlist green |
| Runtime loop | Deterministic RED to GREEN, path policy, acceptance | Locally closed on exact candidates |
| Live executor | Authenticated Codex on exact candidates | Locally closed; [20 canonical artifacts](../evidence/releases/v0.2.0-alpha.1/live-codex/) validated |
| Documentation | Links, anchors, code blocks, Mermaid, current PDF visual QA | Locally closed |
| Hosted portability | macOS and Linux on exact commits | Blocked by GitHub infrastructure |
| Publication | Three tags in dependency order | Open |

## Scope

The alpha promises one composed task at a time. Manager fleet scheduling,
production reliability, live tracker operation, and autonomous human decisions
are explicitly out of scope. Cockpit remains a read-only observer.
