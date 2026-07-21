# Legs — the lane's stretches (seam → swimlane → leg → task-spec)

Pass 3's decomposition chain has four levels, each more precise than the last:

```
SEAM        the natural joint — a nameable interface with a one-way dependency
 SWIMLANE   one lane per seam — one plan, one focus
  LEG       a stretch inside the lane — one responsibility, one proving test
   TASK-SPEC the atomic unit with an eval — born at Pass 5B, never at Pass 3
```

This reference is the doctrine for the **leg** level: what a leg is, how big it
is, and how it hands off to Pass 5B.

## Why "leg" (and not "stage")

In a relay race each swimmer runs one **leg** of the lane — that is exactly the
idea: a big swimlane subdivides into sequential stretches, each handing the baton
to the next. The metaphor keeps the swimlane vocabulary coherent and avoids the
collisions "stage" carries in software: staging area, deploy stage, dbt staging.

## What a leg is

A leg is the smallest named unit of a plan:

1. **One responsibility, in prose.** What the stretch does — never how. "Dedup
   duplicate records by business signature, quarantine the rest" is a leg; the
   query that does it is a Pass 5 task.
2. **Independently finishable.** A leg can be built and proven without any later
   leg existing. (Shape Up's scope property: a scope you cannot finish
   independently is not a scope — it is half of one.) If leg-02 needs leg-03's
   output, the order is wrong or the boundary is wrong.
3. **Sized to one build-order step + one proving-test cluster.** If a stretch
   needs more than one context window to implement, it is two legs. If two
   stretches share one proving test, they are one leg.
4. **Yields 1:N task-specs.** A leg decomposes into one *or more* Pass 5B
   task-specs. If every leg in a lane maps to exactly one task, the leg level is
   redundant for that lane — collapse it (the "fewest" doctrine applies here
   too: no leg quotas, no forced granularity).
5. **Plan altitude, always.** A leg carries no eval, no SQL, no handler body.
   The eval binds at the task-spec — that is what keeps Pass 4's attack surface
   honest.

## The leg's identity

Inside a plan, legs are named **`leg-NN-<tech>`** in build order —
`leg-01-dlt`, `leg-04-dbt-bronze`, `leg-01-fastapi`. Across artifacts the
fully-qualified form is **`swimlane-<seam>-leg-NN-<tech>`**.

**The stable reference key excludes the tech** (field-grounded — Wilkinson
et al., "Identifiers for the 21st century"; Sparx EA on hierarchical numbers as
unsuitable immutable ids). Links resolve on the tech-less key:

```
swimlane-<seam>-leg-NN          ← the STABLE key (2-digit zero-pad; ids sort lexically)
swimlane-<seam>-leg-NN-<tech>   ← the DISPLAY form (tech = swappable mnemonic label)
```

The `<tech>` is a lowercase-kebab tool slug (`dlt`, `dbt-bronze`, `fastapi`,
`mcp-server`) appended as a mnemonic. It **may be omitted, and may change when the
stack changes, without breaking any reference** — because nothing links on it.
Never put the tool in the key: swapping DuckLake→Iceberg or dlt→Airbyte would
otherwise silently break every cross-artifact reference, branch name, and PR
title. Parse anchor: the literal `-leg-` + two digits, so a multi-word seam or
tech slug stays unambiguous (`<tech>` is always the trailing segment).

A Pass 5B task-spec cites its leg on the **stable key**
(`leg: swimlane-transform-leg-02`), so the traceability chain is complete and
greppable regardless of tool churn:

`ADR → seam → swimlane → leg → task-spec → eval`

## The "too big" test — when a lane earns legs

Legs exist because a lane is too big to hold in one head — never for ceremony.
A piece inside a lane must split when either holds:

- **Head-room:** you cannot state its responsibility in one sentence without an
  "and" that joins two independently provable behaviors.
- **Window-room:** implementing it would take more than one context window (the
  same ceiling task-spec v3.3.0 sizes tasks against).

And the inverse, the **fold test**: two adjacent legs that share a proving test
and would ship in the same task-spec are one leg.

## Worked example — the canonical transform → serve cut

```
SWIMLANE transform  (owns the published-output contract)
  leg-01  ingest + pin raw sources read-only
  leg-02  conform to silver — dedup, types, UTC grain
  leg-03  publish gold — serving-ready tables shaped to the frozen questions

SWIMLANE serve  (consumes the published contract, never below it)
  leg-01  query core — one read-only function per published table
  leg-02  transports — API / MCP framing over the shared core
```

Each leg: one responsibility, one proving-test cluster, independently
finishable in order. `swimlane-serve-leg-01` will yield several task-specs at
Pass 5B (one per published table's reader + the core itself) — 1:N, as intended.

## What Pass 4 does with legs

The adversary attacks **leg by leg**, not just plan by plan: each leg's
responsibility is checked against the tech-spec and the ADRs, each leg boundary
against the independence and fold tests, and every objection cites a leg ID —
`FIXED in swimlane-transform-leg-02` or `ACCEPTED with a named owner`. A leg
that cannot be attacked is a leg that has not been thought about.

## What Pass 5B does with legs

Task-specs are cut **per leg**: the leg's responsibility becomes the task's
intent, the leg's proving-test cluster becomes the eval seeds, and the leg ID
goes into the task frontmatter. The leg never carries the eval itself — it
carries *what the eval must assert*, in prose, so Pass 5B can bind it
mechanically.
