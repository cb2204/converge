<div align="center">

# Converge

**Spec-first delivery for coding agents — `done` is decided by runnable evals, not claimed by the agent.**

[![ci](https://github.com/luanmorenommaciel/converge/actions/workflows/ci.yml/badge.svg)](https://github.com/luanmorenommaciel/converge/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/luanmorenommaciel/converge)](https://github.com/luanmorenommaciel/converge/releases/latest)
[![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](#requirements)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Works with **Claude Code · Codex · Kimi · Grok Build** — one method, one referee CLI, eleven portable skills, zero runtime dependencies

[Install](#-install) ·
[Quickstart](#-quickstart-your-first-gated-task) ·
[How it works](#-how-it-works) ·
[The passes](#-the-nine-passes) ·
[The CLI](#-the-cvg-cli) ·
[Docs](#-documentation)

</div>

---

## What is Converge?

Whatever coding agent you use — Claude Code, Codex, Kimi, Grok Build — Converge makes it work
against **signed task specs whose completion is enforced by evals, not by the agent's word**.
Every task ships with runnable bash evals authored *before* the work; a task only settles when
those evals exit green, and an adversarial judge from a **different model family** can be asked
to refute the result against holdout criteria the builder never saw.

The unit of work is the **Task-Spec**: a self-verifying markdown file with a machine-checked
format, an effort budget, an HMAC sign-off seal, and its own definition of done. The `cvg` CLI
is the **referee** around it — it frames, dispatches, and gates, but holds **zero model
credentials** and never writes a line of product code. Agents play; the referee scores. And
because the referee is plain bash + stdlib Python, the same install serves every harness.

## Why it's different

- **The eval decides done.** A task cannot settle until its evals exit 0 — completion is a
  state-machine invariant, not an agent's claim. The maximal stub attack (all nine specs faked)
  lands all nine RED.
- **The referee is never a player.** `cvg` holds no API keys and calls no models. Engine CLIs
  authenticate themselves; the referee only frames, dispatches headlessly, and gates.
- **Cross-family verification.** Tier-2 acceptance sends the diff, the intent, and **holdout
  criteria the builder never saw** to a different vendor's model, prompted to refute. Proven
  live in both directions — including one REFUTED verdict that caught a fail-open bug green
  evals could not see.
- **A loop with brakes.** `cvg loop` runs attempt → verify → repeat under three-axis budgets
  (iterations · wall-clock · tokens), a stagnation detector, and eight named terminal states —
  only `SETTLED`, `LOCAL_SETTLED`, and `NO_OP` exit zero. An exhausted budget is never a success.
- **Harness-agnostic by construction.** Engines are one adapter file each; skills install into
  every harness's native discovery directory. The same signed spec dispatches to any of them —
  and the gate that scores the work is identical.

## 📦 Install

Three doors, same result: the eleven skills land in every harness's native directory and the
`cvg` CLI lands on your PATH. Pick the one that matches your stack.

**① Plugin marketplace** — inside Claude Code (Grok Build reads Claude marketplaces natively):

```
/plugin marketplace add luanmorenommaciel/converge
/plugin install converge@cvg
```

**② npm / npx** — anywhere Node lives; the package embeds the CLI *and* all skills:

```bash
npm install -g github:luanmorenommaciel/converge     # cvg + cvg-install on PATH
cvg-install                                          # pin skills into the current repo
```

Prefer project-local? `npm install -D github:luanmorenommaciel/converge`, then use
`npx cvg …` and `npx cvg-install`.

**③ One-line shell** — no Node needed, only git + bash:

```bash
curl -fsSL https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh | bash
```

Where skills land, per harness — one install covers all four:

| Harness | Skills discovered from | Also gets |
|---|---|---|
| **Claude Code** | `.claude/skills/` | marketplace plugin (skills + `cvg` on session PATH) |
| **Codex** | `.agents/skills/` (AGENTS.md family) | `cvg` via any install door |
| **Kimi** | `.agents/skills/` | `cvg` via any install door |
| **Grok Build** | `.grok/skills/` | reads Claude marketplaces + `AGENTS.md` natively |

<details>
<summary><b>More: pinning, forks, development installs, requirements</b></summary>

- **Pin an exact release:** `CVG_REF=v0.1.0 curl -fsSL …/install.sh | bash`, or
  `npm i -g github:luanmorenommaciel/converge#v0.1.0`.
- **Install from a fork:** `CVG_REPO_URL=<url>` for the one-liner, or point npm at your fork.
- **Development:** `git clone` the repo, then `bash /path/to/converge/install.sh --symlink`
  from your project — skills and CLI stay live-linked to the checkout.
  `install.sh --help` lists every flag (`--target`, `--no-bin`, `--bin-dir`, `--force`).
- **Windows:** run everything in Git Bash or WSL, and use real `curl` (`curl.exe`, not the
  PowerShell alias).
- **Requirements:** `bash` 3.2+ and `git`. The binding/verification gates use `python3`
  (stdlib only, no pip). Node is needed only for the npm door. Engine CLIs (`claude`,
  `codex`, `kimi`, `grok`) are needed only by the passes that dispatch to them, and each
  authenticates itself — Converge never holds a key.

Installing is idempotent, never writes a credential, and verifies the installed skills parse
before reporting `INSTALL=OK`.
</details>

## ⚡ Quickstart: your first gated task

Once installed, everything happens in the repository you want to deliver into. Three setup
commands, then the loop:

```bash
# 1 · Stand up the control plane (tracked files, safe to review like any code)
cvg init                  # → CVG_INIT=OK      .cvg/gate.yaml + cvg/ workspace
cvg setup signing         # → SETUP_SIGNING=OK repo-private HMAC key, outside git
cvg setup                 # → SETUP=READY      readiness board with your exact next step

# 2 · Route the work, author the spec, seal it
cvg lane "add a health endpoint"          # → LANE=FAST        how much ceremony this earns
cvg tasks new add-health-endpoint XS      # spec scaffolded — you write the evals FIRST
cvg tasks validate cvg/tasks/T-*.md       # → OK               structure + six-tier sizing
cvg tasks gate --stamp cvg/tasks/T-*.md   # → VERDICT: DELEGATE · TIER=1   HMAC-sealed

# 3 · Bind the contract, run the loop
cvg bind --task cvg/tasks/T-*.md          # → CHECK_RUNTIME_CONTRACT=PASS
cvg loop --issue T-… --agent claude       # → TASK_LOOP=SETTLED (or an honest failure state)
```

Every command ends in one stable, greppable token — a harness never parses prose. Swap
`--agent claude` for `codex` or `kimi`; the gates don't change. Agents can discover the whole
surface in one call: `cvg agent-context`.

## 🔁 How it works

A raw idea descends through nine gates. Passes 0–4 are the **design half** — documents in,
adversarial review out. Pass 5 is the **cornerstone** — intent becomes signed, self-verifying
Task-Specs. Passes 6–8 are the **machine half** — the board mirrors the backlog, the bind
freezes an enforceable contract, and the loop drives each task to a terminal state a script
can read. Evidence and lessons flow back to feed the next pass.

```mermaid
flowchart LR
    I([raw idea]) --> P0["0 · Capture"] --> P1["1 · Intent"] --> P2["2 · Structure"] --> P3["3 · Decompose"]
    P3 --> P4{{"4 · Consensus<br/>THE BARRIER — cross-family<br/>adversary + human sign-off"}}
    P4 --> P5["5 · Tasking<br/>signed Task-Specs, evals first"]
    P5 --> P6["6 · Register (opt-in)<br/>specs ⇄ tracker board"]
    P5 --> P7["7 · Bind<br/>execution profile + write fence"]
    P6 --> P7
    P7 --> P8["8 · The Loop<br/>attempt → verify → repeat"]
    P8 --> D([settled: green evals,<br/>receipt, PR])
    D -. evidence + lessons feed the next pass .-> P0
    style P4 fill:#3a2f12,stroke:#f5b042,color:#f7f2e8
    style P8 fill:#0f2a24,stroke:#2dd4bf,color:#e6f7f2
```

Not every change earns all nine passes. `cvg lane` routes work to the ceremony it deserves —
**FAST** (5, 7, 8), **NORMAL** (1, 2, 5, 7, 8), or **FULL** (0–8) — and it **routes but never
waives**: nothing irreversible rides FAST, and no lane dispatches an unsigned spec.

## 🧩 The nine passes

Each pass is an installable skill with one job, one output, and one gate. You (or your agent)
do the work; the gate proves it happened.

| # | Pass | What you do | The gate proves | Token |
|:--:|---|---|---|---|
| 0 | Capture *(optional)* | Turn a raw idea into a BRD — the skill grills the gaps out of you | the brief is complete and signed | `CHECK_BRD=PASS` |
| 1 | Intent | Derive testable tech requirements from the BRD | every requirement is testable, blockers resolved | `CHECK_TECH_SPEC=PASS` |
| 2 | Structure | Record the architecture as ADRs | the decision set is canonical and consistent | `CHECK_ADR=OK` |
| 3 | Decompose | Split the work into swimlanes of ordered legs | tree shape and dependencies are sound | `CHECK_PLAN=OK` |
| 4 | **Consensus — the barrier** | A *different-family* model attacks the plan; you resolve objections and sign | cross-family review really ran; provenance stamped | `CHECK_CONSENSUS=OK` |
| 5 | **Tasking — the cornerstone** | Author Task-Specs: evals first, then budget, then the HMAC seal | each spec is atomic, sized, and safe to delegate | `TIER=1` |
| 6 | Register *(opt-in)* | Project specs onto Linear / GitHub / Jira, one spec = one issue | board ⇄ backlog is 1:1, dependency DAG intact | `CHECK_REGISTER=OK` |
| 7 | Bind | Freeze the execution contract: profile, write fence, pinned hashes | this host can actually enforce it | `CHECK_RUNTIME_CONTRACT=PASS` |
| 8 | The Loop | An engine attempts, evals verify, repeat — bounded on three axes | evals green within budget, receipt written | `TASK_LOOP=SETTLED` |

Pass skills: [`idea-to-brd`](skills/idea-to-brd/) · [`brd-docs-to-tech-req`](skills/brd-docs-to-tech-req/) ·
[`tech-req-to-adrs`](skills/tech-req-to-adrs/) · [`reqs-to-swimlane-plans`](skills/reqs-to-swimlane-plans/) ·
[`sketch-plans-adversarial-review`](skills/sketch-plans-adversarial-review/) · [`task-spec`](skills/task-spec/) ·
[`task-specs-to-issues`](skills/task-specs-to-issues/) · [`task-to-runtime-contract`](skills/task-to-runtime-contract/) ·
[`task-loop`](skills/task-loop/) — plus two utilities, [`pass-to-lesson`](skills/pass-to-lesson/)
(teach what a pass just did) and [`skill-creator`](skills/skill-creator/) (author + validate new
skills). The full catalog with per-skill detail: [`skills/README.md`](skills/README.md).

## 🛠 The `cvg` CLI

One referee for the whole descent. Commands group by stage; every wrapped gate is a byte-exact
pass-through, and every verdict ends in one token.

| Stage | Commands | What they do |
|---|---|---|
| **Start** | `init` · `setup` · `setup signing\|tracker\|key\|repo\|identity\|projection\|harness\|engines` · `doctor` | stand up the control plane, provision the signing key, connect a tracker (key goes to the OS keychain, never the repo), check engine readiness |
| **Design** *(0–4)* | `capture` · `intent` · `structure` · `decompose` · `review` · `lane` | run each design gate; `review --adversary codex,kimi` dispatches the cross-family attack; `lane` routes work to FAST / NORMAL / FULL |
| **Author & sign** *(5)* | `tasks new\|validate\|gate\|accept\|dod` · `eval` · `lint` | scaffold a spec, validate structure + sizing, seal it with the sign-off HMAC, run its evals, lint the backlog |
| **Board** *(6)* | `register` · `register --check` · `ready` · `transition` · `tasks metrics` | project specs onto a tracker (1 spec = 1 issue), gate the mapping, list the dispatchable frontier, move statuses |
| **Execute** *(7–8)* | `bind` · `loop` · `verify` · `gate` | freeze the contract, run the bounded loop, request the cross-family judge, query the repo write fence |
| **For agents** | `agent-context` · `--json` · `--dry-run` | full machine-readable manifest in one call; uniform JSON envelope on any command; preview a mutation without performing it |

What a session actually looks like:

```console
$ cvg tasks gate --stamp cvg/tasks/T-20260730-add-health-endpoint.md
VERDICT: DELEGATE
TIER=1

$ cvg loop --issue T-20260730-add-health-endpoint --agent codex
TRACKER=OK
TASK_LOOP=SETTLED

$ cvg register --check
CHECK_REGISTER=OK
```

Exit codes are contracts with a published retryable / side-effects taxonomy. The complete
surface ledger — every command, what it wraps, and what proved it — is
[`bin/README.md`](bin/README.md).

## 🧾 Status

**Converge 0.1.0** ships the CLI, eleven skills, and the Task-Spec engine as one versioned unit —
the first release where every claim has a receipt behind it:

- **CI is public and green on macOS (bash 3.2) and Linux** — 21 hermetic suites, no secrets, no
  live services: [the gauntlet](.github/workflows/ci.yml).
- **The clean-room acceptance suite** builds an empty repo, installs pinned copies for every
  harness, and proves the full chain — init → sign → bind → bounded RED→GREEN loop → acceptance →
  receipt hash chain — with a stub engine: [`tests/test-clean-room-install-e2e.sh`](tests/test-clean-room-install-e2e.sh).
- **The loop kernel is proven by 52 hermetic checks** (brakes, stagnation, exhaustion, resume,
  cancel, honest no-op): [`tests/test-loop-kernel.sh`](tests/test-loop-kernel.sh).
- **Tier-2 verification has graded real work in both directions** — cross-family, no shared
  vendor: one UPHELD (settled through a merged PR), one **REFUTED** that caught a fail-open bug
  the deterministic evals could not see. *A green eval is necessary, not sufficient — demonstrated.*
- One number, everywhere: `VERSION` is the single source of truth (`cvg 0.1.0` across the CLI,
  skills, and every manifest) and [`tests/test-version-unity.sh`](tests/test-version-unity.sh)
  fails the build on drift.

What's deliberately **not** in 0.1.0: the Manager (fleet dispatch across ready tasks — the loop
is single-task by design today) and the CI eval-gate (server-side re-verification). Both are next
on the roadmap; full history in the [CHANGELOG](CHANGELOG.md).

## 📚 Documentation

| Read | For |
|---|---|
| [`docs/converge-v0.1.pdf`](docs/converge-v0.1.pdf) | **the canonical blueprint** — the descent, the barrier, the architecture, the agent protocol |
| [`docs/task-spec-v0.1.pdf`](docs/task-spec-v0.1.pdf) | the cornerstone unit in depth — six tiers, dual gates, anti-reward-hacking |
| [`presentation/converge.html`](presentation/converge.html) | interactive walkthrough — method, trust chain, evidence model |
| [`presentation/task-spec.html`](presentation/task-spec.html) | Task-Spec anatomy, authoring, signing, execution, recovery |
| [`presentation/cvg-passes-skills-cli.html`](presentation/cvg-passes-skills-cli.html) | all nine passes, eleven skills, and the CLI, step by step |
| [`presentation/asd-agentic-loop.html`](presentation/asd-agentic-loop.html) | the agentic loop: bounded autonomy and settlement |
| [`skills/README.md`](skills/README.md) | the skill catalog — what each pass ships and gates |
| [`bin/README.md`](bin/README.md) | the CLI surface ledger — every command and what proved it |

## ❓ FAQ

<details>
<summary><b>Does my agent have to support Converge?</b></summary>

No. Skills install as plain markdown + scripts into each harness's native discovery directory
(`.claude/skills/`, `.agents/skills/`, `.grok/skills/`); the CLI is plain bash. Any harness
that can run shell commands can drive the gates, and `cvg agent-context` gives an agent the
full surface as JSON in one call.
</details>

<details>
<summary><b>Why signed specs?</b></summary>

The sign-off HMAC seals the eval bodies at the moment a human said "safe to delegate". If an
agent (or anyone) edits an eval afterwards to make it pass, the seal breaks and the gate refuses.
Hand-stamping is rejected; the only path to autonomy is through the gate.
</details>

<details>
<summary><b>What's the "Manager", and why isn't it a skill?</b></summary>

The Manager decides *which* task runs, when, in parallel, watching PRs — an orchestration layer a
Git-native world mostly provides already (Actions as scheduler, the PR as settlement, branch
protection as the gate). Converge ships the execution **Loop** now; the Manager schedules around
it later in CI/CD. It's the top item on the roadmap.
</details>

<details>
<summary><b>Can I use it on an existing repository?</b></summary>

Yes — `cvg init` is non-clobbering and the write fence (`.cvg/gate.yaml`) is a tracked file you
review like any other. Start with `cvg lane` on your next change; nothing forces the full descent.
</details>

## Provenance

Converge practices what it enforces: this repository's own backlog was driven through the loop —
nine tasks settled through merged PRs, one fully unattended — and its CI runs the same gates it
asks of everyone else. Built with Claude Code, Codex, and Kimi in all three seats.

## License

[MIT](LICENSE) — one license for the whole unit.
