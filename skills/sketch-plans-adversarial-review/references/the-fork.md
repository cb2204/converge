# The Fork — plan-driven (A) vs. task-driven (B)

Converge Pass 4 (Consensus), Step 4. Naming the fork is **the decision of this
pass**, not a footnote. It must precede Pass 5 because spec-vs-task is a
*structural* choice about **where the trust boundary sits** — the rest of the
chain forks on it, and it cannot be deferred.

The fork is declared **at the top of every plan** (`sketch/*.plan`), as a
letter + a one-line reason. The gate (`scripts/check-consensus-gate.sh`) fails
unless every plan carries it.

## The one question the fork answers

**Where do we draw the boundary we are willing to trust?**

- **Fork A — plan-driven.** Wrap the *whole system* in one trust boundary. Hand
  one coherent, coupled spec to a single autonomous agent. A human holds one big
  end-to-end gate. The unit of trust is the system.
- **Fork B — task-driven.** Draw the boundary around *each unit*. Cut the plans
  into atomic, individually eval-bearing tasks, dispatched per unit. The unit of
  trust is the task; convergence is task-by-task.

Neither is "better" in the abstract. The right fork is the one whose trust
boundary matches how the system actually *verifies*.

## The rubric — decide on verifiability, not size alone

Ask, per system:

| Question | Points to A | Points to B |
|---|---|---|
| Does any single layer/endpoint verify **in isolation**? | No — only the whole thing proves out | Yes — each unit has a cheap, runnable eval |
| Is the system **small and tightly coupled**? | Yes — the parts don't stand alone | No — clean seams between units |
| Can a human hold **one** end-to-end gate cheaply? | Yes | The gate is naturally per-unit |
| Is the cheapest wrong idea killed by a **whole-run** or a **per-unit** check? | Whole-run | Per-unit |

**Decide on the evals, not the line count.** The deciding test is: *does every
layer and endpoint have a cheap, runnable eval?* If yes, task-by-task
convergence beats one big autonomous run → **Fork B**. If nothing verifies in
isolation and the system only makes sense as a whole → **Fork A**.

## How this repo forks (worked example)

This stack — Postgres → DuckDB → dbt medallion → FastAPI + MCP — lands on
**Fork B**, and both `sketch/*.plan` say so at the top, because:

- The medallion is a **deterministic, layered DAG**: bronze → silver → gold.
  Each dbt model has a known input, a known output, and dbt schema/data tests
  that pass or fail **in isolation**. One model + its tests = one atomic,
  self-checking task.
- The serving layer is a **thin, stateless surface over a frozen contract**: one
  query-core function per mart, one endpoint and one MCP tool per question — each
  independently testable (contract test, endpoint test, tool-vs-endpoint parity,
  read-only/gold-only isolation check).
- Because every unit has a cheap eval, a whole-spec autonomous run would only
  *blur* the layer boundaries, hide which step regressed, and make the per-layer
  evals unenforceable. Task-driven keeps each defect-handling rule, each mart,
  and each endpoint behind its own green check.

A system that instead had *no* per-unit eval — where the medallion and serving
only prove out end-to-end and are too coupled to split — would be **Fork A**:
one coherent spec, one end-to-end eval, one human gate.

## Record the choice AND the why

At the top of every plan, write one of:

```
FORK: B (task-driven) — every layer and endpoint has a cheap runnable eval, so
task-by-task convergence beats one autonomous whole-system run.
```

```
FORK: A (plan-driven) — nothing verifies in isolation; the system is small and
tightly coupled and only proves out as a whole, under one end-to-end gate.
```

The prose form already in this repo's plans is equivalent and also passes the
gate:

```
> **Execution model: FORK B — task-driven.** ...why FORK B fits this build...
```

Both plans must agree on the fork — a split system where lane A is task-driven
and lane B is plan-driven is itself an objection to resolve in Step 3, not a
valid outcome.

## How each fork feeds Pass 5

Pass 5 only makes sense once the fork is committed. The hand-off:

- **Fork A → Pass 5A (`plans-to-coherent-spec`).** Fuses the two sharpened plans
  into ONE coherent, coupled spec governed by a single end-to-end eval — the
  whole system as the unit of trust. No tracker, no per-task backlog.
- **Fork B → Pass 5B (`task-spec`).** Cuts the sharpened plans into atomic,
  vendor-portable, self-verifying Task-Specs (`tasks/T-*.md`), each with its own
  runnable eval. From there the REGISTER bridge (`task-specs-to-issues`) can put
  the backlog on a tracker, and Pass 8 (`task-loop`) drives each issue to a
  green-eval PR.

Do not start Pass 5 until the gate is green and the fork is written at the top
of every plan.
