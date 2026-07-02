---
name: sketch-plans-adversarial-review
description: Runs the Pass 3 swimlane plans through a different model as adversary, sharpens them in place, and decides THE FORK (whole-system plan-driven vs. per-unit task-driven). Implements Converge Pass 4 (Consensus). Use when the user says "adversarial review", "consensus pass", "attack the plans", "have Codex refute this", "find what bites us at build time", or "decide the fork". Engine-agnostic via flags — the adversary is --adversary codex|gemini|gpt (default codex), never baked into the name; no tracker. Do NOT use to write new plans (that is Pass 3 reqs-to-swimlane-plans) or to cut a spec or tasks (that is Pass 5A plans-to-coherent-spec or Pass 5B task-spec) — this pass only hardens existing plans and names the fork.
metadata:
  version: "0.2.0"
compatibility: "Converge chain Pass 4 · Consensus. Runs after Pass 3 (reqs-to-swimlane-plans), before the Pass 5 fork (5A plans-to-coherent-spec / 5B task-spec). Engine/tracker-agnostic."
---

# sketch-plans-adversarial-review

Converge Pass 4 (Consensus): a *different* model attacks each swimlane plan default-to-refuted, every objection is FIXED or ACCEPTED-with-owner, and THE FORK is named — whole-system (plan-driven) or per-unit (task-driven) — before any spec or task is cut.

## Important

- **The adversary must be a different model than the author.** The plans were written by Claude; a different engine (`--adversary`, default `codex`) attacks them. The same model reviewing its own plans produces agreement, not consensus — that defeats the entire pass. This is why Pass 4 binds a *different* model than every other pass in the chain.
- **Default to refuted.** A merely-plausible plan step is not "fine" — the adversary must state why it *might* be wrong or the objection stands. Silence is not passing.
- **Altitude lowers, it does not invert.** Pass 4 hardens what Pass 3 sketched. It creates NO new files and adds NO scope. New requirements are drift — push them back up the chain, never smuggle them in here. The diff on `sketch/*.plan` IS the record of what consensus changed.
- **Nothing is silently dropped.** Every logged objection ends in exactly one of FIX (revised in a plan) or ACCEPT (recorded risk + named owner + reason to proceed).
- **The fork is the decision of this pass, not a footnote.** It must precede Pass 5 because spec-vs-task is a structural choice about where the trust boundary sits. The rest of the chain forks on it; it cannot be deferred.

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | The swimlane plans (`sketch/*.plan`, e.g. `sketch/duckdb-dbt-med-arch.plan`, `sketch/fast-api-mcp.plan`) + the tech-spec (`docs/tech-spec-*.pdf`) + the ADRs (`docs/adrs/*.md`) as ground truth. |
| **OUT** | The **same plans, sharpened in place** (`sketch/*.plan` — the diff is the record) + a short open-questions list + **THE FORK named at the top of every plan**. No new files. |
| **GATE** | Every logged objection is FIXED in a plan or ACCEPTED with a named owner, **AND** the fork is declared at the top of every plan (Fork A whole-system, plan-driven / Fork B per-unit, task-driven) with a reason. Falsifiable — see Step 5. |

## Flags

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--adversary` | `codex` \| `gemini` \| `gpt` | `codex` | Which *different* model runs the refutation. Must differ from the author model (Claude). If the adversary is unavailable, fall back to a fresh same-model session with **no memory** of writing the plans — weaker, but better than self-review in the same context. |

No `--tracker` flag: this pass registers nothing and produces no issues. It sharpens plans in place and decides one fork.

## Instructions

Run the four core steps in order, then the gate. This is Pattern 5 (domain-intelligence): the pass carries the knowledge of *what bites this stack at build time* — the `raw.*` contract from `make land`, DuckDB single-writer, the medallion→serving gold-table interface — and applies it as the lens the adversary attacks through.

### Step 1 — ATTACK (refute as a skeptic who didn't write it)

Hand the plans to the `--adversary` engine, framed as a skeptical principal engineer who did NOT write them and whose job is to REFUTE, not bless.

- **One plan at a time.** Refutation is per-plan and ranked by build-time damage so the cheapest-to-kill wrong idea dies first, at the plan, before any model/mart/endpoint exists.
- **Default to refuted.** Merely plausible is not enough; the adversary must say why a step might be wrong.
- Hunt the build-time bites, using the stack's real seams:
  - **Brownfield assumptions** — where a plan assumes something unproven about the `raw.*` contract produced by `make land`, the stamp/audit columns, or DuckDB's single-writer constraint.
  - **Build order** — gold before silver, an endpoint before the mart it reads, a dbt model before its source lands.
  - **Cross-lane interface** — an FastAPI/MCP endpoint that needs a gold column the medallion lane never emits.
- Demand the **5–7 highest-leverage objections**, ranked by build-time damage, each citing a specific plan section.

### Step 2 — GROUND (check drift vs. tech-spec + ADRs)

The plans answer to the spec and the ADRs, not to the author model's memory of them. For each plan, find where it CONTRADICTS or DRIFTS:

- Claims a requirement it does not actually cover.
- Contradicts the spec's scope (builds something marked out-of-scope, or a metric never asked for).
- Violates a recorded ADR decision (e.g. an ADR pinning DuckDB single-writer, or the medallion layering).
- Disagrees on a number (freshness target, latency budget, success metric).

List each drift as `plan section ↔ spec/ADR section ↔ the conflict`, citing **both** sides. No hand-waving — this catches silent drift where a plan *sounds* right but quietly contradicts the agreed source of truth. If `docs/adrs/` is empty, ground against the tech-spec alone and log "ADRs absent" as an open question — do not invent ADR content.

### Step 3 — SHARPEN (fix or own every objection)

Back with the author model (Claude), take every objection from Steps 1–2 and do exactly one of:

- **FIX** — revise the relevant plan **in place** to resolve it.
- **ACCEPT** — record it as a known risk with a **named owner** and the reason to proceed.

The cross-lane interface (medallion→serving gold-table contract) must survive scrutiny or be corrected. Finish with a short **open-questions list**: each remaining item, its owner, and whether it blocks the build. Nothing may be silently dropped.

### Step 4 — DECIDE THE FORK (name the trust boundary)

State the fork explicitly **at the top of every plan**. The fork is *where the trust boundary sits*:

- **Fork A (plan-driven)** — wraps the whole system in one trust boundary and hands one coherent spec to a single autonomous agent. Choose when the system is small and tightly coupled and only verifies as a whole, and a human will hold one big end-to-end gate.
- **Fork B (task-driven)** — draws the boundary around each unit and cuts the plans into atomic, individually eval-bearing tasks dispatched per unit. Choose when every layer and endpoint has a cheap, runnable eval, so task-by-task convergence beats one big autonomous run.

Record the choice AND the why. Pass 5 only makes sense once the fork is committed.

### Step 5 — GATE (falsifiable; confirm before leaving this pass)

Run the bundled gate to make the exit condition machine-checkable:

```bash
bash .claude/skills/sketch-plans-adversarial-review/scripts/check-consensus-gate.sh sketch/
```

It fails (exit 1) unless all hold:

- [ ] A *different* engine (`--adversary`, default codex) attacked the plans — not the author self-reviewing.
- [ ] Plans were grilled against the tech-spec AND the ADRs for drift, each conflict citing both sides.
- [ ] Every logged objection is FIXED in a plan or ACCEPTED with a named owner — grep finds one resolution per objection.
- [ ] The cross-lane interface (medallion→serving gold-table contract) survived scrutiny or was corrected.
- [ ] **The fork is declared at the top of every plan** — Fork A or Fork B — with a reason.
- [ ] An open-questions list exists; blockers are flagged.

When the gate is green, hand off per the fork (see Examples).

## Examples

**Example 1 — "attack the plans"**
User says *"have Codex refute the swimlane plans."* → Run Step 1 with `--adversary codex` against `sketch/duckdb-dbt-med-arch.plan` then `sketch/fast-api-mcp.plan`, one at a time, default-to-refuted. Codex returns 6 ranked objections, top one: *"the serving lane reads `gold.customer_revenue` but the medallion plan only emits `gold.orders_daily` — interface gap."* → Result: objection logged with a plan-section citation, ready for Step 3.

**Example 2 — "consensus pass" end-to-end**
User says *"run the consensus pass and decide the fork."* → Steps 1–2 surface 7 objections + 2 drifts (a freshness number that contradicts the tech-spec). Step 3 FIXes 6 in place, ACCEPTs 1 to owner `data-eng` (DuckDB single-writer under concurrent load), reconciles the freshness number to the spec. Step 4: every layer and endpoint has a cheap eval → **Fork B (task-driven)** written to the top of both plans with the reason. Step 5 gate is green. → Hand off to `task-spec --tracker repo` (Pass 5B).

**Example 3 — decide Fork A**
Tiny, tightly-coupled system where nothing verifies in isolation. → Step 4 records **Fork A (plan-driven)** at the top of both plans with the reason. → Hand off to `plans-to-coherent-spec` (Pass 5A), which fuses the sharpened plans into one coherent, coupled spec with a single end-to-end eval.

## Troubleshooting

- **Gate fails: "no fork declared."** → Cause: Step 4 skipped, or the fork line isn't at the top of a plan. → Solution: write `FORK: A (plan-driven)` or `FORK: B (task-driven)` + one-line reason at the top of *every* `sketch/*.plan`, then re-run the gate.
- **Gate fails: "objection without resolution."** → Cause: an objection was logged but never marked FIX or ACCEPT. → Solution: for each, either revise the plan in place (FIX) or add `ACCEPT — owner: <name> — reason: ...` (ACCEPT). No silent drops.
- **Adversary blesses everything.** → Cause: not framed default-to-refuted, or the same model is reviewing itself. → Solution: re-frame as a skeptical principal engineer who did NOT write the plans; confirm `--adversary` differs from the author model. If the adversary is down, use a fresh same-model session with no memory of authoring.
- **A new requirement appears during review.** → Cause: scope creep — that is drift, not sharpening. → Solution: log it as an open question and push it back up the chain (Pass 1/2/3). Do not add scope in Pass 4.
- **`docs/adrs/` is empty.** → Cause: Pass 2 ADRs not committed. → Solution: ground against the tech-spec alone and log "ADRs absent" as a blocking open question; do not fabricate ADR content.
- **No plans exist.** → Cause: Pass 3 hasn't run. → Solution: run `reqs-to-swimlane-plans` first; there is nothing to attack yet.

## References

- `references/attack-playbook.md` — the refutation prompt for the adversary, the "default to refuted" framing, and the stack-specific bite list (raw.* contract, DuckDB single-writer, build order, cross-lane gold-table interface).
- `references/the-fork.md` — Fork A vs. Fork B decision rubric, the trust-boundary framing, and how each fork feeds Pass 5A / 5B.
- `scripts/check-consensus-gate.sh` — the falsifiable gate (see Step 5).
