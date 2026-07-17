---
name: plans-to-coherent-spec
description: Converge Pass 5A (Specify, Fork A — plan-driven). Fuses the two hardened swimlane plans into ONE coherent, coupled spec governed by a single end-to-end eval — the whole system as the unit of trust, not a backlog of atomic tasks. Use on the plan-driven fork when the system is small and tightly coupled and a human will hold one big gate. Trigger phrases include "plan-driven", "one coherent spec", "whole system as one unit", "single end-to-end eval", "Fork A", "speckit spec", "openspec", "bmad". Engine-agnostic via --framework {speckit|kiro|openspec|bmad}, default speckit; no tracker binding. Do NOT use for the task-driven fork (per-unit atomic specs with an eval each) — that is Pass 5B task-spec.
metadata:
  version: "0.3.0"
compatibility: ">=claude-code@1.0"
---

# plans-to-coherent-spec — Converge Pass 5A (Specify, Fork A)

> **Identity:** The fork that fuses two hardened plans into one coherent spec governed by a single end-to-end eval.
> **Domain:** Spec authoring, system-as-unit-of-trust, plan-driven specification (vs. atomic tasking).
> **Converge Pass:** 5A — SPECIFY (Fork A, plan-driven). Sibling of 5B `task-spec` (Fork B, task-driven).
> **Engine/flags:** a spec framework bound via `--framework` (SpecKit / Kiro / OpenSpec / BMAD), default `speckit`. The framework is the engine; this skill is the pass.
> **Stack-agnostic:** the examples below often use a data/warehouse project to make the method vivid, but the pass applies to any system — an API, a service, a CLI, a pipeline. Read the stack names as *one example*, not a requirement.

## Important — read first

- **This is a fork, and forks are mutually exclusive.** Pass 4 (`sketch-plans-adversarial-review`) decides THE FORK. Run 5A **only** if Pass 4 named **Fork A** at the top of both plans. If it named **Fork B**, run 5B `task-spec` instead — never both on the same plans.
- **The unit of trust is the WHOLE system, not a layer or a task.** The spec boundary wraps the entire flow, from its inputs through its internal contract to the answers it serves. If you find yourself writing one spec per layer, you are on the wrong fork.
- **Converged = the eval passed, not "feels done".** This pass produces exactly ONE end-to-end eval. If you cannot write that eval, the spec is not yet coherent enough to leave this pass.
- **Altitude drops but does not hit the floor.** Pass 4 sharpened plans; 5A lowers them into a binding spec + its proof. It does not descend to implementation code (queries, handlers, endpoints) — that is Execution (Pass 8 · The Loop).
- **No tracker.** Fork A has nothing to fan out. Tracker binding belongs to Fork B (`task-spec` → `task-specs-to-issues --tracker`).

## Inputs / Outputs / Gate

| Slot | Artifact |
|------|----------|
| **IN** | The two hardened swimlane plans, sharpened in place by Pass 4 (typically one plan for the *shaping* half — how inputs become the published output — and one for the *exposing* half — how that output is served), each carrying the Fork-A decision at its top, every adversary objection fixed or explicitly owned. *Example — a dbt/warehouse project:* `sketch/<transform>.plan` (the transform pipeline over your source tables) + `sketch/<serving>.plan` (the serving layer over the published tables). |
| **OUT** | ONE coherent, coupled spec at `--specs-dir` (framework-native filename per `--framework`) + exactly ONE end-to-end eval at `specs/e2e-eval.sh`. The two plans become one document; the system is the unit. |
| **GATE** | One coherent spec exists; the whole system is the unit of trust (boundary wraps the whole flow — inputs → internal contract → served answers — not a single layer); a single end-to-end eval defines done and runs against the real flow (prep/ingest → transform → assert output → serve). Done = that eval is green. |

## Flags

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--framework` | `speckit` \| `kiro` \| `openspec` \| `bmad` | `speckit` | Binds the spec framework that hosts the coherent spec — its native sections, spec/plan/tasks split, and review ritual. The framework is swapped at this flag; it is never baked into the skill name. |
| `--specs-dir` | path | `specs/` | Where the coherent spec + the e2e eval are written. |
| `--adrs-dir` | path | `docs/adrs/` | Where a spec-level decision that changes an architecture choice is recorded as an ADR (one-way, append-only). |

**No tracker flag.** This fork does not register a backlog. The unit of trust is the whole spec, so there is nothing to fan out to Linear/GitHub/Jira. Tracker binding belongs to Fork B (`task-specs-to-issues --tracker`).

### Framework note (`--framework`)

The framework decides the spec's *native shape*, not its content. Map the three canonical steps onto whatever the framework calls them:

| Framework | Coherent spec lands as | Notes |
|-----------|------------------------|-------|
| `speckit` (default) | `spec.md` + `plan.md` (single feature dir) | Constitution-checked; the e2e eval is the acceptance criterion. |
| `kiro` | `requirements.md` + `design.md` | One spec dir for the whole system, not one per layer. |
| `openspec` | one change proposal + spec deltas | The delta wraps the whole coupled change, reviewed as one. |
| `bmad` | one PRD-style spec doc | Keep it coupled; do not shard into stories on this fork. |

Whatever the framework's filenames, the invariant holds: **one document, one boundary, one eval.**

## Instructions

Four steps: **LIFT → COUPLE → BIND EVAL → SELF-REVIEW.** Hold spec altitude throughout — the system's shape and contract, not its SQL.

### Step 1 — LIFT (two plans into one spec)

Read both hardened plans and fuse them into ONE coherent spec under `--specs-dir`, rendered in the `--framework`'s native shape.

- **Resolve, don't staple.** Do not paste the plans side by side. Write a single narrative: one plan supplies the shaping half (how raw inputs become the published output), the other supplies the exposing half (how that output is served), and the output/contract layer is the seam where they join. *Example — a dbt/warehouse project:* the transform plan shapes source tables into published tables through your pipeline stages, the serving plan exposes those published tables via an API or MCP tool, and the published-table interface is the seam.
- **Carry Pass 4 forward verbatim.** Every accepted risk and open question the adversary surfaced moves into the spec unchanged. Nothing the adversary raised may be silently dropped in the lift.
- **Hold altitude.** Describe the contract and shape, not the implementation (query bodies, handler code). Drift below spec altitude here means you have started building, not specifying.

### Step 2 — COUPLE (the boundary wraps the whole)

Draw the spec boundary around the entire system, from its inputs through its internal contract to the answers it serves, so the unit of trust is large and coupled — not a layer, not a task.

- **State the one-way dependency as an invariant inside the spec.** Name the source floor, the store or stage each thing flows into, and the single crossing between them; everything reads from the source upward and nothing writes back down. *Example — a dbt/warehouse project:* the source database is the floor, the warehouse the analytical store, the ingest/land step the single read-only crossing; everything reads from the source tables upward.
- **Name the output/contract layer explicitly** as the internal contract both halves agree on. Every served read maps to a field the shaping half actually emits — the contract (its schema) is owned by the shaping half, and the serving half binds to it (never redefines it). *Example — a dbt/warehouse project:* the published-table `schema.yml` is owned by the transform half; every endpoint or MCP tool reads a published column it emits.
- **New architecture choices become ADRs.** Where coupling forces a decision (e.g. full-refresh vs. incremental, single-writer store, read-only reader over the contract layer), record it as an ADR in `--adrs-dir`, append-only, so the record of *why* is never lost.

### Step 3 — BIND EVAL (one end-to-end eval)

Write exactly ONE end-to-end eval at `specs/e2e-eval.sh` and make it the definition of done for the whole spec.

- **It must drive the real flow:** run the project's prep/ingest step, then its transform step, then read the output/contract layer and call the serving layer. *Example — a dbt/warehouse project:* `make seed && make land`, then `dbt build`, then query the published tables and call the API/MCP tool.
- **It must assert the far end:** a known input produces the expected output shape AND the expected served answer. One eval, end to end, unambiguous pass/fail.
- **This is the single artifact the shared Execution gate drives to green.** If you cannot write this eval, the spec is not yet coherent enough to leave this pass — go back to Step 2.
- Run `scripts/scaffold-e2e-eval.sh --specs-dir specs/` to stamp a runnable, repo-grounded skeleton, then fill the assertions.

### Step 4 — Self-review (fresh eyes, fix inline)

Before the gate, re-read the fused spec as if you had not written it, and fix
what you find inline — no re-review loop:

1. **Placeholder scan** — any TBD, TODO, or section that trails off? Fill it or return it to the open-questions list with its owner.
2. **Internal consistency** — do the shaping half and the exposing half agree, section by section? Does the e2e eval actually assert what the spec promises?
3. **Staple check** — does any section still read as "Plan A says… / Plan B says…"? That is a staple, not a lift; rewrite it as one narrative around the seam.
4. **Ambiguity** — could the contract layer be read two ways by the two halves? Pick one reading and pin it.

## Gate — confirm before leaving this pass

Run `scripts/check-coherent-spec.sh --specs-dir specs/` — it mechanically checks the structural items below. The judgment items (marked ⊙) it cannot check; you confirm those by eye.

- [ ] **One coherent spec exists** at `--specs-dir` — the two plans are fused into a single document, not stapled together. ⊙
- [ ] **The whole system is the unit of trust** — the spec boundary wraps the whole flow (inputs → internal contract → served answers), never a single layer or task. ⊙
- [ ] The one-way source → store → output → serving dependency is stated as an invariant inside the spec.
- [ ] The **output/contract layer** is named as the internal contract; every serving read maps to a field the shaping half emits. ⊙
- [ ] Every Pass-4 accepted risk / open question carried forward verbatim — nothing dropped in the lift. ⊙
- [ ] **A single end-to-end eval defines done** (`specs/e2e-eval.sh`), tied to the real flow (prep/ingest → transform → assert output → serve).
- [ ] `specs/e2e-eval.sh` is executable and is syntactically valid bash.
- [ ] Done is defined as "the e2e eval is green," never "looks done." ⊙
- [ ] No tracker registered, no atomic task files written — this is the coupled fork.

When these hold, the coherent spec + its e2e eval enter the shared Execution gate.

## Examples

**Example 1 — a canonical Fork-A run (illustrated with a dbt/warehouse project).**
User says: *"Pass 4 landed Fork A on both plans — lift them into one coherent spec."*
Actions: read the two hardened plans (here, a transform-pipeline plan + a serving-layer plan); fuse into `specs/spec.md` in SpecKit shape (LIFT); wrap the boundary around the whole flow (inputs → published tables → served answers) and name the published-table `schema.yml` seam as the internal contract (COUPLE); scaffold and fill `specs/e2e-eval.sh` driving prep/ingest → transform → query the published tables → hit the endpoint + MCP tool (BIND EVAL); run `scripts/check-coherent-spec.sh`.
Result: one spec, one eval, gate green — enters Execution.

**Example 2 — wrong fork.**
User says: *"Cut these plans into atomic tasks with an eval each and register them in Linear."*
Actions: recognize this as **Fork B** (atomic, tracker-backed, unattended). Decline 5A; route to `task-spec` (5B) then `task-specs-to-issues --tracker linear`.
Result: no coherent spec written; user pointed to the correct fork.

**Example 3 — framework swap.**
User says: *"Same lift, but our team uses OpenSpec."*
Actions: run `--framework openspec`; the coherent spec lands as one change proposal + spec deltas wrapping the whole coupled change; the e2e eval is unchanged (framework decides shape, not the eval).
Result: one OpenSpec change, one eval, one gate.

## Troubleshooting

| Error / symptom | Cause | Solution |
|---|---|---|
| Spec reads as two documents glued together | LIFT stapled the plans instead of resolving them | Rewrite as a single narrative; the output/contract layer is the seam, not a section break. |
| You are writing one spec per layer | You are on the wrong fork (this is Fork B behavior) | Stop. If Pass 4 truly named Fork A, wrap the boundary around the whole system; if it named Fork B, switch to `task-spec`. |
| Cannot write a single end-to-end eval | The plans aren't coherent/coupled enough yet | Return to Step 2 (COUPLE): the seam or an invariant is still ambiguous. Fix it, then bind the eval. |
| Adversary risk missing from the spec | Dropped during LIFT | Re-read the Pass-4 plan tops; carry every accepted risk / open question forward verbatim. |
| Urge to add a `--tracker` flag | Confusing Fork A with Fork B | Fork A has no backlog to register. Leave tracker binding to Fork B. |
| `check-coherent-spec.sh` fails on `e2e-eval.sh` | Eval not executable or invalid bash | `chmod +x specs/e2e-eval.sh`; run `bash -n specs/e2e-eval.sh` and fix syntax. |

## Notes

- **One big gate by design — the human stays longer.** Because the unit of trust is the whole coupled system, a human reviews ONE large spec at ONE gate rather than waving through N atomic tasks. That is the deliberate trade of Fork A: more human at one coherent gate, in exchange for a system verified as a whole. Fork B trades the other way (atomic, unattended, eval-per-task).
- **No-drift in the lift.** The plans were hardened in Pass 4; lifting them must not reopen settled questions or quietly add scope. Accepted risks and open questions move forward unchanged; new architecture choices become ADRs, append-only.
- **Why this order.** Specify (5) sits between Consensus (4) and Execution (7). You cannot bind one end-to-end eval until the plans are coherent and coupled; you cannot drive Execution to green until that eval exists. Coherent spec first, then the loop closes against it — never the reverse.

## Handoff

→ Enters the shared **Execution** gate (Pass 8 · The Loop): `task-loop --issue N` drives the **single end-to-end eval** (`specs/e2e-eval.sh`) to green — read the spec → act → run the eval → RED: feed the failure back and revise (local loop) → GREEN: open a PR. On Fork A the runner converges the whole coupled system against that one eval rather than closing tasks one by one.

There is **no separate Manager skill.** The fan-out concern (which issue, when, in parallel, watching PRs) is a **future, separate CI/CD concern** configured in GitHub Actions, not an in-session skill. A human or CI hands `task-loop` its `--issue N`; the runner never picks which issue to run. Execution closes the gate when the e2e eval passes — it does not lower altitude further.
