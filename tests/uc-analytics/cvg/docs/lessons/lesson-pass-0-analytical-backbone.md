# Lesson — Pass 0 (Capture): the Analytical Backbone BRD

> Taught 2026-07-19, after the owner marked
> [`docs/brd-analytical-backbone.md`](../brd-analytical-backbone.md)
> canonical. Pass skill: `idea-to-brd` v0.4.0 · gate: `check-brd.sh` exit 0.

## TL;DR

A canonical BRD now exists: partners crashing production plus a blind
business became one signed problem statement with KPIs, scope, risks, and a
$1,000/month ceiling — Pass 1's raw material.

## Why this pass exists

Pass 0 is the highest altitude in the descent: it turns a raw idea living in
the owner's head into a Business Requirements Document, before any
requirement, architecture, or technology is allowed to exist. Its invariant
is **capture facts, never solutions** — the moment a stack choice or a
design sneaks into the BRD, every later pass inherits an unexamined
decision. The pass interviews the owner (the frontier-rounds grill), reads
the terrain first so it never asks what the repo already answers, and ends
at a gate that checks the document is quantified, scoped, risk-aware, and
signed. Pass 1 (`brd-docs-to-tech-req`) consumes the BRD next, converting
the owner's voice into falsifiable technical requirements.

## The artifact, component by component

### Executive summary

- **What it is:** the whole brief in one breath — problem, phase-one shape,
  ceiling, and what it unlocks.
- **Why it is shaped this way:** added by the v0.4.0 field audit; real-world
  BRDs open with a summary because approvers and late readers decide from
  the first screen.
- **The decision it encodes:** phase one is the backbone plus the production
  lockdown; AI ambitions are explicitly phase two.
- **What breaks downstream without it:** every consumer of the BRD — Pass 1,
  a new engineer, the client on a call — must reconstruct the point from
  eight sections, and each reconstructs it slightly differently.

### Problem

- **What it is:** the pain in the owner's voice: partners run analytical
  queries against the only database that exists, it crashes, and underneath
  that the business has no analytical sight at all.
- **Why it is shaped this way:** the gate requires a quantified problem (at
  least one number) and the do-nothing test — "if we build nothing" is
  answered in writing.
- **The decision it encodes:** the do-nothing cost is intolerable, which is
  why this file is a BRD and not a no-go record.
- **What breaks downstream without it:** Pass 1 cannot rank requirements
  against a pain it cannot see, and the do-nothing baseline that justifies
  every later dollar is lost.

### Goals & KPIs

- **What it is:** three KPIs — answers in under 1 hour, analytical traffic
  on production driven to zero, at least one data-backed roadmap decision —
  plus near-real-time freshness named as the hard part.
- **Why it is shaped this way:** goals must be falsifiable (current →
  target), or the definition of success becomes vibes.
- **The decision it encodes:** freshness is near-real-time, not daily batch
  — resolved during capture, not left open.
- **What breaks downstream without it:** Pass 1 has no metrics to descend
  from, and Pass 8 has nothing to prove the system against.

### Scope

- **What it is:** In / Out / Undecided — backbone, freshness, partner
  migration, and the production lockdown are in; touching the operational
  system, the AI phase, and the silent-failure idea are out.
- **Why it is shaped this way:** an unscoped BRD leaks into everything;
  the Out list is what keeps phase one small enough to land fast.
- **The decision it encodes:** the lockdown is a hard requirement (born from
  the pre-mortem), and partner migration belongs to phase one because it is
  the low-hanging fruit.
- **What breaks downstream without it:** Pass 3 plans lanes for work nobody
  agreed to, and phase one grows until it cannot justify phase two.

### Definition of success

- **What it is:** the three-month picture: backbone in production, near-real-
  time flow, sub-hour answers, zero analytical traffic on production, one
  real decision made from backbone data.
- **Why it is shaped this way:** success must be a scene you can check, not
  a feeling — it restates the KPIs as one observable end state.
- **The decision it encodes:** "done" includes production lockdown and a
  consumed insight, not just a running pipeline.
- **What breaks downstream without it:** the chain can go eval-green on
  every task while phase one still fails, because nobody wrote down what
  winning looks like.

### Stakeholders

- **What it is:** the cast — VP of Engineering as owner/decider, partner
  integration teams, operations/on-call, business leadership.
- **Why it is shaped this way:** the gate demands a named decider; ties must
  have a breaker.
- **The decision it encodes:** the VP of Engineering breaks all ties.
- **What breaks downstream without it:** Pass 1's interrogation and Pass 4's
  fork have no one authorized to settle them, and blockers queue forever.

### Risks

- **What it is:** the pre-mortem's three killers — partners keep querying
  production, cost outgrows the budget, the business never looks at the
  analytics — each marked mitigated or accepted in writing.
- **Why it is shaped this way:** v0.2.0 hardening made the pre-mortem
  ("it shipped and failed — what killed it?") feed the Risks section
  directly.
- **The decision it encodes:** the first risk was not accepted — it became
  the lockdown requirement; the other two are accepted with checks.
- **What breaks downstream without it:** the failure modes surface in
  production instead of in a paragraph, where they cost hours instead of
  words.

### Constraints

- **What it is:** the hard fence: $1,000/month (measured), small team, no
  new hires, everything testable locally and rapidly, land fast enough to
  justify phase two.
- **Why it is shaped this way:** constraints are the only BRD lines that
  later passes may never trade away — they bound every design Pass 2 and
  Pass 3 are allowed to consider.
- **The decision it encodes:** local iteration speed is a business
  requirement, not a developer preference.
- **What breaks downstream without it:** Pass 3 grounds a stack the budget
  cannot carry, and the small team drowns in an architecture sized for a
  bigger one.

### Open questions

- **What it is:** three records with owners: real outage/firefighting
  numbers, the owner's verbatim stack preference (DuckDB / MotherDuck /
  dbt / CDC-from-WAL), and partner-migration mechanics.
- **Why it is shaped this way:** the provenance rule — every `(guessed)`
  number must own a verification question — and the facts-vs-decisions
  rule, which quarantines technology preferences here instead of letting
  them harden into decisions.
- **The decision it encodes:** the stack is a *preference riding to Pass 3*,
  not a decision made at Pass 0.
- **What breaks downstream without it:** guessed numbers silently become
  facts, and the stack gets chosen by momentum instead of by ADRs.

### Source

- **What it is:** provenance — three frontier rounds, voice, 2026-07-17,
  terrain read first (Postgres schema, seed 42, `src/README.md`), plus the
  parked silent-failure stub.
- **Why it is shaped this way:** a BRD without provenance cannot be
  re-interrogated; the terrain read is recorded so nobody re-asks what the
  repo already answered.
- **The decision it encodes:** the silent-failure idea is out — parked as a
  one-line stub for its own future brief.
- **What breaks downstream without it:** when a line is challenged later,
  there is no trail back to who said it and against what terrain — trivial
  to keep, expensive to lose.

### Sign-off

- **What it is:** the owner's verdict — **approved, canonical, 2026-07-19**.
- **Why it is shaped this way:** added by the v0.4.0 field audit; a BRD
  nobody signed is a draft with good posture, and the gate now checks the
  verdict line.
- **The decision it encodes:** capture is closed; changes now ride as change
  requests through the owning pass, never silent edits.
- **What breaks downstream without it:** Pass 1 descends from a document
  that can still shift under it, and every downstream artifact inherits the
  wobble.

## Decisions and roads not taken

| Decision | Rejected alternative | Why it lost |
|----------|---------------------|-------------|
| Build the backbone (this BRD exists) | Do nothing / write a no-go record | The do-nothing cost — continued outages, a blind business, locked AI ambitions — was judged intolerable in writing. |
| Lock production away from analytical consumers (hard requirement) | Trust partners to migrate voluntarily once the backbone exists | The pre-mortem named "partners keep querying production anyway" as a killer; a mitigation beats hope. |
| Near-real-time freshness | Day-old batch loads | Stale answers would not make anyone leave production alone — the KPI collapses without freshness. |
| Stack preference quarantined to Open questions | Record DuckDB/MotherDuck/dbt/CDC as decisions in the BRD | Pass 0 captures facts; technology is grounded and decided at Pass 3 against ADRs. Preference ≠ decision. |
| $1,000/month accepted as phase-one ceiling, growth planned | Reject the cost-growth risk or leave budget unstated | The owner accepted it in writing and plans to add capacity as adoption proves out. |
| Partner migration inside phase one | Defer partners to a later phase | Low-hanging fruit: partners are only on production because nothing else exists. |
| Silent-failure detection parked | Fold incident detection into this brief | Separate problem, separate brief — folding it in would bloat phase one's scope. |

## Vocabulary

- **BRD** — Business Requirements Document: the problem, in the owner's
  voice, with no solution attached.
- **Canonical** — the owner has signed the artifact; it changes only through
  a change request, never a silent edit.
- **Do-nothing test** — writing down what it costs to build nothing; if that
  cost is tolerable, the answer is a no-go record.
- **Frontier rounds** — the batch-grill interview: each round asks the
  current frontier of unknowns as one batch, then advances.
- **Gate** — the pass's exit check, a script whose exit code says whether
  the artifact is complete enough to hand off.
- **KPI** — a key performance indicator: a falsifiable current → target
  number.
- **No-go record** — the durable artifact written when the right decision is
  to not build.
- **Pre-mortem** — imagining the shipped thing failed and asking what killed
  it, before building.
- **Provenance tag** — the `(measured)` / `(estimated)` / `(guessed)` label
  every number carries; guessed numbers must own a verification question.
- **Terrain read** — reading the repo and data before interviewing, so the
  grill never asks what is already answered.

## What to watch

- **Guessed and estimated numbers await reality:** outage count/frequency
  and firefighting hours per week are `(estimated)`/`(guessed)` — open
  question, owner: VP of Engineering. Verify before they calcify.
- **The stack preference is not a decision.** DuckDB / MotherDuck / dbt /
  CDC-from-WAL rides to Pass 3 verbatim; if it shows up earlier as a given,
  that is a leak.
- **Two accepted risks stay live:** cost growth beyond $1k/month (accepted,
  growth planned) and the roadmap staying gut-driven (checked by KPI-3's
  "at least one real decision").
- **Partner-migration mechanics are unresolved** — sequencing and the
  lockdown flip-moment are an open question for Pass 1/Pass 3 to pin.
- **Freshness is named the hard part** — near-real-time is a KPI, and the
  gate's advisory "solution-shape" warn exists precisely because freshness
  talk drifts toward technology talk.

## Check yourself

1. Why is this file a BRD and not a no-go record? (→ see "Problem")
2. Which pre-mortem risk was *not* accepted, and what did it become instead?
   (→ see "Risks")
3. The owner named a full stack — DuckDB, MotherDuck, dbt, CDC. Why is none
   of that in Scope or Constraints? (→ see "Open questions")
4. What three things must be true in three months for phase one to have
   succeeded? (→ see "Definition of success")
5. What changed about how this BRD can be edited the moment it was signed?
   (→ see "Sign-off")
