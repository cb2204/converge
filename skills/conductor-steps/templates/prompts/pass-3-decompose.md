# Pass 3 · Decompose — ADRs → swimlanes

**Mission:** split the work into swimlanes of ordered legs — parallel where
truly independent, sequenced where dependent — so Pass 5 can cut one spec
per leg.

**Inputs:** the gated ADR set (`cvg/docs/adrs/`) and tech spec.

**Procedure:**
1. Partition the work into swimlanes by *write surface*: two lanes should
   never need to touch the same files. Disjoint writes are what make
   parallelism safe later.
2. Within each lane, order the legs by real dependency — data before its
   consumers, contracts before their implementations, checks beside the
   thing they check.
3. Write the tree under `cvg/sketch/swimlane-<name>/`, one leg per file:
   what it delivers, what it depends on, roughly how big it feels
   (the six-tier sizing happens at Pass 5 — here you only flag "this leg
   smells too big").
4. File lane-boundary decisions → `cvg/brain/decisions/`.

**Exit:** `cvg decompose` → `CHECK_PLAN=OK`.

**Hands off to:** Pass 4 (Consensus) — the barrier. Nothing downstream of the
plan is built until an adversary has attacked it and a human has signed.
