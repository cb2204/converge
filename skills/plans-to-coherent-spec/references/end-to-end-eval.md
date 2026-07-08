# The single end-to-end eval — Converge Pass 5A (Fork A)

Fork A produces **exactly ONE eval**: `specs/e2e-eval.sh`. It is the definition of
done for the whole coherent spec. Done = this eval is green — never "looks done."
If you cannot write it, the spec is not yet coherent/coupled enough to leave this
pass; go back to COUPLE (Step 2) and sharpen the seam or an invariant.

This is the single artifact the shared Execution gate (Pass 8 · The Loop) drives
to green. On Fork A the runner converges the whole coupled system against this one
eval, rather than closing tasks one by one.

## Why one eval, not many

Fork B (`task-spec`) writes one atomic eval per task — each layer verified in
isolation, unattended. Fork A trades the other way: the unit of trust is the
**whole system**, so a human holds ONE big gate and the eval spans the entire
spine. One eval that fails somewhere is more honest about a coupled system than N
green per-layer evals that each pass while the seam between them is broken.

## What it must drive — the real flow

The eval drives your project's **actual** pipeline, end to end, through the real
commands and the real read path. No mocks, no stand-ins. Whatever your stack, the
eval walks the same generic stages, from a known deterministic input to the answer
at the far end:

| Stage | What it runs | What it establishes |
|---|---|---|
| **SEED / PREP** | your project's data-prep / ingest command | a **known, deterministic** input to the pipeline |
| **TRANSFORM** | your project's transform step | the input becomes the processed / published state |
| **ASSERT-OUTPUT** | a read-only query against your output/contract layer | the expected shape at the internal contract boundary |
| **SERVE** | your serving layer (API, MCP tool, CLI, etc.) | the expected answer at the **far end** |

Adapt the stages to your pipeline — some projects prep-then-serve with no separate
transform; some publish to files rather than a store. Keep the *shape*: known input
→ transform → assert the contract → assert the served answer.

> **Example — a Postgres → DuckDB → dbt → MCP project.** SEED runs
> `make seed …SEED=42` to write a deterministic Postgres source; TRANSFORM runs the
> data-prep command then `dbt build` to land `raw.*` and build the medallion
> (bronze → silver → gold); ASSERT-OUTPUT reads the `gold.*` marts read-only;
> SERVE hits the FastAPI endpoint and the MCP tool. This is *one* concrete shape,
> not the required one — substitute your own stack's commands throughout.

Grounding facts the eval should encode for **your** project (resolve these once, do
not re-derive them elsewhere):

- **The data-store path / output location** comes from a single source of truth in
  your project (a config module, an env var such as `$DATA_STORE`, a settings file).
  Read it from there; never hardcode a second copy.
- **Reads go through your project's read path** — the eval honors the SAME
  read-only / non-mutating invariant the serving layer must, so it cannot contend
  with or corrupt anything upstream (E1 by construction).
- **The interpreter / runtime** the eval invokes is the project's pinned one (e.g. a
  virtualenv or a lockfile-managed toolchain), with a sensible fallback.
- **Which prep/transform commands exist today vs. are added by Execution** — a
  scaffolded eval may reference commands that Components under construction will
  provide. Note that gap explicitly (see "RED until built").

## What it must assert — the far end

A known input must produce **both**:

1. **The expected output shape** — the internal contract holds: each published
   artifact (table, mart, file, response) exists with the columns/fields its
   contract declares, aggregates reconcile against the upstream stage, and any
   atomicity invariant holds (e.g. one publish generation is visible — no
   half-published state).
2. **The expected served answer** — every entry point in your serving layer returns
   the **same** value for the same frozen question (same core ⇒ same answer), and
   that value matches the output shape asserted above.

One eval, end to end, unambiguous pass/fail.

## RED until built — by design

The scaffold (`scripts/scaffold-e2e-eval.sh`) stamps a runnable skeleton that is
**RED until the transform and serving layers exist**. That is the correct Fork-A
signal, not a bug: the eval is what Execution drives to GREEN. Each stage prints a
precise, actionable reason when its layer is not yet built — for example "no
transform project found — the transform layer (Component A) is not built yet" or
"serving entrypoint missing — the serving layer (Component B) is not built yet" — so
a RED run always names the exact gap to close next.

The skeleton uses `set -uo pipefail` (not `-e`) on purpose: it runs **every** stage
and reports **all** gaps in one pass, instead of stopping at the first failure. It
exits non-zero if any check fails and zero only when the whole spine is green.

## Authoring workflow

1. `scripts/scaffold-e2e-eval.sh --specs-dir specs/` — stamp the skeleton with its
   generic `TODO(author)` stages (SEED/PREP → TRANSFORM → ASSERT-OUTPUT → SERVE).
2. Freeze the **question set** and the **output contract** (the one gating input
   from Pass 4). Until frozen, the published-artifact list and the exact answers are
   provisional.
3. Fill the `TODO(author)` stages and assertions for YOUR stack: the concrete
   prep/transform commands, the concrete output values for your known input, and the
   concrete serving answers they map to.
4. `chmod +x specs/e2e-eval.sh` (the scaffold already does this) and
   `bash -n specs/e2e-eval.sh` — must be clean.
5. `scripts/check-coherent-spec.sh --specs-dir specs/` — the gate confirms the eval
   exists, is executable, is valid bash, and drives the real flow end to end.

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Can't write a single eval | plans not coherent/coupled enough | Return to COUPLE (Step 2): the seam or an invariant is still ambiguous. |
| Eval passes but the system is wrong | assertions stop at "artifact exists" | Assert the **far-end value** (the output total + the serving answer that equals it), not mere existence. |
| Tempted to write one eval per layer | Fork-B thinking | Fork A binds ONE eval spanning input → output → serving. If you truly need per-layer evals, you are on Fork B. |
| `check-coherent-spec.sh` fails on the eval | not executable or invalid bash | `chmod +x specs/e2e-eval.sh`; run `bash -n specs/e2e-eval.sh` and fix syntax. |
| Eval reaches past the contract to intermediate state to "help" | broke the read-only, output-only seam | Read only the published output layer, through your project's read path. A missing field is a new-artifact request to the upstream Component, not a deeper read. |
