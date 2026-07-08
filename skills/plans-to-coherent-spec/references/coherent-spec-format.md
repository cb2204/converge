# Coherent-spec format — Converge Pass 5A (Fork A)

The shape of the ONE coherent spec this pass produces. Not a template to fill
blindly — a contract for what "one document, one boundary, one eval" means, so
the spec you write passes the gate and Execution can drive it to green.

## The invariant

> **One document. One boundary. One eval.**

Two (or more) hardened swimlane plans — typically one that *shapes* the data or
core state and one that *exposes* it — become a **single coherent spec** whose
boundary wraps the **whole system**: `sources → outputs → served answers`. The
unit of trust is that whole, not a layer and not a task.

> **Example — a dbt/warehouse project.** A shaping plan
> (`raw/source tables → transform pipeline → published tables`) and an exposing
> plan (a serving layer over the published tables) fuse into one spec whose
> boundary is `sources → published tables → serving answers`. This is *one shape
> the method takes*, not the only one — a service project might fuse a
> domain-model plan with an API plan; a pipeline project might fuse ingest with a
> report. The invariant is the same: one boundary over the coupled whole.

If you find yourself writing one spec per layer, you are on the wrong fork — stop
and switch to Fork B (`task-spec`).

## Framework-native filename (`--framework`)

The framework decides the file *name and section shape*, never the content. The
`check-coherent-spec.sh` gate looks for any of these:

| `--framework` | Coherent spec lands as | Notes |
|---|---|---|
| `speckit` (default) | `specs/spec.md` (+ `specs/plan.md`) | Constitution-checked; the e2e eval is the acceptance criterion. |
| `kiro` | `specs/requirements.md` + `specs/design.md` | ONE spec dir for the whole system, not one per layer. |
| `openspec` | one change proposal (`proposal.md`) + spec deltas | The delta wraps the whole coupled change, reviewed as one. |
| `bmad` | one PRD-style doc (`prd.md`) | Keep it coupled; do not shard into stories on this fork. |

Whatever the filename, the eval is always `specs/e2e-eval.sh` — the framework
changes the spec's shape, never the eval.

## What one coherent spec contains

A single narrative, resolved (not two plans stapled together). At minimum:

1. **Problem & boundary** — one paragraph restating what the system does, and an
   explicit statement that the boundary wraps `sources → outputs → served
   answers`. This is the unit of trust.

2. **The one-way dependency, stated as an invariant.** Name the source floor, the
   store or state it lands in, and the **single crossing** between them.
   Everything reads from the source layer upward; **nothing writes back down.**
   State it as a directed chain the gate can find, for example:

   ```
   source → store (raw/ingested) → transform stages → output/contract layer → serving
   (source)  (single read path)                        (= seam)               (read-only)
   ```

   > **Example — a warehouse stack.** `Postgres → DuckDB (raw.*) → bronze →
   > silver → gold → serving`, where the read-only `ATTACH` performed by the
   > project's data-prep command is the single crossing and `gold` is the seam.
   > Substitute your own source, store, transform, and output names.

3. **The two halves, fused at the output seam.**
   - *Shaping half* (from the shaping plan): source/raw data → intermediate
     stages → a **trust boundary** where defects are neutralized or quarantined →
     an **output/contract layer** of serving-ready results.
   - *Exposing half* (from the exposing plan): a read-only access core over the
     output/contract layer, plus one serving entry point (API endpoint, MCP tool,
     etc.) per frozen question.
   - The **output-layer interface is the seam** where they join — see below.

4. **The output-layer interface — named as the internal contract.** The shaping
   half *owns* it (each output declares its columns/fields, types, nullability,
   and grain in a committed contract — for example a dbt `schema.yml` in a
   warehouse project). The exposing half *binds* to it and never redefines it. An
   output field does not exist for serving until it exists in a committed
   contract. List the candidate outputs (final list gated on the frozen question
   set), each named as a contract rather than as SQL or handler code.

5. **Carried-forward risks & open questions — verbatim.** Every accepted risk and
   open question the Pass-4 adversary surfaced moves into the spec unchanged.
   Nothing raised may be silently dropped in the lift. (For example: an
   owner-gated question set; the real latency/freshness instrument rather than a
   proxy; any atomic-publish invariant.)

6. **The definition of done** — a pointer to `specs/e2e-eval.sh`: done is that
   eval green, never "looks done."

## Coupling invariants (Step 2 — COUPLE)

These are the load-bearing statements the spec must make explicit, because they
are what makes the two halves ONE system:

- **Single crossing, one direction.** There is exactly one path from source to
  store, and it runs one way. Serving reads the **output/contract layer only** —
  never the intermediate stages, the raw layer, or the upstream source. This is
  what makes isolation of the source system true *by construction*.
- **The output seam is a versioned contract, owned upstream.** Serving compiles
  against the shaping half's published contract; a new answer needs a **new
  output**, never a deeper read into intermediate layers.
- **Atomic output generation.** Every output carries a shared run/version id;
  serving binds to the latest fully-published id, so a mid-transform run never
  exposes a half-published mix. State it as an invariant, not a lock.
- **Single-writer store.** The build/ingest step then the transform step,
  serialized — one writer at a time; readers (serving) run concurrently
  read-only. Match whatever concurrency contract your store provides.

## New architecture choices become ADRs

Where coupling forces a decision (full-refresh vs. incremental, single-writer
store, read-only output reader, any status→derived-value mapping), record it as an
ADR under `--adrs-dir` (`docs/adrs/NNNN-*.md`), **append-only**, so the record of
*why* is never lost. Do not reopen questions Pass 4 already settled — lifting must
not add scope.

## Altitude

Spec altitude throughout: the system's **shape and contract**, not its query or
handler code. Naming an output such as `revenue_by_category(category, day,
revenue, order_count)` as a contract is spec altitude; writing the transform that
fills it is Execution (Pass 8 · The Loop). Drift below this line means you have
started building, not specifying.

## The gate

Run `scripts/check-coherent-spec.sh --specs-dir specs/`. It mechanically checks
the structural items (spec present, one-way invariant stated, output seam named,
`e2e-eval.sh` present + executable + valid bash + drives the real flow, no Fork-B
drift). The judgment items (⊙) — one narrative not two, boundary wraps the whole,
every serving read maps to an emitted output field, every Pass-4 risk carried
forward, done = eval green — you confirm by eye.
