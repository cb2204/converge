# Lesson — Pass 3 (Decompose): swimlanes & legs

> Converge Pass 3 (`reqs-to-swimlane-plans`), run 2026-07-21 on the analytical
> backbone. Easy-first for a newcomer to the method.
> modes: adept, review, level=eli5

## TL;DR

We split the system into three lanes (capture → transform → serve), and cut each
lane into small named "legs" — each its own file you can build and check on its own.

## Why this pass exists

Pass 2 wrote down *what's true* about the ground (the ADRs). Pass 3 is the first
time we say *what to build and in what order* — but only at the "map" level, never
the code. Its one rule: **plan altitude only** — describe the work, don't write it.
It exists so the plan can be *attacked* (Pass 4) and *sliced into tasks* (Pass 5)
before a single line of code is committed. Who reads it next: Pass 4's reviewer.

## The artifact, component by component

### The three swimlanes

- **What it is:** three lanes — **capture** (get data off the source safely),
  **transform** (shape it into answers), **serve** (hand answers out).
- **Why it is shaped this way:** each lane has a different job and a clean handoff
  (a "seam") between them, so they can be built and owned separately.
- **The decision it encodes:** the system's real seams are the landing contract
  (`raw.*`) and the published contract (`gold.*`).
- **What breaks downstream without it:** if the lanes aren't cleanly cut, Pass 5
  builds tangled work that can't be tested in isolation.

### The leg (one file per leg)

- **What it is:** a small stretch inside a lane — one job, one set of checks — kept
  in **its own file** (`swimlane-capture-leg-01-dlt.md`).
- **Why it is shaped this way:** so the big plan (the PRD) stays a thin index and
  each leg can change on its own without touching the others.
- **The decision it encodes:** one leg = one responsibility + 1–3 acceptance
  criteria, and it later becomes one-or-more task-specs.
- **What breaks downstream without it:** without atomic legs, Pass 5 has no clean
  unit to turn into a task, and the plan bloats until nobody can read it.

### The seam

- **What it is:** the named, one-way boundary between two lanes (e.g. `gold.*`).
- **Why it is shaped this way:** a frozen contract lets both sides build in parallel
  without watching each other's insides.
- **The decision it encodes:** downstream reads only the published contract, never
  below it.
- **What breaks downstream without it:** a lane reaching "below the seam" couples
  everything, and one change breaks the other lane silently.

### The PRD (the lean index)

- **What it is:** the swimlane's front page — seam, a diagram, non-goals, and a
  table linking to each leg. It holds **no leg detail**.
- **Why it is shaped this way:** to stay skimmable forever as legs grow.
- **The decision it encodes:** the parent indexes; the children hold the detail.
- **What breaks downstream without it:** a fat all-in-one plan nobody re-reads, and
  drift between the overview and the parts.

## Decisions and roads not taken

| Decision | Rejected alternative | Why it lost |
|----------|---------------------|-------------|
| Capture is its own lane | Fold capture into transform | Different job, different ADRs, a nameable landing contract — a real seam |
| Steel thread = capture | Mark transform the thread | Capture is the riskiest seam; prove the scary part end-to-end first |
| One file per leg | One big plan per lane | Keeps the PRD thin and lets each leg evolve alone (Converge's one-file-per-unit grain) |
| Name the stack in the leg (`-dlt`) | Defer all tools to later | Pass 3 decides stack against ADRs — but as a swappable label, never the id key |

## Vocabulary

- **seam:** the one-way boundary between two lanes; the contract that crosses it.
- **swimlane:** one lane of work = one plan (a directory here).
- **leg:** a small named stretch inside a lane; one job, its own file.
- **PRD:** the lean index doc for a swimlane; links to its legs.
- **plan altitude:** describing *what/when*, never *how* (no code, no evals).
- **steel thread:** the thin end-to-end slice built first to prove the pipe connects.

## What to watch

- The `0003` principal gap is a **blocks-build** open question on capture — real work
  must create it before R-2/R-5 can be measured.
- The stack names (dlt, dbt, DuckLake…) are **reversible picks**, not locked.
- These plans are **meant to be attacked** at Pass 4 — they're deliberately soft.

## Check yourself

1. What are the two seams in this system, and which lane owns each? (→ see "The seam")
2. Why is capture its own lane instead of part of transform? (→ see "Decisions")
3. Why does each leg live in its own file? (→ see "The leg")
4. What does "plan altitude" forbid? (→ see "Why this pass exists")

## ADEPT explanations

### The seam

- **Analogy:** a loading dock — the truck (upstream) drops pallets on the dock; the
  warehouse (downstream) only ever touches the dock, never climbs into the truck.
- **Diagram:** `capture --raw.*--> transform --gold.*--> serve`
- **Example:** serve reads `gold.*` only; it never peeks at `raw.*` or the source.
- **Plain-English:** a fixed handoff point so each side works without watching the other.
- **Technical:** a nameable one-way interface (published contract) with additive-safe
  evolution; consumers pin only what they read.

## Review schedule

Q: What are the three lanes, in order?
A: capture → transform → serve.
Q: What is a "leg"?
A: A small named stretch inside a lane — one job, its own file, 1–3 acceptance criteria.
Q: What is the steel thread, and which lane is it here?
A: The thin end-to-end slice built first; here it's capture.

Schedule:

- day 1 — re-test cards 1–3.
- day 3 — re-test any missed on day 1.
- day 7 — full deck.
- day 21 — full deck.
