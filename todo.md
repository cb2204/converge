# Converge — Backlog

> The gaps between what the spine *promises* and what the repo *ships today*,
> surfaced by the v2 blueprint review. Each item is written to be cut into
> Task-Specs (Pass 5B) when picked up — the method eats its own dog food.
> Organized strictly by priority: **P0** makes Pass 8's gate real, **P1**
> hardens the trust layer and makes the machine visible, **P2** compounds the
> loop, **P3** is hygiene. **B-12 · B-13 · B-14 added 2026-07-08** from the
> H1-2026 field scan — see [Field notes](#field-notes--h1-2026) for sources.

---

## Priority board

| # | Item | Priority | Impact | Effort | Depends on | Status |
|---|------|:--:|:--:|:--:|------|--------|
| **B-1** | The Manager — `fleet-loop` (Pass 7 slot) | **P0** | 🔥 unlocks Pass 8's gate | L | — | open |
| **B-2** | CI eval-gate — server-side re-verification | **P0** | 🔥 makes "closed by evals" true | M | — | open |
| **B-3** | `converge-status` — spine as derived JSON | **P1** | feeds board + resumability | S | — | open — design proven in the B-4 spike |
| **B-4** | `converge-board` — the graphical interface | **P1** | see the machine run | M | B-3 (soft) | open — **spiked & validated 2026-07-07**, rebuild spec below |
| **B-12** | Graded verifier stack — the Goodhart defense | **P1** | 🔥 hardens the eval moat | M | B-2 (soft) | open — added 2026-07-08 |
| **B-13** | Security pass — threat model & guardrails | **P1** | 🔥 closes the injection surface | M | — | open — added 2026-07-08 |
| **B-5** | Fork A's loop story (synthetic issue) | **P2** | closes Fork A's execution gap | S | B-1 | open |
| **B-6** | Pass 9 · Sustain — keep the fleet green | **P2** | drift defense | M | B-1, B-2 | open |
| **B-7** | Adversary adapters for Pass 4 | **P2** | repeatable Consensus | S | — | open |
| **B-8** | Fleet metrics — receipts for the moats | **P2** | measured optionality claims | S | B-1 | open |
| **B-9** | Golden fixture — 30-minute end-to-end | **P2** | onboarding + B-1's test bed | M | — | open |
| **B-14** | Standards alignment — AGENTS.md v1.1 first · A2A v1.2 | **P2** | rides the AAIF consolidation | S | — | open — added 2026-07-08 |
| **B-10** | Pass cards — regenerate `prompts/` | **P3** | non-Claude engines | S | — | open |
| **B-11** | Chores — ~~LICENSE~~, ~~stack scrub~~, `.claude/` cleanup | **P3** | hygiene | S | — | partial — LICENSE + scrub done at v0.1 |

**Sequencing**

```
P0   B-1 fleet-loop ──┬──▶ B-2 eval-gate       (together they make Pass 8's gate real)
                      │
P1   B-12 verifier stack · B-13 security       (harden the trust layer — H1-2026)
P1   B-3 status ──────┴──▶ B-4 board           (see the machine run — spiked, spec captured)
P2   B-5 fork-A · B-6 sustain · B-7 adversary · B-8 metrics+cost · B-9 fixture · B-14 standards
P3   B-10 pass cards · B-11 chores
```

**First move on P0:** run Pass 5B **on this backlog** — cut B-1 and B-2 into
task-specs (the gates below are written to be their Exit Checks), register
them, and let the method build its own Manager.

---

## Field notes — H1 2026

*The scan behind B-12/B-13/B-14 and the B-1 reframe (2026-07-08). Three
validations to say louder, one commoditization to respect.*

- **Loop Engineering is now the named mainstream discipline** —
  [Osmani, Jun 7](https://addyosmani.com/blog/loop-engineering/) /
  [O'Reilly, Jun 22](https://www.oreilly.com/radar/loop-engineering/);
  Steinberger: *"you should be designing loops that prompt your agents"*;
  Cherny: *"my job is to write loops."* The field has the slogan; Converge has
  the descent that produces a loop-runnable backlog. **Positioning line:**
  *Loop Engineering tells you to build loops; Converge tells you what has to
  be true before a loop is safe to run.* Osmani's loudest caveat — loop token
  costs vary wildly — becomes B-8's cost dimension.
- **The "Verification Horizon" is the recognized 2026 bottleneck** — verifiers
  must be *scalable, faithful, robust*; pick two
  ([arXiv 2606.26300](https://arxiv.org/html/2606.26300v1);
  [DevOps.com](https://devops.com/the-bottleneck-isnt-coding-anymore-its-verification/);
  ["the Audit Tax"](https://dev.to/temrel/the-audit-tax-why-your-agent-made-you-slower-45bj)).
  "Eval defines done" bet on this before it was named — and the HMAC sign-off
  envelope (hand-stamps rejected) is ahead of the field. B-12 closes the gap
  the frame exposes: code-graders alone are gameable.
- **Standards consolidated under the Linux Foundation (AAIF, Dec 2025)** —
  MCP + AGENTS.md (+ goose) donated; A2A at v1.2; AGENTS.md in 60k+ repos with
  a [v1.1 proposal](https://codex.danielvaughan.com/2026/06/05/agentic-ai-foundation-agents-md-mcp-linux-foundation-codex-cli-developers/)
  (frontmatter, nested precedence). Converge's engines-as-flags and cross-tool
  emission anticipated exactly this. B-14 keeps the harness on the standard's
  leading edge.
- **The orchestration plumbing is being absorbed by platforms** —
  [GitHub Agent HQ mission control](https://github.blog/news-insights/company-news/welcome-home-agents/)
  and [Agentic Workflows in technical preview](https://github.com/orgs/community/discussions/186451)
  (agent runs as Actions with sandboxing/permissions/review). Dispatch is
  becoming commodity; **the durable moat narrows to gate semantics
  (task-spec + eval-gate) and the grounded harness.** Hence the B-1 reframe:
  bind the Manager to the platform, don't rebuild it.

---

# P0 — make Pass 8's gate real

> **The headline finding: Pass 7 is a hole, and it's the load-bearing one.**
> The v2 spine drawing shows *7 · Execute* and *8 · The Loop — fleet green,
> closed by evals*, but the pass table jumps 6 → 8, and the only execution
> skill (`task-loop`) closes **one issue** and stops — by design. So today:
> **(a) Pass 8's gate is unreachable** — nothing dispatches ready issues,
> watches PRs, settles dependencies, or detects fleet-green; and **(b) the
> local eval is trusted, not verified** — `task-loop` runs the eval locally
> and pastes GREEN into the PR body; nothing re-runs it server-side, so the
> merge gate is agent honesty, not a machine check. The Manager was
> deliberately deferred in v2 — correctly, as *orchestration*. But the
> **guarantee layer** (re-verification + settlement + termination) is not
> orchestration sugar; it's what makes the Dark Factory claim true. That's
> B-1 and B-2.

## B-1 · The Manager — `fleet-loop` (fill the Pass 7 slot)

**One sentence:** a stateless *tick* that derives everything from the board +
git, dispatches `task-loop --issue N` for ready issues, and settles green PRs —
until the fleet is green.

### Why it can be dumb and still guarantee the process

Every guarantee already lives in a gate a skill ships; the Manager is
deterministic plumbing **between** gates:

| Guarantee | Provided by | Already ships? |
|---|---|---|
| Only well-formed, eval-carrying specs enter the board | `safe-to-delegate.sh --stamp` (HMAC seal) | ✅ task-spec |
| Board ≅ backlog, 1:1, no orphans, **no cycles** (DAG ⇒ topological dispatch terminates) | `verify-registration.sh` | ✅ task-specs-to-issues |
| No `touches_paths` overlaps ⇒ safe parallel dispatch | `lint-backlog.sh` | ✅ task-spec |
| Per-issue: eval green **or** explicit blocked report — never silent failure | `task-loop` (bounded by `budget_iterations`) | ✅ task-loop |
| The work is real (blast radius, clean checkout, HMAC integrity) | `accept-task.sh --gold-sanity` | ✅ task-spec |
| **Fleet-level progress + termination** | **the Manager tick** | ❌ **this item** |
| **Server-side eval re-run as the merge gate** | **CI eval-gate** | ❌ **B-2** |

### The tick (pseudo-contract)

```
tick():
  ready    = adapter.read_ready()          # tracker: status ready ∧ no open blocked-by
  inflight = issues with an open task/ branch or PR
  if ready = ∅ ∧ inflight = ∅:
      run check-fleet-green.sh             # every issue closed by a green-eval PR
      → emit fleet report · STOP           # the only exit
  for issue in ready, up to MAX_PARALLEL:
      skip if overlapping touches_paths with any inflight issue   # serialize overlaps
      acquire lock (assign/label on the issue — at-most-one loop per issue)
      dispatch: task-loop --issue N --agent <from spec's agent hint>
                (one git worktree per in-flight issue — isolation)
  settle:
      PR + green eval-gate check  → merge  → "Closes #N" closes the issue
                                  → dependents' blocked-by clears → next tick picks them up
      blocked-task report         → label blocked + park; never auto-retry
  ledger: append tick record to _fleet.jsonl
```

**Design invariants (these are what "guarantees the process"):**

1. **Stateless / idempotent ticks.** The Manager holds no memory; every tick
   recomputes from (board + git). Kill it anytime, restart, same behavior —
   the same principle as "the board never lies," applied to the orchestrator.
2. **Only the loop writes state.** The Manager never edits a spec, closes an
   issue by hand, or flips a status — it dispatches, merges green, and labels
   blocked. All state transitions remain eval-gated.
3. **At-most-one loop per issue** via a lock carried *on the issue itself*
   (assignee or label), so two ticks (or a human + the Manager) can't
   double-dispatch.
4. **Termination is provable:** the dependency graph is a DAG
   (`verify-registration.sh`), every dispatched issue ends in exactly one of
   {merged-green, parked-blocked} within `budget_iterations`, and parked
   issues leave the ready set ⇒ the ready set strictly shrinks ⇒ the tick
   loop terminates at fleet-green or fleet-report-with-parked.

### Two profiles, one contract

- **Profile L — local (works today, no CI):** `fleet-loop` skill +
  `scripts/manager-tick.sh` + `scripts/check-fleet-green.sh`. Runs the tick in
  a `/loop`-style session or a plain `while` with worktrees. This is the
  laptop-scale Dark Factory.
- **Profile C — CI/CD (the v2-blessed target):** three GitHub Actions
  templates shipped under `templates/ci/`:
  - `converge-dispatch.yml` — cron tick + issue-event trigger; queries ready
    issues via the tracker adapter; matrix-dispatches headless workers
    (`claude -p "/task-loop --issue N"`, `codex exec …`) under a concurrency
    group per issue.
  - `converge-eval-gate.yml` — **on PR**: re-runs the task's own eval in a
    clean container as a **required status check** (see B-2). Branch
    protection makes the platform, not the agent, enforce the gate.
  - `converge-settle.yml` — on merge: issue closes, tick re-fires for
    unblocked dependents.

  The platform provides scheduler (cron), settlement (merge), and gate
  (required checks) — exactly the v2 position: *"in a Git-native world the
  platform already provides most of it."*

> **Reframe (2026-07-08): bind the Manager, don't build it.** GitHub shipped
> the substrate the v2 doc predicted — [Agent HQ mission control](https://github.blog/news-insights/company-news/welcome-home-agents/)
> and [Agentic Workflows (technical preview)](https://github.com/orgs/community/discussions/186451):
> agent runs as standard Actions with sandboxing, permissions, and review
> guardrails built in. Profile C should **target that substrate** — Converge
> supplies what the platform doesn't: the definition of done (task-spec), the
> eval-gate as the required check, and the settle/park semantics. Keep the
> hand-rolled three-workflow design above as the fallback for non-GitHub
> trackers and as the reference spec for what any substrate must provide.
> The Manager is also a **budget officer**: enforce per-task `budget_tokens` /
> cost caps alongside `budget_iterations` (see B-8) — park on budget
> exhausted, same discipline.

**Gate:** on a toy backlog of ≥5 issues with a diamond dependency,
`fleet-loop` reaches fleet-green unattended, with one issue force-failed →
parked + reported, and `check-fleet-green.sh` exits 0 only after every issue
is closed by a green-eval PR.

## B-2 · The eval-gate — server-side re-verification

`run-issue-eval.sh` gets a `--ci` mode (JSON verdict per eval, machine exit
code — `run-task-spec.sh --ci` already does this in task-spec; port the
pattern), plus the `converge-eval-gate.yml` template that runs it in a clean
container on every `task/*` PR and reports a required status check.

**Why P0:** without it, "closed by evals" means "closed by a *claim* of
evals." With it, a lying or hallucinating worker physically cannot merge.
Trust nothing the worker says; re-run the eval.

**Gate:** a PR whose local run claimed GREEN but whose eval fails in the
container is blocked from merge with the failing eval's output on the check.

---

# P1 — harden the trust layer *(added 2026-07-08)*

> The Verification Horizon frame: a verifier must be **scalable, faithful,
> robust** — and most approaches get only two. Converge's runnable bash evals
> are scalable + robust but thin on intent-faithfulness, and agents under
> optimization pressure *perform for the test* ("the bigger the task, the more
> likely the gate lies"). B-12 layers faithfulness on top; B-13 defends the
> pipeline itself.

## B-12 · Graded verifier stack — the Goodhart defense

Adopt the three-tier grader stack as an explicit Converge concept and wire it
into the gates:

| Tier | Grader | Catches | Where it runs |
|---|---|---|---|
| 1 | **Code-based** — the task's own bash evals (today's moat) | mechanical wrongness | task-loop locally + B-2 eval-gate in CI |
| 2 | **Model-based** — an LLM judge reviews the *diff against the spec's stated intent* (Behavior zone), prompted to refute | gamed evals, lookup-table stubs, spec-skirting | eval-gate, after tier 1 goes green |
| 3 | **Human** — one pair of eyes on what survives 1–2 | judgment the spec never captured | PR review, scaled by risk |

Mechanics:
- Validation card gains an optional `check_type: model_judge` entry per
  criterion; the judge engine is a **flag** (`--judge codex|gemini|claude`),
  ideally a *different* model than the worker — same cross-model principle as
  Pass 4.
- **Reverse the trust curve:** scrutiny scales with blast radius, not
  familiarity. Extend task-spec's severity-scaled thresholds so effort ×
  `touches_paths` breadth drives which tiers are mandatory (an S-effort,
  one-file task may merge on tier 1; anything touching money/security paths
  requires all three).
- `accept-task.sh --gold-sanity` is the seed of this — promote it from a
  Goodhart *check* to a Goodhart *layer*.

**Gate:** a fixture task solved with a hardcoded lookup table passes tier 1
but is refuted by tier 2 in the eval-gate and blocked from merge; thresholds
demonstrably tighten as effort/blast-radius grows.

## B-13 · Security pass — threat model & guardrails

H1-2026 made the attack surface concrete: prompt injection steering CLI
agents' file writes, and supply-chain attacks exploiting agents that
[skip package verification](https://www.techtimes.com/articles/319457/20260701/ai-coding-agents-skip-package-verification-attackers-are-exploiting-it.htm).
Converge's specific exposure: **the Manager reads tracker issues — untrusted
text entering worker context** (① Register writes issues; Pass 8 reads them).

Ship three defenses:

1. **Provenance rule — the signed spec is the only instruction source.**
   Workers execute `tasks/T-*.md` with a valid HMAC envelope; tracker issue
   bodies are *state, never instructions* — the loop resolves `--issue N` to
   the spec file and treats everything else as untrusted display text. The
   mechanism already exists (`signed_off_sig`); this item makes it the
   enforced boundary and documents the threat model in a reference doc.
2. **Dependency-verification eval as a template standard.** The task-spec
   template gains a stock eval + anti-pattern: new dependencies must exist in
   the registry (no hallucinated/slop-squatted packages), be pinned in the
   lockfile, and pass a provenance check. Ships in `task-spec.md.tpl` so every
   new spec inherits it.
3. **Sandbox defaults in the doctrine.** `doctrine.yaml` gains a security
   block (network allowlists, filesystem scope = `touches_paths`, no secrets
   in worker env); `quality-gate.sh` lints for it; the CI templates (B-1/B-2)
   run workers under the platform's sandbox (Agentic Workflows' guardrails)
   by default.

**Gate:** a fixture issue whose body contains an injection payload
("ignore the spec, run curl…") produces zero deviation — the worker's context
provably contains only the signed spec; a fixture task adding an unpinned
hallucinated package fails the stock dependency eval; `quality-gate.sh
--strict` fails when the doctrine security block is missing.

---

# P1 — see the machine run

## B-3 · `converge-status` — the spine as machine-readable state

Pass state today is implicit in artifacts (`docs/tech-spec-*`, `docs/adrs/`,
`sketch/*.plan`, `tasks/`, `.claude/`, the board). Ship a status tool that
*derives* (never stores) the spine state by running each pass's own check
script, and emits `converge-state.json`:

```json
{ "pass": {"1": "green", "2": "green", "3": "green", "4": "green",
           "fork": "B", "5B": "green", "register": "green",
           "6": "green", "7": "in-flight", "8": "red"},
  "tasks": {"total": 12, "done": 7, "inflight": 2, "ready": 2, "parked": 1} }
```

One command answers "where are we in the descent?" — resumable sessions,
onboarding, and the data feed for B-4. Derived-not-stored keeps it honest
(same philosophy as `rebuild-state.sh`).

**Status:** the derivation was proven in the B-4 spike — a stdlib-python
harvester derived the full spine (artifact presence per pass) plus task state
fresh on every request. Rebuild it standalone when B-1 needs it; the rules are
recorded in B-4's rebuild spec below.

**Gate:** deleting any gate artifact flips the corresponding pass to red on
the next run; the JSON validates against a shipped schema.

## B-4 · `converge-board` — the graphical interface

**Spiked end-to-end 2026-07-07 and validated (9/9 done-task evals green),
then removed to keep this repo method-only.** Everything below was built and
proven once, so the next pickup is re-execution, not design.

**Gate:** `serve.py state` emits schema-valid JSON from real `tasks/`
frontmatter; the DAG shows every task and one edge per `depends_on` pair; a
task whose deps aren't done displays blocked; the file renders with zero
network requests in snapshot mode.

<details>
<summary><b>The full rebuild spec (validated in the spike — click to expand)</b></summary>

### Architecture — two lanes, one seam

Ship as `skills/converge-board/` with two swimlanes:

- **harvest (data plane)** — one python3-**stdlib** script, `serve.py`, three
  commands, zero pip:
  - `state` — print fresh state JSON to stdout
  - `serve [--port 7341]` — localhost server: `/` serves the board HTML,
    `/state` **re-harvests the repo on every GET** (no-store headers; derived,
    never cached — the board cannot lie)
  - `snapshot` — bake fresh state into the HTML's JSON island (see below)
- **render (front end)** — ONE self-contained HTML file (inline CSS/JS/SVG,
  no CDN, no build step); the file is the deliverable.

**The seam** between the lanes is a JSON Schema (`state.schema.json`,
Draft 2020-12) with seven required top-level keys:
`generated_at · repo · spine[] · lanes[] · tasks[] · ledger[] · summary`.
Each task carries: `id, file, title, status, display_status, lane, effort,
deps, touches, signed_off, evals[], goal, why`. Ledger events are typed:
`TICK · DISPATCH · RED · GREEN · MERGED · PARKED · FLEET-GREEN`.

### Dual-mode — the real-time answer (validated)

One HTML, two truths:
- **LIVE** — on load the page probes `fetch('/state')`; on success it shows a
  pulsing LIVE pill and re-polls every 3 s, re-rendering in place only when
  the JSON changes (pause polling when `document.hidden`). Editing a task's
  `status:` in an editor updates the DAG within one poll — no reload.
- **SNAPSHOT** — when the probe fails (file://), it renders the embedded
  `<script id="snapshot" type="application/json">` island and stops all
  network. Shareable, CI-publishable artifact of the fleet at a point in time.
  (Escape `</` as `<\/` when baking to keep the island inert.)

### Harvest rules (also B-3's derivation rules)

- **Sources:** `tasks/T-*.md` frontmatter (tiny stdlib YAML-subset parser:
  scalars, inline + block lists — no pyyaml), lane names from
  `sketch/*.plan` first headings, ledger rows from `_fleet.jsonl` if present.
  Eval names regexed from `^eval_\w+\(\)` in the body; goal from `## Goal`.
- **`display_status` is computed, never claimed:** frontmatter `status` is
  file truth, but `ready` with any un-done dependency *displays* **blocked**
  (dispatchability is a fact about the graph — the manager's rule).
- **Spine** derived from artifact presence: `docs/tech-spec-*` (P1),
  `docs/adrs/*.md` (P2), `sketch/*.plan` (P3), specs + signed-off counts
  (5B), tracker binding (①), `.claude/` harness (P6), fleet done/total
  (7/8: green when all done, amber while mixed, idle when empty).

### Views (all validated in the spike)

1. **Board** — spine gate strip (green/amber/idle + purple fork card) ·
   summary chips + fleet-convergence bar · status filter chips · the
   **swimlane DAG**: columns = longest-path depth over `depends_on` (memoized,
   cycle-guarded — ~40 lines of JS, no graph library), rows = lane bands,
   arrowed bezier edges (solid = settled dep, dashed = open dep, **purple =
   cross-lane seam**), hover highlights the full up/downstream chain and dims
   the rest, click → detail drawer (spec path, why, status pill with
   file-vs-displayed mismatch note, deps as click-to-navigate links, touches,
   real `signed_off` value, eval names, goal).
2. **Lineage** — for the selected task, three columns: upstream chain → the
   task + every `touches_paths` glob → downstream dependents; plus a global
   **files ↔ tasks map** flagging any path touched by 2+ tasks with
   `⚠ OVERLAP — serialize` (the manager's parallel-dispatch rule, visualized).
3. **Ledger** — `_fleet.jsonl` timeline with typed event colors; when empty,
   an **honest empty state** documenting the event vocabulary and pointing at
   B-1 — never fabricated rows.
4. **Guide** — the board documents itself: run commands, the two modes, the
   seam schema, derivation rules, backlog mapping.

**Design direction (validated):** dark control-room — blue-black ground with
a faint blueprint grid, serif masthead echoing the canonical PDF, mono for all
data, semantic green/amber/blue/grey/red for state, purple reserved for
fork/seam. Reduced-motion respected; nodes keyboard-operable.

### The fleet decomposition (re-cut these as Task-Specs on pickup)

The spike decomposed into 12 atomic units — 9 landed, 3 remain future work:

| Unit | Lane | Deps | Landed in spike? |
|---|---|---|:--:|
| state-schema (the seam contract) | harvest | — | ✅ |
| frontmatter-harvester (tasks → state.tasks[]) | harvest | schema | ✅ |
| spine-derivation (artifacts → gates; = B-3 first cut) | harvest | harvester | ✅ |
| live-state-endpoint (/state fresh per GET) | harvest | harvester | ✅ |
| snapshot-baker (JSON island in-place) | harvest | endpoint | ✅ |
| dag-autolayout (topo columns + lane bands + seam edges) | render | schema | ✅ |
| live-poll-fallback (dual-mode loader + mode pill) | render | endpoint, dag | ✅ |
| lineage-view (3-column + overlap map) | render | dag | ✅ |
| ledger-view (timeline + honest empty state) | render | harvester | ✅ |
| sse-push (EventSource replaces polling) | render | poll-fallback | ⬜ future |
| tracker-overlay (adapter read-side: issue/PR per task) | harvest | endpoint | ⬜ future |
| ledger-live-manager (stream ticks, patch nodes) | render | sse, tracker | ⬜ future |

### Lessons the spike paid for (do not relearn)

- **Compute before write.** The snapshot baker once truncated the HTML because
  `open(w)` evaluated before a failing `re.sub` — build the new content fully,
  then write. Also: use a *function* replacement in `re.sub` (JSON payloads
  contain `\u`, which explodes template replacements).
- **Fix broken evals upstream in the spec**, never bend the code to a bad
  grep (one eval pattern carried a stray trailing quote — a Pass 5B fix).
- **No fake data.** A v1 prototype shipped a synthetic ledger styled as real;
  it undermined trust in everything else. Empty states that explain beat
  demo rows that lie.
- The whole thing needs no framework: stdlib server + hand-rolled SVG DAG
  were entirely sufficient and keep the skill bash/python-portable.

</details>

---

# P2 — compound the loop

## B-5 · Fork A's loop story — the synthetic issue

`task-loop` requires `--issue N`; Fork A has one coherent spec, one e2e eval,
and **no issues** — so today Fork A has no Pass 7/8 mechanism at all. Two
options (decide via a mini Pass 4 on the options):

- **(a)** document the *synthetic single issue* pattern — register the whole
  spec as one issue whose eval is `specs/e2e-eval.sh`, reuse task-loop as-is;
- **(b)** a thin `spec-loop` skill: run e2e eval → feed RED back → revise →
  GREEN → PR, HITL at the single big gate.

Bias to (a): zero new machinery, and the fork stays "one method, two paths."

## B-6 · Pass 9 · Sustain — what keeps the fleet green

Fleet-green is a point in time; drift is not. A scheduled re-run of **all**
task evals (the fleet's regression suite) + `refresh-doctrine.sh` +
`quality-gate.sh --strict` on the harness, emitting a drift report and
(optionally) reopening the issue whose eval went red — the same
green-eval-owns-state discipline, pointed at time. Ships as a fourth CI
template `converge-sustain.yml` (cron, weekly).

## B-7 · Adversary adapters for Pass 4

`--adversary codex|gemini|gpt` is a flag, but the refutation dispatch is
manual today. Mirror task-spec's `runbooks/dispatch-recipes/` pattern:
`adapters/<engine>.sh` that takes a plan file + the attack-playbook prompt and
returns the objection list. Makes Consensus repeatable and CI-runnable
(Pass 4 in a nightly "attack the plans" job during long projects).

## B-8 · Fleet metrics — receipts for the moats *(+cost dimension, 2026-07-08)*

`_fleet.jsonl` (from B-1) + `query-fleet-metrics.sh`: time-to-green per issue,
RED-iterations histogram, first-pass rate, park rate, per-engine comparison
(`--agent claude` vs `kimi` vs `codex` on the same backlog). This is how the
"harness = +2.3 to +10.1 points" class of claims gets reproduced on your own
repos — the optionality moat measured, not asserted.

**Cost dimension (from Loop Engineering's loudest caveat — loop token costs
"vary wildly if you are token rich or poor"):** task-specs bound *iterations*
but not *spend*. Add an optional `budget_tokens` (or cost cap) to the
frontmatter, a `tokens`/`cost` field on every `_fleet.jsonl` event, and
cost-per-green + cost-per-engine to the metrics queries. The Manager parks on
budget-exhausted exactly as it does on iterations (see B-1 reframe) — and the
engine arbitrage claim finally gets a price axis, not just a quality one.

## B-9 · Golden fixture — the 30-minute end-to-end

`examples/toy-revenue/` — a tiny seeded repo (SQLite or DuckDB) where the whole
chain runs brief → fleet-green in under 30 minutes with 3–4 task-specs. The
worked example lives in a private repo today; newcomers need a runnable one.
Also becomes the integration test for B-1's gate.

## B-14 · Standards alignment — AGENTS.md-first · A2A v1.2 *(added 2026-07-08)*

The AAIF consolidation settled the stack; keep the harness on its leading edge:

- **Invert the emission order.** The dominant Q1-2026 guidance is *"maintain
  one `AGENTS.md`; add tool-specific files only for tool-specific features"* —
  and CLAUDE.md/AGENTS.md overlap in new repos has compressed to near zero.
  `agents-kbs-tech-stack` currently treats `.claude/` as primary with
  `AGENTS.md` as a mirror; flip it: **`AGENTS.md` is the universal baseline**
  (source of truth for doctrine + per-tech do/don'ts), `CLAUDE.md` carries
  only Claude-specific capabilities (skills, subagents), Cursor/Copilot files
  stay derived.
- **Track AGENTS.md v1.1.** The proposal formalizes optional YAML frontmatter
  (`description`, `tags`) and nested per-directory files with
  closest-file-wins precedence — a natural fit for per-tech KB scoping. Emit
  v1.1-compatible output behind a flag until the spec merges.
- **A2A v1.0 → v1.2.** task-spec ships a canonical A2A v1.0 `TaskState`
  dispatcher (`ts_a2a_state_v1`); A2A is now at v1.2 under the Linux
  Foundation. Verify the mapping still conforms, and shape B-1's
  manager↔worker contract as A2A-style **structured delegation → async
  execution → result**, so remote/cross-vendor workers slot in without a
  contract change.

**Gate:** `emit-cross-tool.sh` produces an AGENTS.md that carries the full
doctrine baseline (validated by `quality-gate.sh`); CLAUDE.md in a scaffolded
repo contains no content duplicated from AGENTS.md; the A2A state mapping
passes a conformance check against the v1.2 spec.

---

# P3 — hygiene

## B-10 · Pass cards — regenerate `prompts/`

The v1-era `prompts/p1…p7` cards were dropped. Regenerate one runnable prompt
card per pass **from each SKILL.md** (script, not hand-written — single source
of truth) so the method is drivable from engines that don't load Claude Code
skills.

## B-11 · Chores

- ~~Root `LICENSE` file (README says MIT; no file exists).~~ — **done at v0.1**:
  MIT `LICENSE` shipped at the repo root.
- ~~Stack-agnostic scrub of the spine skills~~ — **done at v0.1**: the
  postgres→duckdb→dbt→MCP worked example no longer leaks into skill
  instructions; it survives only as labeled illustration, and the README keeps
  one worked example. `plans-to-coherent-spec` scripts redesigned generic.
- `.claude/` cleanup: empty scaffolding dirs + a leftover AgentSpec README are
  in the repo working tree — either scaffold it for real (Pass 6 on this repo)
  or drop it.
- ~~v2 PDF page 10 placeholder text~~ — **superseded 2026-07-07**: v3 PDF
  shipped (`docs/cvg-aut-systems-spine-steps-v3.pdf`) with the section written;
  v2 kept as a historical record.
