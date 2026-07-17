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
