# BRD template — Pass 0 output skeleton

The BRD is the owner's document, in the owner's voice. Every section below is
required (the gate checker greps for them); the *content* stays at problem
altitude — no requirements, no solution shape, no technology decisions.

```markdown
# BRD — <idea title>

## Problem

Who feels the pain, when, and what it costs — with at least one number
(hours/week, $/month, incidents/quarter). Symptoms AND the underlying
problem, in the owner's words. "A lot" and "too slow" do not pass the gate.
Every number carries a provenance tag — `(measured)`, `(estimated)`, or
`(guessed)` — and every guessed one has a matching open question to verify it.
Close with the do-nothing answer: what it costs to build nothing — the line
that justifies this BRD existing instead of a no-go record.

## Goals & KPIs

What changes if this exists, stated as the owner's own metric(s).
At least one KPI, ideally current → desired ("reporting takes 3 days → same
day"). These are the KPIs Pass 1 traces its success metrics to.

## Scope

**In:** at least one explicit entry.
**Out:** at least one explicit entry.
**Undecided:** any genuinely open boundary — each one repeated under Open
questions with an owner.

## Definition of success

What the owner will point at in three months to say "this worked."
From the owner's seat, not the builder's.

## Stakeholders

Who owns the idea, who feels the pain, who signs off. Named people or roles.
**When more than one is named: name the decider** — the single person who
breaks ties when stakeholders disagree.

## Risks

The pre-mortem answers: "it's six months from now, this shipped, and it
failed — what killed it?" Each risk is either accepted in writing here or
converted to an owned open question. An empty section means the pre-mortem
was skipped, not that there are no risks.

## Constraints

Business constraints only: budget, deadline, compliance, people.
A technology named by the owner is a *preference*, recorded under Open
questions ("owner prefers X — revisit at Pass 3"), never a constraint here.

## Open questions

- question: "..."
  owner: <named person — required for every entry>
  blocks: <what this holds hostage, if anything>

If an owner is not reachable during capture, this section doubles as the
questionnaire to send them.

## Source

Where the idea came from (conversation date, voice note, whiteboard photo,
meeting) — the provenance Pass 1 can trace lines back to.
```

## Per-section reminders

- **Problem** — half the gate. If you can't quantify the pain, the number
  itself becomes an owned open question; never soften it into prose.
- **Goals & KPIs** — the owner's numbers, not engineering metrics. Latency
  budgets and row counts are Pass 1's translation, not Pass 0's capture.
- **Scope** — one entry each side minimum. An empty "Out" means the boundary
  was never tested; ask "what are we explicitly NOT doing?" before drafting.
- **Open questions** — the honest middle between stalling and inventing.
  Owner required on every record; `(open)` blockers are fine at Pass 0 (they
  become Pass 1's gap register), but they must be *owned*.
- **Risks** — accepted risks stay here in the owner's words; anything that
  needs an answer moves to Open questions with an owner. Don't let the
  pre-mortem's findings evaporate into conversation.

## The no-go record (the other exit)

When the do-nothing test shows tolerable inaction, write
`docs/no-go-<slug>.md` instead of a BRD:

```markdown
# NO-GO — <idea title>

**Date:** <capture date>
**The idea:** <two lines, in the owner's words>
**Why it didn't clear:** <the do-nothing answer, verbatim>
**What would reopen it:** <the condition or number that, if it changed,
makes this worth revisiting>
```

Parked, not deleted — a searchable memory that prevents re-litigating the
same idea from scratch. A no-go record has no handoff and no gate script;
its only job is to exist and be findable.
