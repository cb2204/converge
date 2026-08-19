<div align="center">

<img src="assets/lockup-hero.png" alt="CONVERGE — Coordinate intent, decomposition, task authority, execution, and settlement without duplicating authority." width="100%">

# Converge

**Coordinate intent, decomposition, task authority, execution, and settlement without duplicating authority.**

[![ci](https://github.com/luanmorenommaciel/converge/actions/workflows/ci.yml/badge.svg)](https://github.com/luanmorenommaciel/converge/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/luanmorenommaciel/converge)](https://github.com/luanmorenommaciel/converge/releases)
[![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](#requirements)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Converge 0.2.0 | cvg 0.2.0 | Seamwise 0.2.0 | Task-Spec 3.8.0

[Owns](#what-converge-owns) · [Skills](#why-the-skills-exist) · [Descent](#descent) · [Chat](#chat-experience) · [CLI](#cli) · [Install](#install) · [Docs](#documentation)

</div>

## What Converge owns

Converge is the thin coordinator and assurance layer around two independent
engines. It calls their public binaries. It does not import, vendor, or copy
their implementations.

```mermaid
flowchart LR
    I["Reviewed delivery intent"] --> S["Seamwise 0.2"]
    S --> R{"Human accepts topology"}
    R --> P["TaskPlan/v1 + lineage"]
    P --> T["Task-Spec 3.8"]
    T --> M["Unsigned Task-Spec Markdown"]
    M --> A["taskspec gate --stamp"]
    A --> B["Converge runtime bind"]
    B --> L["Bounded task loop"]
    L --> X["Independent Task-Spec acceptance"]
    X --> Z["Settlement + composition evidence"]

    classDef design fill:#111720,stroke:#F5F2EA,color:#F5F2EA,stroke-width:1.5px;
    classDef proof fill:#111720,stroke:#F3B64C,color:#F5F2EA,stroke-width:1.5px;
    class I,S,P,T,M,A,B,L,X,Z design;
    class R proof;
```

![Converge authority: Seamwise then Task-Spec then bind and loop](assets/converge-authority.png)

| System | Sole authority |
|---|---|
| Seamwise | Evidence-backed seams, swimlanes, capability legs, reviewed decomposition, `TaskPlan/v1`, and lineage |
| Task-Spec | TaskPlan validation, materialization, Task-Spec structure, authorization, handoff, evals, and acceptance |
| Converge | Cross-engine sequencing, executable binding, bounded execution, settlement, and composition receipts |
| Human reviewer | Acceptance of Seamwise topology and explicit risk decisions |
| Executor | Product-code changes inside the authorized runtime contract; never self-acceptance |

Duplicate capability is tolerable. Duplicate authority is not. A Seamwise
review does not authorize task dispatch, a Task-Spec materialization receipt
does not sign a task, and model narration is never settlement evidence. The
full non-authority table is in [docs/concepts/authority.md](docs/concepts/authority.md).

## Why the skills exist

The CLI is the referee. Skills exist so a chat agent finds the next pass without reading the whole method. The installer projects **exactly eleven** Converge skills to `.agents/skills/`, `.claude/skills/`, and `.grok/skills/`. Pass 5 Tasking is standalone [`taskspec`](https://github.com/luanmorenommaciel/task-spec), not a mirrored skill.

| Pass # | Skill | Why it exists | When / not | Gate / proof | Optional? |
|:--:|---|---|---|---|:--:|
| 0 | [`idea-to-brd`](skills/idea-to-brd/) | Turn a raw idea into a BRD in the owner's voice, or record a no-go | When: "capture this idea", "write the brief", "start pass 0". Not: BRD exists (Pass 1), writing a tech-spec (Pass 1) | `CHECK_BRD=PASS` | ✓ |
| 1 | [`brd-docs-to-tech-req`](skills/brd-docs-to-tech-req/) | Transform a client BRD into a verifiable tech-spec with falsifiable requirements | When: brief landed, "turn this into a tech-spec", "start pass 1". Not: architecture decisions (Pass 3), no BRD (Pass 0) | `CHECK_TECH_SPEC=PASS` | |
| 2 | [`tech-req-to-adrs`](skills/tech-req-to-adrs/) | Ground the spec against the real system and record grounding decisions as ADRs | When: "structure pass", "write the ADRs", "ground the spec". Not: solution design or "build X" (Pass 3) | `CHECK_ADR=OK` | |
| 3 | [`reqs-to-swimlane-plans`](skills/reqs-to-swimlane-plans/) | Split the system into one sketch plan per swimlane along its natural seams | When: "decompose", "swimlane plans", "split into plans". Not: atomic tasks or implementation code (Pass 5) | `CHECK_PLAN=OK` | |
| 4 | [`sketch-plans-adversarial-review`](skills/sketch-plans-adversarial-review/) | Run plans through a different-family model as adversary; end at THE BARRIER | When: "adversarial review", "attack the plans", "consensus pass". Not: writing new plans (Pass 3), cutting tasks (Pass 5) | `CHECK_CONSENSUS=OK` | |
| 5 | standalone [`taskspec`](https://github.com/luanmorenommaciel/task-spec) | Turn accepted legs into atomic, vendor-neutral units with runnable evals | Use Task-Spec CLI directly; Converge consumes the external CLI, not a mirrored skill | `TIER=1` | |
| 6 | [`task-specs-to-issues`](skills/task-specs-to-issues/) | Project signed Task-Specs onto tracker issues with `blocked-by` links | When: "register the tasks", "push to Linear/GitHub". Not: skip to keep queue repo-local | `CHECK_REGISTER` | ✓ |
| 7 | [`task-to-runtime-contract`](skills/task-to-runtime-contract/) | Bind one signed Task-Spec to an enforceable runtime contract and emit task brief | When: Pass 7 · Bind before task-loop. Not: authoring specs, selecting work, executing | `CHECK_RUNTIME_CONTRACT=PASS` | |
| 8 | [`task-loop`](skills/task-loop/) | Take ONE issue, run its eval in a bounded loop until GREEN, open a PR | When: "run issue N", "execute this task". Not: picking which task (Manager) | `TASK_LOOP=SETTLED` | |
| util | [`evidence-to-next-pass`](skills/evidence-to-next-pass/) | Derive where the descent stands from workspace evidence; hand agent the right pass prompt | When: "what's next", "where are we", before steering any pass. Not: waiving gates | `NEXT_PASS=<N>` | |
| util | [`pass-to-lesson`](skills/pass-to-lesson/) | After any closed pass, teach the owner what was built and why | When: "teach me what was built", "explain this pass". Not: running a pass, attacking artifacts | `CHECK_LESSON=PASS` | ✓ |
| util | [`skill-creator`](skills/skill-creator/) | Author, evaluate, package, and structurally validate agent skills | When: creating or improving skills | Validated skill package | |

`cvg verify` belongs to the **Pass 8 runtime story** even though packaged under `task-to-runtime-contract`: it consumes the bound spec and diff, then asks a different-family judge to attack held-out criteria before settlement.

`cvg lane` chooses `FAST`/`NORMAL`/`FULL` and **never waives a gate**.

Deep essays on each pass stay in [skills/README.md](skills/README.md).

## Descent

The method has **two phases with one barrier between them**. Consensus (Pass 4) is the last human sign-off before the machine takes over.

```mermaid
flowchart TB
  START(["Idea, request, or existing BRD"])
  BARRIER{{"THE BARRIER<br/>owner signs off the hardened plans"}}
  STOP["Explicit handoff<br/>BLOCKED · STALLED · EXHAUSTED · CANCELLED · ERROR"]
  DONE(["Settlement evidence<br/>green change ready for human PR review"])

  subgraph DESIGN["PHASE 1 · DESIGN — human-led · make intent precise"]
    direction TB
    P0["0 · CAPTURE · optional<br/>idea-to-brd<br/>frontier questions + do-nothing test<br/>OUT: BRD or no-go · GATE: CHECK_BRD"]
    NOGO(["Durable no-go record<br/>the idea stops honestly"])
    P1["1 · INTENT<br/>brd-docs-to-tech-req<br/>understand → interrogate → crystallize<br/>OUT: falsifiable tech-spec · GATE: CHECK_TECH_SPEC"]
    P2["2 · STRUCTURE<br/>tech-req-to-adrs<br/>ground the spec against the real system<br/>OUT: ADRs + CONTEXT glossary · GATE: CHECK_ADR"]
    P3["3 · DECOMPOSE<br/>reqs-to-swimlane-plans<br/>seam → swimlane → leg<br/>OUT: swimlane tree · GATE: CHECK_PLAN"]
    P4["4 · CONSENSUS<br/>sketch-plans-adversarial-review<br/>cross-family refutation + objection resolution<br/>OUT: hardened plans + log · GATE: CHECK_CONSENSUS"]
  end

  subgraph BUILD["PHASE 2 · BUILD — machine-led · turn agreement into evidence"]
    direction TB
    P5["5 · TASKING<br/>task-spec<br/>leg → atomic task + runnable evals<br/>OUT: sealed Task-Spec DAG · GATE: TIER=1"]
    P6["6 · REGISTER · opt-in<br/>task-specs-to-issues<br/>idempotent 1:1 tracker projection<br/>OUT: issues + blocked-by graph · GATE: CHECK_REGISTER"]
    P7["7 · BIND<br/>task-to-runtime-contract<br/>7A enforceable contract + 7B worker brief<br/>OUT: profile + guards + adapters · GATE: CHECK_RUNTIME_CONTRACT"]
    P8["8 · THE LOOP<br/>task-loop<br/>fresh attempt → tier-1 eval → learn → repeat<br/>OUT: one named TASK_LOOP state"]
    T1{"Task's sealed eval is green<br/>and path policy holds?"}
    T2{"Tier-2 independent refutation<br/>different family + holdout"}
  end

  START --> P0
  START -. "usable BRD: skip optional Capture" .-> P1
  P0 -->|"BRD"| P1
  P0 -->|"do-nothing wins"| NOGO
  P1 --> P2 --> P3 --> P4 --> BARRIER --> P5
  P5 --> P6 --> P7 --> P8 --> T1
  P5 -. "repo-local queue: skip opt-in Register" .-> P7
  T1 -->|"RED · budget remains"| P8
  T1 -->|"RED · stop condition"| STOP
  T1 -->|"GREEN"| T2
  T2 -->|"REFUTED"| P8
  T2 -->|"UPHELD or recorded low-risk UNAVAILABLE"| DONE
  T2 -->|"unavailable + high risk"| STOP

  LANE["ROUTER · cvg lane · not a pass<br/>FAST · NORMAL · FULL<br/>chooses a route; never waives a gate"] -.-> P5

  classDef design fill:#111720,stroke:#F5F2EA,color:#F5F2EA,stroke-width:1.5px;
  classDef build fill:#29313A,stroke:#F5F2EA,color:#F5F2EA,stroke-width:1.5px;
  classDef proof fill:#111720,stroke:#F3B64C,color:#F5F2EA,stroke-width:1.5px;
  classDef terminal fill:#111720,stroke:#F5F2EA,color:#F5F2EA,stroke-width:1.5px;
  classDef stop fill:#111720,stroke:#29313A,color:#F5F2EA,stroke-width:1.5px;
  class P0,P1,P2,P3,P4 design;
  class P5,P6,P7,P8 build;
  class BARRIER,T1,T2,LANE proof;
  class DONE,NOGO,START terminal;
  class STOP stop;
  style DESIGN fill:#070A0F,stroke:#F5F2EA,stroke-width:1px;
  style BUILD fill:#070A0F,stroke:#F5F2EA,stroke-width:1px;
```

![Converge descent: design passes, barrier, then machine build](assets/converge-descent.png)

**Two phases, one barrier.** Capture (Pass 0) is optional. Register (Pass 6) is opt-in. Workspace is `cvg/` first.

Full descent guide: [docs/guides/descent.md](docs/guides/descent.md).

## Chat experience

The descent conductor ([`evidence-to-next-pass`](skills/evidence-to-next-pass/)) owns the canonical pass prompts and the sequence itself.

### The four-step chat path

1. **Session opens** → `cvg next` — derives where the descent stands from workspace evidence
2. **Before a pass** → `pre N` — the missing step IS the instruction (`PASS_PRE=OK` or `PASS_PRE=MISSING`)
3. **Steer with the pass prompt** — `skills/<pass-skill>/references/pass-prompt.md` (shipped, never copied into the consumer)
4. **After the pass** → `post N` then the pass's `cvg` gate

**Evidence presence is not a verdict.** `cvg next` sequences; gates decide.

### Pass prompt example (Pass 0 · Capture)

> **Mission:** turn the stakeholder's raw, incomplete idea into a Business
> Requirements Document in *their* voice. The interview is the work: grill the
> gaps out of the idea — do not politely paraphrase it.
>
> **Exit:** `cvg capture` → `CHECK_BRD=PASS`. If it fails, fix what it names and
> re-gate — never argue with the gate.

Pass 5 has no Converge pass-prompt — it uses the standalone Task-Spec CLI directly.

### Harness destinations

| Harness | dest |
|---|---|
| Codex / Kimi | `.agents/skills/` |
| Claude Code | `.claude/skills/` |
| Grok | `.grok/skills/` |

No Cursor dest exists in `install.sh`.

**Claude Code plugin.** Claude Code can also load `.claude-plugin/` (`plugin.json` + `marketplace.json`): eleven owned skills + `cvg`; Task-Spec independently installed at 3.8.

**Router scaffold.** `cvg setup harness` scaffolds `AGENTS.md` (~50 lines, routing only, non-clobbering). Bind (Pass 7B) emits `AGENTS.task.md` (identifiers, not content).

**Cockpit.** [Cockpit](apps/cockpit/) is a read-only observation and interpretation surface over `cvg snapshot`. It cannot authorize work.

```bash
npm run cockpit:install
npm run cockpit:dev --   --cvg-home "$PWD"   --project-root /absolute/path/to/project
```

Full chat guide: [docs/guides/chat.md](docs/guides/chat.md).

## CLI

### First composed journey

```bash
export CVG_TASKSPEC_BIN=/absolute/path/to/task-spec/bin/taskspec
export CVG_SEAMWISE_BIN=/absolute/path/to/seamwise/bin/seamwise

cvg compose prepare --source recipe.yaml
# COMPOSE=NEEDS_REVIEW

cvg compose review   --reviewer "repository-owner"   --reason "The seams, ownership, dependencies, and rollback paths are accepted."
# COMPOSE=PREVIEW_READY

cvg compose preview
# COMPOSE=PREVIEW_READY

cvg compose materialize
# COMPOSE=MATERIALIZED

cvg compose status
# COMPOSE=MATERIALIZED
```

The materialized leaves still contain `signed_off: false`.
Authorization remains explicit and per leaf:

```bash
taskspec gate --stamp cvg/tasks/T-20260815-health-status.md
cvg bind --task cvg/tasks/T-20260815-health-status.md
git add cvg/tasks cvg/execution
git commit -m "authorize and bind health status task"
cvg loop --issue T-20260815-health-status --agent codex
```

### Pass verbs

```bash
cvg init
cvg setup signing
cvg lane "add a health endpoint"

cvg capture
cvg intent
cvg structure
cvg decompose --source recipe.yaml
cvg compose review --reviewer owner --reason "Topology accepted"
cvg tasks plan --manifest seamwise/task-plan.json
cvg compose materialize
cvg tasks validate cvg/tasks/T-20260815-health-status.md
cvg tasks gate --stamp cvg/tasks/T-20260815-health-status.md
cvg bind --task cvg/tasks/T-20260815-health-status.md
cvg loop --issue T-20260815-health-status --agent codex
```

### Compose states

- `COMPOSE=NEEDS_REVIEW`
- `COMPOSE=PREVIEW_READY`
- `COMPOSE=MATERIALIZED`
- `COMPOSE=BLOCKED`
- `COMPOSE=ENGINE_UNAVAILABLE`

### Machine contract

Every public form accepts global `--json` and `--dry-run` in any position.

```bash
cvg --json help
cvg version --json
cvg agent-context --json
cvg compose --json status
```

`--json` emits one `ConvergeCLIResult/v1` document. The canonical 57-form matrix is [contracts/cli-command-matrix.json](contracts/cli-command-matrix.json); the human reference is [docs/reference/cli.md](docs/reference/cli.md).

Task-Spec pin remains **3.8.0**; 3.9.x writes an absolute `path:` into `_state.yaml` and is not supported.

## Install

### Requirements

- Git
- Bash 3.2 or newer
- Python 3
- Task-Spec 3.8.0 for every Converge installation
- Seamwise 0.2.0 only for decomposition and `cvg compose`
- Node 22 only for the npm door and Cockpit

Install the published stack in dependency order:

```bash
git clone --branch v3.8.0 https://github.com/luanmorenommaciel/task-spec.git
bash task-spec/install.sh --global --copy
taskspec demo

python3 -m pip install   "git+https://github.com/luanmorenommaciel/seamwise.git@v0.2.0"

git clone --branch v0.2.0   https://github.com/luanmorenommaciel/converge.git
bash converge/install.sh --target /absolute/path/to/your-project --copy
```

Converge also supports:

```bash
npm install -g github:luanmorenommaciel/converge
cvg-install
```

or:

```bash
CVG_REF=v0.2.0   bash -c "$(curl -fsSL https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh)"
```

The installer projects exactly eleven Converge skills to `.agents/skills/`,
`.claude/skills/`, and `.grok/skills/`. It installs no Task-Spec or Seamwise
implementation. The repository is private; all install doors require access.

## Release truth

| Claim | Current evidence |
|---|---|
| Task-Spec 3.8.0 | Published from immutable commit `0e6180cfc3009bd4ef9cf7ab050b463e10d4af91`; hosted Ubuntu/macOS release installation green |
| Seamwise 0.2.0 | Published from immutable commit `5a398169c3fefcb65eb1a47c0cb4f967dfdc0515`; exact-commit and packaged Ubuntu/macOS gates green |
| Converge 0.2.0 | Release work merged through PRs #13–#15; `v0.2.0` identifies the immutable release commit |
| Hosted CI | All eight jobs passed on exact feature SHA `1fa054546b5678838af21969816b94f8dab4ed1b` in run `32048296517` |
| Release publication | The `v0.2.0` tag workflow independently verifies Ubuntu/macOS, builds checksummed assets, and publishes the GitHub release |
| Historical Converge 0.1.0 | Published and immutable; it documents the former bundled Task-Spec architecture |

## Who this is for

**Factory compose + settlement.** Use Converge for dock, factory, and big-bang only — not the everyday consult path.

## Who this is not for

- **Everyday coordinator** — use WorkHelm for nuances, backlog, RPI
- **Manager fleet** — task scheduling across the frontier is a separate, still-future layer
- **Autonomous approval** — Converge never merges, pushes, or opens a PR on the user branch unless a human asked

## Scope of v0.2.0

This release promises a reproducible composed single-task path with strict
external-engine boundaries. It does not promise Manager fleet scheduling,
production reliability, a live tracker, or autonomous approval of human
decisions.

## Documentation

| Start here | Best for |
|---|---|
| [Knowledge base](docs/index.md) | Map and how to navigate |
| [Getting started](docs/getting-started/index.md) | Install, first composed leaf, reviewer route |
| [Descent guide](docs/guides/descent.md) | Two phases, one barrier, workspace discovery |
| [Chat guide](docs/guides/chat.md) | Four-step chat path, harness dests, plugin |
| [Skills reference](docs/concepts/skills.md) | Eleven skills + standalone Tasking |
| [Authority](docs/concepts/authority.md) | Who may decide what |
| [Trust](docs/trust/index.md) | What a receipt proves and what it does not |
| [CLI reference](docs/reference/cli.md) | Generated 57-form table |
| [Contracts](contracts/README.md) | Versioned JSON schemas |
| [Skill catalog](skills/README.md) | Deep essays on each pass |
| [Cockpit](apps/cockpit/README.md) | Read-only observer |
| [Contributing](CONTRIBUTING.md) | Local bootstrap and gates |

## Repository map

| Path | Role |
|---|---|
| `bin/` | Stable CLI plus focused private helpers |
| `contracts/` | Canonical CLI matrix and versioned JSON Schemas |
| `skills/` | Exactly eleven Converge orchestration and assurance skills |
| `apps/cockpit/` | Read-only observer UI |
| `templates/` | Consumer workspace templates |
| `tests/` | Hermetic gate, install, loop, JSON, and composed-flow suites |
| `scripts/` | Docs, package, release, and evidence tooling |
| `evidence/` | Retained live-executor traces for named release gates |
| `docs/` | Knowledge base; start at [`docs/index.md`](docs/index.md) |
| `assets/` | README hero, Settlement Fold catalog, and process plates — see [ASSETS.md](assets/ASSETS.md) |

## Verification

`make bootstrap` assembles the pinned pairing under `.engines/` and `.venv/`,
after which `make check` needs no exported paths. See [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
make check
make check-json
make check-docs
make check-composed
make check-live-evidence
make demo-composed
make release-check
```

A green local `make check` needs the release pairing:

- Task-Spec **3.8.0** at commit `0e6180cfc3009bd4ef9cf7ab050b463e10d4af91`
- Seamwise **0.2.0** at commit `5a398169c3fefcb65eb1a47c0cb4f967dfdc0515`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
