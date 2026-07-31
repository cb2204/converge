# bin/ — the cvg CLI

> **This file is the CLI's status card: what exists, what it wraps, what
> proved it.** It records the present only. The backlog — what comes next
> and in what order — lives in ONE place: the project's issue tracker.
> A second todo here would fork the truth — deliberately not done.

**cvg 0.1.0** — one unit, one version (root `VERSION`); the numbers
below are the CLI's pre-unification lineage · (0.20.0 — **Pass 8 becomes an actual loop.** `loop` now routes
to `loop-kernel.sh`, which runs **attempt → verify → repeat** until the spec's
Exit Check exits 0, bounded on three axes (iterations · wall-clock · tokens) with
a stagnation detector, each attempt in a **fresh engine process** with state on
disk. Until now it routed straight to the settler, which verifies once and
settles — so every spec's `budget_iterations` and
`circuit_breaker_no_progress` were declared and enforced by nothing, the same
defect class as an unenforced `external_writes` policy. The run lands in exactly
one **named terminal state** — `TASK_LOOP=SETTLED|LOCAL_SETTLED|NO_OP|BLOCKED|
STALLED|EXHAUSTED|CANCELLED|ERROR`, only the first three exiting zero, because an
error or an exhausted budget is never a success. `--gate-only` keeps the old
single-shot verdict; `--resume` continues from the checkpoint. Engines are one
adapter file each under `scripts/engines/`, so the CLI still spells no vendor.
0.19.x — **the CLI covers the whole chain, 0 through 8.**
`loop --issue <id>` brought Pass 8 into the CLI (it was a raw script path the
readme nonetheless advertised): one assigned task, one settlement — and it
**settles LOCALLY** (`TASK_LOOP=LOCAL_SETTLED`) unless
the execution profile grants external writes, because commit, push, tracker
mutation and PR creation are four effects, not one. `verify --task <spec>
[--judge E]` adds the **tier-2 adversarial check**: a different-family engine
grades the diff against intent *and a holdout it never saw*, failing closed
(`CHECK_VERIFY=UPHELD|REFUTED|UNAVAILABLE|ERROR`). `bind --check` is now
**genuinely read-only** — it recomputes the HMAC directly instead of shelling
out to the delegation gate, which used to run the task's own evals; a check that
executes untrusted project code is not a check. `setup harness` scaffolds the
project router (~50 lines) and stops — cvg never generates doctrine, and an
existing router is never clobbered (a `.proposed` sibling is written instead).
`ready` is now **dependency-aware**: it previously listed every spec as ready
when the true frontier was one, which would have dispatched tasks whose inputs
do not exist yet. 0.16.0 added `bind` / `bind --check` for Pass 7 · Bind:
one signed Task-Spec becomes a hash-bound execution profile with portable path
guards and runtime adapter manifests; the deterministic verdict is
`CHECK_RUNTIME_CONTRACT=PASS|FAIL`. 0.13.0 R.setup.linear — `setup tracker linear` needs **only
the API key**: it auto-discovers your team (single team auto-selects, else
`--team <KEY>`), resolves the key→UUID, and records the UUID in `.cvg/config`
(the API key stays in the env); the adapter also accepts a team KEY or UUID;
0.12.0 R.setup `setup`/`setup tracker` — the guided
**connectivity surface** (engines · trackers · index/memory-planned): a status
board + guided connect that records CHOICES in `.cvg/config` and **never
credentials** (secrets stay in the environment / a secrets manager); `register`
now defaults `--tracker` from it; 0.11.0 R①.I `register`/`register --check` — the Pass 6 · Register
bridge onto a **pluggable tracker** (`github|linear|jira`;
`fake` for offline tests): 1 spec = 1 issue, `depends_on` → `blocked-by`, and a
`tracker_ref` receipt stamped back into each spec; proven offline 42/42 via the
`fake` adapter; 0.5.0 R3.I `decompose`; 0.6.0 R4.I `review`/`doctor` — the first
**dispatching** subcommand + the engine-adapter/doctor layer, Milestone 3.1;
0.7.0 R4.build — multi-engine adversary `review --adversary codex,kimi` merges two
cross-family views into one referee-stamped log, the ATTACK half of the auto-loop) · born
2026-07-19 at R0.I (Milestone 1.1 executed early per
the owner's pivot; `capture` added same day; 0.2.1 same day — second-eyes
hardening: `capture` refuses unknown flags and flag conflicts, every exit-2
surface ends in `CHECK_BRD=USAGE_ERROR`; 0.3.0 same day at R1.I — `intent`
wraps the Pass 1 exit contract, `CHECK_TECH_SPEC=…` tokens; 0.4.0 at R2.I,
2026-07-21 — `structure` wraps the Pass 2 ADR gate, `CHECK_ADR=…` tokens,
R2.P golden diff EMPTY) · Task-Specs `tasks/done/T-20260719-cvg-router.md` +
`tasks/done/T-20260719-cvg-capture.md` + `tasks/done/T-20260719-pass0-gate-v031.md`
+ `tasks/done/T-20260719-cvg-intent.md` + `tasks/done/T-20260721-cvg-structure.md`
— each stamped Tier-1, 3/3 evals, accepted with `--gold-sanity`.

## The two files

| File | Role |
|---|---|
| `cvg` | The router. One name over the proven task-spec scripts. Referee, never a player: no model credentials, no LLM calls, wrapped commands are byte-exact pass-throughs (`exec`). Bash 3.2-safe, zero dependencies. |
| `_ui.sh` | Shared presentation layer (sourced). Color only on an interactive TTY; `NO_COLOR` non-empty disables; `CVG_COLOR=0|1` overrides; 8 basic ANSI colors only; color never carries meaning alone. Never touches wrapped-command output. Grows the stage strip at `cvg capture`. |

## Command surface (0.1.0)

| Command | Wraps | Proven by |
|---|---|---|
| `cvg init` | native workspace templates | creates the canonical tracked `.cvg/gate.yaml` and `cvg/{brain,docs,sketch,tasks,execution,loop,receipts}` control plane without clobbering existing files, and seeds `cvg/brain/_prompts/` with the canonical pass prompts (one steering blueprint per pass); idempotent `CVG_INIT=OK\|UNCHANGED`. |
| `cvg capture [--draft\|--no-go] [brief]` | `idea-to-brd/scripts/check-brd.sh` (Pass 0 exit contract) | golden byte-parity with the direct gate on the signed proving-ground BRD (R0.P); discovery contract (0→exit 2, 2→exit 2 naming both, 1→gates) |
| `cvg intent [--draft] [spec]` | `brd-docs-to-tech-req/scripts/check-tech-spec.sh` (Pass 1 exit contract) | golden byte-parity with the direct gate on the signed proving-ground tech-spec (R1.P); same discovery contract; exit-2 paths end in `CHECK_TECH_SPEC=USAGE_ERROR` |
| `cvg structure [--final] [--dir d]` | `tech-req-to-adrs/scripts/scaffold-adr.sh --check` (Pass 2 ADR gate) | golden byte-parity with the direct gate on the canonical proving-ground ADR set (R2.P, EMPTY diff); discovery over `cvg/docs/adrs/` then `docs/adrs/` (0→exit 2, 2→exit 2 naming both, 1→gates); FAIL passed through unmasked; exit-2 paths end in `CHECK_ADR=USAGE_ERROR` |
| `cvg decompose [--dir d]` | `reqs-to-swimlane-plans/scripts/new-plan.sh --check` (Pass 3 swimlane gate) | golden byte-parity with the direct gate on the proving-ground swimlane tree (R3.P, EMPTY diff); discovery over `cvg/sketch/` then `sketch/` `swimlane-*/` (0→exit 2, 2→exit 2 naming both, 1→gates); FAIL passed through unmasked; exit-2 paths end in `CHECK_PLAN=USAGE_ERROR` |
| `cvg review --adversary E` | `sketch-plans-adversarial-review/scripts/dispatch-review.sh` (Pass 4 dispatch) | **first dispatching subcommand** — frames the attack-playbook + swimlane plans, shells out to a **different-family** engine headless (`codex exec`/`kimi -p`/`claude -p`, read-only, `timeout`-or-bash-watchdog), and **stamps provenance itself** (input sha256s) into `sketch/.consensus/objection-log.json`. Fail-closed: `REVIEW=OK\|ERROR\|SKIP\|TIMEOUT\|USAGE_ERROR`. Referee never a player — zero creds; the engine CLI authenticates itself. Engine cmd env-overridable for tests (`CVG_CODEX_CMD` …). |
| `cvg review --adversary codex,kimi` | `sketch-plans-adversarial-review/scripts/dispatch-review-multi.sh` (Pass 4 multi-adversary) | a **comma-list** dispatches each engine through the proven single-engine path (reused via `--out`) and **merges** the judgments into ONE referee-stamped log: objections unioned + renumbered + tagged `raised_by`, `adversaries[]` recorded, provenance recomputed by the referee. Fail-closed if **no cross-family** engine ran (`REVIEW=ERROR`) or all absent (`REVIEW=SKIP`). Two independent cross-family views beat one — the ATTACK half of the auto-loop. |
| `cvg review [--check]` | `sketch-plans-adversarial-review/scripts/check-consensus-gate.sh` (Pass 4 gate) | validates the stamped objection log (structure + semantics + **provenance re-hash** of the live plans); `CHECK_CONSENSUS=OK\|FAIL\|EMPTY\|USAGE_ERROR` |
| `cvg doctor` | `sketch-plans-adversarial-review/scripts/doctor.sh` | engine readiness for Pass 4 dispatch — per-engine PASS/SKIP; requires ≥2 engines + ≥1 cross-family; `DOCTOR=OK\|FAIL` |
| `cvg doctor runtime-contract [--runtime R]` | `task-to-runtime-contract/scripts/attest-runtime.py` | **host attestation for Pass 7** — what THIS machine can genuinely enforce (isolation primitive, runtime binary, worktree support), so a required control the host cannot honor fails the bind closed instead of being assumed. `DOCTOR_RUNTIME_CONTRACT=OK\|DEGRADED\|FAIL`. |
| `cvg bind --task <spec>` | `task-to-runtime-contract/scripts/bind-runtime-contract.py` | Pass 7 · Bind: Tier-1 sign-off by default, Task-Spec hash, evidence hashes, topology substance, portable path guards, and generic/Claude/Codex/Kimi adapter manifests; immediately gates to `CHECK_RUNTIME_CONTRACT=PASS\|FAIL`. |
| `cvg bind --check --task <spec>` | `task-to-runtime-contract/scripts/check-runtime-contract.py` | **Genuinely read-only** freshness + enforceability recheck before dispatch (the Manager, future CI/CD) or Pass 8 execution. It recomputes the sign-off HMAC directly (`verify_signoff_pure`) rather than shelling out to the delegation gate, which executes the task's own evals — *a check that executes untrusted project code is not a check*. Proven: the repository is byte-identical before and after. |
| `cvg verify --task <spec> [--judge E]` | `task-to-runtime-contract/scripts/verify-work.py` | **Tier-2 adversarial check behind Pass 8.** A different-family engine grades the diff against the task's intent **and a holdout it never saw**, so a run cannot pass by satisfying only the evals it could read. Fails closed: `CHECK_VERIFY=UPHELD\|REFUTED\|UNAVAILABLE\|ERROR`. |
| `cvg loop --issue <id>` | `task-loop/scripts/loop-kernel.sh` (Pass 8; `--gate-only` → `open-issue-pr.sh`) | **the loop** — attempt → verify → repeat over ONE assigned task until its Exit Check exits 0, bounded on iterations · wall-clock · tokens with a stagnation detector, each attempt a fresh engine process briefed from disk. Flags may only **tighten** the spec's budgets — a ceiling that can be raised at the call site is not a ceiling. Lands in exactly one named terminal state (`SETTLED\|LOCAL_SETTLED\|NO_OP\|BLOCKED\|STALLED\|EXHAUSTED\|CANCELLED\|ERROR`); `EXHAUSTED` is a planned landing that commits work-in-progress and writes a `HANDOFF.md` for `--resume`. Then the settlement leg: Staging comes from the capability envelope's `fs.write` grant (never `git add -A`, which could sweep an untracked file outside the write scope past the diff-based guard), every staged path is re-checked before commit, and the `pass` receipt is written **last** so it cannot attest to a settlement that never happened. Honors `policy.external_writes: deny` — stops at a local commit and prints `TASK_LOOP=LOCAL_SETTLED`; push/PR require the policy or `--allow-external-writes`. |
| `cvg tasks new <slug>` | `generate-task-spec.sh` | writes only through the shared project-root backlog resolver, appends a creation event, and rebuilds state; clean-room coverage proves it cannot create a second root `tasks/` backlog. |
| `cvg tasks validate [--no-state] <spec>` | `validate-task-spec.sh` (the six-tier engine) | routed pass-through; enforces the six-tier sizing gate — leaf write-surface budgets (XS≤1/S≤2/M≤3/L≤5) and XL/XXL nodes that must declare `children:` (decompose, no route out). A normal success refreshes the derived `_state.yaml`; `--no-state` is the genuinely read-only CI/audit form. |
| `cvg tasks gate [--stamp] <spec>` | `safe-to-delegate.sh` | eval_1: byte + exit-code parity vs direct call. A plain verdict is read-only; only explicit `--stamp` mutates the sign-off envelope. Gate 0 **refuses an XL/XXL node** — a worker dispatches its children (leaves), never the node itself. |
| `cvg tasks accept <spec>` | `accept-task.sh` | accepted its own birth task (`--stamp --gold-sanity` → ACCEPT) |
| `cvg lane <intent> [--files N] [--paths p]` | `task-spec/scripts/classify-lane.py` | **routes work to the ceremony it earns** — FAST (5,7,8) · NORMAL (1,2,5,7,8) · FULL (0–8); deterministic and offline. It **routes but never waives**: auth/money/migrations/secrets/public-API or anything irreversible can never ride FAST, a new seam forces FULL, and no lane dispatches an unsigned spec. `LANE=FAST\|NORMAL\|FULL\|USAGE_ERROR`. |
| `cvg gate [--path p]` | `task-to-runtime-contract/scripts/check-gate.py` | **the repo write fence, read-only** — parses the tracked `.cvg/gate.yaml` policy and answers whether a path may be written: the fence a Task-Spec cannot widen. CI asserts both directions (the policy parses AND `auth/` is refused). `CHECK_GATE=OK\|ABSENT\|FORBIDDEN\|ERROR`. |
| `cvg tasks dod <spec>` | `definition-of-done.sh` (task-spec) | renders the **Definition of Done + traceability matrix** (every behavior `B-N` → its verifying eval → terminal); gates `DOD=COMPLETE\|GAPS` (an untraced behavior FAILS) and inherits `--json`. |
| `cvg tasks metrics [filters]` | `query-metrics.sh` | queries the canonical append-only lifecycle event index selected by the same backlog resolver as every other task command. |
| `cvg register [--tracker T] [--no-stamp-refs]` | `task-specs-to-issues/scripts/register.sh` (Pass 6 · Register) | **the opt-in bridge from the sealed backlog onto a board** — projects signed-off Task-Specs onto a tracker (1 spec = 1 issue; `depends_on` → `blocked-by`), then stamps a `tracker_ref: <tracker>:<issue>` receipt back into each spec (the issue-side marker stays the idempotency key). Pluggable **six-verb** adapter `github\|linear\|jira` (default `linear`), `fake` for tests; the referee holds **no** tracker creds — the adapter authenticates itself. Idempotent (re-run upserts, never duplicates). `REGISTER=OK\|FAIL\|DRY_RUN\|EMPTY`. Proven offline: `skills/task-specs-to-issues/tests/test-register.sh` (145 checks via the `fake` adapter and function-level cache probes). |
| `cvg register --check` | `task-specs-to-issues/scripts/verify-registration.sh` | gates the mapping is faithful (1:1 count, every `depends_on` is one `blocked-by`, no cycle, no un-gated leak); read-only. `CHECK_REGISTER=OK\|FAIL`. |
| `cvg setup` | native (`workspace` + signing + doctor + adapter `preflight`) | readiness board for the initialized workspace, Tier-1 signing, engines, and optional integrations, with one exact next step. Records CHOICES in `.cvg/config`, never credentials. `SETUP=READY\|INCOMPLETE`. |
| `cvg setup signing [--force]` | `task-spec/configs/setup-taskspec-signing-key.sh` | provisions the repository HMAC key under Git-private state with mode `0600`; idempotent unless explicit rotation is requested; refuses non-Git and symlinked-key paths. `SETUP_SIGNING=OK\|UNCHANGED\|NOT_GIT\|UNSAFE_PATH\|USAGE_ERROR`. |
| `cvg setup tracker <t> [--team K]` | native (+ adapter `preflight`) | guided connect — validates a backend and records it as the default in `.cvg/config`; `cvg register` then defaults `--tracker` from it. **Linear needs only `LINEAR_API_KEY`** — the team is auto-discovered (one team auto-selects; else `--team <KEY>` from the URL), resolved key→UUID, and recorded (key never stored). `SETUP_TRACKER=OK\|NEEDS_TEAM\|UNREACHABLE\|USAGE_ERROR`. |
| `cvg setup key [tracker]` | `task-specs-to-issues/scripts/tracker-key.sh set` | stores the tracker API key ONCE, outside the repo — OS keychain first, `0600` file under `~/.config/converge/` as fallback; reads stdin, never argv (argv is visible in `ps`). `.cvg/` keeps recording choices, never credentials. `TRACKER_KEY=STORED\|OK\|ABSENT`. |
| `cvg setup repo [--branch b] [--url u]` | native (git remote) | derives a browsable blob base URL from the git remote (github/gitlab/bitbucket shapes) and records it as `spec_base_url`, so every registered issue links back to the spec it was projected from. Branch-pinned. `SETUP_REPO=OK\|UNDETECTED\|USAGE_ERROR`. |
| `cvg setup identity [--list] [--map KEY=VAL]` | native (+ adapter `users` verb) | maps an `execution_backend`/`agent` **choice** to a tracker identity so `register` can seed `assigneeId` (create-only). `--list` discovers identities; `--map` validates strict unique keys and writes atomically with mode `0600` to machine-local `.cvg/identity`. Setup also places local `.cvg` choices/cache in Git's local exclude file. Optional — an unmapped assignee fails soft. `SETUP_IDENTITY=OK\|NEEDS_MAP\|UNREACHABLE\|USAGE_ERROR`. |
| `cvg setup projection [--enable\|--disable] …` | native (+ adapter `preflight`) | opts in to T3 structure projection — `register`'s Step-0 pre-pass ensures Initiative→Project→Milestones (idempotent, by name) and posts append-only health. Its local `.cvg/projection.lock` cache is Git-excluded, symlink-refusing, same-directory atomic, and mode `0600`. **Default DISABLED**, so a plain `cvg register` is byte-identical to before. `SETUP_PROJECTION=OK\|DISABLED\|UNREACHABLE\|USAGE_ERROR`. |
| `cvg eval <spec>` | `run-task-spec.sh` | ran its own birth task's evals, 3/3 + Exit Check |
| `cvg lint` | `lint-backlog.sh` | routed pass-through |
| `cvg transition <id> <state>` | `transition-status.sh` | moved `T-20260719-cvg-router` ready → done |
| `cvg next [--lane FULL\|NORMAL\|FAST]` | `conductor-steps/scripts/next-pass.sh` | **the descent conductor** — derives which pass is current and which comes next from workspace evidence (no stored state), prints the evidence board, the canonical steering prompt (`cvg/brain/_prompts/pass-N-*.md`), and the pass's closing gate. Read-only and instant (presence probes, never gate execution); evidence presence is not a verdict — the gates stay authoritative. Same engine's `pre N`/`post N` hooks enforce order fail-closed. Proven: 19-check hermetic suite. `NEXT_PASS=0-8\|DONE`. |
| `cvg ready [--all]` | `list-ready.sh` | **dependency-aware** — emits only the dispatchable frontier (status `ready` **and** every `depends_on` already done), then reports how many ready specs it hid. It previously ignored `depends_on` entirely and listed all 9 backbone specs as ready when the true frontier was 1, contradicting the register gate — and `ready` is the surface a Manager selects from, so it would have dispatched 8 tasks whose inputs do not exist yet. Fails closed on a dangling or cyclic edge; `--all` restores the flat listing. |
| `cvg setup harness` | `task-to-runtime-contract/scripts/scaffold-router.py` | scaffolds the **project router** (~50 lines: identity, folder map, where-to-look, house rules) and stops. **cvg never generates doctrine.** Non-clobbering: an existing router is untouched and a `.proposed` sibling is written instead. `SETUP_HARNESS=OK\|PROPOSED\|UNCHANGED\|USAGE_ERROR`. |
| `cvg setup engines` | `sketch-plans-adversarial-review/scripts/doctor.sh` | alias for `cvg doctor` inside the setup surface — per-engine readiness PASS/SKIP with the same `DOCTOR=OK\|FAIL` contract. |
| `cvg help` / `cvg version` | native | eval_2 (completeness), eval_3 (no ANSI when piped / `NO_COLOR`) |
| `cvg agent-context` (alias `manifest`) | native (python3 stdlib) | **agent-native self-description (2026 SOTA — clispec.dev / cli-agent-spec):** one JSON document — `schema_version` + full command tree + the token each command emits + the **exit-code taxonomy** (`retryable` / `side_effects`) + the global contracts. One call replaces N `help` iterations for an agent. |

Resolution uses two independent roots: `CVG_HOME` selects the installed
Converge tool package, while `CVG_PROJECT_ROOT` selects the consuming project's
local `.cvg/` state. Both may be explicit; otherwise each is discovered.

## Where the CLI looks for your work — the `cvg/` workspace

Every pass discovers its own inputs. For Task-Spec commands, the CLI exports one
project-root backlog decision: canonical `cvg/tasks/`, with an existing bare
`tasks/` directory retained only as a legacy fallback. Other passes search
`cvg/docs/` then `docs/` (passes 0–2),
`cvg/docs/adrs/` then `docs/adrs/` (Pass 2), `cvg/sketch/` then `sketch/`
(Pass 3), and `cvg/tasks/` then `tasks/` (Pass 5 onward, including `register`,
`ready`, `lint`, `eval` and `loop`). An explicit path or `--tasks-dir` always
wins, and `TASKSPEC_BACKLOG_DIR` still overrides the search.

This matters more than it looks. **A workspace is not always the git root** —
`cvg/` can live at `<repo>/projects/demo/cvg/`. Anchoring anything to the git
root instead of to the
workspace is the single defect this CLI has re-learned four times: it made
`register` fail out of the box, made `ready` read an empty backlog inside a valid
workspace, and made Pass 8 look for its own task in the parent repo. The rule is
now uniform — **resolve relative to the workspace, derive the workspace from the
tasks dir, and run evals there** — and it is pinned by tests that build a
workspace *below* the repo root, the one layout in which the two anchors can be
told apart.

## Contracts every future subcommand inherits

1. **Wrap, don't rewrite** (rule 3) — route to the proven scripts; a
   rewrite needs a written reason on the record (CHANGELOG or the board).
2. **Byte-parity pass-through** — no decoration of wrapped output, ever;
   beauty lives in `help`/`version`/error surfaces only.
3. **Degradation floor** — no ANSI on non-TTY, `NO_COLOR`, or
   `CVG_COLOR=0`; every state readable as words.
4. **Bash 3.2 + ShellCheck clean** (`shellcheck -x bin/cvg bin/_ui.sh`),
   zero pip/npm dependencies in the core path (rule 5).
5. **Dogfood ceremony** — S+ subcommands are cut as Task-Specs, gated
   before build, gold-sanity accepted after (rule 6).
6. **Agents are first-class users** (owner directive, 2026-07-19) — every
   gate/verdict surface ends in ONE stable greppable machine token (e.g.
   `CHECK_BRD=PASS`, `TIER=1`, `CONFORMANCE=L2`), exit codes are contracts,
   and piped output is plain and parse-stable. A harness should never have
   to parse prose. The agent-native SOTA layer is now **complete** (2026 —
   clispec.dev / cli-agent-spec): **`cvg agent-context`** makes the
   surface machine-discoverable, and **`--json`** (global flag, any
   position) wraps every command in a uniform envelope `{ok, command, token,
   verdict, exit_code, changed, dry_run, data, error, warnings, meta}` — a pure
   re-invoke wrapper, so the **default byte-parity path is untouched**. **`--dry-run`**
   short-circuits a mutation (`changed=false`). The exit-code taxonomy
   (`retryable`/`side_effects`) is published in `agent-context`. Proven:
   `tests/test-cvg-json-envelope.sh` (14/14).

## Not yet built

`status` · `ci` · `work` · `run`/`route` · `board`/`graph` ·
`deliver`/`metrics` — tracked on the project board. (`next` **shipped** as the
conductor-steps surface.)

`verify` **shipped** as the tier-2 judge; `doctor` and `lane` shipped
earlier. What the surface still owes is *dispatch* across the fleet — the
Manager — not routing.
