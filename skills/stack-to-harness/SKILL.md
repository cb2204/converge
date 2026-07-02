---
name: stack-to-harness
description: |
  Implements Converge Pass 6 (Harness). Reads the tech stack the in-scope Task-Specs put in play and scaffolds the control plane fitted to exactly that stack: paired architect and developer agents per tech, grounded KBs, a doctrine, rules, and cross-tool mirrors (.claude/ plus AGENTS.md, Cursor, Copilot). This is the quality moat that makes any commodity coding agent succeed. Thin orchestration over the bundled agents-kbs-tech-stack skill; stack-derived, engine-agnostic, no tracker. Use when the user says "scaffold the harness", "build the agents and KBs", "harness pass", "Converge Pass 6", or after Tasking (5B) and before the execution loop. Do NOT use to author tasks (that is task-spec), to run a task (that is task-loop), or to add one tech to an already-standing harness (call agents-kbs-tech-stack directly).
metadata:
  version: "0.2.0"
---

# stack-to-harness — Converge Pass 6 · Harness

The control-plane builder. It reads the system's tech stack — surfaced by the Task-Specs in scope — and scaffolds the harness fitted to exactly that stack: paired `architect` + `developer` agents per tech, grounded KBs, a doctrine, rules, and cross-tool mirrors. This is the **quality moat**: the standing control plane that makes any commodity coding agent succeed. It is thin orchestration over the bundled `agents-kbs-tech-stack` skill, which owns the menu, templates, and scripts.

## Important

- **Stack-derived, not task-derived.** The tasks only *scope* which techs are in play. The harness content comes from the **stack**. A dbt KB exists because the system uses dbt — not because one task named it. Scaffold the tech, not the task.
- **Never scaffold speculatively.** Only build harness for techs the in-scope tasks actually touch. In this repo that is exactly four: `dbt`, `duckdb`, `fastapi`, `mcp`. If a tech is not named by any task, leave it out.
- **Order matters: Tasking (5B) before Harness (6), on purpose.** The tasks are the requirements; the harness is fitted to what they need, never built ahead of them.
- **Delegate; do not reimplement.** All scaffolding is done by the bundled `agents-kbs-tech-stack` skill via its scripts. This skill is the Converge-named wrapper that scopes the stack and drives that skill. Do not hand-write agents or KB files.
- **Converged = the gate passed, not "feels done".** This pass converges when every in-play tech has its paired agents + grounded KB, the `quality-gate` lint is green, and the cross-tool mirrors are emitted. See the Gate below.
- **No engine or tracker flags.** This is a single transformation parameterized by the stack the tasks reveal, not by a model or a board.

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | The in-scope Task-Specs (`tasks/T-*.md`) — they reveal which techs are in play — plus the repo itself. |
| **OUT** | `.claude/` — paired `<tech>-architect` + `<tech>-developer` agents, KB trees under `kb/<tech>/`, `kb/_index.yaml`, `doctrine.yaml`, `rules/`, and the three universal closers — plus emitted mirrors `AGENTS.md`, `.cursor/rules/`, `.github/copilot-instructions.md`. |
| **GATE** | The control plane stands and is grounded: every tech the tasks touch has its architect + developer + KB, the three closers are wired via the closer-hook protocol, the `quality-gate` lint is green, and the cross-tool mirrors are emitted so every engine inherits one contract. |

## Instructions

### Step 1 — Scope the stack from the tasks

Read `tasks/T-*.md` and detect exactly which techs the work touches. Use each spec's `title`, `touches_paths`, and body — not the `agent:` field, which is usually `any`. Map paths to techs: `models/` or dbt configs → `dbt`; DuckDB SQL / `warehouse.duckdb` / macros → `duckdb`; `api/` FastAPI routes → `fastapi`; MCP tool servers → `mcp`.

For this repo the scoped set is `dbt duckdb fastapi mcp` (four techs). Record the set as `TECHS`. Do **not** add a tech no task names, and do **not** drop a tech a task needs. If the mapping is ambiguous, ask once before scaffolding — this is the one judgment call in the pass.

### Step 2 — Confirm the stack is not already covered

Check `.claude/agents/` and `.claude/kb/`. For each tech in `TECHS`, a paired `<tech>-architect.md` + `<tech>-developer.md` and a `kb/<tech>/` tree either exist or do not. The bundled scripts are idempotent (they refuse to clobber), so re-running is safe — but if all four techs are already covered and `quality-gate` is green, this pass is already converged; stop and report rather than re-scaffold.

### Step 3 — Scaffold each tech (delegate)

For each tech in `TECHS`, invoke the bundled skill's scaffold script. It renders the architect + developer templates from `menu/techs.yaml`, seeds the KB tree, and updates `kb/_index.yaml` (additive):

```bash
SKILL=~/.claude/skills/agents-kbs-tech-stack
for TECH in dbt duckdb fastapi mcp; do
  TARGET_REPO="$PWD" \
  PROJECT_NAME="uc-postgres-duckdb-dbt-analytics" \
  PROJECT_DESCRIPTION="Postgres→DuckDB landing with a dbt medallion served read-only over FastAPI + MCP" \
  TECH="$TECH" \
  bash "$SKILL/scripts/scaffold.sh"
done
```

The architect owns judgment (trade-off matrices, thresholds, decision frameworks) and has **no Bash**; the developer owns implementation (production patterns, tests) and **has Bash**. Both ground in the real `kb/<tech>/` tree — never a stub.

### Step 4 — Install the universal closers (once)

Run once per repo so the closed engineering loop is wired:

```bash
TARGET_REPO="$PWD" bash "$SKILL/scripts/install-closers.sh"
```

This installs `code-reviewer`, `code-simplifier`, and `code-documenter`. They are **tech-agnostic by interface, tech-aware by grounding**: at runtime each reads `kb/_index.yaml`, sniffs the file's language, and loads the matching tech KB via the closer-hook protocol. The install skips any closer that already exists — it never overwrites user edits.

### Step 5 — Run the quality gate

```bash
TARGET_REPO="$PWD" bash "$SKILL/scripts/quality-gate.sh" --strict
```

The gate lints for scaffold drift: placeholder leaks, architect role-boundary violations (Bash in an architect's tools), developer alignment (Bash present), and closer wiring. `--strict` exits **7** if any BLOCKER is present; default mode is advisory (exit 0). If a BLOCKER surfaces, fix it (or pipe the verdict into `/codex:rescue`) and re-run until green. **Do not leave this pass on a red gate.**

### Step 6 — Emit the cross-tool mirrors

```bash
TARGET_REPO="$PWD" bash "$SKILL/scripts/emit-cross-tool.sh"
```

This publishes `AGENTS.md` (repo root), `.cursor/rules/*.mdc`, and `.github/copilot-instructions.md` from the canonical `.claude/` surface + `doctrine.yaml`. Emission is idempotent and additive: if a mirror was hand-edited, the emitter writes a `.proposed` sibling and prints a NOTE rather than clobbering. This is what makes Claude, Codex, Cursor, and Copilot read **one** agent contract.

### Step 7 — Confirm the gate and report

Walk the Gate checklist below. Report the scoped tech set, the agent/KB/closer counts, the gate verdict, and the emitted mirror paths. Then hand off to the loop.

## Gate — confirm before leaving this pass

- [ ] Every tech the tasks touch (`dbt`, `duckdb`, `fastapi`, `mcp`) has a paired architect + developer agent.
- [ ] Each agent is grounded in a real `kb/<tech>/` tree registered in `kb/_index.yaml`, not a stub.
- [ ] The three universal closers are installed and wired to the tech KBs via the closer-hook protocol.
- [ ] `doctrine.yaml` exists (the single numeric source of truth for the agents).
- [ ] Cross-tool mirrors (`AGENTS.md`, `.cursor/rules/`, `.github/copilot-instructions.md`) are emitted — one contract, every engine.
- [ ] `quality-gate.sh --strict` exits 0 (no BLOCKER, no scaffold drift).
- [ ] Nothing speculative was scaffolded — only the techs the tasks named.

## Examples

**Example 1 — "Scaffold the harness for this stack."**
Actions: Read `tasks/T-*.md`, detect `dbt duckdb fastapi mcp` (Step 1) → confirm none are already covered (Step 2) → loop `scaffold.sh` over the four techs (Step 3) → `install-closers.sh` (Step 4) → `quality-gate.sh --strict` (Step 5) → `emit-cross-tool.sh` (Step 6) → walk the Gate and report (Step 7).
Result: `.claude/` holds 8 tech agents + 3 closers + 4 KB trees + doctrine; `AGENTS.md` / Cursor / Copilot emitted; gate green. Ready for the loop.

**Example 2 — "Harness pass, but a task only touches dbt and DuckDB."**
Actions: Step 1 scopes `TECHS=dbt duckdb` — FastAPI and MCP have no task in scope, so they are **not** scaffolded. Run Steps 3–6 over the two techs only.
Result: A harness fitted to exactly the tasks in play — the moat, not a mall.

**Example 3 — "Add a Kafka architect to the harness."**
Actions: This is not a Pass 6 scope call — it is a single additive tech. Route the user to call `agents-kbs-tech-stack` directly, after confirming `kafka` exists in `menu/techs.yaml`.
Result: Correct altitude; Pass 6 is reserved for scoping the harness to the task set, not one-off additions.

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `quality-gate.sh` exits 7 | A BLOCKER: placeholder leak, Bash in an architect's tools, or a missing closer | Read the verdict block, fix the flagged file (or pipe it into `/codex:rescue`), re-run `--strict` until green. |
| `scaffold.sh: TECH not in menu` | A scoped tech has no `menu/techs.yaml` entry | Add the tech to the menu first (see the bundled skill's `references/tech-menu-curation.md`), then re-run Step 3. |
| Emitter wrote a `.proposed` file | A cross-tool mirror was hand-edited since the last emit | Diff `AGENTS.md` against `AGENTS.md.proposed`, merge intentionally, delete the `.proposed`. The emitter never clobbers hand edits. |
| Scaffolded a tech no task touches | Step 1 over-scoped | Remove the stray agents + KB; only techs an in-scope task names belong in the harness. |
| KB entries are empty stubs | Scaffold seeds placeholders by design | Populate the `TODO` blocks in `kb/<tech>/` — closer sharpness is bounded by KB content quality. This is where the moat is actually dug. |

## Handoff

→ **`task-loop`** (Pass 8 · The Loop, `--issue N`) reads this harness when it executes each task, grounding the coding agent in the right tech KB. `task-loop` **is** the execution loop: read one task → act → run its eval → RED feeds the failure back and revises (local loop) → GREEN opens a PR.

The **Manager** — which issue runs, when, in parallel, watching PRs — is a **future, separate concern configured in CI/CD (GitHub Actions), not an in-session skill.** There is no `fleet-orchestrator`. A human or CI passes `--issue N` to the loop; the harness must simply stand before the loop starts.

## References

- Bundled skill: `agents-kbs-tech-stack` (`~/.claude/skills/agents-kbs-tech-stack/`) — owns the menu, templates, and all four scripts (`scaffold.sh`, `install-closers.sh`, `quality-gate.sh`, `emit-cross-tool.sh`).
- `references/scoping-the-stack.md` — how to map `tasks/T-*.md` paths to the scoped tech set.
- `references/the-quality-moat.md` — why the harness is the one artifact that outlives the project.
