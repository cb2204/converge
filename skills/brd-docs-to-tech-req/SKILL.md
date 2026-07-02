---
name: brd-docs-to-tech-req
description: Transforms a client BRD (docs/brd-*.pdf) into a verifiable tech-spec (docs/tech-spec-*.md or .pdf) — the engineering solution shape for the client's problem. Implements Converge Pass 1 (Intent), the top of the chain. Use when a brief has landed and someone says "turn this brief into a tech-spec", "start Converge pass 1", "what are we building", or "what are we actually building here". Runs the Understand / Interrogate / Crystallize steps and gates on restating the problem in one paragraph AND the spec answers it, every requirement falsifiable, success metrics traced to the BRD's KPIs. Stays above the stack — no schema, no engine choice. Do NOT use for architecture or stack decisions (that is Pass 3) or when a signed-off tech-spec already exists (go to Pass 2, tech-req-to-adrs). Engine/format bound via flags, never baked into the name.
metadata:
  version: "0.2.0"
---

# brd-docs-to-tech-req — Converge Pass 1 (Intent)

> **Identity:** The intent compiler — restates the client's problem and crystallizes a verifiable solution shape.
> **Domain:** Requirement comprehension, scope definition, KPI-tied success metrics — above the stack.
> **Converge Pass:** 1 of 8 — Intent. First pass; descends from *the client's problem* to *our verifiable spec*.
> **Engine/flags:** authoring engine is a flag (default: Claude CoWork project, conversational, no repo). No tracker — Pass 1 produces a consensus doc, not issues.

Pass 1 is the highest-altitude pass in Converge. It turns a client's Business Requirements Document — prose pains, unquantified goals, fuzzy scope — into a **tech-spec**: a document where every requirement is falsifiable and every success metric traces to one of the client's own KPIs. It answers exactly one question: **what are we building, and how will we know it works** — never *how* it is built. The stack (here: postgres → duckdb → dbt → MCP) is decided in Pass 3, not here.

## Important

- **The gate is falsifiability, not completeness.** A requirement belongs in the spec only if a future eval could pass or fail it. A requirement that cannot be made falsifiable goes to the open-assumptions list with a named owner — it does not get softened into the spec.
- **Brief-in, spec-out — never blur them.** The BRD is the client's, in the client's words. The tech-spec is ours. The entire job of Pass 1 is the translation between them. Do not paraphrase the BRD and call it a spec.
- **No premature technology.** No schema, no `src/db/01_schema.sql`, no DuckDB, no dbt, no MCP, no framework names. Describe WHAT the engine must do and HOW WELL. Naming a technology here is the most common Pass 1 failure.
- **Converged = the gate passed**, not "feels done." Even at this altitude the discipline holds: "verifiable" means a future eval could decide it.

## Instructions

### Step 1 — Understand (read like the engineer who must deliver it)

Read the BRD (`docs/brd-*.pdf`, e.g. `docs/brd-analytical-backbone.pdf`) as the senior engineer accountable for delivery, not as a summarizer.

- Find the **real pain**: who feels it, when, and what it costs — financial, operational, strategic — in the client's own numbers.
- Separate **symptoms from the underlying problem**. A brief that asks for "a dashboard" usually has a decision the client can't make underneath it.
- Name the **data the engine will act on** at the problem level — the shape of the source, not its schema (here: order, payment, customer, and product records that land as `raw.*` in the warehouse).
- Close by writing, in **one paragraph**, what "solved" looks like from the client's seat. This paragraph is half the gate — write it before you write anything else.

### Step 2 — Interrogate (turn a vague brief into a buildable one)

Surface the **2–3 questions that would most change what gets built**. Draw them from three places:

1. **Scope** — what is in, what is explicitly out, where the boundary is genuinely unclear.
2. **Definition of done** — what the client will point at to say "yes, this works."
3. **Any soft number or claim** — every KPI, threshold, or "fast/reliable/accurate" that isn't yet measurable.

For each question: give **your best default answer** so momentum holds, and **name the client stakeholder** who owns the real answer when it is above the engagement's pay grade. Record these as open assumptions with owners — do not stall waiting for perfect answers, and do not silently invent them.

### Step 3 — Crystallize (write the signable tech-spec)

Write the deliverable back to the client at `docs/tech-spec-*` (e.g. `docs/tech-spec-analytical-engine.pdf`). Structure it:

1. **Problem restated** — one paragraph, plain language, from the client's seat (Step 1's paragraph, sharpened).
2. **Scope** — in / out, explicit, at the problem level.
3. **Requirements** — each one **verifiable** and tied to a client KPI. Phrase every requirement so an eval could pass or fail it (see the falsifiability rewrite in [references/falsifiable-requirements.md](references/falsifiable-requirements.md)).
4. **Success metrics** — as **current → target**, each traced to a KPI in the BRD.
5. **Data named** — the source records the engine consumes, at the problem level.
6. **Open assumptions** — each with a named owner (from Step 2).

Emit per `--out-format`: `pdf` while the spec is a consensus object the client reads and signs; `md` once locked, so Pass 2 can read it. Stay above the stack throughout.

### Step 4 — Gate (confirm before leaving this pass)

Do not descend to Pass 2 until every box is checked. Run the bundled checklist verifier against the spec:

```bash
bash .claude/skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh docs/tech-spec-analytical-engine.md
```

- [ ] You can **restate the client's problem in one paragraph** from the client's seat.
- [ ] The tech-spec **answers the brief** — every client pain maps to at least one requirement.
- [ ] Scope (in / out) is explicit at the **problem level** — what the engine does and how well, not which stack does it.
- [ ] **Every requirement is verifiable** — a future eval could pass or fail it.
- [ ] Success metrics trace to the BRD's KPIs (**current → target**).
- [ ] The **data the engine acts on is named** (the source `raw.*` shape at the problem level).
- [ ] **Open assumptions are recorded**, each with a named owner.
- [ ] **No premature technology** — no schema, no engine, no framework. The stack is Pass 3's.

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | The customer BRD + attachments/threads — `docs/brd-*.pdf` (e.g. `docs/brd-analytical-backbone.pdf`). The *what* and *why*, in the client's words. |
| **OUT** | A tech-spec — `docs/tech-spec-*.md` or `.pdf` (e.g. `docs/tech-spec-analytical-engine.pdf`). The *how-well*, at a level the client signs off on. |
| **GATE** | Restate the problem in one paragraph AND the spec answers it: scope explicit, data named, every requirement falsifiable, success metrics traced to KPIs (current → target), assumptions owned. |

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--engine NAME` | `cowork` | Authoring engine. `cowork` = Claude CoWork project (conversational, no repo, no code) — the canonical Pass 1 engine. Swappable; the gate is engine-invariant. |
| `--out-format md\|pdf` | `pdf` | Deliverable format. `pdf` while the spec is a consensus object the client approves; `md` once locked so the build can read it. |

No tracker flag — Pass 1 emits a single consensus document, not a registered work set. Tracker binding starts at Pass 5B / register.

## Examples

**Example 1 — the canonical trigger.**
User: *"Turn this brief into a tech-spec — start Converge pass 1."* (`docs/brd-analytical-backbone.pdf` is present.)
Actions: Read the BRD (Step 1) → write the one-paragraph problem restatement → surface 2–3 scope/done/soft-number questions with default answers and owners (Step 2) → crystallize `docs/tech-spec-analytical-engine.pdf` with verifiable requirements and current→target metrics (Step 3) → run the gate checklist (Step 4).
Result: A signable tech-spec where every requirement is falsifiable and no technology is named. Hand off to `tech-req-to-adrs`.

**Example 2 — "what are we actually building here?"**
User points at a brief and asks what it really means. Actions: run Understand + Interrogate only; return the one-paragraph restatement plus the 2–3 highest-leverage questions. Result: shared clarity before any spec is committed — the buildable version of the brief.

**Example 3 — premature-stack request (negative).**
User: *"Write the tech-spec — it should use DuckDB and dbt with a star schema."* Actions: accept the intent, but keep the stack out of the spec; record it as an open assumption for Pass 3. Result: the spec says the engine must "model orders and payments into query-ready facts within N seconds," not "use dbt." Technology is deferred, not adopted.

## Troubleshooting

| Error / symptom | Cause | Solution |
|---|---|---|
| A requirement can't be eval'd | It's a wish, not a spec line ("make it fast") | Rewrite as current → target with a measurable threshold, or move it to open-assumptions with an owner. See [references/falsifiable-requirements.md](references/falsifiable-requirements.md). |
| The spec names DuckDB / dbt / a schema | Descended into Pass 3 altitude | Strip the technology; restate as a WHAT/HOW-WELL requirement. The stack is decided in Pass 3. |
| Can't restate the problem in one paragraph | Understand step was skipped or the BRD is genuinely ambiguous | Re-read for the real pain and its cost; if still ambiguous, that's the top Interrogate question — assign it an owner. |
| Success metrics have targets but no baselines | KPI baseline not pulled from the BRD | Every metric is current → target; if current is unknown, record it as an assumption owned by the client. |
| No BRD exists | Pass 1 needs a client problem document as input | Do not invent one. Get the brief first; Pass 1 does not fabricate intent. |
| A signed-off spec already exists | You're re-running a completed pass | Skip to Pass 2 (`tech-req-to-adrs`) unless the brief materially changed. |

## Notes

- **Altitude.** Pass 1 is the highest pass: problem → verifiable spec. It comprehends the *what/why* and produces the *how-well*. Every later pass lowers altitude from here, so ambiguity left here is inherited by all of them.
- **Why this order.** No ADR, plan, task, or eval can be trusted if the problem it serves is unstated or unverifiable. Pass 2 checks this spec against the real repo; a soft Pass 1 makes every pass below it soft. Gate first, descend second.

## Handoff

→ **`tech-req-to-adrs`** (Converge Pass 2) consumes this tech-spec (`docs/tech-spec-*`), reconciles it against the real repo, and records the binding technology decisions as ADRs under `docs/adrs/`.
```
