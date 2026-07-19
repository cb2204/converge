# Lesson — Pass 1 (Intent): the analytical-backbone tech-spec

> Taught 2026-07-19, after Gate H1 (owner verdict: approved — canonical).
> Artifact: `cvg/docs/tech-spec-analytical-backbone.md`. Companion records:
> `brain/decisions/2026-07-19-pass1-round1-owner-answers.md` (D1–D5),
> `brain/decisions/2026-07-19-pass1-round3-gap-resolutions.md` (D6–D8).

## TL;DR

The fuzzy brief became a contract: eleven falsifiable requirements, every
threshold traced to an owner decision, machine-consumable by the passes
that now descend from it.

## Why this pass exists

Pass 1 sits one rung below the BRD: the brief says what *hurts*, the
tech-spec says what *must be true* when the pain is gone. Its invariant is
**brief-in, spec-out — never blur them**: it adds the engineer's questions
(how fresh? how fast? how proven?) without adding the engineer's answers
(no store, no tooling, no capture mechanism — that is Pass 3, decided
against Pass 2's ADRs). Its output is consumed next by Pass 2
(`tech-req-to-adrs`), which grounds every requirement against the real
terrain and records the decisions as ADRs. This run added a second
invariant, the owner's: the spec must be sufficient for **agentic
execution** — downstream consumers are machines, so every clause must be
decidable without judgment.

## The artifact, component by component

### Header & provenance block

- **What it is:** the quoted preamble naming the consumed BRD, the three
  interrogation rounds, and where D1–D8 live on disk.
- **Why it is shaped this way:** the standing rule that interrogation
  answers land on disk the moment they arrive (born from the R1.R session
  crash) — the spec cites the records instead of restating them.
- **The decision it encodes:** provenance is a chain — spec → decision
  files → BRD; nothing load-bearing lives only in chat.
- **What breaks downstream without it:** a Pass 2 agent cannot verify a
  threshold's origin, and a lost session takes the "why" with it.

### TL;DR and Outcome

- **What it is:** one breath of what phase one delivers, then one
  paragraph of what is true when it works.
- **Why it is shaped this way:** the field's spec discipline (verified in
  the three-engine review): a reader — or a routing agent — decides in ten
  seconds what this document is.
- **The decision it encodes:** the backbone is standalone, near-real-time,
  and locks production — the three commitments everything else expands.
- **What breaks downstream without it:** summaries drift from the body and
  agents anchor on the wrong altitude.

### Problem restated

- **What it is:** the BRD's pain in one paragraph, plus what "solved"
  means, ending in the $1,000/month boundary.
- **Why it is shaped this way:** problem-first (the field review found 31
  of 40 real specs lead with the solution and pay for it in review); no
  solution shape appears.
- **The decision it encodes:** partners and internal consumers are ONE
  problem — a single backbone serves both.
- **What breaks downstream without it:** Pass 2 grounds requirements
  against terrain with no shared statement of why they exist.

### Scope (In / Out)

- **What it is:** four In bullets, five Out bullets — at problem level.
- **Why it is shaped this way:** the Outs carry the BRD's scope-outs
  forward (no re-architecting production, no AI, incident-detection
  parked) plus the terrain fence (`_control` never on the analytical
  surface) and the altitude fence (no stack choices here).
- **The decision it encodes:** the lockdown is the ONLY permitted touch on
  the operational system.
- **What breaks downstream without it:** scope creep re-enters at Pass 3
  as "while we're in there" engineering.

### Must requirements (R-1 … R-8)

- **What it is:** the eight conditions phase one fails without: freshness
  p99 ≤ 5 min (R-1), zero analytical queries by identity + capture
  overhead ≤ 20% p95 (R-2), class SLAs 5/30/60 min against Q-SET-1's
  answer keys (R-3), never-silently-wrong with 15-min staleness alerting
  (R-4), migrate-all-then-revoke with a 7-day clean window (R-5), ≤
  $1,000/month from billing exports (R-6), 15-minute local loop (R-7),
  100 queries/day with a ≥ 20% peak hour (R-8).
- **Why it is shaped this way:** every clause is falsifiable and carries
  its eval sketch inline; after the agentic-execution review, every
  judgment call became data (definitions by identity, oracles by answer
  key, p99 as the normative bound with sample size and probe interval).
- **The decision it encodes:** each R names its decision inline — D1–D8
  and BRD lines; this is the traceability spine.
- **What breaks downstream without it:** Pass 5B cannot write
  deterministic evals, and two agents reading one clause build two
  different systems.

### Should / Could requirements (R-9 … R-11)

- **What it is:** 3× load headroom (R-9), auditable staleness history
  recorded from the 5-minute floor (R-10), partner onboarding ≤ 1 business
  day via runbook (R-11).
- **Why it is shaped this way:** MoSCoW priority differentiation — the
  gate requires the spec to say what phase one will NOT die for.
- **The decision it encodes:** growth to 300/day must not force
  re-architecture, but it is not a phase-one acceptance criterion.
- **What breaks downstream without it:** Pass 3 treats every requirement
  as equally load-bearing and over-builds the first cut.

### Won'ts (W-1 … W-3)

- **What it is:** three explicit refusals — production re-architecture, AI
  capabilities, the incident-detection product.
- **Why it is shaped this way:** a Won't is a decision, not an omission;
  reviewers (and agents) grep for non-goals first.
- **The decision it encodes:** phase two exists, and this document refuses
  to borrow from it.
- **What breaks downstream without it:** the strongest ideas from the
  grill (incident detection) silently re-enter and blow the $1,000 ceiling.

### Success metrics table

- **What it is:** six metrics, each current → target, each traced to a KPI
  or decision; KPI-3 (≥ 1 roadmap decision made from backbone data)
  deliberately carries no R-id — a business outcome the owner measures,
  not a requirement an eval can force.
- **Why it is shaped this way:** current → target is the gate's required
  form; the numbers repeat the requirement thresholds exactly so the table
  and the body can never disagree.
- **The decision it encodes:** what "worked" means is measured, not felt.
- **What breaks downstream without it:** phase one ships and nobody can
  say whether it succeeded.

### Data named

- **What it is:** the four operational domains (customers, products,
  orders, payments) and their change events; consumers named; `_control`
  excluded from the product surface.
- **Why it is shaped this way:** problem-level data naming — entities, not
  schemas — is the most Pass 1 may say about data.
- **The decision it encodes:** what the source committed is the only truth
  the backbone may serve (feeds R-4).
- **What breaks downstream without it:** Pass 2 has no bounded surface to
  ground against the real schema.

### Assumptions (A-1 … A-3)

- **What it is:** three owned assumptions — the stack preference stays
  quarantined (A-1), load numbers are estimates (A-2), pain baselines
  remain unverified (A-3).
- **Why it is shaped this way:** an assumption with an owner is checkable;
  an unstated one is a landmine.
- **The decision it encodes:** the owner's DuckDB/dbt/CDC preference is
  deliberately NOT consulted here — Pass 3 decides against ADRs.
- **What breaks downstream without it:** preference hardens into
  architecture without ever being examined.

### Gap register (GAP-001 … GAP-003, all resolved)

- **What it is:** three typed records, each with severity, what it blocks,
  an owner, and a RESOLVED resolution mapped to D6/D7/D8.
- **Why it is shaped this way:** typed YAML so a machine can read gate
  state; a blocker left `(open)` shuts the gate mechanically.
- **The decision it encodes:** unanswered questions are records with
  owners, never footnotes.
- **What breaks downstream without it:** open questions vanish into chat
  scrollback and resurface as production surprises.

### Sign-off block (Gate H1)

- **What it is:** the owner's verdict line ("approved — canonical"), the
  ISO date, and the review condition it was given under.
- **Why it is shaped this way:** added at R1.C after the three-engine
  structure review found it missing — the field's "approved-by, blank
  until sign-off" practice, and the same authorization boundary Pass 0's
  BRD carries.
- **The decision it encodes:** a spec without a signed verdict is a draft,
  and Pass 2 must not consume a draft.
- **What breaks downstream without it:** the machine stage has no
  mechanical way to distinguish judged from unjudged intent (the gate
  check enforcing this is the next hardening step).

## Decisions and roads not taken

| Decision | Rejected alternative | Why it lost |
|----------|---------------------|-------------|
| D1 — 5-minute freshness floor, never relaxed in phase one | Looser "hourly is fine" (cheaper) or tighter real-time streaming | Hourly reopens the days-stale blindness the BRD names; true real-time buys nothing at 100 queries/day and threatens the cost ceiling |
| D2 — three SLA classes (5/30/60 min) with timed drills | One blanket "under an hour" SLA | A blanket SLA lets easy questions subsidize hard ones; classes make each kind of question independently falsifiable |
| D3 — migrate ALL partners, then revoke, then 7-day clean window | Revoke first (fastest lockdown) or run both surfaces in parallel indefinitely | Revoke-first breaks partners mid-flight; indefinite parallel means the lockdown never provably happens |
| D4 — never silently wrong: staleness visible, alert at 15 min | Serve interpolated/padded values to look fresh | A plausible-but-fabricated answer destroys the trust the backbone exists to create; honest staleness is recoverable, silent wrongness is not |
| D5 — size for 100 queries/day, estimates confirmed as planning numbers | Delay the spec for precise partner forecasting | The numbers affect sizing, not shape; A-2 re-validates them at migration planning |
| D6 — capture overhead ≤ 20% p95 ceiling, 15% target | The interrogator's 5% default | Owner call: the feed is business-critical enough to spend production headroom; recorded as a deliberate loosening, re-examined at Pass 3 |
| D7 — 15-minute local loop | Faster (5-min) or unbounded "it works locally" | 15 min is the confirmed v1 bar: tight enough to keep iteration honest, loose enough to not constrain Pass 3 |
| D8 — partner migration in elected waves, composition at planning | Fixing the full partner order inside this spec | The order is execution planning; R-5's acceptance never depended on it — pinning it here would freeze a decision with no information behind it |
| p99 as R-1's normative bound (review fix B-4) | "Every committed write" (a max bound) | A max bound and a p99 eval contradict — two agents would build two architectures; the guarantee and the eval must be the same number |
| Analytical queries defined by database principal (review fix B-2) | Classifying reads by intent/judgment | The feed itself reads production; only identity makes the zero-count decidable — by judgment, any query can be excused |
| Q-SET-1 answer-key oracle; the eval harness may read `_control` (review fix B-3) | "Correct answer" left to the drill runner's judgment | Pass 5B cannot eval "correct" without an oracle; the terrain fence is for the product surface — a verifier is not a business consumer |

## Vocabulary

- **ADR** — architecture decision record: one grounded decision with its
  evidence, written at Pass 2.
- **Agentic execution** — downstream passes run by machine agents, which
  can only consume clauses that are decidable without human judgment.
- **Canonical** — the owner's signed verdict that an artifact is the
  anchor; everything below descends from it.
- **Frontier round** — one interrogation batch: every currently askable
  question at once, each with a recommended default, one reply answers all.
- **Gap register** — typed open-question records (id, severity, owner,
  resolution); blockers shut the gate mechanically.
- **Gate H1** — the first of Converge's two human stops: the owner's
  canonize verdict on the tech-spec.
- **MoSCoW** — Must/Should/Could/Won't requirement prioritization.
- **Oracle** — the pre-agreed source of the correct answer an eval
  compares against (here: Q-SET-1's answer keys).
- **p99** — the value the slowest 1% of samples exceed; "p99 ≤ 5 min"
  means 99% of writes are queryable within 5 minutes.
- **Provenance tag** — `(measured)`/`(estimated)`/`(guessed)` on every
  number, so nobody load-bears a guess unknowingly.
- **SLA** — service-level agreement: a time bound a class of answers must
  meet.
- **Tech-spec** — Pass 1's artifact: requirements and metrics at problem
  level, above the stack.
- **Traceability** — every requirement names the decision or BRD line it
  came from, so any threshold can be walked back to its "why."

## What to watch

- **D6 is generous by design** — up to 20% p95 overhead on a database
  whose fragility started this project; the Pass 3 re-examination is
  mandatory, and R-2 publishes the measured number regardless.
- **A-3 pain baselines** stay `(estimated)`/`(guessed)` — narrative only,
  no target depends on them.
- **Three future deliverables were named, not built:** Q-SET-1 (drill
  questions + answer keys), the partner registry (D8, decidable "all"),
  and the runbook's on-call name (Pass 6). Each is where a later pass must
  make good on this spec's promises.
- **The gate does not yet enforce the Sign-off block** — check-tech-spec
  v0.3.0 passes an unsigned spec; the exit-contract hardening (the Pass 1
  analog of Pass 0's P-8) is queued as the next machine-stage step.

## Check yourself

1. Why is R-1's bound p99 and not "every write"? (→ see "Must
   requirements" and the p99 row in Decisions)
2. What makes a query "analytical" for R-2 and R-5's zero-count — and why
   couldn't judgment do it? (→ see "Must requirements", R-2)
3. In what order do migration, revocation, and the 7-day window happen,
   and which alternative did D3 reject? (→ see Decisions, D3)
4. Where does the owner's DuckDB/dbt/CDC preference live right now, and
   which pass is allowed to consult it? (→ see "Assumptions", A-1)
5. What are the three named-but-unbuilt deliverables this spec depends on
   later? (→ see "What to watch")
