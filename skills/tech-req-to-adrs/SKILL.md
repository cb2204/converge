---
name: tech-req-to-adrs
description: >-
  Converge Pass 2 (Structure). Reads the Pass 1 tech-spec plus the real codebase
  and writes grounding ADRs under docs/adrs/ — facts and constraints about the
  terrain, never solution design. Use when the user says "structure pass",
  "write the ADRs", "ground the spec against the repo", "is this greenfield or
  brownfield", or "start Pass 2 / Converge Structure". Names the ground, runs the
  brownfield to verify, and records each grounding decision as a numbered ADR that
  Pass 3 can stand on. NOT for solution design or "build X" statements — that is
  Pass 3 planning; stay at terrain altitude.
  Engine is Claude Code on the repo; engine/tracker-agnostic, no baked names.
metadata:
  version: "0.2.0"
  converge_pass: 2
  pass_name: structure
license: Complete terms in LICENSE
compatibility: "Claude Code; bash 3.2+ (macOS system bash safe)"
---

# tech-req-to-adrs — Converge Pass 2 (Structure)

Ground the Pass 1 tech-spec against the real system and record the grounding
decisions as ADRs. This pass lowers altitude from *what to build* (the spec) to
*what is true about the terrain we build on* (the ADRs). The deliverable is
files under `docs/adrs/`, not a session summary — v1 produced no file and the
understanding died with the session; this version writes it down so Pass 3 can
stand on it.

- **Converge pass:** 2 of 8 — STRUCTURE.
- **In:** the Pass 1 tech-spec (`docs/tech-spec-*.pdf|md`) + the real repo.
- **Out:** `docs/adrs/NNNN-<slug>.md`, one grounding decision per file.
- **Gate:** the terrain is *named* and every grounding fact is recorded as an ADR a stranger can reconstruct — with no "build X" in any of them.

## Important

- **Terrain, not design.** An ADR records a **fact or constraint that already holds** and its evidence. The instant it says "build the gold mart that…" it has drifted into Pass 3 and must be split: the fact stays here, the design moves on. This no-drift invariant is the single failure mode of this pass and the only thing the gate truly enforces.
- **Run the brownfield; do not assume it.** Grounding requires reading and *running* the real source, not summarizing a doc. Reconcile row parity into the warehouse before you write a word.
- **Evidence over assertion.** Every ADR cites the line, count, or Make target that makes it true (e.g. `payments.order_id BIGINT NOT NULL REFERENCES orders(order_id)`), so the next engine trusts the file, not the author.
- **No engine/tracker flags.** The engine is fixed (Claude Code on the repo). There is no adversary and no tracker here; those bind in Pass 4 (`--adversary`) and the Fork B register (`--tracker`).

## Instructions

Three steps, in order: **Name the ground → Ground → Record**. The order is
load-bearing — you cannot record a constraint you have not verified, and
recording first would enshrine assumptions.

### Step 1 — Name the ground

State plainly whether this is **greenfield** (nothing exists; the ADRs record the
constraints the spec imposes) or **brownfield** (a working base exists; the ADRs
record what is already true). Write it in the first record — `0000-context.md` or
the first numbered ADR — so every later decision is anchored to known terrain.

In this repo it is **brownfield**: a Postgres `public.*` source (customers,
products, orders, payments), a correlated seeder, a 14-mode silent defect
generator, and a read-only Postgres → DuckDB `raw.raw_*` landing that all run
today. Name that explicitly; a reader must know what is *given* before reading
what *must hold*.

### Step 2 — Ground (check spec against the real system)

Pressure-test the spec against reality — run it, do not read about it:

- `make up && make seed && make land`, then confirm **row parity** from Postgres `public.*` into DuckDB `raw.raw_*`.
- Confirm `raw.*` is the ONLY schema in the warehouse — no transform or serving layer exists yet (that is what later passes build).
- Read `src/db/01_schema.sql` and interrogate the spec against it. Surface the 3–4 facts that would bite Pass 3 if assumed wrong:
  - **Join:** how do orders and payments actually relate? (`payments.order_id BIGINT NOT NULL REFERENCES orders(order_id)`.)
  - **Grain:** what is the real time grain? (`ordered_at` / `paid_at` are `TIMESTAMPTZ` — UTC.)
  - **Metric:** what does "revenue" mean against the real `status` columns and the `_control` fence that never lands?

Every fact you intend to record must trace to a schema line, a row count, or a Make target you actually observed.

### Step 3 — Record (write the ADRs)

For each grounding decision, scaffold and fill one `docs/adrs/NNNN-<slug>.md` with
the bundled script:

```bash
bash .claude/skills/tech-req-to-adrs/scripts/scaffold-adr.sh "payments join on order_id"
# → docs/adrs/0001-payments-join-on-order-id.md  (auto-numbered, dated, templated)
```

The script auto-increments `NNNN`, slugifies the title, stamps the date, and lays
down a fixed ADR skeleton (Status / Ground type / Context / Decision / Evidence /
Consequences). Fill it so each record states **what is** and **what must hold**,
cites its evidence, and names its consequence for downstream passes — never a
build instruction. Representative set for this repo:

- `0001-payments-join-on-order-id` — the only orders↔payments seam.
- `0002-utc-date-grain` — all time columns are `TIMESTAMPTZ`; the date grain is UTC.
- `0003-revenue-is-paid-only` — revenue counts paid payments, not order totals.
- `0004-control-schema-never-lands` — `_control.*` is a facilitator fence; the pipeline only sees `public.*` / `raw.*`.

## Gate — confirm before leaving this pass

Run the checker, then eyeball the invariant:

```bash
bash .claude/skills/tech-req-to-adrs/scripts/scaffold-adr.sh --check
```

- [ ] The terrain is **named** (greenfield or brownfield) in writing.
- [ ] The brownfield was *run*, not assumed: `make up && make seed && make land` reconciled with row parity; `raw.*` confirmed as the only warehouse schema.
- [ ] Every grounding decision is its own `docs/adrs/NNNN-<slug>.md` file.
- [ ] Each ADR records a **fact/constraint** with cited evidence — none says "build X" or designs a solution (`--check` greps for build-verbs and flags drift).
- [ ] The join rule, the date grain, and the revenue definition are each pinned to a real schema/source line.
- [ ] A reader with no session context can reconstruct the given-vs-build picture from `docs/adrs/` alone.

Converged = the checklist passes, not "feels done."

## Examples

**Example 1 — "Run the structure pass on the analytical engine."**
Actions: read `docs/tech-spec-analytical-engine.pdf`; `make up && make seed && make land`;
diff Postgres `public.*` counts against DuckDB `raw.raw_*`; read `src/db/01_schema.sql`;
scaffold `0000-context` (brownfield) + `0001`…`0004` for the join/grain/revenue/control
facts; run `scaffold-adr.sh --check`.
Result: `docs/adrs/` holds five records; `--check` is green; Pass 3 can read them.

**Example 2 — "Is this greenfield or brownfield, and what are we standing on?"**
Actions: Step 1 only — write `docs/adrs/0000-context.md` naming it brownfield and
listing the given surface (seeder, defect generator, `raw.raw_*` landing) vs. the
build surface (transform + serving, not yet present).
Result: the given-vs-build map is a file, not a memory.

**Example 3 — "Ground the spec against the repo" but the draft ADR says "build a payments fact table keyed on order_id."**
Actions: split it. Keep the fact (`0001-payments-join-on-order-id`: payments join
orders on `order_id`); delete the build clause and hand the "fact table" design to
Pass 3.
Result: the ADR passes `--check`; no design leaks into Pass 2.

## Troubleshooting

- **`--check` fails: "build-verb detected in ADR".** → An ADR designs a solution (build/create/implement/add). → Split it: keep the fact, move the design to Pass 3 (`reqs-to-swimlane-plans`).
- **Row counts differ between `public.*` and `raw.raw_*`.** → The landing was stale or a defect changed a row mid-run. → Re-run `make land`; if it persists, that discrepancy IS a grounding fact — record it (e.g. an ADR on which defect modes survive into `raw`).
- **No tech-spec exists.** → Pass 1 has not run. → Stop and run `brd-docs-to-tech-req` first; Pass 2 needs the spec as input.
- **Tempted to write "build X".** → You have left terrain altitude. → Stop; that belongs to Pass 3. Pass 2 records only what *is* and what *must hold*.
- **`_control.*` rows appear in the warehouse.** → The fence leaked. → That is a real defect and a grounding fact; record it and flag the landing, do not silently drop it.

## Handoff

→ **`reqs-to-swimlane-plans`** (Pass 3, DECOMPOSE) reads `docs/adrs/*.md` as its
grounding inputs and splits the system at its real seam (transform vs. serving)
into `sketch/*.plan` files. Every plan must trace back to a fact recorded here and
may not contradict a recorded ADR.

## References

- `references/adr-vs-design.md` — the no-drift boundary: worked examples of a grounding ADR vs. a design ADR, and how to split a mixed one.
- `references/grounding-checklist.md` — the brownfield run-and-reconcile protocol (row parity, schema inventory, join/grain/metric interrogation).
