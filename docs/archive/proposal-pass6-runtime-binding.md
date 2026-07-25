# Proposal: Reframe Converge Pass 6 as Runtime Binding

> ⚠️ **HISTORICAL DOCUMENT — read the banner before the body.**
> This proposal is preserved as the record of an *approved decision*, in the
> numbering and vocabulary that were current when it was written. Two things
> have changed since, and the body below was deliberately **not** rewritten:
>
> 1. **Bind is now Pass 7, not Pass 6.** Register (`task-specs-to-issues`)
>    took slot 6 when it was promoted into the numbered chain. Everywhere this
>    document says "Pass 6 · Bind", read **Pass 7 · Bind**; where it says
>    "Pass 7 Manager", read **the Manager — a future CI/CD concern outside the
>    numbered chain**.
> 2. **The fork is gone.** "Fork A integration" is no longer pending — it was
>    *cancelled*. The plan-driven branch and its `plans-to-coherent-spec` skill
>    were deleted in v3.4; a tightly-coupled slice is now an `L` leaf inside the
>    task tree. Pass 4 ends at **the barrier** (the owner's sign-off), not at a
>    route decision.
>
> The canonical, current statement of the method is **[`PLAN.md`](PLAN.md) §✦**
> and **[`readme.md`](readme.md)**. Trust those over this file.

- **Status:** Approved direction; revised after independent Claude Code and Kimi peer review
- **Implementation status:** Working v1 prototype; production hardening, real proving grounds, and the promotion benchmark remain pending (*Fork A integration: cancelled — see banner*)
- **Verification snapshot:** 2026-07-24 — 19/19 disposable runtime-contract regression checks green
- **Pass name:** Pass 6 · Bind
- **Skill name:** `task-to-runtime-contract`
- **Primary artifact:** Execution profile
- **Gate token:** `CHECK_RUNTIME_CONTRACT=PASS|FAIL`

## Executive decision

Replace the current standing agent-and-knowledge-base fleet with a task-to-runtime-contract skill.

The current design creates permanent architect/developer personas and generic KB trees for every selected technology. It was designed to mitigate context pollution, weak role boundaries, and unreliable orchestration. Current frontier runtimes now provide isolated subagents, progressive skill loading, scoped instructions, worktree isolation, model and effort routing, hooks, compaction, sessions, and tracing. These capabilities reduce the value of permanent per-technology personas.

They do not remove the need for a durable control surface. That surface is now:

- One canonical, signed execution unit: a Task-Spec in the current task-driven
  v1 path, or a coherent-spec authorization envelope if the recommended Fork A
  adapter is implemented.
- Minimal task-relevant context with provenance and freshness.
- Explicit permissions and trust boundaries.
- Dependency-aware execution topology.
- Concrete, runtime-enforced guards.
- Ephemeral workers only when justified.
- Deterministic readiness and acceptance gates.
- Structured execution receipts.
- Durable, owner-approved project knowledge earned from completed work.

Pass 6 should bind and prove the runtime contract for one signed task. It should not create a standing fleet for the technology stack.

## Implemented v1 surface

The initial end-to-end prototype now includes:

- `skills/task-to-runtime-contract/` with a concise skill entrypoint, runtime
  contract references, and OpenAI interface metadata.
- `cvg bind --task <spec>` and a `cvg bind --check` verification entrypoint
  intended to become strictly read-only.
- Tier-1 sign-off by default with an explicit supervised Tier-2 migration mode.
- A deterministic JSON-subset-of-YAML execution profile bound to the complete
  Task-Spec hash.
- Automatic ADR discovery plus hashed project-knowledge and cached-document
  inputs.
- Single-agent default, substantive non-single justification, and disjoint
  parallel ownership checks.
- Candidate-path, tool-input, and final-diff enforcement.
- Generic, Claude, Codex, and Kimi adapter manifests.
- Pass 8 fail-closed consumption of the runtime contract.
- Receipt-backed knowledge candidates that remain proposed until human review.
- Legacy non-clobbering emission and strict TODO-content rejection.
- Regression coverage for binding, freshness, topology, path policy, adapters,
  CLI JSON/dry-run behavior, Pass 8 consumption, knowledge accretion, and the
  two legacy safety defects.

The disposable suite currently reports **19/19 runtime-contract checks green**.
That proves the declared v1 flow and its tested negative cases. It does not yet
prove that every execution-critical field is cryptographically sealed, that
`bind --check` is side-effect free, that vendor-native controls are installed,
or that Pass 8 settles work atomically. Those are production-hardening
requirements, not optional refinements.

The fair five-arm benchmark and real Pass 6/Pass 8 proving-ground runs remain
promotion gates. The implementation does not pre-judge their result.

## Placement in Converge

Pass 6 sits after a unit of work has been authorized and before any runtime is
allowed to execute it:

```text
Pass 5B · Tasking
signed Task-Spec + eval + scope + budgets
              │
              ▼
① Register
Task-Spec projected onto one tracker issue
              │
              ▼
Pass 6 · Bind
task-to-runtime-contract
              │
              ├── exact source hash
              ├── required ADRs and evidence
              ├── path and capability policy
              ├── single-agent-first topology
              ├── runtime adapter contract
              └── CHECK_RUNTIME_CONTRACT verdict
              │
              ▼
Pass 7 · Manager
selects which ready unit runs, when, and where
              │
              ▼
Pass 8 · The Loop
branch/worktree → implement → eval → guard → accept → PR or blocked receipt
```

Pass 7 is an orchestration plane rather than another in-session skill. It owns
cross-task selection, dependencies, concurrency, locks, worktrees, and fleet
settlement. Pass 8 remains one assigned unit, one branch, one acceptance
contract, and one PR or blocked report.

## What a real invocation should do

An operator or upstream agent says:

> Bind `T-20260724-build-revenue-model` for execution with Codex.

The Pass 6 skill runs the equivalent of:

```bash
cvg bind \
  --task tasks/T-20260724-build-revenue-model.md
```

For work that genuinely needs approved project knowledge or pinned external
documentation:

```bash
cvg bind \
  --task tasks/T-20260724-build-revenue-model.md \
  --knowledge cvg/knowledge/failures/postgres-locking.md \
  --doc https://example.dev/v1/reference=cvg/knowledge/references/example-v1.md
```

The skill then:

1. Verifies one authorized, runnable execution unit.
2. Binds the exact source revision by SHA-256.
3. Selects only the ADRs, project knowledge, and pinned documentation needed
   for this run.
4. Defaults to one agent and records a more complex topology only when static
   evidence justifies it.
5. Compiles portable enforcement plus the selected runtime adapter.
6. Writes the derived execution artifacts.
7. Re-runs the readiness gate and stops.

The default v1 artifact shape is:

```text
cvg/execution/T-20260724-build-revenue-model/
├── execution-profile.yaml
└── adapters/
    ├── generic.json
    ├── claude.json
    ├── codex.json
    └── kimi.json
```

Successful binding ends with:

```text
CHECK_RUNTIME_CONTRACT=PASS
```

Any stale signature, missing evidence, invalid topology, overlapping ownership,
or unavailable mandatory enforcement ends with:

```text
CHECK_RUNTIME_CONTRACT=FAIL
```

Pass 6 does not pick the next issue, implement code, create permanent
technology personas, or silently expand authority. After Pass 7 assigns the
unit, Pass 8 consumes the current profile:

```bash
task-loop \
  --issue T-20260724-build-revenue-model \
  --agent codex
```

The intended Pass 8 sequence is:

1. Re-verify the signed source and Pass 6 profile.
2. Create the isolated branch or worktree before implementation.
3. Give the selected runtime only the bound evidence and authority.
4. Run the bounded RED/GREEN implementation loop.
5. Require both the task eval and portable path guard to pass.
6. Run clean-checkout post-execution acceptance.
7. Commit only authorized paths.
8. Push and open a PR only when external-write policy and approval permit it.
9. Emit an evidence-grade receipt, or an explicit blocked receipt.
10. Optionally derive a proposed, receipt-backed knowledge candidate for human
    promotion.

In short:

```text
Task-Spec = what is authorized and what done means
Pass 6    = that authority compiled into runtime controls
Pass 8    = work performed and proven under those controls
```

## Fork A convergence gap

The current Converge documentation says Fork A and Fork B both reconverge at
Pass 6. The v1 implementation does not yet make that true:

- Fork B produces signed Task-Specs and registered issues, which
  `task-to-runtime-contract` and `task-loop --issue` consume directly.
- Fork A produces one coherent specification and one end-to-end eval, with no
  Task-Spec backlog and no tracker issue.
- The current binder accepts only `--task <Task-Spec>`, and the current loop is
  issue-oriented.

This is a method-level contract gap, not merely documentation drift. Before the
README claims universal reconvergence, choose and implement one of two models:

1. **Recommended — normalized signed execution unit.** Pass 6 accepts a common
   authorization interface. Fork B adapts a signed Task-Spec; Fork A adapts its
   coherent spec, human sign-off, one end-to-end eval, and whole-system scope.
   The Fork A adapter does not decompose the coherent spec into artificial
   tasks. Both paths then share evidence binding, enforcement, runtime
   readiness, receipts, and acceptance.
2. **Separate execution paths.** Scope `task-to-runtime-contract` and
   `task-loop` explicitly to Fork B and give Fork A a separate coherent-spec
   runner.

The normalized execution-unit model is preferred because it preserves one
Bind-to-Loop control plane while keeping the two trust boundaries distinct.
Until that adapter exists, the honest shipped claim is: **Pass 6 v1 supports
the task-driven Fork B path.**

## Peer-review disposition

Both independent reviews returned `APPROVE_WITH_CHANGES`. Their strongest findings are incorporated as follows:

| Peer-review finding | Final disposition |
|---|---|
| Fix unsafe cross-tool overwrites immediately | Accepted as P0 |
| Reject TODO-heavy scaffolds in strict mode | Accepted as P0 |
| Do not duplicate Task-Spec state in the profile | Accepted |
| Keep Pass 7 Manager and Pass 8 loop boundaries explicit | Accepted |
| Compile concrete enforcement, not advisory YAML alone | Accepted |
| Split preparation-time topology from runtime escalation | Accepted |
| Gate profile substance and freshness | Accepted |
| Add a durable knowledge-accretion path | Accepted |
| Support offline and version-pinned documentation | Accepted |
| Benchmark against a genuinely curated knowledge baseline | Accepted |
| Use exactly three permanent generic roles | Rejected; use capability classes |
| Move all intra-task worker coordination to Pass 7 | Rejected; Pass 7 owns cross-task orchestration |
| Copy all Task-Spec fields into the profile | Rejected |
| Make `pass-to-lesson` the canonical knowledge writer | Rejected; it remains a human-learning projection |
| Rename the skill `task-to-execution-profile` | Rejected; the profile is derived evidence, not the canonical contract |
| Keep the working name `prepare-execution` | Rejected after owner review; it is vague and action-only |
| Rename to `task-to-runtime-contract` and Pass 6 · Bind | Accepted; names the input, transformation, and enforceable outcome |

## Legacy-baseline findings

The legacy Pass 6 implementation audited before this redesign was split between:

- [`skills/agents-kbs-tech-stack/`](skills/agents-kbs-tech-stack/), the scaffolding engine — *retained as legacy; Pass 7 reuses its cross-tool emitter for the harness step.*
- `skills/stack-to-harness/`, the Converge wrapper — ***deleted***, superseded by `task-to-runtime-contract`.

That behavior creates:

- An architect and developer agent for every selected technology.
- Optional technology troubleshooters.
- Three permanent closer agents.
- A multi-file KB tree for every selected technology.
- `.claude/` as the canonical source.
- Derived `AGENTS.md`, Cursor rules, and Copilot instructions.

A disposable end-to-end audit found:

| Check | Result |
|---|---|
| Skill package validation | Both skills structurally valid |
| Technology menu | 22/22 entries valid |
| Emitter shell syntax | Passes `bash -n` |
| One-technology scaffold | 20 files and five agents |
| Unfinished content | 74 `TODO` markers |
| Strict quality gate | Returned `APPROVE` despite unfinished content |
| Hand-edited `AGENTS.md` | Overwritten on the next emission |
| `.proposed` conflict file | Not created |
| Regression suite | None committed for these two skills |
| Real proving-ground Pass 6 | Still open in `cvg-todo.md` |

Two defects were release blockers regardless of whether the redesign proceeded:

1. The skills promise additive, non-clobbering `.proposed` behavior, but [`emit-cross-tool.sh`](skills/agents-kbs-tech-stack/scripts/emit-cross-tool.sh) overwrites existing files.
2. The strict gate validates scaffold shape and tool declarations but can approve an effectively empty KB because it does not reject the generated TODO syntax.

Both defects are corrected in the implemented migration surface and covered by
regression tests.

## Non-negotiable architecture boundaries

### The authorized source remains canonical

In the current task-driven v1 path, the signed Task-Spec continues to own:

- Task identity and authorization.
- HMAC signature and sign-off.
- Goal, behavior, and acceptance criteria.
- `touches_paths`, `creates_paths`, and do-not-touch restrictions.
- Dependencies.
- Required tools.
- Execution backend or agent hint.
- Iteration and execution budgets.
- Retry and circuit-breaker policy.
- Executable evaluations and Exit Check.

Pass 6 must reference this state, not copy it into a competing schema.

If the recommended Fork A adapter is implemented, the coherent specification,
its one end-to-end eval, whole-system scope, and explicit sign-off remain that
path's canonical authorization source. The adapter normalizes the interface
needed by Pass 6; it must not manufacture a fake per-task backlog or duplicate
the coherent spec into a competing Task-Spec.

New author-time constraints such as network policy, external-write permission, approval requirements, and token or cost budgets belong in the Task-Spec schema.

### Pass 6, Pass 7, and Pass 8 remain separate

| Pass | Responsibility |
|---|---|
| **Pass 6 · Bind** | Bind one signed task to its evidence, initial topology, enforcement, knowledge inputs, and readiness gate |
| **Pass 7 · Manager** | Select and dispatch ready tasks, coordinate cross-task concurrency, locks, worktrees, dependencies, budgets, and fleet settlement |
| **Pass 8 · The Loop** | Execute exactly one assigned issue, run its evaluations, and produce one PR or blocked report |

Pass 7 owns concurrency across tasks.

Pass 8 may use context-isolated helpers inside its one assigned task when the Pass 6 profile permits it. All helpers remain inside the same issue boundary, worktree, evaluation contract, branch, and PR. This does not authorize Pass 8 to select or fan out across sibling tasks.

### Instructions are not enforcement

`AGENTS.md` and skills guide judgment. They do not provide a security boundary.

Fragile or safety-critical guarantees must be enforced through:

- Portable guard scripts.
- Worktree, sandbox, or container boundaries.
- Pre-action vendor hooks where supported.
- Post-action diff and path validation.
- Network and external-write controls.
- Machine-readable gate results.
- Required CI re-verification where post-execution proof matters.

## Design principles

### 1. Assume the model is capable

Store only context a capable model cannot reliably infer:

- Project-specific invariants.
- Accepted architectural decisions.
- Domain terminology.
- Schemas and interfaces.
- Proven failure patterns.
- Exact verification commands.
- Permissions and prohibited operations.
- Version-specific or proprietary behavior.

Do not pre-author generic tutorials for Python, React, Spark, dbt, Postgres, or other technologies.

### 2. Default to one agent

Use one strong agent for cohesive work. Multi-agent execution is an escalation mechanism, not the default topology.

Preparation-time reasons to select a more complex initial topology include:

- Independent legs with disjoint ownership.
- Broad discovery that would pollute implementation context.
- Distinct tools or permissions.
- A requirement for independent adversarial verification.
- A required isolated worktree or sandbox.

Runtime signals such as repeated failures, context pressure, or unexpected dependencies belong to Pass 8. Pass 6 records which escalations are allowed, their budgets, and whether they require approval; it does not claim those runtime events have occurred.

### 3. Partition by task and dependency, not technology

Partition work using:

- Task-Spec legs and dependencies.
- Writable-path ownership.
- Interface boundaries.
- Shared-file and shared-state coupling.
- Permission boundaries.
- Verification dependencies.

Technology detection remains useful for documentation retrieval and tool selection. It is not the primary worker boundary.

### 4. Keep the derived artifact thin

The execution profile records only:

- The exact authorized execution-unit revision it prepared.
- Context and knowledge references selected for this run.
- Initial execution topology and justification.
- Enforcement and adapter artifacts generated or selected.
- Pinned external documentation.
- Freshness and provenance.

It does not reproduce the Task-Spec's budgets, permissions, evaluations, behaviors, or sign-off fields.

### 5. Earn durable knowledge

Retire generic TODO-seeded KBs, but preserve reusable project knowledge:

- Version-pinned framework behavior.
- Internal and proprietary conventions.
- Postmortem findings.
- Proven failure patterns.
- Reusable recovery procedures.
- Accepted implementation patterns.
- Pinned external-document snapshots.

Only owner- or reviewer-approved, provenance-backed material becomes canonical project knowledge.

### 6. Keep the core portable

The canonical contract is vendor-neutral:

- Signed Task-Spec.
- Execution profile.
- `AGENTS.md`.
- Portable guards.
- Readiness gate.
- Receipt schema.
- Project knowledge.

Claude, Codex, Kimi, and other runtimes receive derived adapters for hooks, subagent configuration, permission modes, sandboxing, and worktree integration.

## Keep, reframe, and retire

| Current capability | Decision | New framing |
|---|---|---|
| Signed Task-Spec scope | Keep | Canonical authorization and execution contract |
| ADR grounding | Keep | Reference accepted decisions with paths and hashes |
| Project glossary | Keep | Reference canonical terminology without duplication |
| `AGENTS.md` portability | Keep | Universal contextual baseline |
| Nested instruction scopes | Keep | Add only where directories need distinct rules |
| Context isolation | Keep | Ephemeral contexts and worktrees when justified |
| Tool and permission boundaries | Strengthen | Enforce through portable guards and vendor adapters |
| Deterministic gate | Strengthen | Validate substance, freshness, and enforceability |
| Cross-tool support | Reframe | Portable core plus thin vendor adapters |
| Structured delegation | Strengthen | Typed task packets and result receipts |
| Technology detection | Reframe | Documentation retrieval and tool selection |
| Glossary wiring | Keep | Point to `docs/CONTEXT.md`; never duplicate it |
| Human-only setup wizards | Keep | Generate only for required auth, secrets, or console steps |
| Diagnosis | Keep | Runtime capability class, not a permanent tech persona |
| Review, simplify, document | Keep | Invoke as capabilities or skills when required |
| Architect/developer pair per technology | Retire | Configure task-specific capabilities dynamically |
| Permanent technology personas | Retire | Replace with ephemeral runtime configurations |
| Generic technology KB trees | Retire | Use pinned docs plus earned project knowledge |
| Static menu thresholds and missions | Retire | Route from task risk, dependencies, and permissions |
| `.claude/` as canonical | Retire | Vendor directories become derived adapters |
| Manual TODO-population workflow | Retire | An incomplete artifact cannot pass readiness |
| `refresh-doctrine.sh` and numeric persona doctrine | Retire | Replace with Task-Spec policy and gate semantics |
| `validate-menu.sh` | Retire with the technology menu |
| `bootstrap-kb.sh` / `accept-drafts.sh` | Retire | Replace with reviewed knowledge-candidate promotion |
| `detect-code-light.sh` in Pass 6 | Retire | Repository shape belongs to tasking/context discovery |
| “Any commodity agent succeeds” claim | Retire | Replace with measurable readiness and benchmark claims |
| Separate `agents-kbs-tech-stack` engine | Retire | One skill owns the Pass 6 contract |

## Naming decision

### Canonical name: `task-to-runtime-contract`

For the current task-driven rollout, the name states the complete
transformation:

- **Task** — the signed Task-Spec is the canonical v1 input.
- **To** — Pass 6 derives evidence and controls without duplicating the source.
- **Runtime** — the output is consumed by the actual executor, not a standing
  documentation fleet.
- **Contract** — hashes, topology, permissions, guards, adapters, and the gate
  are enforceable obligations.

The pass label is **Bind** because Pass 6 binds a specific signed execution-unit
revision to the exact context and controls under which it may run. It does not
execute the unit, schedule sibling units, or create permanent technology
personas.

`prepare-execution` was rejected because “prepare” does not say what becomes
true or which artifact owns the obligation. `task-to-execution-profile` was
rejected because it over-anchors the skill to a derived evidence file and can
imply that the profile replaces the Task-Spec.

| Concept | Canonical term |
|---|---|
| Pass | Pass 6 · Bind |
| Skill | `task-to-runtime-contract` |
| Primary artifact | Execution profile |
| Successful gate | `CHECK_RUNTIME_CONTRACT=PASS` |
| Failed gate | `CHECK_RUNTIME_CONTRACT=FAIL` |
| Cross-task consumer | Pass 7 · Manager |
| Single-task consumer | Pass 8 · The Loop |

## Runtime-binding skill contract

### Frontmatter

```yaml
---
name: task-to-runtime-contract
description: Bind one signed Converge Task-Spec to an enforceable, task-scoped runtime contract. Use for Pass 6 · Bind, before a Manager dispatches a task or task-loop executes it, when the executor needs a hash-bound evidence slice, explicit topology, portable path guards, vendor adapter manifests, pinned documentation, and a deterministic CHECK_RUNTIME_CONTRACT verdict. Replaces the legacy stack-to-harness workflow; do not use to author Task-Specs, select work across tasks, or execute the task.
---
```

### Inputs

- One signed, runnable Task-Spec.
- Referenced accepted ADRs and system specification.
- Repository instructions and current source tree.
- Project glossary and approved project knowledge.
- Current or cached official documentation when required.
- Runtime capability inventory for the selected execution backend.

An unsigned task, a decomposition-only parent, or a task with unresolved required decisions is not executable input.

Those are the implemented Fork B inputs. A future Fork A adapter must supply
the same normalized authorization properties from the coherent specification,
its single end-to-end eval, whole-system scope, and human sign-off without
converting that path into a per-task backlog.

### Default outputs

```text
<repo>/
├── AGENTS.md
├── <nested>/AGENTS.md                         # only where distinct rules exist
├── cvg/
│   ├── execution/
│   │   └── <task-id>/
│   │       ├── execution-profile.yaml
│   │       └── adapters/                     # runtime translation manifests
│   └── knowledge/
│       ├── failures/
│       ├── patterns/
│       ├── references/
│       └── candidates/
└── <vendor-specific files>                   # derived only when required
```

The profile is committed as Pass 6 evidence. If the referenced Task-Spec hash changes, readiness fails until the profile is regenerated.

Vendor-specific worker definitions may be generated ephemerally at execution time. Their templates and hashes remain traceable from the profile.

### Thin execution-profile example

```json
{
  "schema": "cvg.execution-profile.v1",
  "task": {
    "id": "T-20260724-example",
    "spec_ref": {
      "path": "cvg/tasks/T-20260724-example.md",
      "sha256": "<sha256>"
    },
    "authorization": {
      "signed_off": true,
      "trust_tier": 1,
      "requires_tier1": true
    }
  },
  "context": {
    "required_files": [
      {"kind": "adr", "path": "cvg/docs/adrs/0001-example.md", "sha256": "<sha256>"}
    ],
    "approved_project_knowledge": [],
    "external_docs": []
  },
  "topology": {
    "mode": "single",
    "justification": "Single-agent default; no static topology escalation trigger was selected.",
    "capabilities": ["diagnose", "implement", "verify"],
    "workers": [
      {
        "name": "primary",
        "permission_class": "task-scoped-write",
        "ownership_source": "task_spec"
      }
    ]
  },
  "enforcement": {
    "path_policy_source": "task_spec",
    "portable_postflight_required": true,
    "receipt_writer": "skills/task-to-runtime-contract/scripts/write-execution-receipt.py",
    "adapters": [
      {"runtime": "generic", "path": "cvg/execution/T-20260724-example/adapters/generic.json"}
    ]
  },
  "knowledge": {
    "candidate_output": "cvg/knowledge/candidates/T-20260724-example.md"
  },
  "generated": {
    "by": "task-to-runtime-contract",
    "version": "1.0.0",
    "format": "JSON subset of YAML 1.2"
  }
}
```

The Task-Spec remains the source for paths, budgets, tools, permissions, behavior, evaluations, retry policy, and authorization.

## Capability model

Do not standardize on an exact number of worker personas. Select capability classes and map them to the chosen runtime:

| Capability | Typical permissions | Responsibility |
|---|---|---|
| Discover | Read-only | Locate evidence and map dependencies |
| Diagnose | Read plus diagnostic execution | Reproduce failures and verify hypotheses |
| Implement | Scoped write | Modify authorized paths and run local evaluations |
| Verify | Independent read and evaluation | Challenge claims and test acceptance |
| Integrate | Scoped shared-surface ownership | Reconcile independently produced legs inside one task |
| Document | Documentation-only write | Update required docs and evidence |

Several capabilities may run in one agent. A separate worker is justified only when isolation, permissions, independence, or context pressure makes it materially useful.

## Runtime-binding workflow

### Step 1: Verify authorization

- Locate exactly one runnable Task-Spec.
- Verify HMAC signature and execution authorization.
- Reject unsigned tasks and decomposition-only parents.
- Resolve referenced ADRs and upstream artifacts.
- Verify required Task-Spec policy fields are present.

### Step 2: Compile the evidence slice

Select only:

- The Task-Spec.
- Relevant accepted ADRs.
- Applicable root or nested instructions.
- Project-specific invariants and schemas.
- Approved project knowledge.
- Required pinned or cached external documentation.

Record paths, hashes, versions, retrieval dates, and cache locations.

### Step 3: Select the initial topology

Default to one agent.

Select a more complex topology only when static evidence shows:

- Independent legs with disjoint ownership.
- A separate discovery context is warranted.
- Tools or permissions differ.
- Independent verification is required.
- Isolation is required by risk or policy.

Document a task-specific justification. A generic sentence such as “parallelism is faster” is insufficient.

### Step 4: Bind capability classes

Select only the capabilities the task requires. Map them onto runtime-supported workers, tools, permissions, effort levels, and context slices.

Do not create permanent technology personas.

### Step 5: Generate enforcement

- Build portable path and diff guards.
- Select worktree, sandbox, or container isolation.
- Generate runtime hooks and ephemeral worker definitions when required.
- Declare network and external-write enforcement from the Task-Spec.
- Require approval for authority not already granted.
- Record generated artifact paths and hashes.

### Step 6: Pin external documentation

For every external source:

- Prefer version-specific official documentation.
- Record URL, version, retrieval time, and content hash.
- Cache the required extract for reproducibility.
- Use cached material in offline mode.
- Fail or request direction if required documentation is unavailable and no approved cache exists.

### Step 7: Validate readiness

Run `check-runtime-contract.py`. It must test:

- Task signature and runnable-leaf status.
- Task-Spec hash freshness.
- Existence and hashes of required ADRs, knowledge, and documentation.
- Absence of TODOs and placeholders in emitted artifacts.
- Acceptance-to-verifier coverage by resolving the Task-Spec's validation card.
- Evaluation command resolvability.
- Non-overlapping ownership for parallel legs.
- No contradiction between writable and forbidden paths.
- Presence of enforcement artifacts when policy requires them.
- Non-clobbering behavior for generated cross-tool files.
- Substantive justification for non-single topology.
- Exactly one terminal machine verdict whose exit code agrees with it.

Successful output:

```text
CHECK_RUNTIME_CONTRACT=PASS
```

Failed output:

```text
CHECK_RUNTIME_CONTRACT=FAIL
```

### Step 8: Hand off without crossing pass boundaries

- Pass 6 records readiness and stops.
- Pass 7 selects and dispatches ready tasks, controls cross-task concurrency, and settles the fleet.
- Pass 8 executes one assigned task and may instantiate only the intra-task helpers allowed by its profile.
- Pass 8 produces one PR or one blocked report plus an execution receipt.

### Step 9: Accrete knowledge after execution

An execution receipt may produce a proposed knowledge candidate containing:

- A proven failure pattern.
- A version-specific gotcha.
- A reusable recovery command.
- An accepted implementation pattern.
- A pinned internal or external reference.

Candidates are not canonical automatically. An owner or designated reviewer approves promotion into `cvg/knowledge/`.

`pass-to-lesson` remains an optional human-learning projection of the completed pass. It does not write canonical agent knowledge or authorize downstream changes.

## Portability contract

| Surface | Portable core | Vendor adapter |
|---|---|---|
| Task authorization | Signed Task-Spec and HMAC verification | None |
| Context | Profile references, hashes, cached docs | Runtime-specific context injection |
| Instructions | `AGENTS.md` baseline | `CLAUDE.md`, Cursor, Copilot, or runtime-specific extension |
| Path enforcement | Portable preflight/postflight guards | Pre-tool hooks or sandbox policy |
| Workers | Capability and ownership contract | Claude subagents, Codex subagents, Kimi worker modes |
| Isolation | Git worktree or container fallback | Native worktree/sandbox integration |
| Gate | `check-runtime-contract.py` | Optional CI/status-check adapter |
| Receipts | Portable receipt schema | Runtime trace links and provider metadata |

No adapter may weaken a portable gate silently. Unsupported enforcement must fail closed or request explicit approval.

## Implemented skill contents

Initial version:

```text
skills/task-to-runtime-contract/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── scripts/
│   ├── bind-runtime-contract.py
│   ├── check-runtime-contract.py
│   ├── check-path-policy.py
│   ├── guard-tool-input.py
│   ├── write-execution-receipt.py
│   └── propose-knowledge-candidate.py
└── references/
    ├── runtime-contract.md
    ├── topology-and-permissions.md
    ├── vendor-adapters.md
    └── knowledge-accretion.md
```

The implementation uses a deterministic **binder**, not a second schema
compiler. It verifies the canonical Task-Spec, derives hashes and net-new
topology state, emits the thin JSON-subset-of-YAML profile, and immediately
runs the runtime-contract gate. It never rewrites or reproduces the Task-Spec.

Do not include:

- Technology tutorials.
- Permanent agent prompts.
- A technology menu.
- Architect/developer templates.
- User-facing README or changelog files inside the skill.

## Production-hardening plan

The next implementation pass must close the following work packages before
production sign-off.

### Work package 1: Seal the complete execution authorization

The current HMAC payload covers the task ID, body digest, and sign-off metadata.
Execution-critical frontmatter is not comprehensively covered. A signed task
can therefore retain a valid Tier-1 signature while fields such as write scope,
dependencies, network requirements, budgets, or backend routing change.

Required changes:

- Define a canonical serialization of all authorization-relevant Task-Spec
  fields, or sign the complete canonical Task-Spec excluding only explicitly
  mutable receipt/tracker fields.
- Include paths, dependencies, policy, budgets, routing, eval ownership, and
  sign-off in that boundary.
- Prevent a mutable execution profile from lowering `requires_tier1`.
- Make the execution profile deterministically derivable and freshness-bound;
  optionally attest the emitted profile when the runtime needs independent
  transport integrity.
- Add adversarial tests for scope widening, dependency changes, trust-tier
  downgrade, profile tampering, and stale evidence.

### Work package 2: Make readiness verification genuinely pure

`cvg bind --check` is documented as read-only, but its current sign-off path
calls the executable delegation gate. That gate runs task evals and may touch
repository state such as the Task-Spec state index. Read-only verification
must not depend on potentially mutating project commands.

Required changes:

- Split structural/signature verification from executable eval probing.
- Make `cvg bind --check` perform zero repository writes and no untrusted
  project execution.
- Put executable preflight in a disposable worktree, sandbox, or container with
  network denied by default.
- Add a regression that hashes the repository before and after `bind --check`
  and proves byte-for-byte stability outside permitted temporary locations.

### Work package 3: Install enforceable runtime adapters

The current adapter JSON files describe expected controls. They do not prove
that a vendor configuration, hook, sandbox, or permission boundary was
installed. `guard-tool-input.py` can inspect known path fields but does not
mediate arbitrary shell side effects.

Required changes:

- Generate or install the selected runtime adapter instead of optimistically
  emitting every manifest.
- Implement concrete Claude, Codex, Kimi, and portable-runner adapter paths.
- Add `cvg doctor runtime-contract` to attest the capabilities actually
  available in the selected runtime.
- Mediate direct file writes, shell redirection, destructive commands, symlink
  and traversal escapes, network use, secrets access, and external writes.
- Keep the final diff guard mandatory even when a stronger native hook exists.
- Fail closed when the runtime cannot satisfy a required control.

### Work package 4: Make Pass 8 settlement atomic and policy-consistent

The current settlement script evaluates and writes a receipt before it creates
the task branch, then stages the entire working tree with `git add -A`, pushes,
and opens a PR. The profile simultaneously declares external writes denied by
default. This ordering and policy contradiction must be removed.

Required changes:

- Create the task branch or isolated worktree before dispatch and before any
  implementation writes.
- Execute through the selected, doctor-verified runtime adapter.
- Run the bounded RED/GREEN loop inside that isolation boundary.
- Run the portable path guard over the complete diff.
- Run `accept-task.sh --gold-sanity` from a clean checkout before settlement.
- Stage only the exact authorized paths; never use `git add -A`.
- Treat commit, push, tracker mutation, and PR creation as separate external
  effects governed by explicit policy and approval.
- Write the success receipt only after the commit and PR outcome are known.
- On any failure, write a blocked receipt without claiming settlement.

### Work package 5: Upgrade receipts and earned knowledge

The v1 receipt proves the basic link among task, profile, eval-output hash,
path-policy verdict, runtime label, and branch. Production evidence requires a
fuller trace.

Receipt v2 should include:

- Base commit, final commit, and diff hash.
- Exact eval command, exit status, duration, and durable raw-log reference.
- Acceptance and gold-sanity verdicts.
- Runtime, model, version, effort, and adapter identity.
- Hook, sandbox, network, secret, and path-policy decisions.
- Approval and external-write events.
- Iterations, retries, context size, tokens, cost, and wall-clock time when
  available.
- Branch, push, tracker, and PR results.
- Blocking reason and last proven state when execution does not settle.

Receipt writes must be atomic and safe under concurrent execution. Only a valid
receipt may seed a knowledge candidate, and promotion must remain a distinct
human or policy-controlled action.

### Work package 6: Prove promotion on real work

Required evidence:

- Unit, regression, adversarial, and negative-policy tests.
- Task-Spec signature and portability suites.
- Skill structure validation.
- Bash 3.2 compatibility for declared portable shell paths.
- One genuine Pass 6 proving-ground receipt.
- One genuine Pass 8 branch-to-PR or branch-to-blocked receipt.
- The fair five-arm benchmark, including a genuinely curated KB baseline.
- Honest README, tracker, and proposal status derived from those results.

Production-ready Pass 6 does not by itself make the entire Converge automation
plane production-ready. The wider method still requires the real Pass 7
Manager, runtime worker dispatch, CI re-verification, independent acceptance,
provenance defenses, and operational metrics.

## Recommended implementation and release sequence

Implement in reviewable commits:

1. `task-spec: seal execution authorization fields`
2. `cvg: make runtime binding checks pure`
3. `runtime-contract: enforce runtime adapters`
4. `task-loop: make execution settlement atomic`
5. `runtime-contract: add evidence receipts and adversarial tests`
6. `docs: reconcile Pass 6 and live implementation status`

The documentation session should finish and push first. After that:

1. Refresh the local checkout from the exact pushed commit.
2. Verify branch, upstream, status, and the documentation diff.
3. Create `feat/runtime-contract-v2` from that stable baseline.
4. Preserve unrelated files and stage only an explicitly reviewed path list.
5. Run the complete test and proving-ground sequence.
6. Push the feature branch and open a PR only with explicit authorization.
7. Request separate approval before a potentially expensive multi-model
   benchmark.

Do not use `git add -A`, do not bundle unrelated documentation or deleted
artifacts, and do not claim the implementation was pushed until the remote
branch and PR are verified.

## Migration and promotion status

### Phase 0: Fix the live safety defects — implemented

- Implement non-clobbering `.proposed` behavior in `emit-cross-tool.sh`.
- Add regression coverage for AGENTS, Cursor, and Copilot outputs.
- Expand placeholder detection to include `TODO`, `<!-- TODO -->`, and template stub tokens.
- Make strict mode reject an ungrounded KB.
- Correct the “10 curated techs” documentation drift.

These fixes are required even if the legacy system is later retired.

### Phase 1: Stabilize the canonical contract — v1 implemented; authorization v2 pending

- Keep current author-time policy in Task-Spec, including
  `requires.network`; add future policy fields there only when a real consumer
  requires them.
- Define the thin execution-profile schema.
- Define the portable enforcement and adapter interfaces.
- Define the knowledge-candidate approval contract.
- Update the documented Pass 6, Pass 7, and Pass 8 boundaries.
- Expand the HMAC boundary over all execution authorization before production
  promotion.

### Phase 2: Prove the profile on disposable signed tasks — implemented for v1

Exercise:

1. One cohesive task that should remain single-agent.
2. One task requiring read-only discovery or independent verification.
3. One task with truly independent, low-coupling execution legs.

The regression suite covers the cohesive single-agent path, rejects weak or
overlapping multi-agent profiles, and accepts a disjoint parallel contract.

### Phase 3: Implement `task-to-runtime-contract` — working v1 prototype

- Create the concise SKILL.md.
- Implement `bind-runtime-contract.py` and `check-runtime-contract.py`.
- Implement portable path and diff guards.
- Implement the smallest required runtime adapters.
- Validate all scripts on disposable fixtures.
- Forward-test the skill on fresh tasks without leaking the expected topology.

Adapter manifests and portable path guards exist. Production promotion still
requires runtime installation/attestation, shell and external-effect
enforcement, and the Fork A execution-unit adapter.

### Phase 4: Integrate execution while preserving management — v1 integration implemented; settlement hardening pending

- Teach `task-loop` to require the execution profile instead of the legacy `.claude/` KB harness.
- Preserve `task-loop`'s one-issue invariant.
- Permit only bounded intra-task helpers declared or allowed by the profile.
- Keep issue selection, cross-task concurrency, and fleet settlement in Pass 7.
- Preserve runtime traces outside the coordinator context and return typed receipts.

Pass 8 currently consumes the profile and enforces a final path-policy gate.
Production promotion still requires branch/worktree creation before execution,
clean-checkout acceptance, scoped staging, approval-aware external effects, and
receipt emission after settlement.

### Phase 5: Establish knowledge accretion — candidate seam implemented; receipt v2 pending

- Define `cvg/knowledge/` schemas and provenance requirements.
- Generate proposed knowledge candidates from receipts.
- Require owner or reviewer promotion.
- Feed only approved knowledge into future Pass 6 context selection.
- Keep human lessons and canonical machine knowledge as separate projections.

The v1 candidate boundary is correct. Production promotion still requires the
evidence-grade receipt schema, atomic concurrent writes, and a deterministic
promotion policy.

### Phase 6: Run a fair benchmark — pending promotion gate

Benchmark the same representative signed Task-Specs under:

1. Frontier model with repository instructions only.
2. Frontier model plus thin execution profile.
3. Adaptive profile with selective helpers.
4. Current legacy scaffold as it actually exists.
5. A genuinely curated project-knowledge or populated-KB baseline representing the strongest legacy counterfactual.

Pre-register the success thresholds before running the benchmark. Measure:

- First-pass acceptance rate.
- Evaluation retries.
- Token and monetary cost.
- Wall-clock time.
- Context loaded.
- Coordination and merge conflicts.
- Unsupported-claim rate.
- Stale-context defects.
- Permission violations.
- Gate escapes.
- Knowledge reuse across later tasks.

Promote the replacement only when it is non-inferior on acceptance, materially better on cost or safety, and produces no new blocker-class gate escapes.

## Acceptance criteria

The redesign is ready for production promotion when:

- The originating signed execution unit is the only canonical authorization
  and acceptance contract; the profile never competes with it.
- Every execution-authorizing field is inside the cryptographic integrity
  boundary.
- The execution profile contains only derived, consumed fields.
- Profile freshness is bound to the Task-Spec hash.
- A mutable profile cannot downgrade the required trust tier.
- `cvg bind --check` is proven side-effect free.
- Pass 6, Pass 7, and Pass 8 ownership is unambiguous.
- Single-agent execution is the default.
- Preparation-time topology and runtime escalation are distinct.
- Permissions are enforced, not merely documented.
- The selected runtime is capability-attested and fails closed when it cannot
  honor a required control.
- Portable guards and vendor adapters have an explicit relationship.
- External-write policy agrees with commit, push, tracker, and PR behavior.
- Pass 8 creates isolation before implementation, stages only authorized paths,
  and runs clean-checkout acceptance before settlement.
- Success receipts are written only after the final commit and PR outcome are
  known.
- Receipt v2 captures sufficient provenance to reproduce and audit the run.
- Version-pinned and offline documentation paths are supported.
- Durable knowledge is earned, provenance-backed, and review-approved.
- Human lessons are not confused with canonical machine knowledge.
- No empty or placeholder artifact can pass readiness.
- Generated cross-tool files cannot clobber user-authored instructions.
- Fork A either has a real normalized execution-unit adapter or is explicitly
  excluded from this Bind-to-Loop path.
- At least one real Pass 6 and one real Pass 8 proving-ground execution have
  produced inspectable evidence.
- The benchmark includes a populated, best-case knowledge baseline.
- Promotion thresholds are declared before the benchmark.

## Resolved v1 design decisions

1. The profile stores only hashes, selected evidence, topology, adapter
   references, receipt paths, and knowledge-candidate paths.
2. The portable baseline is candidate-path checking where the runtime supports
   it plus a mandatory git-diff guard before settlement.
3. Existing Task-Spec fields remain canonical; `requires.network` supplies the
   current network posture. External writes default to deny, so commit, push,
   tracker mutation, and PR behavior must be brought under explicit policy
   before production promotion.
4. Knowledge candidates are receipt-backed Markdown with status `proposed`;
   only a human review promotes them.
5. The first adapter matrix covers generic, Claude, Codex, and Kimi runtimes.
6. Benchmark sample size and the pre-registered non-inferiority margin remain
   empirical rollout decisions, not implementation guesses.

## Research basis

The proposal is consistent with current agent-runtime capabilities and research on selective orchestration:

- [Codex subagents](https://developers.openai.com/codex/subagents)
- [Codex skills](https://developers.openai.com/codex/build-skills)
- [Codex AGENTS.md guidance](https://developers.openai.com/codex/agent-configuration/agents-md)
- [Claude Code subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks-guide)
- [OpenAI Agents SDK agents](https://openai.github.io/openai-agents-python/agents/)
- [OpenAI Agents SDK tools](https://openai.github.io/openai-agents-python/tools/)
