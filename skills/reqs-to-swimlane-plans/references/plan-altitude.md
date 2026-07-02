# Plan altitude — the one guardrail of Pass 3 (no tasks, no SQL)

Pass 3 produces **plans**, not code and not tasks. A plan describes *what* each
lane contains and *in what order* it is built. This reference draws the altitude
line with worked examples and the rule for pulling a leaked detail back up.

## The one-line test

> Does this line say **what to build and in what order**, or does it say **how to
> build it**? If it's *how* — a `SELECT`, a handler body, an atomic task with an
> eval — it has dropped below plan altitude. Push it to Pass 5 (`task-spec`) and
> keep the *responsibility* in prose here.

A plan states responsibilities and sequence. A task states an executable unit with
its own pass/fail check. Code states the implementation. Only the first belongs at
this pass.

## Why the line matters

Pass 3 output is deliberately **un-hardened** — it is *supposed* to have soft spots
that Pass 4's adversary finds and sharpens in place. The moment a plan holds real
SQL or a task with an eval, it has skipped that review: the code was never
attacked, the seam was never tested, and Pass 5 lost the frozen shape it was meant
to build against. Holding altitude is what keeps the review meaningful.

## Plan altitude vs. below-altitude, side by side

| Plan altitude (Pass 3 — keep here) | Below altitude (Pass 5 — move out) |
|---|---|
| Silver **dedups `duplicate_order` by business signature and quarantines the rest**. | `SELECT ... QUALIFY row_number() OVER (PARTITION BY customer_id, product_id, …)` |
| Gold materializes **serving-ready marts shaped to the frozen E4 questions**. | `CREATE TABLE gold_revenue_by_category AS SELECT category, …` |
| The query core exposes **one read-only function per gold mart**. | `def revenue_by_category(day): return conn.execute("SELECT …")` |
| Test: **aggregates reconcile to silver (sum-of-mart = sum-of-source)**. | `assert result == 42061.50  # eval` in a `T-*.md` task with a bash block. |

The left column would read the same to any engineer and leaves the *how* open for
Pass 5. The right column pins an implementation — that is task/code work, and
pinning it here robs Pass 4 of anything to attack.

## Pulling a leaked detail back up

When a draft plan says *"silver dedups by signature — here's the SELECT:"* split it:

1. **Keep the responsibility.** *"Dedup `duplicate_order` by its non-PK business
   signature; keep the lowest `order_id`, route the rest to quarantine."* That is a
   plan sentence — it says what the layer must do and why.
2. **Move the SQL.** The `SELECT`/`QUALIFY` is a Pass 5 atomic task. Delete it from
   the plan; it re-appears as a `tasks/T-*.md` with its own dbt-test eval.

Likewise, an atomic task with an eval (`bash_eval:`, an `assert`, a `T-YYYYMMDD-…`
id) does not belong in a plan — the plan names the *test's assertion in prose*
("no NULL measures", "every frozen E4 question maps to a mart"), and Pass 5 writes
the runnable eval.

## What the check catches

`scripts/new-plan.sh --check` greps every `sketch/*.plan` for head-of-line
altitude leaks and missing structure:

- **SQL leak** — a line beginning `SELECT` / `INSERT INTO` / `CREATE TABLE|VIEW` /
  `WITH … AS (` / `UPDATE` / `DELETE FROM` / `MERGE INTO`.
- **Task / eval leak** — an atomic-task id (`T-######`, a `Task:` bullet) or an
  `eval:` / `acceptance_eval:` / `bash_eval:` block.
- **Missing section** — a plan without Identity / Features / Dependencies / Build
  order / Tests-that-prove / Open-questions is not skimmable or attackable.

A clean `--check` means the plans are at altitude and ready for the Pass 4
adversary. The check is heuristic, not a compiler — a `SELECT` embedded mid-prose
won't trip it, and judgment still owns the call; the grep just catches the obvious
drops.

## Related boundaries this pass also holds

Altitude is the *primary* guardrail, but two siblings ride with it:

- **Inherit the ADRs; never re-decide them.** A plan cites `docs/adrs/NNNN-*.md`
  (join path, grain, read boundary) — it does not re-settle them. Re-deciding is
  its own failure mode (see the skill's Step 3), distinct from an altitude leak.
- **Don't answer open questions inside the plan.** Anything the ADRs don't cover is
  surfaced in the Open-questions table with an owner and a blocks-build flag — not
  invented into the plan body.
