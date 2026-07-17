---
name: pass-to-lesson
description: Converge teaching companion — optional after ANY pass. Turns a just-closed pass's artifacts (BRD, tech-spec, ADRs, plans, specs, task-specs, harness, PRs) into a durable lesson at docs/lessons/lesson-*.md plus a spoken-style walkthrough, so the owner understands what the autonomous chain built — every component, the decision it encodes, what breaks downstream without it, and the roads not taken. Use when someone says "teach me what was built", "explain this pass", "walk me through the tech-spec/ADRs/plans", "debrief the pass", "what did you just do and why", or "start the lesson". Runs Locate / Read / Teach / Quiz and gates on every emitted artifact appearing in the walkthrough, every decision naming a rejected alternative, every term of art defined at first use, and the lesson ending in check-yourself questions. Explains decisions, never reopens them. Do NOT use to run a pass (each pass has its own skill) or to review/attack artifacts (that is Pass 4, sketch-plans-adversarial-review).
metadata:
  version: "0.1.0"
compatibility: "Converge chain · teaching companion (optional, after any pass gate). Engine/tracker-agnostic; bash 3.2+ (macOS system bash safe)."
---

# pass-to-lesson — Converge teaching companion

> **Identity:** The teaching pass — turns a closed pass's artifacts into the owner's understanding, so delegation never becomes ignorance.
> **Domain:** Explanation, pedagogy, decision archaeology — runs at every altitude, changes nothing.
> **Converge Pass:** none — an optional companion, invocable after **any** pass's gate goes green.
> **Engine/flags:** the current session. Depth via `--depth`, the Feynman loop via `--quiz`. No tracker.

Converge delegates the *writing* of every artifact to the chain — but it never delegates the *understanding*. Each pass ends with a gate and a handoff, and the owner is left holding a document they approved but may not be able to explain. This companion closes that gap: after a pass's gate passes, it reads everything the pass produced and teaches it back — component by component, decision by decision — and leaves a durable lesson under `docs/lessons/` so the understanding survives the conversation.

## Important

- **Teaching is part of the delegation contract.** An artifact the owner cannot explain is an artifact nobody owns. The chain wrote it; the owner must be able to defend it. This skill exists so "the autonomous did it" never becomes the answer to "why is it shaped this way?"
- **Teach the why, not the tour.** "This file contains the ADRs" teaches nothing. Every component gets the four-part treatment: what it is, why it is shaped this way, which decision it encodes, and **what breaks downstream without it**. The last part is the test — if you can't say what breaks, you haven't understood the component yet either.
- **Explain decisions, never reopen them.** The lesson is a debrief, not a review. If teaching surfaces a genuine disagreement, record it as a change request against the pass that owns the decision — never silently edit the artifact, and never argue the owner out of the pass's gate.
- **No unexplained jargon.** Every term of art (gate, swimlane, fork, ADR, harness, eval, frontier…) is defined in one plain sentence at first use and collected in the lesson's Vocabulary section. The owner consumes lessons by voice; an undefined term is a stall.
- **The learner's words are the gate.** The lesson isn't done when it's written — it's done when the owner can restate the TL;DR and the top decision in their own words (the quiz, Step 4). Understanding is falsifiable too.
- **Lessons are durable.** Like no-go records, lessons live in the repo (`docs/lessons/`) and are searchable — the owner re-reads them before client calls, onboarding, or the next pass. A lesson that exists only in chat scrollback is a lesson lost.

## Inputs / Outputs / Gate

| | Artifact |
|------|----------|
| **IN** | A pass that just closed (its artifacts, its gate output, the session that produced them) — or any named Converge artifact the owner points at. |
| **OUT** | A lesson at `docs/lessons/lesson-<pass-slug>-<topic>.md` from [references/lesson-template.md](references/lesson-template.md), plus a conversational walkthrough (and, with `--quiz on`, a Feynman check). |
| **GATE** | Every artifact the pass emitted appears in the component walkthrough; every decision names at least one rejected alternative; every term of art is defined at first use; the lesson ends with 3–5 check-yourself questions; nothing in the taught artifacts was modified. |

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--depth full\|brief` | `full` | `full` = every component gets the four-part treatment. `brief` = TL;DR, top three components, top decision — a five-minute debrief for a pass the owner has seen before. |
| `--quiz on\|off` | `on` | `on` = end with the Feynman loop (owner explains back, you correct). `off` = deliver the lesson and stop — for async/absent owners reading the file later. |

## Instructions

### Step 1 — Locate (which pass closed, and what did it emit?)

Identify the pass being taught — from the conversation, or from the freshest artifacts on disk. The artifact map:

| Pass | What it emitted (teach all of it) |
|:--:|---|
| 0 `idea-to-brd` | `docs/brd-*.md` (or `.pdf`) — or a `docs/no-go-*.md` record |
| 1 `brd-docs-to-tech-req` | `docs/tech-spec-*` (requirements, metrics, gap register) |
| 2 `tech-req-to-adrs` | `docs/adrs/NNNN-*.md` + `docs/CONTEXT.md` |
| 3 `reqs-to-swimlane-plans` | `sketch/*.plan`, one per lane |
| 4 `sketch-plans-adversarial-review` | the same plans sharpened in place (the diff IS the artifact) + objection log + the fork declaration |
| 5A `plans-to-coherent-spec` | the one coherent spec + `specs/e2e-eval.sh` |
| 5B `task-spec` | `tasks/T-*.md` — atomic, self-verifying units |
| ① `task-specs-to-issues` | the tracker board — one issue per spec, `blocked-by` edges |
| 6 `stack-to-harness` | `.claude/` (agents, `kb/`, `doctrine.yaml`, `rules/`, closers) + emitted mirrors |
| 8 `task-loop` | the PR (branch, diff, green eval) or the blocked-task report |

Collect the full inventory: every file the pass created or changed (use git — the pass's commits bound the diff), the gate script's output, and any conversation context (locked decisions, accepted objections, open questions).

### Step 2 — Read (build the component inventory)

Read everything in the inventory. For each artifact, list its components at the granularity the owner will meet them — sections of a BRD, individual ADRs, lanes of a plan, fields of a task-spec, agents of a harness. For each component draft the four-part treatment: **what it is · why it is shaped this way · the decision it encodes · what breaks downstream without it**. Where the "why" isn't in the artifact, recover it from the pass's SKILL.md rules, the session, or the gate — and if it is genuinely unrecoverable, say so in the lesson rather than inventing a rationale.

### Step 3 — Teach (write the lesson, then walk it)

Write `docs/lessons/lesson-<pass-slug>-<topic>.md` from [references/lesson-template.md](references/lesson-template.md):

1. **TL;DR** — one breath: what exists now that didn't before, and what it unlocks.
2. **Why this pass exists** — its altitude, what it protects, who consumes its output next.
3. **The artifact, component by component** — the four-part treatment for every component in the inventory. Nothing emitted is skipped; a component too trivial to teach still gets one line saying why it's trivial.
4. **Decisions and roads not taken** — every decision the pass locked, each with at least one rejected alternative and the reason it lost. This is where understanding lives; a decision with no alternative is a description, not a decision.
5. **Vocabulary** — every term of art used above, one plain sentence each.
6. **What to watch** — open questions, `(guessed)` numbers, accepted risks, minor gaps: the lesson's honest edges.
7. **Check yourself** — 3–5 questions the owner should now be able to answer, each pointing at the section that answers it.

Then **walk it conversationally**: short plain-prose paragraphs in the pass's teaching order, voice-friendly — no tables read aloud, no bullet dumps. The file is the record; the walkthrough is the lesson.

### Step 4 — Quiz (the Feynman loop, `--quiz on`)

Ask the owner to explain back, in their own words: (a) the TL;DR, and (b) the single most load-bearing decision and why its alternative lost. Correct gently and concretely — point at the artifact line, not at the lesson. One round is usually enough; stop when the restatement would survive a client asking "why is it built this way?". What the owner *couldn't* restate marks the lesson section to sharpen — fix the file before closing.

Then run the gate checker and walk the checklist:

```bash
bash .claude/skills/pass-to-lesson/scripts/check-lesson.sh docs/lessons/lesson-<pass-slug>-<topic>.md
```

- [ ] **Every emitted artifact appears** in the component walkthrough (inventory vs. Section 3 — no silent skips).
- [ ] **Every decision names a rejected alternative** and why it lost.
- [ ] **Every term of art is defined** at first use and collected under Vocabulary.
- [ ] The lesson **ends with 3–5 check-yourself questions**.
- [ ] **Nothing in the taught artifacts changed** — `git status` is clean apart from the lesson file.
- [ ] (`--quiz on`) The owner **restated the TL;DR and the top decision** in their own words.

## Examples

**Example 1 — the canonical trigger.**
User: *"Pass 1 just closed — teach me what was built."* Actions: locate `docs/tech-spec-analytical-engine.md` and the gate output (Step 1) → inventory its sections and gap register (Step 2) → write `docs/lessons/lesson-pass-1-analytical-engine.md` and walk it: why requirements are falsifiable, which decision made metric M current→target, what the two minor gaps hold hostage (Step 3) → quiz: owner restates why "use DuckDB" was recorded as a preference, not a decision (Step 4). Result: the owner can defend the spec to the client without opening it.

**Example 2 — teach a single artifact, not a whole pass.**
User: *"Walk me through ADR 0003 — I don't get it."* Actions: scope the inventory to that ADR + `docs/CONTEXT.md` terms it uses; four-part treatment for the ADR's fact, evidence, and downstream dependents; `--depth brief` shaped output, lesson appended under `docs/lessons/`. Result: a five-minute targeted lesson, not a full-pass debrief.

**Example 3 — teaching surfaces a disagreement (negative).**
Mid-lesson the owner says *"that scope boundary is wrong — fix it."* Actions: do NOT edit `docs/brd-*.md`; record the objection as a change request against Pass 0 (or the gap register if Pass 1 already consumed it) and finish the lesson noting the contested line. Result: the artifact's provenance stays intact; the change flows through the pass that owns it.

**Example 4 — async owner.**
The pass closed overnight in an autonomous run; the owner reads later. Actions: run with `--quiz off`; the lesson file carries the full walkthrough and the check-yourself questions stand in for the quiz. Result: understanding is waiting in `docs/lessons/` when the owner is.

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| The lesson reads like a changelog ("added X, added Y") | The four-part treatment collapsed to "what it is" | For every component, force the fourth part first: what breaks downstream without it? Rewrite from there. |
| A decision has no alternative to name | It was a description, or the alternative was never articulated | Check the pass's session and gate; if the alternative is genuinely unrecorded, write "alternative unrecorded — inferred: X" and flag it under What to watch. |
| The owner fails the quiz on the same section twice | The lesson section teaches the what, not the why | Rewrite that section around its decision and failure mode, then re-quiz only that section. |
| Teaching keeps turning into re-litigating the pass | Debrief and review got blurred | Park every objection as a change request against the owning pass; the lesson explains the artifact as gated, disagreements ride separately. |
| The lesson is enormous and the owner tunes out | `--depth full` on a pass with a large artifact surface (Pass 6, Pass 5B backlogs) | Use `--depth brief` for the walkthrough and let the full component table live in the file; teach the top three load-bearing components by voice. |
| No one can say which pass produced an artifact | Locate step skipped, or artifacts from several passes are interleaved | Bound the inventory with git (the pass's commits) before teaching; a lesson spanning two passes should be two lessons. |

## Notes

- **Why a companion, not a step inside each pass.** Every pass ends at its gate; welding a lesson onto each would couple ten skills to one pedagogy and make teaching mandatory. As a companion it is one skill, versioned once, invocable after any pass — and skippable when the owner already knows the terrain.
- **Why lessons are files.** The same reason no-go records are: memory that survives the session. `docs/lessons/` becomes the engagement's teaching trail — onboarding material for the next engineer and pre-read for the client call, for free.
- **Voice-first by design.** The owner dictates and listens. The walkthrough is prose a human can speak; the tables stay in the file.

## Handoff

→ None — a lesson changes nothing downstream. The chain continues wherever the taught pass's own handoff points; this companion returns the owner there, now able to explain what they are approving.

## References

- `references/lesson-template.md` — the lesson skeleton (TL;DR · Why this pass exists · Component walkthrough · Decisions and roads not taken · Vocabulary · What to watch · Check yourself) with per-section guidance.
- `scripts/check-lesson.sh` — the gate (sections present, decisions carry alternatives, check-yourself questions counted, vocabulary present).
