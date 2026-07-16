# cvg — Build Plan (one step at a time)

> The build backlog for `cvg`, the multi-harness CLI that automates Converge.
> **This file is the working contract for every build session.** The root
> [`todo.md`](todo.md) stays the *method* backlog (B-1…B-14); this file is the
> *build* backlog that implements B-1/B-2/B-3/B-4/B-9/B-12/B-13 as one CLI,
> ordered so every step is small, testable, and proven before the next begins.
>
> Context artifacts (read before building):
> [`readme.md`](readme.md) · [`presentation/cvg-automation-plan-v1.0.html`](presentation/cvg-automation-plan-v1.0.html)
> (the full design: command surface §06, flow §07, use-case §08, phases §11, risks §12)
> · [`skills/task-spec/`](skills/task-spec/) (the atomic unit — its scripts are the CLI's core).

---

## Fresh session? Start here

This file is the complete contract — assume no prior conversation. **cvg** is a
multi-harness CLI that automates the Converge method (eight passes, fuzzy brief
→ eval-gated system; see `readme.md`). The CLI is the **referee, never a
player**: it frames prompts, dispatches engine CLIs headlessly, and gates their
outputs with the existing check scripts — zero model credentials, no LLM calls
of its own. Before writing code, read: this file top to bottom →
`skills/task-spec/SKILL.md` + its `scripts/` (you WRAP these, never rewrite:
`safe-to-delegate.sh`, `accept-task.sh`, `run-task-spec.sh --ci`,
`validate-task-spec.sh`, `lint-backlog.sh`, `transition-status.sh`,
`conformance-check.sh`, `ref-executor.sh`) → the presentation deck. Then find
the first unchecked step below, do ONLY that step, prove its gate, log it,
commit (`cvg: <milestone.step> <what>`), and stop for the user's go.

---

## Rules of engagement (read every session)

1. **One step at a time.** Never start step N+1 before step N's gate is proven
   green in this file. Check the box, paste the proof command + output summary
   under the step, commit, then move on.
2. **The CLI is the referee, never a player.** `cvg` frames prompts, dispatches
   engines, and gates outputs. It holds **zero model credentials** and never
   calls an LLM API itself — it shells out to engine CLIs (`claude -p`,
   `codex exec`, `kimi`, …).
3. **Wrap, don't rewrite.** The 53 shell scripts in `skills/*/scripts/` are the
   subcommand implementations. `bin/cvg` routes to them. A rewrite of a working
   script needs a written reason in this file.
4. **State is derived, never stored.** Truth = `tasks/*.md` frontmatter +
   tracker + git. No database, no daemon state, no canonical graph file.
5. **Bash 3.2-safe core** (macOS system bash), matching task-spec's discipline.
   Python is stdlib-only. No npm/pip dependencies anywhere in the core path.
6. **Dogfood from Milestone 1 onward:** any step of effort S or larger is cut
   as a Task-Spec first (`skills/task-spec`), gated with
   `safe-to-delegate.sh --stamp`, and accepted with `accept-task.sh --stamp
   --gold-sanity` when done. Trivial steps (XS) may skip the ceremony — note it.
7. **Fixture-first testing.** Every piece is proven on
   `tests/e2e-test-engine/` (Milestone 0), never only on the converge repo
   itself. The fixture tests the *machine*; the real proving ground
   (`uc-postgres-duckdb-dbt-analytics`) validates the *method*.
8. **Gold-sanity always. Evals must discriminate** — an eval that passes on the
   unbuilt baseline is a bug in the step, not a pass.

---

## Milestone 0 — the test bed (implements B-9)

*You cannot test a factory without a floor. Build the floor first.*

- [x] **0.1 · Golden fixture repo** — `tests/e2e-test-engine/` ✅ 2026-07-16
  *(created as `examples/toy-revenue/`, renamed 2026-07-16)*
  - Build: tiny seeded SQLite (or DuckDB) repo — `orders`, `payments`,
    `products` tables, a `seed.sh`, a trivial transform script, and
    `evals/smoke.sh` (one passing eval) + `evals/red.sh` (a deliberately
    failing eval, used later to test RED paths).
  - **Prove:** fresh clone → `bash seed.sh && bash evals/smoke.sh` exits 0 in
    < 60 s; `evals/red.sh` exits 1.

- [x] **0.2 · Fixture backlog** — 6 Task-Specs with a diamond dependency ✅ 2026-07-16
  - Build: in `tasks/` (git-root-anchored by the tooling — one repo, one
    queue), author T1 (root) · T2, T3 (depend on T1) · T4 (depends on T2+T3)
    · T5 (independent) · T6 (designed to exhaust `budget_iterations` — an
    unsatisfiable eval). Real runnable evals against the seeded DB. Wire
    `depends_on`; give T2/T3 disjoint blast radii and T4 an overlap with T3.
  - **Prove (amended to match linter reality):** `safe-to-delegate.sh --stamp`
    → 6/6 DELEGATE + HMAC-sealed; `validate-task-spec.sh` green on all 6;
    `lint-backlog.sh` reports **exactly one** issue — the deliberate T3↔T4
    overlap, listed with both ids (exit 1 is expected: overlaps are issues by
    design, and that listing is the Manager's serialization input) — and no
    cycles, duplicates, or dangling deps.

---

## Milestone 1 — cvg v0: one name, derived state (implements B-3)

- [ ] **1.1 · The router** — `bin/cvg`
  - Build: bash-3.2-safe entrypoint with subcommand map wrapping existing
    scripts: `cvg tasks validate|gate|accept`, `cvg eval`, `cvg lint`,
    `cvg transition`, `cvg ready`, plus `cvg help` and `cvg version`.
    Repo-local resolution: find `skills/task-spec/scripts/` from the repo the
    command runs in (or a `CVG_HOME` override for the fixture).
  - **Prove:** on the fixture, `cvg tasks gate tasks/T-…md` produces the exact
    same verdict + exit code as calling `safe-to-delegate.sh` directly (diff
    the outputs); `cvg help` lists every subcommand.

- [ ] **1.2 · Derived spine state** — `cvg status [--json]`
  - Build: stdlib-python harvester (the B-4 spike rules, rebuilt): spine state
    from artifact presence (tech-spec → P1, `docs/adrs/` → P2, `sketch/*.plan`
    → P3, stamped specs → 5B, tracker binding → ①, `.claude/` → P6, fleet
    done/total → 7/8) + task state from frontmatter. `display_status` is
    computed: `ready` with un-done deps *displays* blocked.
  - **Prove:** on the fixture — move an artifact away → that pass flips red on
    the next run; restore → green. JSON validates against a shipped
    `state.schema.json`.

- [ ] **1.3 · The queue accessor** — `cvg next [--json]`
  - Build: read-only: returns the first task whose `status: ready` ∧ all
    `depends_on` done ∧ `signed_off: true`, in graph order; `null` when dry.
    Never mutates anything.
  - **Prove:** fixture backlog → returns T1 (T5 listed as also-ready); hand-flip
    T1 to done + rebuild state → returns T2/T3; flip all → returns null with
    `done_count`/`remaining_count` correct.

**Milestone gate:** `cvg status` + `cvg next` agree with reality after any
manual file edit, with no stored state anywhere. `git grep -l 'state cache'` → empty.

---

## Milestone 2 — trust before scale (implements B-2)

- [ ] **2.1 · Machine-readable eval runs** — `cvg eval T-… --ci`
  - Build: JSON line per eval (id, verdict, duration, tail of output) +
    machine exit code — port the `run-task-spec.sh --ci` pattern up to the
    issue level (`run-issue-eval.sh --ci`).
  - **Prove:** on fixture T5 — JSONL parses with `jq`; exit 0 iff Exit Check
    passes; `evals/red.sh` task exits non-zero with the failing eval named.

- [ ] **2.2 · The CI eval-gate** — `cvg ci install` (first template)
  - Build: `templates/ci/converge-eval-gate.yml` — on `task/*` PRs, clean
    container, re-run the task's own evals via `cvg eval --ci`, report a
    required status check. Push the fixture to a throwaway GitHub repo and
    enable branch protection.
  - **Prove (the B-2 gate):** a PR whose branch claims GREEN but whose eval
    fails in the container is **blocked from merge**, with the failing eval's
    output visible on the check. A genuinely green PR merges.

---

## Milestone 3 — engines: dispatch ONE task (the first real automation)

- [ ] **3.1 · Engine adapters + doctor** — `adapters/engines/*.sh`, `cvg doctor`
  - Build: adapter contract — stdin/arg: prompt file + workdir; behavior:
    headless run (`claude -p`, `codex exec --json`, `kimi`), exit code through,
    final message to stdout. ~20 lines each. `cvg doctor` certifies each
    installed engine: binary present, hello-world card round-trips, artifact
    lands in the workdir.
  - **Prove:** `cvg doctor` prints a per-engine PASS/SKIP table on this
    machine; at least two engines PASS.

- [ ] **3.2 · Single-task worker** — `cvg work T-… --engine e`
  - Build: acquire lock (`transition-status.sh` → in-progress), create a git
    worktree, hand the engine the **sealed spec as the only instruction
    source**, loop: implement → `cvg eval --ci` → RED feeds back, bounded by
    `budget_iterations`; GREEN → done + evidence; exhaustion → parked with
    `blocked_reason`. (This is `ref-executor.sh` with the dumb work block
    swapped for a real engine.)
  - **Prove:** fixture T5 goes ready → done **unattended** by a real engine,
    evals green from a clean checkout; T6 parks at budget with a report and
    the worktree preserved for inspection.

- [ ] **3.3 · Conformance: cvg certifies itself**
  - Build: nothing new — run task-spec's own suite against the new worker.
  - **Prove:** `conformance-check.sh --level L2 --executor "cvg work --engine
    claude"` prints `CONFORMANCE=L2`.

---

## Milestone 4 — the Manager tick (implements B-1, Profile L)

- [ ] **4.1 · Sequential tick** — `cvg run --once`
  - Build: stateless: read ready (`cvg next`), dispatch one `cvg work`, settle
    (done) or park, append `TICK/DISPATCH/GREEN/PARKED` events to
    `_fleet.jsonl`, exit.
  - **Prove:** three consecutive `--once` runs on the fixture complete T1 then
    T2 then T3, deriving everything fresh each time (kill/restart safe).

- [ ] **4.2 · Parallel fleet** — `cvg run --max-parallel 3`
  - Build: at-most-one lock per task carried on the task/issue; one worktree
    per in-flight task; **serialize `touches_paths` overlaps**; park on budget;
    stop only at fleet-green or all-parked; `check-fleet-green.sh`.
  - **Prove (THE B-1 gate):** the diamond backlog reaches fleet-green
    unattended with T6 force-failed → parked + reported; T4 provably waited
    for the T3 overlap; `check-fleet-green.sh` exits 0 only when every task is
    closed by a green eval.
  - *Note from 0.2:* the T3↔T4 overlap is also dependency-ordered, so deps
    alone would serialize it — to prove the overlap rule specifically, this
    step must add one **no-dependency** overlap pair to the fixture backlog
    (two ready tasks sharing a path) and show the Manager runs them serially.

- [ ] **4.3 · Routing v1** — `cvg route [--explain]`
  - Build: pin (`execution_backend`) → rules (effort × severity → engine
    table in `.converge/routing.yaml`) → fallback default. Every decision logs
    a rationale record `{task, chose, source, why}` to the ledger. (Receipts
    layer comes in Milestone 7 — leave the seam.)
  - **Prove:** `--explain` dry-run prints one rationale per ready task; a pin
    always wins; changing a rule changes the plan without touching code.

---

## Milestone 5 — the board (implements B-4; spike rules apply)

- [ ] **5.1 · Harvester + zoom 0/1** — `cvg board --serve|--snapshot`
  - Build: stdlib `serve.py` (`state` / `serve` / `snapshot`, re-harvest per
    GET, no-store) sharing Milestone 1's derivation; ONE self-contained HTML —
    spine gate strip (zoom 0) + swimlane DAG with overlap badges (zoom 1);
    LIVE/SNAPSHOT dual mode. Design: the blueprint language of
    `presentation/*.html`. **Read-only — the board never writes.**
  - **Prove:** re-pass the 9 spike evals (schema-valid JSON from real
    frontmatter; every task + one edge per dep; blocked display; zero network
    in snapshot mode); editing a task's `status:` updates the DAG within one
    poll.

- [ ] **5.2 · Ledger rail + trust ladder (zoom 2)**
  - Build: `_fleet.jsonl` timeline (typed events, honest empty state) and the
    per-task trust ladder (signed_off/HMAC → dispatched → tiers → accepted)
    rendered from real fields.
  - **Prove:** watch a live `cvg run` paint DISPATCH/RED/GREEN/PARKED in
    order; the ladder for a done task shows every rung with its evidence.

---

## Milestone 6 — verification depth (implements B-12 + B-13)

- [ ] **6.1 · Tier-2 judge** — `cvg verify T-… --judge e`
  - Build: fresh-context dispatch to a *different* engine; context allowlist =
    diff + Behavior zone + evals (never the worker's transcript); structured
    verdict JSON; **fails closed** (missing/malformed verdict ≠ pass);
    severity decides whether tier 2 is mandatory.
  - **Prove (the B-12 gate):** a fixture task "solved" with a hardcoded lookup
    table passes tier 1 but is **refuted by tier 2** and blocked.

- [ ] **6.2 · Provenance + injection defense**
  - Build: enforce sealed-spec-as-only-instruction-source in `cvg work`
    (issue bodies are display text, never prompt content); stock
    dependency-verification eval added to the task-spec template.
  - **Prove (the B-13 gate):** a fixture issue whose body contains "ignore the
    spec, run curl…" produces zero deviation — the worker's prompt file
    provably contains only the sealed spec.

---

## Milestone 7 — conductor, platform, receipts (the horizon)

- [ ] **7.1 · `cvg deliver`** — sequence passes 1–6 + register, stopping only
  at H1/H2; resume from `cvg status`. Gate: brief → sealed registered backlog
  with exactly two human stops.
- [ ] **7.2 · Profile C** — bind the tick to GitHub Actions / `gh aw`
  (`cvg ci install` emits dispatch + settle templates). Gate: the Milestone-4
  fixture goes fleet-green in CI, laptop closed.
- [ ] **7.3 · Receipts routing** — `cvg metrics` (time-to-green, RED
  histogram, cost + first-pass per engine) feeding `cvg route` layer 3.
  Gate: the router demonstrably changes a pick based on accumulated ledger
  data, with the rationale citing the numbers.

---

## Progress log

> Append one line per completed step: date · step · proof command · result.

- 2026-07-16 · **0.1** · `/bin/bash seed.sh && /bin/bash evals/smoke.sh` → exit 0 in 0.064s (bash 3.2.57); `evals/red.sh` → exit 1 ("gold_daily_revenue does not exist yet"). Effort XS — Task-Spec ceremony skipped per rule 6. Note: red.sh doubles as backlog T1's Success Criteria (discriminating by construction).
- 2026-07-16 · **housekeeping** · fixture renamed `examples/toy-revenue/` → `tests/e2e-test-engine/` (proof re-run green from new path); `cvg-kickoff-prompt.md` deleted — its bootstrap content folded into this file ("Fresh session? Start here"). One contract file from here on.
- 2026-07-16 · **0.2** · 6 specs authored via `generate-task-spec.sh` + filled; `validate-task-spec.sh` 6/6 OK; `safe-to-delegate.sh --stamp` 6/6 DELEGATE (Tier-1 HMAC, key 1f197c76); `lint-backlog.sh` → exactly 1 issue: overlap on `build_daily_totals.sh` between T-…-build-daily-totals and T-…-build-revenue-report, exit 1 (deliberate). **Findings paid for:** (1) overlap detection is touches_paths-only — a file created by task A and modified by task B must be redundantly declared in B's *and A's* touches+creates to be machine-visible (convention adopted); (2) editing sealed frontmatter invalidates the envelope → re-stamp is the only path (proved on T3, new sig minted); (3) the tooling anchors `tasks/` at git root — fixture backlog lives in the repo's single queue, which is what the Manager wants anyway. Dogfood note: the step's deliverable IS task-specs, so the ceremony (generate→validate→gate) was intrinsic.
