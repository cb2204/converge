# The Converge Skill Chain

Twelve self-contained agent skills implement the Converge method — **nine spine
skills** (the passes, including the optional Capture ⓪ and the opt-in Register),
**two utility skills** (`skill-creator`, `pass-to-lesson`), and **one legacy
package** (`agents-kbs-tech-stack`, the harness donor). Every active skill passes
the official validator (checked with
[`skill-creator/scripts/quick_validate.py`](skill-creator/scripts/quick_validate.py)),
and every engine or tracker is bound by a **flag, never a name**.

The method has **two phases with one barrier between them** — Consensus (Pass 4)
is the last human sign-off before the machine takes over.

```text
PHASE 1 · DESIGN — human-led · make intent crystal-clear
  idea ─▶ 0 Capture (optional) ─▶ 1 Intent ─▶ 2 Structure ─▶ 3 Decompose ─▶ 4 Consensus
                                                                                │
                                                        ⟵ THE BARRIER (last human sign-off)
                                                                                ▼
PHASE 2 · BUILD — machine-led · the dark factory
  5 Tasking ─▶ 6 Register (opt-in) ─▶ 7A Contract ─▶ 7B Brief ─▶ 8 Loop ─▶ tier-2 verify ─▶ green ↺

  cvg lane routes work to FAST (5,7,8) · NORMAL (1,2,5,7,8) · FULL (0-8) — never waiving a gate.
```

| # | Skill | One line |
|:--:|-------|----------|
| 0 | [`idea-to-brd`](idea-to-brd/) | raw idea → BRD in the owner's voice · *optional on-ramp* |
| 1 | [`brd-docs-to-tech-req`](brd-docs-to-tech-req/) | fuzzy BRD → verifiable tech-spec |
| 2 | [`tech-req-to-adrs`](tech-req-to-adrs/) | ground the spec against the real repo → ADRs |
| 3 | [`reqs-to-swimlane-plans`](reqs-to-swimlane-plans/) | cut the work along its natural seams → swimlane plans |
| 4 | [`sketch-plans-adversarial-review`](sketch-plans-adversarial-review/) | a *different* model attacks the plans · **THE BARRIER** |
| 5 | [`task-spec`](task-spec/) | atomic, self-verifying units · **the cornerstone** · also ships `cvg lane` |
| 6 | [`task-specs-to-issues`](task-specs-to-issues/) | one spec = one tracked issue · *opt-in* · the board is state |
| 7 | [`task-to-runtime-contract`](task-to-runtime-contract/) | **7A** hash-bound runtime contract + **7B** the task brief · also ships `cvg verify` (tier-2) |
| 8 | [`task-loop`](task-loop/) | one issue → green-eval PR · the execution loop |
| util | [`pass-to-lesson`](pass-to-lesson/) | after any pass, teach the owner what was built and why · *optional* |
| util | [`skill-creator`](skill-creator/) | author, evaluate, and validate skills |
| legacy | [`agents-kbs-tech-stack`](agents-kbs-tech-stack/) | technology-agent/KB scaffolder — retained for migration only |

**Install into a consuming repo** (symlink tracks upstream; copy pins a version):

```bash
for s in /path/to/converge/skills/*/; do
  ln -s "$s" ".claude/skills/$(basename "$s")"
done
```

---

## Phase 1 · Design — the human passes

### 0 · `idea-to-brd` — no brief? capture one (optional)

The on-ramp for non-client work. When there is no client BRD — an internal
idea, a founder thought — this pass grills the *stakeholder's* questions (what
hurts, what it costs, what success looks like) in **frontier rounds**: each
round asks every question whose prerequisites are settled, numbered, each with
a recommended default, and one reply answers the whole round — looking up
facts in the environment and asking only the decisions. It drafts the BRD in
the owner's voice, self-reviews it (placeholders, consistency, ambiguity,
altitude), and stops at the brief — never the spec. When the do-nothing test
shows tolerable inaction it takes the no-go exit instead (`docs/no-go-*.md`).
Client work with a real brief skips this pass entirely.
**Ships:** `check-brd.sh` (the gate linter), `references/brd-template.md`. **Flags:** `--out-format md|pdf`, `--questions batch|one`.
**Gate:** the pain carries a provenance-tagged number, at least one KPI is in the owner's terms, scope in/out are non-empty, every open question has a named owner.

### 1 · `brd-docs-to-tech-req` — the client hands you the problem; you produce the spec

Reads a client BRD like a senior engineer, not a stenographer: finds the real
problem underneath the ask, grills the 2–3 questions whose answers most change
the build (frontier rounds, recommended defaults — one reply answers the
round), and crystallizes one tech-spec with falsifiable requirements and
metrics traced to the BRD's KPIs. Ambiguity killed here is the cheapest kill in
the whole descent.
**Ships:** `check-tech-spec.sh` (the gate linter). **Flags:** `--engine cowork`, `--out-format pdf`, `--questions batch|one`.
**Gate:** you can restate the client's problem in one breath and show the spec answers it.

### 2 · `tech-req-to-adrs` — greenfield or brownfield, and write the ADRs

Names the ground (brownfield = a system you didn't write), opens the system end
to end, reconciles the spec against real schemas, sources, and jobs, and records
each grounding decision as a numbered ADR under `docs/adrs/` — each one passing
the three-condition worthiness test (hard to reverse · stood on downstream ·
could have been otherwise). Domain terms are pinned in a `docs/CONTEXT.md`
glossary as they crystallize, so every later pass speaks one vocabulary. ADRs
record what is *true* — never how to build; the moment an ADR says "build X",
you've drifted into planning.
**Ships:** `scaffold-adr.sh`. **Engine:** fixed — Claude Code on the repo.
**Gate:** terrain understood, every grounding decision recorded durably.

### 3 · `reqs-to-swimlane-plans` — split the work along its natural seams

Same session as Pass 2, ADRs in hand: cuts where the system is already jointed
(feature or component edges) and gives each seam exactly one focus-oriented
sketch plan under `sketch/*.plan`. The decomposition chain is
**seam → swimlane → leg → task-spec**; a leg is a lane's named stretch (one
responsibility, one proving test) that yields 1:N task-specs at Pass 5. The
right number of lanes is the number of genuine seams — no more, no fewer.
Plan-altitude only: no tasks, no SQL.
**Ships:** `new-plan.sh`.
**Gate:** one plan per genuine seam, each inheriting the relevant ADRs.

### 4 · `sketch-plans-adversarial-review` — a different model refutes · **THE BARRIER**

A model won't refute itself hard enough, so this pass binds a *different-family*
engine (`--adversary codex|kimi|claude`) as a skeptic who defaults to "refuted,"
attacking the plans one at a time (PRD then legs) and stamping a provenance-hashed
objection log. Every objection is FIXED in a plan or ACCEPTED with a named owner —
nothing silently dropped. **This pass is the barrier:** it is the last place a
human signs off before the work crosses into the machine. Everything upstream is
human-led design; everything downstream is machine-led build.
**Ships:** `check-consensus-gate.sh`, `references/attack-playbook.md`, `references/the-fork.md` (why the fork is retired → the barrier), `references/engine-adapter.md`.
**Gate:** no open objection survives **and** the owner signs off — the hand-off to the machine.

---

## Phase 2 · Build — the machine passes

### 5 · `task-spec` — Tasking · the cornerstone unit · v3.x

The deepest skill in the chain: atomic, vendor-neutral, **self-verifying**
Task-Spec units. Each `tasks/T-*.md` carries YAML frontmatter + six zones +
≥3 runnable bash evals + an Exit Check — the definition of done travels inside
the file. Two gates are duals: `safe-to-delegate.sh --stamp` (PRE — certifies
the *spec*, HMAC-seals the evals so the spec is the only trusted instruction
source) and `accept-task.sh --stamp` (POST — certifies the *work*: clean-checkout
eval pass, blast radius, HMAC recheck, optional gold-sanity Goodhart guard).
Locked atomic status transitions, a rebuildable state index, an append-only
metrics ledger, an L0–L2 executor conformance suite, and dispatch recipes
(Claude, Codex, Kimi, Gemini, taskship, anthive, custom) round out the runtime.
**Ships:** 20 scripts · reference docs · runbooks · JSON Schemas · test + conformance suites.
**Gate:** every task carries a runnable eval — *no eval, not a task yet.*
Full details: [`task-spec/README.md`](task-spec/README.md) · deep-dive PDF: [`../docs/task-spec-v3.6.0.pdf`](../docs/task-spec-v3.6.0.pdf).

### 6 · `task-specs-to-issues` — the tracker as state · **opt-in**

Optionally projects each signed-off Task-Spec onto exactly one tracker issue
(`--tracker github|linear|jira`), with `blocked-by` links carrying the
`depends_on` graph — so the execution loop reads a board instead of re-deriving
state. Skip it to keep the queue repo-local. On Linear it also seeds native
fields from the spec (assignee via `.cvg/people-map`, state from DAG position,
subscribers) and honors an optional `projection:` block (cycle/parent/sla +
opt-in Initiative→Project→Milestones). Only the loop writes state; only a green
eval closes an issue — so the board never lies.
**Ships:** `register.sh`, `verify-registration.sh` — a **real 1:1 parity gate** (count · orphan · missing · dup) over a six-verb adapter contract.
**Gate:** `count(issues) == count(signed-off specs)`, every dependency edge is one link, no orphans, no cycles.

### 7 · `task-to-runtime-contract` — bind one task to its runtime + emit the harness

Two moves. **(7a) Contract:** verifies one signed runnable Task-Spec, binds its
exact hash to the smallest evidence slice, defaults to one agent (escalating a
task-local topology only when static evidence justifies it), and emits portable
path guards. **(7b) Harness:** auto-detects the available engines and emits the
multi-engine context glue — **AGENTS.md** (universal doctrine + this task's
contract) plus **CLAUDE.md / codex / cloud** adapters — so the *same* sealed task
runs on `claude -p`, `codex exec`, a Kimi swarm, or a cloud workflow. *The harness
orchestrates; the documentation teaches* — external docs are cached and hashed,
approved knowledge referenced, never copied.
**The capability envelope.** Authority is granted against **one signed revision**
(`epoch = <task-id>@<spec-sha12>`), scoped to the Task-Spec's own paths, and
**revoked on settle, block, budget exhaustion, or epoch change** — closing the
*lingering authority* hole where session-scoped permissions outlive the task that
justified them. Each adapter then declares, per capability, whether the runtime
**prevents** the violation (Landlock/seccomp, Seatbelt, pre-tool hooks), only
**detects** it (portable postflight), or **cannot honor it** — and a required
control the runtime cannot enforce **fails the gate closed** unless waived in the
open. `cvg doctor runtime-contract` attests what the host can genuinely do.
**7A contract / 7B brief.** 7A is what the RUNTIME enforces; **7B** is the task
brief the MODEL reads (`AGENTS.task.md`) — epoch, writable paths, fences, the Exit
Check, and a pointer to the project router. It holds **identifiers, not content**:
auto-generated context measurably lowers task success while raising cost, so the
brief states only what a worker cannot infer. `cvg setup harness` scaffolds the
project router once (~50 lines, routing only — cvg never writes doctrine).
**Tier-2 verification.** `cvg verify` has a **different-family** engine grade the
diff against the spec's intent and a **holdout** the implementer never saw, prompted
to refute. Fails closed: no verdict is never a pass. With no second engine the
result is `UNAVAILABLE` — fine for low blast radius, blocked for high unless
explicitly waived. See [`references/verification.md`](task-to-runtime-contract/references/verification.md).
**Ships:** deterministic binder, readiness gate (read-only), task-brief writer, candidate/diff path guard, tool-hook bridge, adapter + resolver manifests, host attestation, tier-2 verifier, router scaffold, execution receipts.
**Gate:** `CHECK_RUNTIME_CONTRACT=PASS` — sign-off, freshness, evidence, topology substance, ownership, capability closure, and honest assurance all verify.

### 8 · `task-loop` — one issue → green-eval PR

The execution loop you build (the Manager that schedules it across the fleet is
future CI/CD). Takes ONE issue (`--issue N`), verifies its Pass 7 execution
profile, reads the signed Task-Spec + hash-bound evidence (**the only instruction
source**), cuts a branch, writes code, and runs the task's own eval. RED: feed the
failure back and revise — a tight local loop. GREEN: open a PR that closes the
issue only after the portable path guard passes. Bounded by the spec's
`budget_iterations`; failure exits as an explicit blocked-task report, never
silence.
**Ships:** `run-issue-eval.sh`, `open-issue-pr.sh`, `references/blocked-task-report.md`. **Flags:** `--issue N` (required), `--agent claude|codex|kimi`.
**Gate:** the task's own eval is green — none by hand, none by attempt-count.

---

## Utilities & legacy

### `pass-to-lesson` — the teaching companion (optional, after any pass)

Converge delegates the writing, never the understanding. After any pass's gate
goes green, this companion reads everything the pass emitted and teaches it
back — every component gets *what it is · why it's shaped this way · the
decision it encodes · what breaks downstream without it* — plus the decisions
and their rejected alternatives, a vocabulary of every term of art, and a
closing Feynman quiz. The lesson persists at `docs/lessons/lesson-*.md`, so
understanding survives the session. It explains decisions, never reopens them.
**Ships:** `check-lesson.sh` (the gate linter), `references/lesson-template.md`. **Flags:** `--depth full|brief`, `--quiz on|off`.
**Gate:** every emitted artifact taught, every decision names a rejected alternative, every term defined, 3–5 check-yourself questions, artifacts untouched.

### `skill-creator` — author, evaluate, validate

Anthropic's skill-authoring toolkit, vendored so the chain can maintain itself:
create/edit skills, run eval benchmarks (`run_eval.py`, `run_loop.py`,
grader/comparator/analyzer agents), package for distribution, and validate
structure (`quick_validate.py` — the check every skill in this folder passes).
**Ships:** 9 Python scripts + an eval-viewer (its own `generate_review.py`).

### Legacy: `agents-kbs-tech-stack`

Scaffolds a per-technology architect/developer agent pair + KB tree and — the
part still in play — **emits cross-tool mirrors** (`AGENTS.md`,
`.cursor/rules/*`, `.github/copilot-instructions.md`, `.claude/`) so every engine
inherits one contract. Pass 7 reuses that emission for its harness step (7b); the
standing-fleet scaffolding itself is no longer canonical. Safety contracts are
maintained: differing cross-tool files produce `.proposed` siblings, and strict
mode rejects TODO-seeded KB content.

---

## Compliance & conventions

- **Validator:** active skills pass `quick_validate.py` (frontmatter schema —
  only `name/description/license/allowed-tools/metadata/compatibility` keys;
  naming; description present and bounded).
- **Anatomy:** every skill is `SKILL.md` + `references/` + `scripts/`, with
  `runbooks/`, `templates/`, `tests/` on the larger ones. Everything
  *enforceable* is a script, not prose; core gate paths are **bash-3.2-safe**
  (macOS system bash).
- **Engine neutrality:** engines and trackers appear only as flags
  (`--adversary codex`, `--tracker linear`, `--agent kimi`) — never in a
  skill's name or hard-coded in a script.
- **Contributing:** validate any change with
  `python3 skills/skill-creator/scripts/quick_validate.py <skill-dir>`; add
  concepts under `references/concepts/`, playbooks under `runbooks/`.

**By the numbers:** 12 skill packages (9 spine + 2 utility + 1 legacy), with full
test and conformance suites in `task-spec` and `task-to-runtime-contract`.

> *"You are converged when the eval passes — not when you feel done."*
