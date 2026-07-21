# Lesson — Pass 2 (Structure): the grounding ADRs

> Converge Pass 2 (`tech-req-to-adrs`), closed 2026-07-21. Teaches the seven
> grounding ADRs + glossary written against the live Postgres terrain.
> Companion to `lesson-pass-1-analytical-backbone.md`. Explains decisions;
> does not reopen them.

## TL;DR

The spec's assumptions now meet the real schema: seven immutable terrain facts
(`docs/adrs/0000–0006`) + a glossary that Pass 3 must build on and cannot
contradict.

## Why this pass exists

Pass 1 said *what to build* (the tech-spec, altitude: the outcome). Pass 2
lowers altitude to *what is true about the ground we build on* — and writes it
down as evidence-backed records, one fact per file, in git. Its one "never
blur" rule: **an ADR records a terrain fact or constraint (what IS / what MUST
hold), never a build instruction** — the instant it says "build X," it has
drifted into Pass 3 and must be split. It exists because agents fail most
catastrophically on *assumed* terrain: a hallucinated join key or a misread
metric produces confidently wrong work at machine speed. Pass 3 (`reqs-to-
swimlane-plans`) consumes these ADRs as its grounding inputs — every plan must
trace to a fact here and may not contradict one.

## The artifact, component by component

### 0000-context — naming the ground

- **What it is:** the context record — greenfield/brownfield call plus the
  given surface (what runs today) vs. the build surface (what the spec still
  asks later passes to build).
- **Why it is shaped this way:** you cannot record a constraint you have not
  located; the ground is named first so every later ADR is anchored to it.
- **The decision it encodes:** this is **greenfield** — the operational
  Postgres exists, but the analytical lane (capture/store/transform/serving)
  does not.
- **What breaks downstream without it:** Pass 3 can't tell which components it
  must build from which already exist — it might "plan" a source that's
  actually a deliverable, or assume a store that isn't there.

### 0001-analytical-reads-fenced-to-public — the `_control` fence

- **What it is:** the rule that the backbone feed reads `public.*` only;
  `_control` (the chaos ledger) is verifier-oracle-only.
- **Why it is shaped this way:** `_control` is facilitator ground truth living
  in the same database; without an explicit fence it reads like just another
  source schema.
- **The decision it encodes:** the pipeline never ingests `_control`; the R-3
  eval harness *may* read it as a correctness oracle (a verifier is not an
  analytical consumer).
- **What breaks downstream without it:** the answer key leaks into the surface
  whose correctness it is meant to judge — the R-3 oracle becomes circular.

### 0002-no-row-level-change-timestamp — the freshness clock source

- **What it is:** the fact that `public` has **no** change/CDC column; the only
  timestamps are insert-time, yet `orders` rows mutate in place.
- **Why it is shaped this way:** R-1/R-4/R-10 measure freshness of *changes*,
  and a planner would reach for an `updated_at` that does not exist.
- **The decision it encodes:** the freshness change-signal must come from
  outside the `public` columns; which mechanism is a **Pass 3** choice (this
  ADR deliberately does not pick WAL/CDC/snapshot).
- **What breaks downstream without it:** Pass 3 builds freshness on
  `ordered_at`, which is blind to the status/`total_amount` updates R-1 must
  catch — the 5-minute guarantee silently measures the wrong thing.

### 0003-single-principal-no-analytical-query-seam — the R-2/R-5 precondition

- **What it is:** the fact that the operational DB has one login role
  (`postgres`) — no separation of app / capture / analytical readers.
- **Why it is shaped this way:** R-2 defines an analytical query "by
  principal" and R-5 revokes analytical access — both need the DB to tell
  principals apart.
- **The decision it encodes:** the by-principal seam is a **build-surface
  prerequisite**, not a given the acceptance tests can assume.
- **What breaks downstream without it:** Pass 3 claims R-2/R-5 are satisfiable
  by observation when the very identities they count don't exist — the
  lockdown and the zero-query window become undefined.

### 0004-revenue-is-captured-not-paid — the metric definition

- **What it is:** the resolution of a spec-vs-data conflict — the spec says
  "paid," the data has no such status; revenue = `sum(amount) WHERE
  status='captured'`, on `paid_at`.
- **Why it is shaped this way:** grounding is where a fuzzy business word meets
  the real column values; the conflict is itself a fact to record.
- **The decision it encodes:** `captured` is realized revenue; `authorized`,
  `refunded`, `failed` are not; order totals are not revenue.
- **What breaks downstream without it:** Pass 3 sums the wrong rows — counting
  authorizations and refunds overstates revenue against the R-3 answer key.

### 0005-payments-order-cardinality-not-enforced — the join guardrail

- **What it is:** the fact that `payments.order_id` is a non-unique FK — the
  schema permits many payments per order; the seed's 1:1 is data, not a
  guarantee.
- **Why it is shaped this way:** the seed hides the risk at 1:1, so a planner
  would naturally join one-to-one.
- **The decision it encodes:** aggregate payments per order; never assume 1:1;
  never substitute `orders.total_amount`.
- **What breaks downstream without it:** the moment production writes a second
  payment row for an order, a 1:1 revenue join double-counts or drops money.

### 0006-revenue-join-grain-is-transitive — the flagship join path

- **What it is:** the fact that `payments` carries no `product_id`/`customer_id`
  — revenue-by-product/customer must join `payments → orders → products|
  customers`.
- **Why it is shaped this way:** R-3's Q-SET-1 slices revenue by product and
  customer, but the slicing keys live on `orders`, not `payments`.
- **The decision it encodes:** the revenue metric's real grain is the two-hop
  transitive join; there is no direct edge.
- **What breaks downstream without it:** Pass 3 references `payments.product_id`
  (which fails) or reports revenue-by-product ungrounded, off the real grain.

### docs/CONTEXT.md — the glossary

- **What it is:** ten canonical terms (revenue, analytical query, freshness
  lag, staleness, the four domains, `_control` ledger, time grain, money
  precision, referential integrity, partner-vs-customer), each tracing to
  evidence.
- **Why it is shaped this way:** two agents must not mean different things by
  "revenue" or "partner"; terms-only, no design — it is a dictionary.
- **The decision it encodes:** the vocabulary is pinned once, at grounding,
  where words meet columns — including that "partner" (a query consumer) is
  **not** a `customers` row.
- **What breaks downstream without it:** every later pass re-derives fuzzy
  terms and drifts; "partner activity" gets answered from `customers`, revenue
  from floats.

## Decisions and roads not taken

| Decision | Rejected alternative | Why it lost |
|----------|---------------------|-------------|
| Revenue = `captured` payments (0004) | Order totals, or any non-`failed` payment | The spec's "paid" status doesn't exist; counting authorized/refunded overstates money never taken or given back |
| Freshness signal comes from outside `public` columns (0002) | Use `updated_at` / `ordered_at` as the write clock | No change column exists; `ordered_at` is blind to in-place `orders` updates |
| Leave the capture mechanism to Pass 3 (0002, review B-2) | Prescribe Postgres WAL / logical replication here | That's a Pass 3 stack choice, and it touches the operational system just like the `updated_at` this ADR rejected under W-1 |
| `_control` fenced from the pipeline, oracle-only (0001) | Ingest `_control` as a normal source schema | Leaks the answer key into the surface whose correctness it judges |
| By-principal seam is build-surface, not given (0003) | Assume distinct principals already exist | Only the `postgres` role can log in; R-2/R-5 become unmeasurable |
| Transitive revenue join `payments→orders→products` (0006) | Assume `payments.product_id` exists | The column is absent; a direct slice fails |
| Promote revenue / cardinality / transitive-join to their own ADRs (0004–0006) | Keep them as glossary lines only | Each passes the worthiness test (hard-to-reverse · stood-on-downstream · could-have-been-otherwise) |

## Vocabulary

- **accepted / immutable:** an ADR's lifecycle state after sign-off; a changed
  fact is handled by *superseding*, never editing.
- **ADR:** Architecture Decision Record — here, one evidence-backed terrain
  fact per file.
- **capture:** the mechanism that feeds operational changes into the backbone
  (chosen at Pass 3).
- **CDC:** change-data-capture — reading a database's change/replication stream
  rather than polling columns.
- **`_control` fence:** the rule keeping the facilitator's chaos ledger out of
  the analytical pipeline.
- **grain:** the unit/resolution of a column — here, the UTC time grain
  (`TIMESTAMPTZ`) and the join grain (per-order, transitive).
- **greenfield:** the thing to build doesn't exist yet (vs. brownfield, a
  working base already runs).
- **grounding fact:** a claim about the terrain that a downstream pass stands
  on, cited to a schema line / row count / command output.
- **principal:** a database login identity; R-2 counts analytical queries "by
  principal."
- **`spec_ref`:** the ADR frontmatter field citing the requirement IDs (R-n)
  the fact grounds — the traceability chain.
- **worthiness test:** the three conditions an ADR must meet (hard-to-reverse ·
  stood-on-downstream · could-have-been-otherwise) — the guard against ADR
  inflation.

## What to watch

- **Seed is small** (50/20/200/200), not the Makefile default (500/200/5000);
  facts are structural (seams, types, constraints), so counts don't change
  them — but re-verify if the seed is regenerated.
- **`_control` is empty** now (silent injection); the fence is structural, not
  count-dependent.
- **The principal seam and "partner activity" are unmeasurable today** (0003) —
  a build-surface prerequisite the R-2/R-5/Q-SET-1 acceptance tests depend on.
- **Net-of-refunds revenue** is left open as a Pass 3 metric question; the base
  term is captured-only (0004).
- **Re-verification is manual for now:** every Evidence block carries a
  re-runnable command (two were re-executed at close), but the automated
  `--check --reverify` runner (that turns rot into a CI signal) is still a
  future step, slotted at R2.I / the Milestone-2 gate.

## Check yourself

1. Why is "revenue" defined as `captured` and not the spec's word "paid"? (→ see "0004-revenue-is-captured-not-paid")
2. The terrain has no `updated_at` column — so where must the freshness clock come from, and who decides the mechanism? (→ see "0002-no-row-level-change-timestamp")
3. What would break if Pass 3 joined `payments` to `orders` one-to-one? (→ see "0005-payments-order-cardinality-not-enforced")
4. Why can the R-3 eval harness read `_control` when the pipeline cannot? (→ see "0001-analytical-reads-fenced-to-public")
5. R-2 and R-5 look satisfiable by just watching the query log — why aren't they, today? (→ see "0003-single-principal-no-analytical-query-seam")
