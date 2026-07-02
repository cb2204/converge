# Seams and swimlanes — finding the natural cut (by feature vs. by component)

Pass 3 splits a confirmed system into one **swimlane plan per seam**. This
reference is the protocol behind Step 1: how to find a seam that is real, name the
interface that lives on it, and refuse the ones that aren't.

## What a seam is

A seam is a **nameable interface** with a **one-way dependency** across it. Two
groups are separated by a real seam when:

1. You can point to the exact contract that crosses it — tables, columns, a
   function signature — not a vibe.
2. The dependency runs in **one direction**: one side *produces* the contract, the
   other *consumes* it. If the arrow points both ways, it is one lane, not two.
3. Each side could be built against a *frozen* version of that contract without
   watching the other side's internals.

> The one-line test: **can you name the interface?** If yes, it is a seam — cut
> there. If you can't, it is a hidden coupling — fold the lanes back together and
> keep looking.

## By feature OR by component — never an arbitrary slice

There are two honest ways to cut, and the architecture tells you which:

- **By component** — split where the *technology or responsibility* changes. In
  this repo the terrain changes at `raw.*`: everything above it that *shapes* data
  (dbt over DuckDB) is one responsibility; everything that *exposes* it (FastAPI /
  MCP) is another. That is a component seam.
- **By feature** — split where two independent *capabilities* share nothing but a
  contract (e.g. "billing" vs. "notifications"). Cut per feature when the features
  don't stack into a pipeline.

A medallion-plus-serving system like this one is naturally a **component** cut. A
breadth-of-features product is naturally a **feature** cut. What is never allowed
is an arbitrary slice — "front half / back half", or "the big models vs. the small
ones" — that no interface backs.

## The canonical cut in this repo (two lanes)

The brownfield already ends at DuckDB `raw.*` (`raw_customers`, `raw_products`,
`raw_orders`, `raw_payments`, verified by `make land`). So the seam falls cleanly
*above* raw:

```
raw.*  ─┤ Component A · Transform ├─►  gold.*  ─┤ Component B · Serve ├─►  answers
(given)   (dbt: bronze→silver→gold)   (the seam)  (query-core + FastAPI + MCP)
```

- **Component A · Transform** — the sole writer of the analytical tables. Consumes
  `raw.*`, produces `gold.*`. Lives in `sketch/duckdb-dbt-med-arch.plan`.
- **Component B · Serve** — the read-only consumer. Reads `gold.*` only, never
  below it. Lives in `sketch/fast-api-mcp.plan`.
- **The seam is the `gold.*` contract** — owned by A, consumed by B. A produces the
  gold tables (and their per-mart column shapes); B binds to them. Naming this
  contract here is what lets Pass 4 attack it and Pass 5 build both lanes against a
  frozen shape.

Two lanes is the *common shape* for this system — not a rule and not a quota. The
lane count is the number of genuine seams the architecture reveals.

## The downstream lane names the exact interface it consumes

The seam is a contract, so the consuming lane must pin it precisely:

- The serve lane names **which gold tables and columns** each endpoint/tool reads,
  and **never reaches below gold** (no silver, bronze, raw, or Postgres read).
- A column that isn't in the upstream contract is a **new mart request upstream**,
  never a deeper read. That rule is what keeps the seam a hard boundary instead of
  a leaky suggestion.
- Because B binds to a *frozen* gold shape, B can be planned in full while A's
  silver/gold SQL is still in flux — the seam decouples the two build efforts.

## False seams — fold them back

| Symptom | Why it's false | Fix |
|---|---|---|
| Three lanes: transform, FastAPI, MCP | FastAPI and MCP share one query core and differ only in protocol framing | One serve lane, two transports (B2/B3 over a shared B1). Record the split-later condition: only if MCP needs logic HTTP doesn't. |
| A lane you added to "balance" the diagram | No interface crosses into it | Delete it; its work belongs inside an existing lane. |
| A boundary you can describe but not name | The interface isn't pinned | Either name the exact tables/columns (real seam) or fold the lanes (false seam). Fuzziness is the signal. |

## Output of Step 1

You leave Step 1 with: the list of lanes, the **dependency direction** between
them, and the **named interface** on each seam (here, the `gold.*` contract). You
have *not* planned the contents yet — that is Step 2, one `sketch/<lane>.plan` per
seam via `scripts/new-plan.sh`.
