---
name: idea-to-brd
description: Converge Pass 0 (Capture) — optional, like Register ①. Turns a raw idea with no client brief — a founder thought, an internal itch, a hallway conversation, a voice-note transcript — into a BRD (docs/brd-*.md or .pdf) written in the owner's voice, so Pass 1 can consume it unchanged. Use when someone says "I have an idea", "capture this idea", "no BRD exists", "write the brief", "grill me about this idea", or "start Converge pass 0". Runs Scope-check / Grill (one question at a time, facts looked up, decisions asked) / Draft / Self-review and gates on the pain carrying a number, at least one KPI in the owner's terms, in/out scope each non-empty, and every open question owned. Produces the brief, NEVER the spec — no requirements, no solution shape, no technology. Do NOT use when a client BRD already exists (enter at Pass 1, brd-docs-to-tech-req) or to write a tech-spec (that IS Pass 1).
metadata:
  version: "0.1.0"
compatibility: "Converge chain Pass 0 · Capture (optional). Runs before Pass 1 (brd-docs-to-tech-req) when no BRD exists. Engine/tracker-agnostic; bash 3.2+ (macOS system bash safe)."
---

# idea-to-brd — Converge Pass 0 (Capture)

> **Identity:** The capture pass — makes a raw idea articulate as a brief, in the owner's voice.
> **Domain:** Idea capture, stakeholder interrogation, problem articulation — one rung above Pass 1.
> **Converge Pass:** 0 of 8 — Capture. **Optional**, like Register ①: client work with a real brief enters at Pass 1 directly; take this pass only when no BRD exists.
> **Engine/flags:** conversational capture (default: the current session). Output format via `--out-format`. No tracker.

Pass 0 is the on-ramp for non-client work. Pass 1's contract assumes a brief has landed (`docs/brd-*.pdf|md`) — but internal projects, founder ideas, and "I have this thing in my head" moments have no client BRD. Without this pass, the temptation is to write the tech-spec directly and skip the brief, which blurs the exact boundary Pass 1 protects (*brief-in, spec-out — never blur them*). Pass 0 produces the missing brief: the pain, the goals, the owner's own numbers — and stops there.

## Important

- **The output is the brief, never the spec.** A BRD states what hurts, who feels it, what it costs, and what success looks like — in the owner's words. The moment it states a requirement, a solution shape, or a technology, it has jumped to Pass 1 altitude (or worse, Pass 3). Pass 0 asks the stakeholder's questions; Pass 1 asks the engineer's.
- **Facts vs decisions.** If a fact can be found by exploring the environment — the repo, prior docs, past engagements — look it up rather than asking. The *decisions* are the owner's: put each one to them and wait. Never burn a question on something a file can answer.
- **One question at a time.** Announce the map of what you want to pin down, then walk it branch by branch. Batching questions is bewildering; momentum comes from offering your best default with each question.
- **"Too small for a BRD" is the anti-pattern.** Every idea goes through this — a one-tool utility, a single report, a config-sized product. Small ideas are where unexamined assumptions cost the most. The BRD can be short (half a page for a truly small idea), but it must exist and pass the gate.
- **Converged = the gate passed**, not "feels captured." The gate is falsifiable: a number in the pain, a KPI in the owner's terms, scope boundaries with entries, owners on every open question.

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | A raw idea with no BRD — a conversation, a voice-note transcript, a whiteboard photo, a half-page of notes. The owner is in the room (or reachable). |
| **OUT** | A BRD at `docs/brd-<slug>.md` (or `.pdf`) in the owner's voice — the same artifact shape a client engagement would hand Pass 1. |
| **GATE** | The pain is stated with a number (cost, count, or frequency); at least one KPI is named in the owner's terms; scope in/out each has at least one entry; every open question has a named owner; no requirement, solution shape, or technology appears. |

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--out-format md\|pdf` | `md` | BRD format. `md` is the default (Pass 1 reads it directly); `pdf` when the brief is itself a consensus object others sign. |
| `--questions one\|batch` | `one` | Interrogation mode. `one` = one question at a time (canonical). `batch` = each round asks every open frontier question at once — for an owner who prefers rounds over turns. |

No `--engine` beyond the session and no tracker — Pass 0 emits one document.

## Instructions

### Step 1 — Scope-check (is this one idea?)

Before asking anything, assess the idea's shape. If it describes multiple independent systems ("a platform with chat, billing, and analytics"), flag the decomposition **first** — don't burn questions refining details of an idea that is really four ideas. Help the owner pick the first slice; each slice gets its own BRD → Pass 1 cycle.

Then explore what the environment already knows: prior BRDs and tech-specs under `docs/`, related repos, earlier notes. Every fact found here is a question you don't ask.

### Step 2 — Grill (the stakeholder's questions, one at a time)

Announce the map — "here is what I want to pin down" — then walk it. The branches, in order of leverage:

1. **The pain** — who feels it, when, and what it costs. Push for a number: hours lost, money leaked, decisions delayed. "A lot" is not a cost.
2. **The goal** — what changes if this exists, in the owner's own metric. This becomes the KPI Pass 1 traces success metrics to.
3. **Scope boundary** — what is explicitly in, what is explicitly out, and which boundary is genuinely undecided.
4. **Success, from the owner's seat** — what will they point at in three months to say "this worked"?
5. **Constraints** — business constraints only (budget, deadline, compliance, people). Technology is not a Pass 0 topic; if the owner names a stack, record it as a *preference* under open questions, never as a decision.

Protocol per question: offer your best default answer grounded in Step 1's findings (*"My recommendation: X — because Y. Confirm or redirect."*); push back exactly once on a vague answer ("give me a number"); lock concrete answers by restating (*"Locked: <answer>."*). What the owner cannot resolve becomes an **open question with a named owner** — never a silently-assumed answer. If the named owner is not in the room, the open-questions section doubles as a questionnaire to send them.

### Step 3 — Draft (write the BRD in the owner's voice)

Write `docs/brd-<slug>.md` from [references/brd-template.md](references/brd-template.md): Problem · Goals & KPIs · Scope (in/out) · Definition of success · Stakeholders · Constraints · Open questions · Source. Every line traces to a locked answer or a Step 1 finding. Keep the owner's vocabulary — the BRD is *theirs*; Pass 1 does the translation to engineering language, not you.

### Step 4 — Self-review, then gate

Re-read the draft with fresh eyes and fix inline (no re-review loop):

1. **Placeholder scan** — any TBD, TODO, or vague filler? Fix or move to open questions.
2. **Internal consistency** — do the goals contradict the scope? Does the success definition match the pain?
3. **Ambiguity** — could any line be read two ways? Pick one, make it explicit.
4. **Altitude** — any requirement, solution shape, or technology that leaked in? Strip it or demote it to a recorded preference.

Then run the gate checker and walk the checklist:

```bash
bash .claude/skills/idea-to-brd/scripts/check-brd.sh docs/brd-<slug>.md
```

- [ ] The **pain carries a number** — cost, count, or frequency, in the Problem section.
- [ ] **At least one KPI** is named in the owner's terms under Goals.
- [ ] **Scope in and out** each have at least one entry; the undecided boundary (if any) is an open question.
- [ ] **Every open question has a named owner.**
- [ ] The BRD is in the **owner's voice** — no requirement, no solution shape, no technology decision.
- [ ] **Definition of success** is written from the owner's seat.

## Examples

**Example 1 — the canonical trigger.**
User: *"I have an idea — grill me and write the brief."* Actions: scope-check (one idea, no prior art under `docs/`) → grill the five branches one question at a time, offering defaults → draft `docs/brd-cost-dashboard.md` in the owner's voice → self-review, strip a leaked "use DuckDB" into a recorded preference → `check-brd.sh` green. Result: a BRD Pass 1 consumes exactly as it would a client's.

**Example 2 — the idea is really four ideas.**
User describes a platform with ingestion, chat, billing, and analytics. Actions: stop at Step 1 — flag the decomposition, help pick the first slice (ingestion), capture only that BRD; the other three become one-line stubs in a parking list. Result: one gated BRD, not a four-headed brief no pass can consume.

**Example 3 — a BRD already exists (negative).**
User: *"Capture this idea"* but `docs/brd-analytical-backbone.pdf` covers it. Actions: point at the existing brief and route to Pass 1 (`brd-docs-to-tech-req`); Pass 0 does not duplicate a landed brief. Result: no second BRD; the chain enters at the right pass.

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| The BRD reads like a spec (requirements, "the system shall") | Altitude leak into Pass 1 | Rewrite in the owner's voice: pains, goals, success — Pass 1 owns the translation to requirements. |
| Gate fails: no number in the Problem section | The pain was accepted as "a lot" / "too slow" | Re-ask with a forced quantifier: hours per week, dollars per month, incidents per quarter. If the owner truly doesn't know, the number becomes an owned open question. |
| The owner keeps naming technologies | Enthusiasm for the how before the what | Record each as a *preference* under open questions ("owner prefers X — revisit at Pass 3"); keep the body technology-free. |
| Questions stall — the owner can't answer | The named owner of that branch isn't in the room | Record it as an open question with the right owner named; the section doubles as a questionnaire to send them. Don't invent the answer. |
| The idea keeps growing mid-grill | Scope-check was skipped or too gentle | Return to Step 1: re-slice, park the growth as new one-line stubs, finish the first slice's BRD. |
| "This is too small to need a BRD" | The anti-pattern | Write the half-page version anyway — the gate still runs. Small ideas hide the costliest assumptions. |

## Notes

- **Why a separate pass, not a Pass 1 mode.** Pass 0 and Pass 1 both interrogate, but they ask different questions: Pass 0 asks the *stakeholder's* (what hurts, what does it cost), Pass 1 asks the *engineer's* (definition of done, soft numbers made measurable, failure expectations). Collapsing them produces a document that is neither a clean brief nor a falsifiable spec — the exact blur Pass 1's first rule forbids.
- **Optional by design.** Like Register ①, this pass is taken only when its precondition holds (no BRD exists). The spine's numbering and story are unchanged; client engagements never see this pass.

## Handoff

→ **`brd-docs-to-tech-req`** (Converge Pass 1, Intent) consumes this BRD exactly as it would a client's — reads it like the engineer who must deliver it, interrogates the engineering questions, and crystallizes the falsifiable tech-spec. Nothing downstream knows or cares that the brief was captured rather than handed over.

## References

- `references/brd-template.md` — the BRD section skeleton (Problem · Goals & KPIs · Scope · Definition of success · Stakeholders · Constraints · Open questions · Source) with per-section guidance.
- `scripts/check-brd.sh` — the falsifiable gate (sections present, pain quantified, KPIs named, open questions owned).
