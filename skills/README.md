# The Converge Skill Chain

Eleven self-contained Claude Code skills that implement the Converge method —
**nine spine skills** (eight passes + the fork's two branches + Register), one
**harness engine**, and one **authoring tool**. Every skill passes Anthropic's
official validator (**11/11**, checked with
[`skill-creator/scripts/quick_validate.py`](skill-creator/scripts/quick_validate.py)),
and every engine or tracker is bound by a **flag, never a name**.

```text
BRD ──▶ 1 Intent ──▶ 2 Structure ──▶ 3 Decompose ──▶ 4 Consensus ──▶ ◆ THE FORK
                                                                        │
                                        ┌───────────────────────────────┴──────┐
                                        ▼ Fork A                               ▼ Fork B
                                  5A Specify                             5B Tasking ──▶ ① Register
                                        └───────────────┬──────────────────────┘
                                                        ▼
                                       6 Harness ──▶ 8 The Loop ──▶ fleet green ↺
```

| Pass | Skill | One line |
|:--:|-------|----------|
| 1 | [`brd-docs-to-tech-req`](brd-docs-to-tech-req/) | fuzzy BRD → verifiable tech-spec |
| 2 | [`tech-req-to-adrs`](tech-req-to-adrs/) | ground the spec against the real repo → ADRs |
| 3 | [`reqs-to-swimlane-plans`](reqs-to-swimlane-plans/) | cut the work along its natural seams → swimlane plans |
| 4 | [`sketch-plans-adversarial-review`](sketch-plans-adversarial-review/) | a *different* model attacks the plans · **the fork is decided** |
| 5A | [`plans-to-coherent-spec`](plans-to-coherent-spec/) | Fork A — one coherent spec, one e2e eval |
| 5B | [`task-spec`](task-spec/) | Fork B — atomic, self-verifying units · **the cornerstone** |
| ① | [`task-specs-to-issues`](task-specs-to-issues/) | one spec = one tracked issue · the board is state |
| 6 | [`stack-to-harness`](stack-to-harness/) | scaffold the control plane the stack needs · the quality moat |
| 8 | [`task-loop`](task-loop/) | one issue → green-eval PR · the execution loop |
| — | [`agents-kbs-tech-stack`](agents-kbs-tech-stack/) | *engine* — the scaffolder Pass 6 drives |
| — | [`skill-creator`](skill-creator/) | *tooling* — author, evaluate, and validate skills |

**Install into a consuming repo** (symlink tracks upstream; copy pins a version):

```bash
for s in /path/to/converge/skills/*/; do
  ln -s "$s" ".claude/skills/$(basename "$s")"
done
```

---

## The spine skills, one by one

### 1 · `brd-docs-to-tech-req` — the client hands you the problem; you produce the spec

Reads a client BRD like a senior engineer, not a stenographer: finds the real
problem underneath the ask, grills the 2–3 questions whose answers most change
the build, and crystallizes one tech-spec with falsifiable requirements and
metrics traced to the BRD's KPIs. Ambiguity killed here is the cheapest kill in
the whole descent.
**Ships:** `check-tech-spec.sh` (the gate linter). **Flags:** `--engine cowork`, `--out-format pdf`.
**Gate:** you can restate the client's problem in one breath and show the spec answers it.

### 2 · `tech-req-to-adrs` — greenfield or brownfield, and write the ADRs

Names the ground (brownfield = a system you didn't write), opens the system end
to end, reconciles the spec against real schemas, sources, and jobs, and records
each grounding decision as a numbered ADR under `docs/adrs/`. ADRs record what
is *true* — never how to build; the moment an ADR says "build X", you've
drifted into planning.
**Ships:** `scaffold-adr.sh`. **Engine:** fixed — Claude Code on the repo.
**Gate:** terrain understood, every grounding decision recorded durably.

### 3 · `reqs-to-swimlane-plans` — split the work along its natural seams

Same session as Pass 2, ADRs in hand: cuts where the system is already jointed
(feature or component edges) and gives each seam exactly one focus-oriented
sketch plan under `sketch/*.plan`. The right number of lanes is the number of
genuine seams — no more, no fewer. Plan-altitude only: no tasks, no SQL.
**Ships:** `new-plan.sh`.
**Gate:** one plan per genuine seam, each inheriting the relevant ADRs.

### 4 · `sketch-plans-adversarial-review` — a different model refutes the plans

A model won't refute itself hard enough, so this pass binds a *different*
engine (`--adversary codex|gemini|gpt`) as a skeptic who defaults to
"refuted." Every objection is FIXED in a plan or ACCEPTED with a named owner —
nothing silently dropped. The pass ends by deciding **the fork**: does the
trust boundary wrap the whole system (Fork A) or each unit (Fork B)?
**Ships:** `check-consensus-gate.sh`, `references/attack-playbook.md`, `references/the-fork.md`.
**Gate:** no open objection survives **and** the fork is declared with a reason.

### 5A · `plans-to-coherent-spec` — Fork A · one coherent spec (plan-driven)

For tightly-coupled systems where pieces only make sense together: fuses the
hardened swimlane plans into ONE coupled specification — the named SDD
frameworks (SpecKit, Kiro, OpenSpec, BMAD) live here via `--framework` — and
binds a single end-to-end eval that defines done for the whole.
**Ships:** `scaffold-e2e-eval.sh`, `check-coherent-spec.sh`.
**Gate:** one coherent spec, the whole system as its unit of trust, one e2e eval runs.

### 5B · `task-spec` — Fork B · the cornerstone unit (task-driven) · v3.2.0

The deepest skill in the chain: atomic, vendor-neutral, **self-verifying**
Task-Spec v3 units. Each `tasks/T-*.md` carries YAML frontmatter + six zones +
≥3 runnable bash evals + an Exit Check — the definition of done travels inside
the file. Two gates are duals: `safe-to-delegate.sh --stamp` (PRE — certifies
the *spec*, HMAC-seals the evals) and `accept-task.sh --stamp` (POST —
certifies the *work*: clean-checkout eval pass, blast radius, HMAC recheck,
optional gold-sanity Goodhart guard). Locked atomic status transitions, a
rebuildable state index, an append-only metrics ledger, an L0–L2 executor
conformance suite, and seven dispatch recipes (Claude, Codex, Kimi, Gemini,
taskship, anthive, custom) round out the runtime.
**Ships:** 20 scripts · 19 reference docs · 19 runbooks · JSON Schemas · test + conformance suites.
**Gate:** every task carries a runnable eval — *no eval, not a task yet.*
Full details: [`task-spec/README.md`](task-spec/README.md) · deep-dive PDF: [`../docs/task-spec-v3.2.0.pdf`](../docs/task-spec-v3.2.0.pdf).

### ① · `task-specs-to-issues` — the tracker as state

Projects each signed-off Task-Spec onto exactly one tracker issue
(`--tracker github|linear|jira`), with `blocked-by` links carrying the
`depends_on` graph — so the execution loop reads a board instead of re-deriving
state. The tracker is a pluggable backend behind a two-method adapter (read
ready / write result). Only the loop writes state; only a green eval closes an
issue — so the board never lies.
**Ships:** `register.sh`, `verify-registration.sh` (1:1, no orphans, **no cycles**).
**Gate:** `count(issues) == count(signed-off specs)`, every dependency edge is one link.

### 6 · `stack-to-harness` — the quality moat

Reads which techs the in-scope tasks put in play and scaffolds the control
plane fitted to exactly that stack — paired architect + developer agents per
tech, grounded KBs, doctrine, rules, and cross-tool mirrors. Thin orchestration
over `agents-kbs-tech-stack`; scaffolds only what the system actually uses,
never speculatively. The stack fills the harness; the tasks point at it.
**Ships:** delegates to the engine below.
**Gate:** the control plane stands and is grounded; the quality-gate lint is green.

### 8 · `task-loop` — one issue → green-eval PR

The execution loop you build (the Manager that schedules it is future CI/CD).
Takes ONE issue (`--issue N`), reads its task-spec + cited ADRs + grounded
harness, cuts a branch, writes code, runs the task's own eval. RED: feed the
failure back and revise — a tight local loop. GREEN: open a PR that closes the
issue. Bounded by the spec's `budget_iterations`; failure exits as an explicit
blocked-task report, never silence.
**Ships:** `run-issue-eval.sh`, `open-issue-pr.sh`, `references/blocked-task-report.md`. **Flags:** `--issue N` (required), `--agent claude|codex|kimi`.
**Gate:** the task's own eval is green — none by hand, none by attempt-count.

---

## The engine and the tooling

### `agents-kbs-tech-stack` — the scaffolder Pass 6 drives (v0.3.0)

For each tech on the curated menu it produces a **paired** architect (planning,
no Bash) + developer (code + tests, has Bash) agent and a full KB tree, installs
three universal closers (code-reviewer, code-simplifier, code-documenter) wired
via the closer-hook protocol, and **emits cross-tool mirrors** — `AGENTS.md`,
Cursor rules, Copilot instructions — so every engine inherits one contract. A
`quality-gate.sh` pass lints the scaffold for drift (`--strict` exits non-zero
on any BLOCKER); a tunable `doctrine.yaml` captures the portable defaults.
**Ships:** 10 scripts, 6 references, 2 runbooks, 19 templates.

### `skill-creator` — author, evaluate, validate

Anthropic's skill-authoring toolkit, vendored so the chain can maintain itself:
create/edit skills, run eval benchmarks (`run_eval.py`, `run_loop.py`,
grader/comparator/analyzer agents), package for distribution, and validate
structure (`quick_validate.py` — the check every skill in this folder passes).
**Ships:** 9 Python scripts + an eval-viewer (its own `generate_review.py`).

---

## Compliance & conventions

- **Validator:** all 11 skills pass `quick_validate.py` (frontmatter schema —
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

**By the numbers:** 11 skills · 53 shell scripts · 11 Python scripts ·
41 reference docs · 21 runbooks · full test + conformance suites in `task-spec`.

> *"You are converged when the eval passes — not when you feel done."*
