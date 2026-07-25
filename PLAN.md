# PLAN — the one document

> **This file consolidates `MAP.md` + `todo.md` + `cvg-todo.md`** into one
> working contract (2026-07-24): where things are, what's next, the rules, both
> tracks, the backlog, parked items, and the log. Assume no prior conversation —
> read §1 → §2 → the rules, then work.
>
> ✅ **2026-07-24 — the migration landed.** `MAP.md` / `todo.md` / `cvg-todo.md`
> are now **redirect stubs** pointing here. `readme.md` + `skills/README.md` are
> rewritten to the fork-less 0–8 model. **Skills = 12** (`plans-to-coherent-spec`
> + `stack-to-harness` deleted). `docs/` pruned to v5 + task-spec. Root `tasks/` +
> `temp/` + `tmp/` cleared.
>
> Older task-specs carry `source_note: cvg-todo.md`. That is **historical
> provenance and stays valid** — this file is its continuation.

---

## §✦ · THE METHOD — current shape (2026-07-24 pivot: the fork is gone)

> This section supersedes the fork model everywhere. `readme.md` + `skills/README.md`
> are being propagated to match; until they are, THIS is canonical.

**Thesis — intent-driven development.** The durable human job is making *intent
crystal-clear*; the machine's job is figuring out *how*. Converge invests the
human effort where models stay weak (intent + verification) and gets out of the
way where they're strong (implementation). This is the horizon and it holds for
years: *as more is automated, sending the right intent to the machine stays the
one irreducible driver of building the right thing.* Reduce **procedural
blockers**; never reduce the **verification gate** — the isolated eval is not a
blocker, it is the load-bearing property.

**Field validation (Exa/Firecrawl, 2026-07-24).** This maps onto Dan Shapiro's
*Five Levels: from Spicy Autocomplete to the Dark Factory* (Jan 2026): Phase 1 =
his **L4** (a PM writes/argues the spec, crafts the skills), Phase 2 = his **L5**
dark factory (specs in, software out). The barrier at Consensus **is** the L4→L5
line. The field names **three load-bearing properties** of a *real* dark factory
(vs "agentic coding with automation"): (a) agents work from **written specs** —
Converge ✅; (b) an **isolated evaluator grades against holdout the coder can't
see** — Converge ⚠️ (this is exactly **B-12**, now promoted from polish to
load-bearing); (c) **deploy path unchanged** — Converge ✅. "Dark factory" is now
crowded (Stripe Minions 1,300 PRs/wk, Ramp, OpenAI Harness Eng, `peter-stratton/
dark-factory`, Terraphim). **Converge's durable moat:** the full front-of-funnel
intent descent (0–4) — most tools start at "you already have a spec"; cross-*family*
adversarial consensus; HMAC-sealed specs (injection defense); multi-harness /
engine-agnostic; derived-not-stored.

### The two phases — the barrier is at Consensus

```
PHASE 1 · DESIGN — human-led · make intent crystal-clear
0 Capture → 1 Intent → 2 Structure → 3 Decompose → 4 Consensus  ⟵ THE BARRIER
PHASE 2 · BUILD — machine-led · the dark factory
5 Tasking → 6 Register (opt-in) → 7 Bind (+harness) → 8 Loop ↺
```

| # | Pass | Skill | Output · gate |
|:--:|---|---|---|
| 0 | Capture *(optional)* | `idea-to-brd` | BRD · `CHECK_BRD` |
| 1 | Intent | `brd-docs-to-tech-req` | tech-spec · `CHECK_TECH_SPEC` |
| 2 | Structure | `tech-req-to-adrs` | ADRs · `CHECK_ADR` |
| 3 | Decompose | `reqs-to-swimlane-plans` | swimlane plans (legs) · `CHECK_PLAN` |
| 4 | **Consensus — THE BARRIER** | `sketch-plans-adversarial-review` | sharpened plans + objection log · `CHECK_CONSENSUS` · **last human sign-off** |
| 5 | Tasking | `task-spec` | atomic sealed task-specs (DAG) · `safe-to-delegate --stamp` |
| 6 | Register *(opt-in)* | `task-specs-to-issues` | tracker board OR repo-local · `CHECK_REGISTER` |
| 7 | Bind *(+harness emit)* | `task-to-runtime-contract` | per-task contract + multi-engine harness · `CHECK_RUNTIME_CONTRACT` |
| 8 | Loop ↺ | `task-loop` | green-eval PR closes the issue → frontier advances |

**Skills = 12:** 9 spine (above) · 2 utils (`pass-to-lesson`, `skill-creator`) ·
1 legacy (`agents-kbs-tech-stack` — the harness donor for 7b). **DELETED:**
`plans-to-coherent-spec` (old Fork A) + `stack-to-harness` (superseded by Bind).

### Phase 2 — machine-side, step by step

- **5 · Tasking** — the sharpened plans → atomic, self-verifying `tasks/T-*.md`.
  Each carries: intent (the leg's responsibility), a **runnable eval** (definition
  of done), `depends_on` (the DAG), `touches_paths` (blast radius), effort, and an
  **HMAC sign-off seal** (the spec becomes the only trusted instruction source).
- **6 · Register — OPT-IN.** Two modes: **repo-local** (specs stay in `tasks/`,
  queue derived locally) or **tracked** (`cvg register` → Linear/GitHub/Jira issues
  + blocked-by links; the board becomes the shared visible queue). `register --check`
  is a real 1:1 parity gate. *(Repo-local Loop is a near-term gap — B-5 / `cvg next`.)*
- **7 · Bind (+ harness emit)** — two moves:
  - **7a Contract** — bind ONE signed task to a hash-bound evidence slice, explicit
    topology, portable path guards, pinned docs → `CHECK_RUNTIME_CONTRACT`.
  - **7b Harness emit** *(the re-homed piece)* — auto-detect engines (`cvg doctor`)
    and emit the **multi-engine context glue**: **AGENTS.md** (universal doctrine +
    this task's contract) + **CLAUDE.md / codex / cloud.md** (engine-specific).
    Principle (Delacretaz): *the harness orchestrates, the documentation teaches* —
    context is queryable, not baked in. This is what lets the SAME task run on
    `claude -p`, `codex exec`, a **kimi swarm**, or a cloud workflow.
- **8 · Loop ↺** — dispatch the bound task INTO a harness: branch/worktree, the
  engine reads AGENTS.md + the sealed contract (**only** instruction source) +
  queryable docs, implements → runs the eval → RED feeds back (bounded) → GREEN →
  PR closes the issue → the frontier advances. The **isolated holdout verifier**
  (B-12) is the merge gate. Orchestrated across the fleet by the Manager (B-1).

### The graph / observability layer — `cvg graph` (NEW, answers "see it move")

Converge builds ONE graph across every pass (BRD → requirements → ADRs → swimlanes
→ legs → task-specs `depends_on` DAG → issues `blocked-by` → PRs). A new
cross-cutting verb makes it visible — **derived, never stored** (the graph is a
*view* computed from files+tracker+git, so it cannot lie):

- `cvg graph` → derive + emit `converge-state.json` (nodes = passes/tasks, edges =
  deps; task status ready/inflight/done/parked; eval green/red).
- `cvg graph --serve` → localhost frontend, re-derives every request — watch tasks
  move and tests flip green live.
- `cvg graph --snapshot` → shareable static HTML.

Implements **B-3** (state) + **B-4** (board, already spiked 9/9) under one verb the
whole pipeline feeds. Lights up from Pass 3 (the swimlane DAG) and gets richer
through tasking/register/loop.

### Put-in-now (from the research, before the next pass)
1. **Bake the L4→L5 framing + the "3 load-bearing properties" checklist** into the
   README as the north-star (positions Converge precisely in the named field).
2. **Promote B-12 (holdout verifier) in the backlog narrative** from hardening to a
   *definitional* property of being a dark factory — it's one of the three.
3. **State the moat explicitly** (front-of-funnel intent descent · cross-family
   consensus · HMAC-sealed specs · multi-harness · derived-not-stored) — the space
   is crowded; the differentiators must be on the tin.

### Locked decisions (2026-07-24)
Fork **removed**; `plans-to-coherent-spec` **deleted**; numbering **continuous 0–8**;
Register **opt-in**; Bind **absorbs harness emit (7b)**; `cvg graph` **added**;
root `tasks/` + `temp/` **cleared**; Phase 1 **crystal-clear (locked)**; Phase 2
**detail open to refinement** (harness/graph specifics).

---

## §0 · Map — where do I look for X?

| Looking for… | Go to |
|---|---|
| **The method** (12 skills, the chain, no fork) | [`skills/README.md`](skills/README.md) |
| **The plan** (state, rules, tracks, backlog, log) | this file |
| **The proving ground** (greenfield run, Pass 0 →) | [`tests/uc-analytics/`](tests/uc-analytics/) — its `CLAUDE.md` maps the inside |
| **The machine fixture** (Track M test floor) | [`tests/e2e-test-engine/`](tests/e2e-test-engine/) |
| **A project's Converge home** | `<project>/cvg/` — its `INDEX.md` maps the five folders (brain → docs → sketch → tasks → receipts) + current pass state |
| **Design decks & demos** | [`presentation/`](presentation/) · [`docs/`](docs/) |
| **The CLI** (`cvg` — router, UI layer, surface ledger) | [`bin/`](bin/) — its `README.md` records what exists and what proved it |
| **The task-spec engine** (scripts the CLI wraps) | [`skills/task-spec/scripts/`](skills/task-spec/scripts/) |

---

## §1 · Where we are — 2026-07-24

**`cvg` v0.16.0 · 12 skills · Track R is at the Loop's doorstep.**

The descent is validated end-to-end from a raw idea to a live tracker board:

| Pass | Skill | State |
|:--:|---|---|
| 0 Capture | `idea-to-brd` | ✅ closed end-to-end (all five beats) |
| 1 Intent | `brd-docs-to-tech-req` | ✅ closed end-to-end |
| 2 Structure | `tech-req-to-adrs` | ✅ closed end-to-end (7 ADRs canonical) |
| 3 Decompose | `reqs-to-swimlane-plans` | ✅ closed end-to-end (3 swimlanes, 9 legs) |
| 4 Consensus | `sketch-plans-adversarial-review` | ✅ closed on a **real** cross-family adversary; **FORK B** named |
| 5B Tasking | `task-spec` | ◐ 9 specs cut, signed Tier-1, all `validate`/`gate`/`dod` green — beats U/C/I/P not formally closed |
| ① Register | `task-specs-to-issues` | ✅ **closed live 2026-07-24** — CVG-21…29 on Linear, 1:1 gate green |
| 6 Bind | `task-to-runtime-contract` | ◐ skill v1.0.0 + `cvg bind` **exist but are uncommitted**; never run on a real task |
| 8 The Loop | `task-loop` | ⬜ not started — **the next frontier** |

**The board is the queue and it is live.** 9 issues, 8 blocked-by links,
Initiative → Project → Capture/Transform/Serve milestones, append-only health.
The ready frontier is exactly **CVG-21** (`cap-steelthread`); the other eight sit
behind it. `cvg register --check` is now a **real** 1:1 parity gate (count ·
orphan · missing · dup) — it can fail, and it's proven to.

**Pass 7 remains the hole** — nothing dispatches ready issues, watches PRs, or
detects fleet-green. That is **B-1**, and it is still the load-bearing gap.

---

## §2 · What's next (ordered)

1. ~~Commit the in-flight Pass 6 work~~ — **done.**
2. ~~R6 · Bind, for real~~ — **done.** Pass 7 now emits 7A (contract) + 7B (task
   brief), carries an epoch-bound capability envelope, and gates fail-closed.
3. **R8 · The Loop, once, by hand** — drive **CVG-21** to a green eval and a PR
   that closes it. The frontier then advances to CVG-22 on its own. *This is the
   single highest-value next act: it closes the loop for the first time, and
   settlement is now trustworthy enough to try it (WP4).*
4. **Then, and only then, automate it** — B-1 (the Manager) + B-2 (the CI
   eval-gate). Building the Manager before the loop has ever closed once is
   automating an unproven path.
5. **Move 4b** — the in-toto/SLSA attestation chain (Plan → Generation →
   Approval), so the envelope's authority is externally checkable.

> **R8 pre-flight is CLEAR.** CVG-21's evals now assert database state and the
> stub attack is red; the spec is re-sealed Tier 1 and re-bound. Two things to
> expect on the run: the profile denies external writes, so it will settle
> **locally** (`TASK_LOOP=LOCAL_SETTLED`) — that is the WP4 gate working, and the
> push/PR leg is a deliberate second run with `--allow-external-writes`; and
> `uc-analytics-postgres` must be up (`make up`) because the evals now talk to it.

**Housekeeping that should not block the above:** nothing is pushed (branch is
ahead of `origin/feat/e2e`); see §9 for the full cleaning list.

---

## §3 · Rules of engagement (read every session)

0. **Go slow and teach.** The owner's understanding of every piece is a
   deliverable equal to working code. Every step: (a) BEFORE building, explain
   what it is, why it exists, how it fits; (b) AFTER proving, walk through what
   was built with runnable commands; (c) never bundle steps.
1. **One step at a time.** Never start N+1 before N's gate is proven green
   *in this file*. Check the box, paste the proof, log it, commit, stop.
2. **The CLI is the referee, never a player.** `cvg` frames prompts, dispatches
   engines, gates outputs. **Zero model credentials**; it shells out to engine
   CLIs (`claude -p`, `codex exec`, `kimi`).
3. **Wrap, don't rewrite.** The shell scripts in `skills/*/scripts/` are the
   subcommand implementations. A rewrite needs a written reason here.
4. **State is derived, never stored.** Truth = `tasks/*.md` frontmatter +
   tracker + git. No database, no daemon state, no canonical graph file.
5. **Bash 3.2-safe core** (macOS system bash). Python is stdlib-only. No
   npm/pip dependencies in the core path.
6. **Dogfood.** Any step of effort S or larger is cut as a Task-Spec, gated with
   `safe-to-delegate.sh --stamp`, accepted with `accept-task.sh --stamp
   --gold-sanity`. XS may skip the ceremony — note it.
7. **Fixture-first testing.** Prove on `tests/e2e-test-engine/` (the machine),
   never only on the converge repo. `tests/uc-analytics/` validates the method.
8. **Gold-sanity always. Evals must discriminate** — an eval that passes on the
   unbuilt baseline is a bug in the step, not a pass.
9. **Skill changes ship through skill-creator discipline.** `quick_validate.py`
   green, version bump, gate changes proven against BOTH a passing and a failing
   synthetic spec — including at least one **non-data domain** (universality).
   *(P-1 will amend this: bump only on gate/flag/IN-OUT changes.)*

### Hard-won traps — do not re-learn

- **`|| true` cannot catch an `exit`.** A helper that calls a function which
  `exit`s (e.g. `tsi_ln_die`) kills the whole process; only a **subshell**
  contains it. All fail-soft GraphQL goes through `_ln_gql_soft`. Command
  substitution `$( )` is already a subshell, so capture-style callers are safe.
- **Compute before write.** Build new content fully, *then* write — a baker once
  truncated its own output because `open(w)` evaluated before a failing `re.sub`.
- **Fix broken evals upstream in the spec**, never bend code to a bad grep.
- **No fake data.** Honest empty states beat demo rows that lie.
- **A gate that hides why it failed is worse than no gate** — never `2>/dev/null`
  an adapter's error inside a check.

---

## §4 · The operating model — five beats per pass

Track R validates the method **one pass at a time**; each pass is a complete
vertical slice. In order, never bundled:

1. **UNDERSTAND** — read the skill + references + check script end to end,
   compare against the field, deliver a hardening list for approval. No edits.
2. **RUN** — execute the pass **for real** on `tests/uc-analytics/`. The owner
   judges every output; hardening gets applied along the way.
3. **CANONIZE** — iterate until the owner calls it canonical. **Includes the
   TEACH beat:** run `pass-to-lesson`, `check-lesson.sh` green, lesson committed.
   *A pass is not closed until its lesson exists.*
4. **IMPLEMENT** — the `cvg` subcommand for this pass: frame → dispatch →
   collect → gate. Thin by design.
5. **PROVE** — re-run through the CLI on the same input; artifacts and verdicts
   must match the canonical manual run (**golden diff EMPTY**).

---

## §5 · Track R — validate the method, pass by pass ⟵ CURRENT

Detail is written only for the CURRENT/OPEN passes. Closed passes are one line;
their full narrative lives in §10 and in git history.

- [x] **R0 · Pass 0 Capture** ✅ 2026-07-19 — all five beats. `cvg capture`,
  golden diff EMPTY, `CHECK_BRD=PASS`. Second-eyes hardening closed the
  template-copy bypass (check-brd v0.3.1, suite 17→27).
- [x] **R1 · Pass 1 Intent** ✅ 2026-07-19 — all five beats. `cvg intent` +
  check-tech-spec v0.4.0 exit contract; golden diff EMPTY.
- [x] **R2 · Pass 2 Structure** ✅ 2026-07-21 — 7 ADRs canonical (0000–0006) +
  10-term glossary; second-eyes caught a frozen false fact before accept.
  `cvg structure`, golden diff EMPTY, `CHECK_ADR=OK`.
- [x] **R3 · Pass 3 Decompose** ✅ 2026-07-21 — skill 0.3.0→**0.7.0**
  (seam → swimlane → leg → task-spec; swimlane = directory; mermaid enforced).
  3 swimlanes, 9 legs. `cvg decompose`, golden diff EMPTY, `CHECK_PLAN=OK`.
- [x] **R4 · Pass 4 Consensus** ✅ 2026-07-21 — gate rewritten to validate a
  **stamped objection log** with referee-computed provenance hashes (the old
  gate was spoofable by typing a model's name). Real kimi adversary raised
  1 blocker + 3 high + 1 medium; all sharpened → **REVISE→PASS**. Owner named
  **FORK B**. `cvg review --adversary` (multi-engine merge) + `cvg doctor`.
  `CHECK_CONSENSUS=OK`.
- [~] **R5 · Pass 5B Tasking** — the backbone is cut and signed; beats not
  formally closed.
  - [x] R5.R ✅ 2026-07-21 — 9 legs → 9 task-specs in
    `tests/uc-analytics/cvg/tasks/`, clean depends_on DAG
    (steelthread→alldomains→{freshness,silver}→gold→publish→core→honest→mcp).
    Every task: `validate` ok · `gate` DELEGATE · `dod` COMPLETE. New
    `cvg tasks dod` (traceability matrix, `DOD=COMPLETE|GAPS`).
  - [ ] R5.U / R5.C / R5.I / R5.P — **decide whether to formally close these or
    fold 5B's validation into the R8 run.** The specs are already signed Tier-1
    and live on the board, so the practical value of a separate C/P beat here is
    low; recommend folding.
- [x] **R① · Register** ✅ **2026-07-24 — CLOSED LIVE.** `task-specs-to-issues`
  projected all 9 signed specs onto Linear as **CVG-21…29** (9 created, then
  idempotently updated), 8 `depends_on` → blocked-by links, receipts stamped.
  Native-field + projection + structure tiers shipped and live-proven:
  assignee (via `.cvg/people-map`), state from DAG position (root→Todo,
  blocked→Backlog), subscribers, the in-frontmatter `projection:` block, and
  opt-in Initiative → Project → Capture/Transform/Serve milestones with an
  append-only health note. **`register --check` is now a real 1:1 parity gate**
  (count · orphan · missing · dup) via a new six-verb-contract `list-issues`;
  proven to fail on injected orphan/missing. 120 offline tests, shellcheck 0.
- [~] **R6 · Pass 6 Bind** — `task-to-runtime-contract` v1.0.0 **exists**
  (skill + agents + references + scripts + tests) and `cvg bind` ships in
  v0.16.0 — **both uncommitted**. Never run on a real signed task.
  **Next:** commit it, then bind `T-20260721-cap-steelthread` and take
  `CHECK_RUNTIME_CONTRACT`. Note this **replaces the legacy `stack-to-harness`**
  workflow (now demoted to a migration-only package).
- [ ] **R8 · Pass 8 The Loop** — `task-loop --issue CVG-21` by hand, one issue.
  This is where Track M wakes up. **No `cvg` verb exists for the loop yet** —
  it is invoked as a skill; decide whether it earns one.

---

## §6 · Track M — the execution machine

Milestone 0 is the test floor and it waits. Milestone 1.1 was absorbed into
R0.I. The rest activate when Track R reaches the Loop.

| Milestone | Implements | State |
|---|:--:|---|
| **0** · test bed (fixture repo + 6-spec diamond backlog) | B-9 | ✅ done 2026-07-16 |
| **1.1** · the router `bin/cvg` | B-3 | ✅ done 2026-07-19 |
| **1.2** · derived spine state `cvg status [--json]` | B-3 | ⬜ open |
| **1.3** · queue accessor `cvg next [--json]` | B-3 | ⬜ open |
| **2.1** · machine-readable eval runs `cvg eval --ci` | B-2 | ⬜ open |
| **2.2** · CI eval-gate `cvg ci install` | B-2 | ⬜ open |
| **3.1** · engine adapters + `cvg doctor` | — | ✅ **done early at R4.I** |
| **3.2** · single-task worker `cvg work` | — | ⬜ open |
| **3.3** · conformance: cvg certifies itself | — | ⬜ open |
| **4.1–4.3** · Manager tick, parallel fleet, routing | B-1 | ⬜ open |
| **5.1–5.2** · the board (harvester + ledger rail) | B-4 | ⬜ open (spiked & validated) |
| **6.1–6.2** · tier-2 judge, provenance/injection defense | B-12, B-13 | ⬜ open |
| **7.1–7.3** · `cvg deliver`, Profile C, receipts routing | — | ⬜ horizon |

### Open milestone detail

**1.2 · `cvg status [--json]`** — stdlib-python harvester (B-4 spike rules):
spine state from artifact presence (tech-spec→P1, `docs/adrs/`→P2,
`sketch/*.plan`→P3, stamped specs→5B, tracker binding→①, runtime contract→P6,
fleet done/total→7/8) + task state from frontmatter. `display_status` is
computed: `ready` with un-done deps *displays* **blocked**.
**Gate:** move an artifact away → that pass flips red next run; JSON validates
against a shipped `state.schema.json`.

**1.3 · `cvg next [--json]`** — read-only: first task with `status: ready` ∧ all
deps done ∧ `signed_off: true`, in graph order; `null` when dry. Never mutates.
**Gate:** fixture returns T1 (T5 also-ready); flip T1 done → returns T2/T3.

**2.1 · `cvg eval T-… --ci`** — JSON line per eval + machine exit code; port
`run-task-spec.sh --ci` up to the issue level (`run-issue-eval.sh --ci`).
**Gate:** JSONL parses with `jq`; exit 0 iff Exit Check passes.

**2.2 · the CI eval-gate** — `templates/ci/converge-eval-gate.yml`: on `task/*`
PRs, clean container, re-run the task's own evals, required status check.
**Gate (= B-2's):** a PR claiming GREEN whose eval fails in the container is
**blocked from merge**, failing output visible.

**3.2 · `cvg work T-… --engine e`** — acquire lock, create a worktree, hand the
engine the **sealed spec as the only instruction source**, loop implement →
`cvg eval --ci` → RED feeds back, bounded by `budget_iterations`; GREEN → done;
exhaustion → parked with `blocked_reason`.
**Gate:** fixture T5 ready → done **unattended**; T6 parks at budget.

**3.3 · conformance** — `conformance-check.sh --level L2 --executor "cvg work
--engine claude"` prints `CONFORMANCE=L2`.

**4.1 `cvg run --once`** → stateless tick. **4.2 `--max-parallel 3`** → the B-1
gate: diamond backlog reaches fleet-green unattended with one force-failed task
parked; **must add a no-dependency overlap pair** to prove the `touches_paths`
serialization rule specifically (the T3↔T4 overlap is already dep-ordered).
**4.3 `cvg route [--explain]`** → pin → rules → fallback,每 decision logged.

**5.1/5.2 · the board** — see B-4's rebuild spec (§7). Read-only; never writes.

**6.1 `cvg verify --judge e`** → fresh-context tier-2 judge, fails closed.
**6.2** → sealed-spec-as-only-instruction-source enforced in `cvg work`.

---

## §7 · The method backlog — why each machine item exists

The gaps between what the spine *promises* and what the repo *ships*. **P0**
makes Pass 8's gate real; **P1** hardens trust and makes the machine visible;
**P2** compounds the loop; **P3** is hygiene.

| # | Item | Pri | Impact | Effort | Depends | Implemented by | Status |
|---|------|:--:|:--:|:--:|---|---|---|
| **B-1** | The Manager — `fleet-loop` (Pass 7 slot) | **P0** | 🔥 unlocks Pass 8's gate | L | — | M4.1–4.3 | open |
| **B-2** | CI eval-gate — server-side re-verification | **P0** | 🔥 makes "closed by evals" true | M | — | M2.1–2.2 | open |
| **B-3** | `converge-status` — spine as derived JSON | P1 | feeds board + resumability | S | — | M1.2–1.3 | open — design proven in the B-4 spike |
| **B-4** | `converge-board` — the graphical interface | P1 | see the machine run | M | B-3 (soft) | M5.1–5.2 | open — **spiked & validated 2026-07-07** |
| **B-12** | Graded verifier stack — the Goodhart defense | P1 | 🔥 hardens the eval moat | M | B-2 (soft) | M6.1 | open |
| **B-13** | Security pass — threat model & guardrails | P1 | 🔥 closes the injection surface | M | — | M6.2 | open |
| **B-5** | Fork A's loop story (synthetic issue) | P2 | closes Fork A's gap | S | B-1 | — | open |
| **B-6** | Pass 9 · Sustain — keep the fleet green | P2 | drift defense | M | B-1, B-2 | — | open |
| **B-7** | Adversary adapters for Pass 4 | P2 | repeatable Consensus | S | — | — | ✅ **effectively done at R4.I** |
| **B-8** | Fleet metrics + cost — receipts for the moats | P2 | measured optionality | S | B-1 | M7.3 | open |
| **B-9** | Golden fixture — 30-minute end-to-end | P2 | onboarding + B-1's test bed | M | — | M0 | ✅ done |
| **B-14** | Standards alignment — AGENTS.md v1.1 · A2A v1.2 | P2 | rides AAIF consolidation | S | — | — | open |
| **B-10** | Pass cards — regenerate `prompts/` | P3 | non-Claude engines | S | — | — | open |
| **B-11** | Chores | P3 | hygiene | S | — | — | ◐ only `.claude/` cleanup left |

**Sequencing**

```
P0   B-1 fleet-loop ──┬──▶ B-2 eval-gate       (together they make Pass 8's gate real)
P1   B-12 verifier stack · B-13 security       (harden the trust layer)
P1   B-3 status ──────┴──▶ B-4 board           (see the machine run — spiked)
P2   B-5 fork-A · B-6 sustain · B-8 metrics+cost · B-14 standards
P3   B-10 pass cards · B-11 chores
```

### B-1 · The Manager — fill the Pass 7 slot

A stateless *tick* that derives everything from the board + git, dispatches
`task-loop --issue N` for ready issues, and settles green PRs — until fleet-green.

**Why it can be dumb and still guarantee the process** — every guarantee already
lives in a gate a skill ships; the Manager is deterministic plumbing *between*
gates:

| Guarantee | Provided by | Ships? |
|---|---|:--:|
| Only well-formed, eval-carrying specs enter the board | `safe-to-delegate.sh --stamp` (HMAC) | ✅ |
| Board ≅ backlog, 1:1, no orphans, no cycles (DAG ⇒ dispatch terminates) | `verify-registration.sh` | ✅ **now a real parity gate** |
| No `touches_paths` overlaps ⇒ safe parallel dispatch | `lint-backlog.sh` | ✅ |
| Per-issue: eval green **or** explicit blocked report | `task-loop` (bounded) | ✅ |
| The work is real (blast radius, clean checkout, HMAC) | `accept-task.sh --gold-sanity` | ✅ |
| **Fleet-level progress + termination** | **the Manager tick** | ❌ **B-1** |
| **Server-side eval re-run as the merge gate** | **CI eval-gate** | ❌ **B-2** |

```
tick():
  ready    = adapter.read_ready()
  inflight = issues with an open task/ branch or PR
  if ready = ∅ ∧ inflight = ∅:
      run check-fleet-green.sh  → emit fleet report · STOP     # the only exit
  for issue in ready, up to MAX_PARALLEL:
      skip if touches_paths overlaps any inflight issue         # serialize
      acquire lock (assign/label on the issue)                  # at-most-one
      dispatch: task-loop --issue N --agent <spec's hint>       # one worktree each
  settle:
      PR + green eval-gate → merge → "Closes #N" → dependents unblock
      blocked report       → label blocked + park; never auto-retry
  ledger: append tick record to _fleet.jsonl
```

**Design invariants:** ① stateless/idempotent ticks (kill anytime, same
behavior); ② only the loop writes state — the Manager dispatches, merges green,
labels blocked; ③ at-most-one loop per issue via a lock *on the issue*;
④ **termination is provable** — the graph is a DAG, every dispatch ends in
{merged-green, parked} within budget, parked issues leave the ready set ⇒ the
ready set strictly shrinks.

**Profiles:** *L (local)* — `fleet-loop` + `manager-tick.sh` +
`check-fleet-green.sh`, laptop-scale. *C (CI/CD)* — `converge-dispatch.yml` /
`converge-eval-gate.yml` / `converge-settle.yml`; the platform supplies
scheduler, settlement, and required checks.

> **Reframe — bind the Manager, don't build it.** GitHub shipped the substrate
> (Agent HQ; Agentic Workflows in preview: agent runs as Actions with sandboxing,
> permissions, review). Profile C should target it; Converge supplies what the
> platform doesn't — definition of done, the eval-gate as the required check, and
> settle/park semantics. Keep the three-workflow design as the fallback + reference
> spec. The Manager is also a **budget officer**: enforce `budget_tokens`/cost caps
> alongside `budget_iterations`; park on exhaustion.
>
> **The Linear path is already wired.** `register` emits `--assignee agent:<role>`;
> one `.cvg/people-map` line makes assignment *the* dispatch signal with zero new
> code. What's missing is a signed, always-on receiver — see
> `skills/task-specs-to-issues/references/agents-api-scaffold.md` (T4 scaffold,
> deliberately dark).

**Gate:** on a ≥5-issue diamond backlog, `fleet-loop` reaches fleet-green
unattended, one force-failed issue parked + reported, `check-fleet-green.sh`
exits 0 only after every issue is closed by a green-eval PR.

### B-2 · The eval-gate — server-side re-verification

`run-issue-eval.sh --ci` (JSON verdict per eval, machine exit code) +
`converge-eval-gate.yml` running it in a clean container on every `task/*` PR as
a **required status check**. Without it, "closed by evals" means "closed by a
*claim* of evals." Trust nothing the worker says; re-run the eval.
**Gate:** a PR whose local run claimed GREEN but whose eval fails in the
container is blocked from merge, with the failing output on the check.

### B-12 · Graded verifier stack — the Goodhart defense

| Tier | Grader | Catches | Where |
|---|---|---|---|
| 1 | **Code** — the task's own bash evals | mechanical wrongness | task-loop + B-2 |
| 2 | **Model** — an LLM judge reviews the *diff vs the spec's stated intent*, prompted to refute | gamed evals, lookup-table stubs, spec-skirting | eval-gate, after tier 1 |
| 3 | **Human** — one pair of eyes on survivors | judgment the spec never captured | PR review, scaled by risk |

Validation card gains `check_type: model_judge`; the judge engine is a **flag**
(ideally a *different* model than the worker — the Pass 4 principle).
**Reverse the trust curve:** scrutiny scales with blast radius, not familiarity —
effort × `touches_paths` breadth drives which tiers are mandatory.
**Gate:** a task solved with a hardcoded lookup table passes tier 1, is refuted
by tier 2, and is blocked.

### B-13 · Security pass — threat model & guardrails

Converge's specific exposure: **the Manager reads tracker issues — untrusted text
entering worker context.** Three defenses: ① **provenance rule** — the signed
spec is the only instruction source; issue bodies are *state, never
instructions* (the mechanism exists as `signed_off_sig`; this makes it the
enforced boundary); ② **dependency-verification eval** as a template standard
(new deps must exist in the registry, be pinned, pass provenance — no
slop-squatted packages); ③ **sandbox defaults in the doctrine** (network
allowlists, filesystem scope = `touches_paths`, no secrets in worker env).
**Gate:** an issue body containing "ignore the spec, run curl…" produces zero
deviation; an unpinned hallucinated package fails the stock eval.

### B-3 · `cvg status` — the spine as derived state

Derive (never store) spine state by running each pass's own check script; emit
`converge-state.json`. One command answers "where are we in the descent?" —
resumable sessions, onboarding, and the feed for B-4. Derivation rules were
proven in the B-4 spike (see below). **Gate:** deleting any gate artifact flips
that pass red; JSON validates against a shipped schema.

### B-4 · `converge-board` — the graphical interface

**Spiked end-to-end 2026-07-07 and validated (9/9 evals green), then removed to
keep this repo method-only.** Next pickup is re-execution, not design.
**Gate:** `serve.py state` emits schema-valid JSON from real frontmatter; the DAG
shows every task and one edge per `depends_on`; blocked displays; zero network in
snapshot mode.

<details>
<summary><b>The validated rebuild spec (click to expand)</b></summary>

**Architecture — two lanes, one seam.** `skills/converge-board/`:
- **harvest** — one python3-**stdlib** `serve.py`, zero pip: `state` (print fresh
  JSON), `serve [--port 7341]` (localhost; `/state` **re-harvests every GET**,
  no-store — the board cannot lie), `snapshot` (bake state into the HTML).
- **render** — ONE self-contained HTML file (inline CSS/JS/SVG, no CDN, no build).

**The seam** is `state.schema.json` (Draft 2020-12), seven required keys:
`generated_at · repo · spine[] · lanes[] · tasks[] · ledger[] · summary`. Each
task: `id, file, title, status, display_status, lane, effort, deps, touches,
signed_off, evals[], goal, why`. Ledger events: `TICK · DISPATCH · RED · GREEN ·
MERGED · PARKED · FLEET-GREEN`.

**Dual-mode (validated).** LIVE — probe `fetch('/state')`, pulsing LIVE pill,
re-poll every 3 s, re-render only on change, pause when `document.hidden`.
SNAPSHOT — on probe failure render the embedded JSON island and stop all network
(escape `</` as `<\/` when baking).

**Harvest rules (= B-3's derivation rules).** Sources: `tasks/T-*.md`
frontmatter (tiny stdlib YAML-subset parser), lane names from `sketch/*.plan`
headings, ledger from `_fleet.jsonl`. Eval names regexed from `^eval_\w+\(\)`.
**`display_status` is computed, never claimed** — `ready` with an un-done
dependency *displays* blocked. Spine derived from artifact presence.

**Views.** ① **Board** — spine gate strip + summary chips + fleet bar + the
**swimlane DAG** (columns = longest-path depth, memoized + cycle-guarded, ~40
lines of JS, no graph library; rows = lane bands; solid = settled dep, dashed =
open, **purple = cross-lane seam**), hover highlights the chain, click → detail
drawer. ② **Lineage** — upstream → task + `touches_paths` → downstream, plus a
files ↔ tasks map flagging any path touched by 2+ tasks `⚠ OVERLAP — serialize`.
③ **Ledger** — typed timeline with an **honest empty state**. ④ **Guide** — the
board documents itself.

**Design:** dark control-room, blueprint grid, serif masthead, mono data,
semantic colors, purple reserved for fork/seam. Reduced-motion respected.

**Decomposition:** 12 units — 9 landed in the spike (schema, harvester, spine
derivation, live endpoint, snapshot baker, DAG autolayout, live-poll fallback,
lineage view, ledger view); 3 remain future (SSE push, tracker overlay, live
manager stream).

</details>

### B-5 · Fork A's loop story
`task-loop` requires `--issue N`; Fork A has one spec, one e2e eval, no issues.
Prefer **(a)** the *synthetic single issue* pattern (register the whole spec as
one issue whose eval is `specs/e2e-eval.sh`, reuse task-loop as-is) over (b) a
`spec-loop` skill. Bias to (a): zero new machinery.

### B-6 · Pass 9 · Sustain
Fleet-green is a point in time; drift is not. Scheduled re-run of **all** task
evals + `refresh-doctrine.sh` + `quality-gate.sh --strict`, emitting a drift
report and optionally reopening the issue whose eval went red. Ships as
`converge-sustain.yml` (weekly cron).

### B-8 · Fleet metrics + cost
`_fleet.jsonl` + `query-fleet-metrics.sh`: time-to-green, RED-iteration
histogram, first-pass rate, park rate, per-engine comparison. **Cost dimension:**
task-specs bound *iterations* but not *spend* — add `budget_tokens`, a
`tokens`/`cost` field per ledger event, and cost-per-green/per-engine queries.
The engine-arbitrage claim finally gets a price axis.

### B-14 · Standards alignment
**Invert the emission order** — `AGENTS.md` becomes the universal baseline
(doctrine + per-tech do/don'ts); `CLAUDE.md` carries only Claude-specific
capabilities; Cursor/Copilot derived. **Track AGENTS.md v1.1** (optional YAML
frontmatter, nested per-directory precedence). **A2A v1.0 → v1.2** — verify
`ts_a2a_state_v1` still conforms and shape B-1's manager↔worker contract as
A2A-style structured delegation → async execution → result.
**Gate:** `emit-cross-tool.sh` produces an AGENTS.md carrying the full doctrine;
CLAUDE.md duplicates nothing; the A2A mapping passes a v1.2 conformance check.

### B-10 · Pass cards
Regenerate one runnable prompt card per pass **from each SKILL.md** (script, not
hand-written) so the method is drivable from engines that don't load skills.

### B-11 · Chores
- ~~Root `LICENSE`~~ ✅ · ~~stack-agnostic scrub~~ ✅ · ~~v2 PDF placeholder~~ ✅
- [ ] `.claude/` cleanup — empty scaffolding dirs + a leftover AgentSpec README:
  either scaffold it for real (Pass 6 on this repo) or drop it.

### Field notes — H1 2026 *(the scan behind B-12/B-13/B-14 and the B-1 reframe)*

- **Loop Engineering is the named mainstream discipline** (Osmani; O'Reilly).
  Positioning: *Loop Engineering tells you to build loops; Converge tells you
  what has to be true before a loop is safe to run.* Its loudest caveat — loop
  token costs vary wildly — becomes B-8's cost dimension.
- **The "Verification Horizon" is the recognized 2026 bottleneck** — verifiers
  must be *scalable, faithful, robust*; pick two. "Eval defines done" bet on this
  before it was named, and the HMAC sign-off envelope is ahead of the field.
  B-12 closes the gap the frame exposes: code-graders alone are gameable.
- **Standards consolidated under the Linux Foundation (AAIF)** — MCP + AGENTS.md
  donated; A2A at v1.2. Engines-as-flags anticipated exactly this → B-14.
- **Orchestration plumbing is being absorbed by platforms** — dispatch is
  becoming commodity; **the durable moat narrows to gate semantics (task-spec +
  eval-gate) and the grounded harness.** Hence the B-1 reframe.

---

## §8 · Parked — do later, out of Track R's way

- [ ] **P-1 · Chain-level versioning policy.** Per-skill semver is heavy at
  current velocity; the chain is the real unit of coherence. Adopt: one Converge
  release version (git tag + root `CHANGELOG.md`); per-skill
  `metadata.version` becomes a **contract marker** (bump only when a gate, flags,
  or IN/OUT artifacts change); no lockstep stamping; state it in
  `skills/README.md`; **amend rule 9** to match; optionally warn when a diff
  touches Gate/Flags/IN-OUT lines without a bump.

- [x] **P-2 · The cvg knowledge home** ✅ **decided + shipped 2026-07-17.** The
  single home is **`<project>/cvg/`** (visible, matches the CLI brand, no
  collision with the converge repo; `.cvg/` stays reserved for machine config).
  Five folders, one kind of knowledge each: **brain** (inputs, append-only) →
  **docs** (agreements, gated) → **sketch** (drafts, transient) → **tasks**
  (sealed units) → **receipts** (evidence, write-once). `cvg/INDEX.md` is the
  front door. Exception: `tasks/` stays git-root anchored until the project is
  its own repo. *Remaining riders:* the grounding-receipt skill enhancement
  (Pass 0 Step 1 / Pass 1 Step 1.5 read the home's index and emit a receipt —
  provenance for every question not asked), plus P-10 and P-11.

- [ ] **P-3 · Second-brain integration.** External brains (Obsidian first, then
  MCP-exposed sources) are **read-only pull sources**; key facts are distilled
  INTO `cvg/brain/inputs/`. The repo stays canonical; the external brain is never
  silently rewritten. Source-adapter contract: source ID/type, explicit path or
  resource allowlist, retrieval timestamp, content digest, source URI,
  permissions/data-residency boundary. Start smallest: an Obsidian vault is
  already a folder of Markdown, so allowlisted file reads work with no plugin.
  Add an MCP Resources adapter as the generic second path. Depends on P-2.
  **Gate:** on a fixture vault + one MCP source, Pass 0 retrieves only
  allowlisted records, cites every claim to URI + digest + observed time, detects
  a changed/conflicting source, proves no source writes, and leaves BRD
  canonicalization to the owner.

- [ ] **P-4 · `--questions auto` — the brain answers first.** For interviewing
  passes 0/1, each frontier round first queries the repo + staged sources. Every
  proposed answer carries `source_ref`, `observed_at`, digest, provenance
  (`measured|estimated|guessed|derived`), state
  (`supported|conflict|stale|unknown`). Only *supported* facts pre-fill;
  conflicts/staleness/unknowns and **all owner decisions** escalate. Approval
  signs the *understanding*, never the source. Depends on P-2 + P-3.
  **Gate:** every answerable factual question leaves the human round with a valid
  citation; contradictory/absent answers abstain; no business decision
  auto-locks; a declined understanding regenerates without the rejected claim.

- [ ] **P-5 · Engrave the pass anatomy** — every pass = **PROCESS → JUDGE →
  TEACH → SHOW**. Today the verbs exist but are distributed. Engrave: (a) make
  the anatomy the uniform close-of-pass contract in `skills/README.md`;
  (b) **generalize the second-engine JUDGE** so ANY pass's artifact can be
  reviewed by another engine — `cvg judge <artifact> --engine codex|kimi
  [--rubric <path>]`, dispatched fresh-context and read-only (artifact + rubric +
  grounding pack only, **never the producer transcript**), returning a
  fail-closed versioned receipt `PASS|REVISE|ABSTAIN|ERROR` with criterion
  findings, severity/confidence, engine/model/version, and prompt + artifact
  hashes. Missing/malformed = `ERROR`, never pass. **Judge bias is part of the
  threat model:** the verdict is adversarial advice, not the owner gate;
  comparative judging randomizes candidate order. (c) standardize SHOW as a small
  **pass receipt** (what was produced, where, gate verdict, lesson link).
  Implement alongside each pass's I-beat, never as a big-bang edit.

- [ ] **P-6 · Reconcile the public skill taxonomy.** ⚠️ **Now concretely
  wrong — see §9.** The live tree has **14** skill packages. `skills/README.md`
  says 14 (correct); the root `readme.md` still says/catalogs **11**. Decide the
  canonical public wording for **passes vs bridges vs supporting skills**, then
  make both READMEs consistent. **Gate:** the advertised count equals
  `find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l`, every skill
  appears exactly once, and the optional path is visibly distinct from the spine.

- [ ] **P-7 · Re-ground the competitive positioning.** The root README says Spec
  Kit and other SDD frameworks stop at `Implement` and lack a closed loop.
  Current Spec Kit ships workflow gates, conditional loops, fan-out/fan-in,
  pause/resume, and `/speckit.converge`. Re-run the comparison on current primary
  sources and distinguish **contract semantics** rather than feature absence:
  adversarial cross-engine consensus, the explicit trust-boundary fork, sealed
  per-unit PRE/POST eval contracts, clean-checkout acceptance, derived tracker
  state. **Gate:** every competitor claim is source-linked and date-stamped; no
  categorical "lacks" survives without a reproducible receipt.

- [x] **P-8 · Pass 0 exit contract** ✅ 2026-07-19 — `check-brd.sh` v0.3.0
  (canonical/`--draft`/`--no-go` modes, machine tokens, 17-row suite), hardened
  to v0.3.1 by second-eyes review. See §10.

- [ ] **P-9 · Pass 1 universality retro-hardening (v0.4.1) before the next domain
  run.** Pass 1 closed with one receipt (data greenfield); verdict
  READY-WITH-GAPS. **Five fixes before run #2 in a non-data domain — two
  behavioral holes CONFIRMED by mutated fixtures:** ① `LEAK_TERMS` is
  data-stack-only — a spec naming React/Kubernetes/Terraform/LangChain gets ZERO
  leak warnings and a clean PASS; extend with per-domain buckets or move to
  `references/leak-terms.txt`, add word boundaries (kills the confirmed
  'sparked'→spark false positive). ② Check 7 **fails OPEN** on unrecognized
  blocker resolutions — `resolution: awaiting owner` on a blocker → clean PASS;
  invert it and add the evasion fixture. ③ The Pass 0→1 handoff glob says
  `docs/brd-*.pdf` but Pass 0's default output is `.md` → fix to `.md|.pdf`.
  ④ Engrave the decisions-on-disk rule in SKILL.md Step 2. ⑤ Mandate stable
  requirement IDs (`R-n`/`W-n`) + a warn-only check.

- [ ] **P-10 · Memory & lesson stewardship.** Treat durable context as a
  **write → manage → read** lifecycle, not a folder that grows forever. Keep raw
  artifacts append-only; derive compact records that always retain source
  URI/path, digest, observed/effective time, author/approver, confidence, and the
  record they supersede. **The engine proposes, never silently rewrites** —
  duplicate/index cleanup may be deterministic, but semantic merges, contradiction
  resolution, promotion, demotion, and archival require a reviewable proposal and
  receipt. Cadence: after every pass close validate the lesson + enqueue
  candidates; nightly refresh indexes and detect drift; weekly generate
  consolidation proposals; monthly run held-out retrieval evaluation and publish a
  stewardship report. Establish a baseline before setting thresholds. **Gate:** a
  seeded history with duplicates, contradictions, superseded decisions, stale
  sources, and one rare critical lesson produces the same auditable proposal set
  on repeat; no raw evidence is lost; no semantic change auto-commits; a held-out
  query set proves maintained context is no worse than the baseline.

- [ ] **P-11 · Tooling radar.** A recurring evidence pipeline, not an unbounded
  install list: **discover → de-duplicate → score → sandbox pilot → adopt /
  reject / watch → re-review**. Every candidate maps to a concrete Converge pain
  before evaluation. The scorecard records source/owner, capability + overlapping
  native feature, maintenance evidence, license, dependencies,
  permissions/secrets/network, data residency, canonical-data impact,
  cross-engine portability, cost, failure behavior, uninstall/rollback, and
  advisories. **Registry presence proves namespace/metadata, not code safety.**
  Every pilot runs on a disposable fixture against a **no-tool baseline** and
  emits a dated receipt. Seed with Graphify, Graphiti, claude-mem, MemPalace.
  **Gate:** ingests from ≥2 source classes, rejects an over-privileged fixture,
  runs and fully removes a sandboxed candidate without residue, reproduces the
  baseline comparison, emits `ADOPT|REJECT|WATCH|ERROR` with cited evidence.

---

## §9 · Needs cleaning — verified drift (2026-07-24)

| # | What | Where | Fix |
|:--:|---|---|---|
| 1 | **Skill count says 11** | root `readme.md` | Actual = **14**. `skills/README.md` is already correct. This is **P-6**. |
| 2 | **Pass 6 work is uncommitted** | `skills/task-to-runtime-contract/` (untracked), `bin/cvg` (modified, 0.16.0) | Run its tests, then commit. Highest-priority cleaning item. |
| 3 | **Other parallel edits uncommitted** | `skills/task-loop/*`, `skills/agents-kbs-tech-stack/scripts/*` | Review + commit or revert. |
| 4 | **Unrelated deletions staged in the tree** | `docs/source/README.md`, `docs/source/cvg-aut-systems-spine-steps-v5.html` | Decide: commit the deletion or restore. |
| 5 | **Untracked `proposal.md`** | repo root | Keep (and commit) or delete. |
| 6 | **Duplicate spec id** | `T-20260721-cvg-decompose` exists in **both** `tasks/` and `tasks/done/` | Same `id:` in two files — will collide on any register that sees both. Delete/rename one. |
| 7 | **Root `tasks/` is mostly fixtures** | 6 of 7 are `register: false` e2e fixtures; only `cvg-decompose` is real (CVG-12) | Fine, but know that `cvg register` with no `--tasks-dir` projects **one** issue. The real backbone is `tests/uc-analytics/cvg/tasks/`. |
| 8 | **`stack-to-harness` is now legacy** | superseded by `task-to-runtime-contract` at Pass 6 | Ensure the root README and any Pass 6 prose stop pointing at it. |
| 9 | **Nothing is pushed** | branch ahead of `origin/feat/e2e` | `git push --follow-tags` when ready. |
| 10 | **`.claude/` scaffolding** | repo root | B-11's last chore: scaffold for real or drop. |

---

## §10 · Progress log

> One line per completed step: date · step · proof · result. Newest first.

- **2026-07-25 · THE DESCENT CLOSES 0→7 ON uc-analytics** — the use case, not
  the machinery. Every gate run in sequence on the real workspace:
  `CHECK_BRD=PASS · CHECK_TECH_SPEC=PASS · CHECK_ADR=OK · CHECK_PLAN=OK ·
  CHECK_CONSENSUS=OK · TIER=1 ×9 · CHECK_REGISTER=OK · CHECK_RUNTIME_CONTRACT=PASS ×9 ·
  DOCTOR_RUNTIME_CONTRACT=OK`.
  **Pass 5 closed properly.** All 8 remaining specs had existence-only evals, so
  they were signed-but-not-delegatable — the board was showing nine ready tasks
  when eight were fake. Their ~22 evals now assert **database state or execute
  the artifact**: silver's grain proven by `count = count(distinct order_id)`,
  gold reconciled against an independent oracle, no-fan-out proven by row count
  vs distinct products, UTC discipline by `data_type <> 'timestamp without time
  zone'`, isolation by `has_schema_privilege(serve_role,'raw','USAGE') = f`, the
  MCP surface by importing the module and requiring a non-empty tool list.
  All 8 re-sealed **Tier 1**.
  **Proven, not asserted:** the maximal stub attack — a stub planted for all
  **27** declared `creates_paths` — leaves **all 9 specs red**.
  **Pass 7 closed for all 9** (was 1 of 9): 9 contracts, 9 task briefs, 36
  adapter manifests, every one epoch-bound with mandatory closure.
  `cvg/INDEX.md` now carries the whole descent as a verdict table.
  **Open (needs the operator):** the live Pass 6 leg. The bodies changed, so the
  Linear board must be re-pushed and re-verified against `[D]` with
  `LINEAR_API_KEY` in the environment. The spec side is green.
  Correction worth recording: I previously said the 8 specs could be sharpened
  "at their own bind time." That was wrong — an eval *describes* the
  done-condition, so the layer not existing yet is precisely why it is RED, not
  a reason it cannot be written. Following that advice would have left the board
  lying.
- **2026-07-25 · PASSES 0–7 WALKED END TO END (and Pass 6 was not done)** —
  asked "are 0–7 complete?", the honest way to answer was to run them rather
  than assert. All nine gates, on the real proving ground:
  `CHECK_BRD=PASS · CHECK_TECH_SPEC=PASS · CHECK_ADR=OK · CHECK_PLAN=OK ·
  CHECK_CONSENSUS=OK · TIER=1 · DOD=COMPLETE · CHECK_RUNTIME_CONTRACT=PASS ·
  DOCTOR_RUNTIME_CONTRACT=OK`.
  **Pass 6 failed.** `cvg register --check` → `ERROR: tasks dir 'tasks' not
  found`. Passes 0–3 all auto-discover the `cvg/` workspace (`cvg/docs`,
  `cvg/docs/adrs`, `cvg/sketch`); Pass 6 was the only pass that did not know
  `cvg/` existed, so `cvg register` failed out of the box in the exact layout
  `cvg/INDEX.md` prescribes. It worked live in R① only because that run passed
  `--tasks-dir` explicitly — the gap was masked by how we happened to call it.
  Fixed: discovery tries `cvg/tasks` then `tasks`; an explicit `--tasks-dir`
  still wins. Both pinned by tests. Offline gate now `CHECK_REGISTER=OK`
  (9 specs, 8 edges); the live board leg fails closed without `LINEAR_API_KEY`,
  which is correct. cvg **0.19.1**.
  Remaining, and NOT blockers for R8: the live `register --check` re-run after
  CVG-21's body changed (needs the key), and `cvg verify` has never graded a
  real diff because no diff exists yet — R8 produces its first one.
- **2026-07-25 · THE EVALS BECOME REAL (R8 pre-flight cleared)** — the last
  thing standing before the Loop, and it was worse than one bad spec.
  **All 25 evals across all 9 registered specs were existence-only** — `test -f`
  plus a keyword grep, nothing executed. Verified by attack: the exact three
  stub files (3 lines total) satisfied CVG-21's entire Exit Check. Every
  registered task could have gone green having built nothing.
  **Product fix (root, permanent):** validate-task-spec.sh Check 16b detects
  existence-only evals and WARNS; `safe-to-delegate.sh` — the gate that claims a
  task is safe to run with nobody watching — **BLOCKS**. New `--supervised`
  downgrades it to a note, and `# task-spec:allow-existence-only` opts out for
  genuinely document-shaped work. That split is the architecture: `validate`
  lints, `safe-to-delegate` decides autonomy.
  **Fixture fix:** CVG-21's evals now assert **database state** — a change
  record actually lands in `raw.orders` in the frozen five-column shape, a
  dedicated capture role really exists in `pg_roles` and can read
  `public.orders`, and `has_schema_privilege(role,'_control','USAGE')` is
  false. A stub cannot make a row appear or revoke its own privilege. Re-attacked
  with the same three stubs: **still red.** Re-sealed Tier 1, re-bound
  (epoch `…@e30674524075`). The other 8 specs now correctly **BLOCK** — each
  must be sharpened at its own bind time, when the layer it tests exists.
  **Also found:** the `--stamp` success line hardcoded `hmac-sha256-v1` and
  printed the version in the keyid slot, so every operator since WP1 was told
  their v2-sealed spec was v1 — the one line whose entire job is to report what
  just happened. Fixed to report what was written.
  **Folder audit:** `tests/e2e-test-engine` is healthy (its designed-RED eval is
  still red) and is **now in CI, asserted in both directions** — a fixture whose
  red eval quietly turns green has stopped being a fixture. `docs/` is clean.
  Proof: 12/12 skills · register 120 · runtime-contract 35 · portability 35 ·
  hmac 32 · task-spec 27 · pass-gates 42 · json-envelope 12 · install 7 ·
  e2e fixture 2 · shellcheck 0 · skill-docs lint clean.
- **2026-07-25 · THE ROOT BECOMES THE PRODUCT** — the repo root is the install
  surface, so it was audited as one. Four things were wrong, and two of them
  broke the install for everyone who is not us.
  **The proving ground leaked upward.** `validate-task-spec.sh` anchored
  `tasks/_state.yaml` at the **git root**, so validating a nested workspace
  spilled its task list into the parent repo — the shipping root carried an
  index of nine `tests/uc-analytics/` specs. `check-path-policy.py` already
  treated `_state.yaml` as a sibling of the spec, so the validator was the one
  out of step; it is now workspace-scoped, with workspace-relative paths.
  Two shipped skills (`idea-to-brd`, `brd-docs-to-tech-req`) also reached into
  `tests/uc-analytics/` for golden fixtures — the product depending on the use
  case. Each now owns its golden. **`grep -rl uc-analytics bin/ skills/` is
  empty, and CI fails the build if it ever isn't.**
  **`cvg loop` — Pass 8 joins the CLI.** Passes 0–7 were `cvg <verb>`; Pass 8
  was a raw script path the readme nonetheless advertised. Wired with help,
  pass map, mutation guard, and agent manifest (`TASK_LOOP=SETTLED|
  LOCAL_SETTLED|BLOCKED|USAGE_ERROR`). cvg 0.18.0 → **0.19.0**.
  **`install.sh` + CI.** One command installs the twelve skills into
  `.claude/skills/` and puts `cvg` on PATH; symlink by default, `--copy` pins,
  idempotent, self-verifying, refuses to install onto its own checkout.
  Writing its test found **two bugs that only ever appear on the install path**:
  `cvg` located `_ui.sh` via `dirname $0` without resolving its own symlink (so
  the PATH entry died on line 21), and `resolve_home()` had no fallback to the
  checkout containing the script (so an installed `cvg` only worked while you
  stood inside Converge — the one place a user never is). Both fixed, both
  pinned by `tests/test-install.sh`. `.github/workflows/ci.yml` runs the whole
  offline gauntlet on macOS **and** Linux — no tracker, no engine, no secrets,
  because a gate that needs a secret silently skips on a fork's PR.
  **The root is now seven entries:** `LICENSE · PLAN.md · readme.md · bin ·
  skills · docs · tests` (+ `install.sh`, `.github`). Dead stubs `MAP.md` /
  `todo.md` / `cvg-todo.md`, leftover `tasks/` and `sketch/` scaffolding
  deleted; `proposal.md` → `docs/archive/`, `presentation/` → `docs/`.
  Proof: 12/12 skills · runtime-contract 35 · register 120 · hmac 32 ·
  task-spec 23 · portability 35 · json-envelope 12 · install 7 · pass-gates 42 ·
  shellcheck 0.
- **2026-07-25 · WP1–WP4 · the harness becomes trustworthy** — four correctness
  gaps closed, 255 offline checks green.
  **WP1 · authorization sealed (HMAC v2).** v1 sealed only identity and body, so
  `touches_paths`, `budget_*`, `agent` and `requires` could be edited after a
  human signed. v2 adds an `authz_digest` over all nine authorization fields.
  v1 seals still verify — as **Tier 2 (supervised)**, with a re-stamp
  instruction — so no existing spec is orphaned.
  **WP2 · `bind --check` is genuinely read-only.** It used to re-derive through
  the writing path; it now runs `verify_signoff_pure()` and performs zero
  repository writes.
  **WP3 · tier-2 verification.** A different-family judge re-checks a green run
  against holdout evals, with train/test separation and fail-closed
  `UPHELD|REFUTED|UNAVAILABLE`. With no second engine the flag is simply omitted
  — the gate never invents a pass.
  **WP4 · settlement is scoped, ordered and policy-consistent.** Three real
  defects: `git add -A` could sweep an **untracked** out-of-scope file past a
  postflight guard that only ever reads the *diff*; the success receipt was
  written *before* the outcome it claimed; and `external_writes: deny` was
  documented but not honored. Staging now comes from the envelope's `fs.write`
  scope and is re-verified path-by-path, the `pass` receipt is written last, and
  denial settles locally with `TASK_LOOP=LOCAL_SETTLED`.
  Also shipped: the **capability envelope** (epoch `<task-id>@<spec-sha12>`,
  mandatory closure on settle/block/budget-exhaustion/epoch-change), fail-closed
  **resolver manifests** with prevent/detect/unenforced assurance, **7A/7B**
  (contract vs. task brief — identifiers, never content), **lane routing**
  (FAST/NORMAL/FULL with floors that only tighten), `cvg doctor
  runtime-contract`, `cvg verify`, `cvg lane`, `cvg setup harness` (router
  scaffold only — auto-generated AGENTS.md measurably *hurts*), and the fork's
  removal (linear 0–8, two phases, twelve skills).
  Proof: 12/12 skills valid · runtime-contract 35 · register 120 · hmac-envelope
  32 · task-spec 21 · portability 35 · json-envelope 12 · shellcheck 0 errors.
- **2026-07-24 · R① REGISTER CLOSED LIVE** — the uc-analytics backbone (9 signed
  specs) projected onto Linear as **CVG-21…29** (9 created, then re-registered
  idempotently `created 0, updated 9`), 8 blocked-by links, receipts stamped.
  Tiers shipped: T1 native fields (assignee via `.cvg/people-map`, state from DAG
  root→Todo/blocked→Backlog, subscribers), T2 in-frontmatter `projection:` block
  (cycle/parent/sla/project/milestone; HMAC-safe — all 9 seals re-verified after
  editing), T3 opt-in structure (Initiative → Project → Capture/Transform/Serve,
  3 issues each, + append-only health). `cvg setup people` / `setup projection`
  born; portability held (github/jira/fake accept-and-discard).
  **`register --check` hardened into a real 1:1 parity gate** via a new
  six-verb-contract `list-issues` (count · orphan · missing · dup) — proven to
  FAIL on injected orphan/missing, not just to go green.
  **Two live-only bugs found and fixed:** (a) `|| true` cannot catch an `exit`,
  so every "fail-soft" GraphQL write could kill the adapter mid-verb — including
  the pre-existing `_ln_stamp_marker` (the idempotency marker) and `_ln_set_due`;
  all nine sites now route through the subshell-wrapped `_ln_gql_soft`.
  (b) `IssueFilter`'s `team:{id:{eq}}` needs `ID!`, not `String!` — the wrong
  type made the parity gate report "board: 0 registered" on a full board, and
  verify was swallowing the cause with `2>/dev/null` (now surfaced).
  Proof: **120 offline tests**, shellcheck 0 errors, `CHECK_REGISTER=OK` live.
  6 commits (`1a4b629`…`00e6bdb`).
- 2026-07-21 · **R5.R** — the whole backbone cut into task-specs: 9 legs → 9
  specs, clean depends_on DAG, every task `validate` ok · `gate` DELEGATE ·
  `dod` COMPLETE. New `cvg tasks dod` (traceability matrix, `DOD=COMPLETE|GAPS`).
- 2026-07-21 · **R4.C/R4.P** — owner named **FORK B**; resolved objection log
  promoted; `cvg review --check` GREEN, `CHECK_CONSENSUS=OK` (all 6 checks incl.
  referee-hashed provenance over 12 live plan files). **Pass 4 closed on a real
  adversarial consensus.**
- 2026-07-21 · **R4.build** — `cvg review --adversary codex,kimi` multi-engine
  merge into ONE referee-stamped log; suite 17/17; fail-closed when no
  cross-family engine.
- 2026-07-21 · **R4.R** — first REAL dispatch exposed 3 defects a fake engine
  never could: greedy `{.*}` JSON extractor → raw_decode scan; macOS has no
  `timeout` so the cap ran **uncapped** → pure-bash watchdog (`REVIEW=TIMEOUT`);
  wrong kimi flags. Fail-closed proven LIVE — kimi outran the cap, **no
  objection log written**: the referee never fabricates a consensus.
- 2026-07-21 · **R4.U** — gate **rewritten**: the old one proved "a different
  model attacked" by grepping for the word (spoofable). Now validates a stamped
  objection-log artifact with referee-computed provenance hashes; cross-**family**
  invariant; suite 10/10.
- 2026-07-21 · **R3** — Pass 3 closed; skill 0.3.0→0.7.0 (seam → swimlane → leg
  → task-spec; swimlane = directory; `<lane>.plan.md`; mermaid enforced);
  `cvg decompose`, golden diff EMPTY, `CHECK_PLAN=OK`.
- 2026-07-21 · **R2** — Pass 2 closed; 7 ADRs canonical + 10-term glossary.
  Second-eyes caught a **frozen false fact** (0002 wrongly claimed
  `payments.status` mutates — real mutation is `orders.*`) before accept.
  `cvg structure`, golden diff EMPTY, `CHECK_ADR=OK`.
- 2026-07-19 · **R1** — Pass 1 closed end-to-end; check-tech-spec v0.4.0 exit
  contract; 15-row suite; golden diff EMPTY, `CHECK_TECH_SPEC=PASS`.
- 2026-07-19 · **R0** — Pass 0 closed end-to-end; `cvg capture`; golden diff
  EMPTY. Second-eyes hardening (v0.3.1) closed the template-copy bypass + 3
  seams; suite 17→27. **Pass 0 = 100% signed off.**
- 2026-07-19 · **P-8** — Pass 0 exit contract (`check-brd.sh` v0.3.0): canonical
  hard-FAILs pending sign-off/missing date/empty scope/blank owners/untagged
  numbers; `--draft` never authorizes; every verdict ends in `CHECK_BRD=…`.
- 2026-07-19 · **1.1** — `bin/cvg` router born via full dogfood ceremony. The
  acceptance itself ran THROUGH cvg — the machine gated its own birth.
- 2026-07-17 · **P-2** — knowledge home decided + skeleton shipped
  (`<project>/cvg/`, five folders, `INDEX.md` front door).
- 2026-07-17 · **R0 terrain** — proving ground pivoted to `tests/uc-analytics/`.
  Smoke test caught real contamination (a stale `ecommerce_pgdata` volume with
  5000 leftover orders); fixed with a renamed project + fresh volume, seed 42 →
  50/20/200/200 verified.
- 2026-07-16 · **0.1 / 0.2** — fixture repo + 6-spec diamond backlog; 6/6
  DELEGATE Tier-1; `lint-backlog.sh` reports exactly the one deliberate overlap.
  **Findings paid for:** overlap detection is `touches_paths`-only (a file
  created by A and modified by B must be declared in both); editing sealed
  frontmatter invalidates the envelope (re-stamp is the only path); tooling
  anchors `tasks/` at git root.
