---
name: sketch-plans-adversarial-review
description: Runs the Pass 3 swimlane plans through a different model as adversary, sharpens them in place, and hands off to task-driven decomposition (Pass 5B). Implements Converge Pass 4 (Consensus). The fork is COLLAPSED (v3.4) — consensus always flows to task-driven — the plan-driven path (Fork A / SDD) is retired now that task-spec is a six-tier sizing engine that scales from a one-liner to a whole backbone. Use when the user says "adversarial review", "consensus pass", "attack the plans", "have Codex refute this", or "find what bites us at build time". Engine-agnostic via flags — the adversary is --adversary codex|gemini|gpt (default codex), never baked into the name; no tracker. Do NOT use to write new plans (that is Pass 3 reqs-to-swimlane-plans) or to cut tasks (that is Pass 5B task-spec) — this pass only hardens existing plans; the gate stamps FORK B (task-driven).
metadata:
  version: "0.5.0"
compatibility: "Converge chain Pass 4 · Consensus. Runs after Pass 3 (reqs-to-swimlane-plans), before Pass 5B (task-spec) — the fork is collapsed to task-driven. Engine/tracker-agnostic."
---

# sketch-plans-adversarial-review

Converge Pass 4 (Consensus): a *different* model attacks each swimlane plan default-to-refuted, every objection is FIXED or ACCEPTED-with-owner, and the hardened plans hand off to **task-driven decomposition** (Pass 5B). The fork is collapsed (v3.4): there is no plan-vs-task choice — `FORK: B (task-driven)` is stamped as a constant.

## Important

- **The adversary must be a different model than the author.** The plans were written by Claude; a different engine (`--adversary`, default `codex`) attacks them. The same model reviewing its own plans produces agreement, not consensus — that defeats the entire pass. This is why Pass 4 binds a *different* model than every other pass in the chain.
- **Default to refuted.** A merely-plausible plan step is not "fine" — the adversary must state why it *might* be wrong or the objection stands. Silence is not passing.
- **Altitude lowers, it does not invert.** Pass 4 hardens what Pass 3 sketched. It creates NO new files and adds NO scope. New requirements are drift — push them back up the chain, never smuggle them in here. The diff on `sketch/*.plan` IS the record of what consensus changed.
- **Nothing is silently dropped.** Every logged objection ends in exactly one of FIX (revised in a plan) or ACCEPT (recorded risk + named owner + reason to proceed).
- **The fork is a constant, not a decision (v3.4).** Consensus always hands off to task-driven decomposition (Pass 5B); `FORK: B (task-driven)` is stamped on every plan. The plan-driven path (Fork A / SDD) is retired — task-spec's six-tier sizing engine absorbs the whole range (a coupled slice is an L leaf, not a separate paradigm).

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | The swimlane tree (`sketch/swimlane-<seam>/` — a lean PRD + one file per leg, from Pass 3 v0.7.0) + the tech-spec + the ADRs (`docs/adrs/*.md`) as ground truth, handed to a **different-family** adversary via the framed [`attack-playbook.md`](references/attack-playbook.md). |
| **OUT** | The **same plans, sharpened in place** (the diff is the record) + **THE FORK named at the top of every swimlane PRD** + a **stamped objection log** at `sketch/.consensus/objection-log.json` ([schema](references/objection-log.schema.json)) — the deterministic gate target. No new plan files. |
| **GATE** | A **different-family** model attacked (proven by the artifact's provenance stamp + input hashes, *not* a grep of a word); every objection is FIX or ACCEPT-with-owner; the fork is declared (in the artifact **and** atop every PRD); and the plans have **not drifted** since the review (the gate re-hashes them). Falsifiable — see Step 5. `check-consensus-gate.sh` ends in `CHECK_CONSENSUS=OK\|FAIL\|EMPTY\|USAGE_ERROR`. |

## Flags

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--adversary` | `codex` \| `kimi` \| `gemini` | `codex` | Which *different-**family*** model runs the refutation. The invariant is a **different family** than the author (Claude = anthropic): `codex`=openai, `kimi`=moonshot, `gemini`=google. Self-preference bias is measured and family-correlated, so same-family review under-reports its own flaws. `claude -p` (fresh, no memory) is the explicitly-**weaker fallback** only. Dispatched headless by `cvg review --adversary <e>` (see `references/engine-adapter.md`). |

No `--tracker` flag: this pass registers nothing and produces no issues. It sharpens plans in place and stamps the constant fork (task-driven).

## Instructions

Run the four core steps in order, then the gate. This is Pattern 5 (domain-intelligence): the pass carries the knowledge of *what bites your stack at build time* — the real contracts, constraints, and cross-lane interfaces of the system being built — and applies it as the lens the adversary attacks through. (Example — in a dbt/warehouse project the bites might be the raw/source table contract produced by the ingest step, a single-writer data store, and the published-table interface the serving lane reads; in another stack they will be different seams. Name your own.)

### Step 1 — ATTACK (refute as a skeptic who didn't write it)

Dispatch the swimlane tree to the `--adversary` engine (headless, read-only, via `cvg review --adversary <e>`), framed by [`attack-playbook.md`](references/attack-playbook.md) as a skeptical principal engineer who did NOT write them and whose job is to REFUTE, not bless. The adversary **emits the stamped objection log** (`sketch/.consensus/objection-log.json`), never edits the plans.

- **One swimlane at a time, then leg by leg.** Refutation is per-lane and per-leg (Pass 3 is now `sketch/swimlane-<seam>/` with one file per leg), ranked by build-time damage so the cheapest-to-kill wrong idea dies first — before any model/mart/endpoint exists.
- **Default to refuted.** Merely plausible is not enough; the adversary must say why a step might be wrong.
- Hunt the build-time bites, using your stack's real seams:
  - **Unverified assumptions about existing state** — where a plan assumes something unproven about the shape of a source/input contract, required audit/lineage columns, or a data-store constraint (e.g. single-writer, transaction limits).
  - **Build order** — a downstream artifact before the upstream it depends on: an output layer before the intermediate it derives from, an endpoint before the table it reads, a transform before its source is available.
  - **Cross-lane interface** — a consumer in one lane needs a field or contract that the producing lane never emits. (For example, in a warehouse-plus-serving project: a serving endpoint reads a column the transform lane never publishes.)
- Demand the **5–7 highest-leverage objections**, ranked by build-time damage, each citing a specific plan section.

### Step 2 — GROUND (check drift vs. tech-spec + ADRs)

The plans answer to the spec and the ADRs, not to the author model's memory of them. For each plan, find where it CONTRADICTS or DRIFTS:

- Claims a requirement it does not actually cover.
- Contradicts the spec's scope (builds something marked out-of-scope, or a metric never asked for).
- Violates a recorded ADR decision (e.g. an ADR pinning a data-store constraint, or the chosen layering/architecture).
- Disagrees on a number (freshness target, latency budget, success metric).

List each drift as `plan section ↔ spec/ADR section ↔ the conflict`, citing **both** sides. No hand-waving — this catches silent drift where a plan *sounds* right but quietly contradicts the agreed source of truth. If `docs/adrs/` is empty, ground against the tech-spec alone and log "ADRs absent" as an open question — do not invent ADR content.

### Step 3 — SHARPEN (fix or own every objection)

Back with the author model (Claude), take every objection from Steps 1–2 and do exactly one of:

- **FIX** — revise the relevant plan **in place** to resolve it.
- **ACCEPT** — record it as a known risk with a **named owner** and the reason to proceed.

**When argument can't settle an objection, settle it with a throwaway prototype.**
Some objections are empirical — "that join explodes at this volume", "that state
model can't express refunds" — and arguing them in prose just trades opinions.
Build the smallest disposable artifact that answers the question (a query
against real data, a 30-line state machine, a mocked contract), run it, and let
the result decide FIX or ACCEPT. The prototype is *evidence, not deliverable*:
throw it away afterwards. If it produced a snippet that encodes the decision
more precisely than prose can (a schema shape, a state machine, a contract),
inline just the decision-rich part into the plan and note it came from a
prototype — never the working demo itself, and never as implementation code
(the altitude rule still holds; the snippet records a *decision*).

Every cross-lane interface (the contract each lane hands to the next) must survive scrutiny or be corrected. Finish with a short **open-questions list**: each remaining item, its owner, and whether it blocks the build. Nothing may be silently dropped.

### Step 4 — STAMP THE FORK (constant: task-driven)

Stamp the fork **at the top of every plan** — it is now a constant: `FORK: B (task-driven)` + a one-line reason.

- **Fork B (task-driven) — THE path.** Draw the boundary around each unit and decompose the plans into task-specs, sized XS→XXL by the task-spec engine (XL/XXL nodes decompose further into leaf atoms). Every unit carries a cheap runnable eval; task-by-task convergence composes back up.
- **Fork A (plan-driven) — RETIRED.** It wrapped the whole system in one SDD spec. Removed in v3.4: frontier models execute well-scoped atoms reliably, and a tree of verified atoms composes more safely than one monolith. If a slice "only verifies as a whole," make it an L leaf (one coherent goal, glm) — not a separate paradigm. See `references/the-fork.md`.

Record the choice AND the why. Pass 5 only makes sense once the fork is committed.

### Step 5 — GATE (falsifiable; confirm before leaving this pass)

Run the bundled gate to make the exit condition machine-checkable:

```bash
bash .claude/skills/sketch-plans-adversarial-review/scripts/check-consensus-gate.sh --dir sketch/
# validates sketch/.consensus/objection-log.json (structure + provenance hashes);
# ends in CHECK_CONSENSUS=OK|FAIL|EMPTY|USAGE_ERROR. cvg review --check wraps this.
```

It fails (`CHECK_CONSENSUS=FAIL`, exit 1) unless all hold — checked against the
**stamped objection log**, not plan prose (so "a different model attacked" is
un-spoofable):

- [ ] A **different-family** engine (`--adversary`, default codex=openai) attacked — proven by the objection log's provenance stamp (engine/model/family + input `sha256`s that match the live plans), not a grep of a word.
- [ ] Plans were grilled against the tech-spec AND the ADRs for drift, each conflict citing both sides.
- [ ] Every logged objection is FIXED in a plan or ACCEPTED with a named owner — grep finds one resolution per objection.
- [ ] Every cross-lane interface (the contract each lane hands to the next) survived scrutiny or was corrected.
- [ ] **`FORK: B (task-driven)` is declared at the top of every plan** — with a reason (the fork is a constant now).
- [ ] An open-questions list exists; blockers are flagged.

When the gate is green, hand off per the fork (see Examples). *Optional debrief:* **`pass-to-lesson`** teaches what this pass just sharpened — the surviving objections, the fork and why it won — before the descent continues.

## Examples

**Example 1 — "attack the plans"**
User says *"have Codex refute the swimlane plans."* → Run Step 1 with `--adversary codex` against each `sketch/*.plan`, one at a time, default-to-refuted. The adversary returns 6 ranked objections, top one being a cross-lane interface gap — *a consumer lane reads a field the producing lane never emits* (for example, in a warehouse-plus-serving project: a serving endpoint reads a published column the transform lane never emits). → Result: objection logged with a plan-section citation, ready for Step 3.

**Example 2 — "consensus pass" end-to-end**
User says *"run the consensus pass and decide the fork."* → Steps 1–2 surface 7 objections + 2 drifts (e.g. a freshness or latency number that contradicts the tech-spec). Step 3 FIXes 6 in place, ACCEPTs 1 to a named owner (a data-store constraint under concurrent load), reconciles the drifting number to the spec. Step 4: every lane and endpoint has a cheap, runnable eval → **Fork B (task-driven)** written to the top of every plan with the reason. Step 5 gate is green. → Hand off to `task-spec --tracker repo` (Pass 5B).

**Example 3 — a tightly-coupled slice that "only verifies as a whole"**
Previously this was Fork A. Now: record **`FORK: B (task-driven)`** like everything else, and make the coupled slice a single **L leaf** (one coherent done-condition, `execution_backend: glm`) inside the task tree — not a separate plan-driven paradigm. → Hand off to `task-spec` (Pass 5B).

## Troubleshooting

- **Gate fails: "no fork declared."** → Cause: the fork line isn't at the top of a plan. → Solution: write `FORK: B (task-driven)` + one-line reason at the top of *every* `sketch/*.plan`, then re-run the gate. (Fork A is retired; the gate rejects `fork.choice: A`.)
- **Gate fails: "objection without resolution."** → Cause: an objection was logged but never marked FIX or ACCEPT. → Solution: for each, either revise the plan in place (FIX) or add `ACCEPT — owner: <name> — reason: ...` (ACCEPT). No silent drops.
- **Adversary blesses everything.** → Cause: not framed default-to-refuted, or the same model is reviewing itself. → Solution: re-frame as a skeptical principal engineer who did NOT write the plans; confirm `--adversary` differs from the author model. If the adversary is down, use a fresh same-model session with no memory of authoring.
- **A new requirement appears during review.** → Cause: scope creep — that is drift, not sharpening. → Solution: log it as an open question and push it back up the chain (Pass 1/2/3). Do not add scope in Pass 4.
- **`docs/adrs/` is empty.** → Cause: Pass 2 ADRs not committed. → Solution: ground against the tech-spec alone and log "ADRs absent" as a blocking open question; do not fabricate ADR content.
- **No plans exist.** → Cause: Pass 3 hasn't run. → Solution: run `reqs-to-swimlane-plans` first; there is nothing to attack yet.

## References

- `references/attack-playbook.md` — the adversary's system prompt (default-to-refuted), the cross-family + per-leg dispatch contract, and the stack's build-time bite list.
- `references/engine-adapter.md` — how `cvg review` dispatches a headless engine (the read-only + schema-JSON + timeout + provenance contract, the invocation cheatsheet, `cvg doctor`).
- `references/objection-log.schema.json` — the stamped review-record schema the gate validates.
- `references/the-fork.md` — why the fork existed and why task-driven (B) won; the collapse to a single path (v3.4).
- `scripts/check-consensus-gate.sh` — the falsifiable gate on the objection log (see Step 5); `tests/run-tests.sh` proves it discriminates.
