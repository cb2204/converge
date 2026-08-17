# Converge Independent Review — kimi-code-cli

## 1. Review Metadata

- **Reviewer / model identifier:** Kimi Code CLI (Moonshot AI), running as an
  interactive CLI agent. The exact underlying model version is not exposed to
  the agent; "kimi-code-cli" is the most precise identifier available to me.
- **Reasoning mode / effort:** standard agentic mode (no explicit
  reasoning-effort flag visible to the agent).
- **Review timestamp:** conducted 2026-08-05 ~22:16 through ~23:59 local time
  (UTC-3), i.e. 2026-08-06 ~01:16–03:00 UTC. All web sources were retrieved
  2026-08-06 (UTC).
- **Git HEAD:** `9c966884e37919c0f7e4c3e027b4b237670eb2ad` —
  `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi`
  (committer date 2026-08-04 20:28:35 -0300).
- **Branch:** `feat/e2e` (not detached). `main` also exists locally.
- **Worktree state at review start:** already dirty with 4 pre-existing
  changes I did not make and did not revert: `M apps/cockpit/package-lock.json`,
  `D review/deepseek.md`, `D review/grok.md`, `D review/kimi.md`. During the
  session an untracked `review/glm.md` appeared (visible in `git status`); it
  was not created by me and, per the review rules, I did not read, list, or
  otherwise inspect it or any other content under `review/`. No pre-existing
  change was treated as a defect of the project.
- **Tools available and used:** `git`, `bash` 5.3.9 (Homebrew) plus stock
  macOS `/bin/bash`, `node` v24.6.0, `python3` 3.14.3, `jq`, `shellcheck`,
  `openssl`, `sqlite3`, `curl`, authenticated `gh` CLI (read-only queries
  only), WebSearch and FetchURL for public-web research. No dependencies were
  installed; no model APIs were invoked for the review itself; no coding
  agents or subagents were launched (the review brief forbids delegation).
- **Files created or replaced by this review:** exactly one —
  `review/kimi-code-cli.md`. Scratch work (test logs, the smoke-test script)
  lives under `/tmp/cvg-review/` and throwaway `mktemp` directories.
- **Limitations:** I did not run the Cockpit's `npm run cockpit:check`,
  production build, or Playwright browser suite, because executing builds
  writes generated artifacts into the working tree and downloading browsers
  would install dependencies, both of which the brief forbids. Cockpit
  verification claims are therefore assessed from source and documentation,
  not from a local run. GitHub Actions state was read through `gh` without
  mutating anything.

## 2. Executive Verdict

- **Overall score: 67.8 / 100** (scorecard arithmetic in §8).
- **Does Converge stand out today?** Technically, yes — within the narrow
  population of people who read it. It is the most rigorously self-verifying
  spec-driven delivery method I found in the current market, and the only one
  whose "done" is a sealed, re-runnable eval gated by a referee that holds no
  model credentials. Commercially and socially, no: the repository has 1 star
  and 0 forks (GitHub API, 2026-08-06), one release, one author, and its
  public CI badge is red at review time (billing, not tests — §4). It stands
  out on evidence discipline, not on adoption.
- **Strongest defensible advantage:** the enforced trust chain around the
  Task-Spec — evals authored first, HMAC-sealed at sign-off, hash-pinned into
  the runtime contract, re-verified before every loop iteration, settlement
  confined to the contracted write scope, and a cross-family adversarial
  verifier that fails closed. I reproduced the core of this independently
  (§5, C-2): one byte of eval tampering is detected and refused, and manual
  hand-stamping is rejected. Nobody else's spec artifact carries that
  property today.
- **Most dangerous weakness:** the autonomy and trust story outruns the
  shipped ceiling, in three compounding ways: (a) the "holdout the builder
  never saw" is not actually withheld from the builder — it sits in the same
  spec file the worker is told to read (F-KCC-02); (b) the signing key is
  readable by any process running as the user, including a shell-capable
  worker engine, so the seal is tamper-evident rather than a boundary against
  a motivated worker — the deep docs admit this, the marketing implies more
  (F-KCC-03); (c) all settlement trust is local — there is no server-side
  re-verification and no fleet Manager (both admittedly unbuilt), so the
  "Autonomous Fabric" is currently a single-task loop with excellent brakes.
  Combined with zero external adoption, the project has a credibility gap on
  exactly the axis it claims to be strongest: proof.
- **Would I adopt it today?** Conditionally yes — as a single-team pilot for
  a repository that already has real tests, with humans reviewing every PR
  the loop opens, tier-2 verification enabled on anything sensitive, and the
  FAST lane reserved for genuinely reversible work. Not for unattended
  high-blast-radius delivery until the server-side eval gate and mechanical
  holdout separation land (§10, Move 1). The method transfers real value even
  in supervised mode; the autonomy claims are the part that is not yet
  earned.

## 3. What Converge Actually Is

Converge is five things shipped as one versioned unit, and it is important to
name what it is not:

1. **A method.** Nine gated passes from raw idea (Pass 0, optional) through
   BRD → tech-spec → ADRs → swimlane plans → cross-family adversarial review
   (Pass 4, "THE BARRIER", the last human sign-off) → signed Task-Specs
   (Pass 5) → optional tracker projection (Pass 6) → runtime binding (Pass 7)
   → a bounded execution loop (Pass 8). Lanes (`FAST | NORMAL | FULL`) route
   work to the ceremony it earns. This is genuine, documented, and internally
   consistent methodology — closer to a disciplined engineering operating
   procedure than to a product feature.
2. **A referee CLI (`bin/cvg`, 2,677 lines of bash 3.2).** A router over the
   skills' scripts with a uniform machine contract: one greppable token per
   surface, published exit-code taxonomy, `--json` envelope, `--dry-run`, and
   `cvg agent-context` emitting the whole surface as one JSON manifest (52
   commands — verified by running it). It holds no model credentials and
   calls no models; that claim survives code inspection.
3. **Twelve installable agent skills** (nine spine passes + three utilities)
   that land in each harness's native discovery directory
   (`.claude/skills/`, `.agents/skills/`, `.grok/skills/`). The skills are the
   steering layer; the gates are scripts the agent (or human) runs.
4. **The Task-Spec format and its trust machinery.** A self-verifying
   markdown unit: YAML frontmatter, ≥3 runnable bash evals plus an Exit
   Check, six-tier effort sizing, an HMAC-SHA256 v2 sign-off envelope, a
   hash-pinned runtime contract, and structured receipts. This is the
   cornerstone and the most defensible engineering in the repository.
5. **A single-task execution loop with settlement** (`loop-kernel.sh`,
   1,024 lines): attempt → verify → repeat in a git worktree, three-axis
   budgets checked before spending, a stagnation detector, eight named
   terminal states (only `SETTLED`, `LOCAL_SETTLED`, `NO_OP` exit zero),
   scope-confined staging, policy-gated external writes, optional tier-2
   cross-family verification, and a receipt written last.

Plus one explicitly unreleased piece: **the Cockpit** (`apps/cockpit/`), a
read-only operational observer over `cvg snapshot --json` with a carefully
sandboxed ACP "Ask" path. It is not in the published package, and its own
proving-grounds file records all four release gates as open (§5, C-13).

**What Converge is not:** it is not an autonomous runtime (it executes no
model and holds no keys); it is not a fleet control plane (the Manager —
dispatch across ready tasks — is admittedly unbuilt; the loop is single-task
by design today); it is not a CI system (the server-side eval gate is a
roadmap item); and it is not an agent. It delivers **bounded autonomy around
externally operated agents**: process, gating, and evidence, with the actual
coding delegated to whatever engine CLI the user already pays for. The unit
of autonomy is *one Task-Spec driven to a local commit or PR*, with merge
still human. That is a real and valuable thing — but "Autonomous Fabric" is
currently an aspiration resting on a single-task loop.

## 4. Repository and Test Coverage

**Shape.** 244 commits since 2026-07-01 (5 weeks old at review time), one
release (`v0.1.0`, 2026-07-31), one author visible in the history. The
load-bearing implementation is `bin/cvg` (2,677 lines bash) routing to
skill-owned scripts; the trust-critical paths are
`skills/task-spec/scripts/{safe-to-delegate,run-task-spec,validate-task-spec,_lib}.sh`,
`skills/task-loop/scripts/{loop-kernel,run-issue-eval,open-issue-pr}.sh` plus
`engines/{claude,codex,kimi}.sh`, and
`skills/task-to-runtime-contract/scripts/{bind,check}-runtime-contract.py`,
`verify-work.py`, `check-gate.py`. CI is a single workflow
(`.github/workflows/ci.yml`) with a two-OS gauntlet plus a Cockpit job, and a
meta-test (`tests/test-ci-covers-every-suite.sh`) that fails the build if any
suite in the package is not wired into the workflow — the class of
self-checking most projects never write.

**What I ran, and what happened** (all commands from the repository root at
HEAD `9c96688`; full logs under `/tmp/cvg-review/`):

| Suite / command | Result |
|---|---|
| `bash tests/test-version-unity.sh` | PASS |
| `bash tests/test-cvg-json-envelope.sh` | PASS |
| `bash tests/test-cvg-snapshot.sh` | PASS |
| `bash tests/test-cvg-doctor-plugin.sh` | PASS |
| `bash tests/test-cvg-doctor-host.sh` | PASS |
| `bash tests/test-cvg-doctor-evidence.sh` | PASS |
| `bash tests/test-cvg-tasks-plan.sh` | PASS |
| `bash tests/test-cvg-tasks-dod.sh` | PASS |
| `bash tests/test-cvg-lesson.sh` | PASS |
| `bash tests/test-install.sh` | PASS |
| `bash tests/test-clean-room-install-e2e.sh` | PASS — empty repo → install → init → sign → bind → stub-engine RED→GREEN loop → acceptance → receipt hash chain |
| `bash tests/test-loop-kernel.sh` | PASS — brakes, stagnation, exhaustion, resume, cancel, honest no-op |
| `bash tests/test-ci-covers-every-suite.sh` | PASS |
| `bash skills/task-spec/tests/test-task-spec-skill.sh` | PASS |
| `bash skills/task-spec/tests/test-hmac-envelope.sh` | PASS |
| `bash skills/task-spec/tests/test-bash-portability.sh` | PASS |
| `bash skills/task-spec/tests/test-effort-sizing.sh` | PASS |
| `bash skills/task-spec/tests/test-extractor-fuzz.sh` | PASS |
| `bash skills/task-spec/tests/test-portability-e2e.sh` | **BLOCKED** — its Python reference consumer requires PyYAML, absent on this host; the brief forbids installing it. CI installs hash-locked PyYAML (`.github/requirements-ci.txt`), so this is an environment limitation, not a product failure. Notably, the suite fails loudly and informatively. |
| `bash skills/task-spec/tests/test-v3-closed-loop-e2e.sh` | PASS |
| `bash skills/task-to-runtime-contract/tests/run-tests.sh` | PASS |
| `bash skills/task-specs-to-issues/tests/test-register.sh` | PASS |
| `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py` | PASS |
| Pass-gate suites: `idea-to-brd`, `brd-docs-to-tech-req`, `tech-req-to-adrs`, `reqs-to-swimlane-plans`, `sketch-plans-adversarial-review` | all PASS |
| `skills/pass-to-lesson`, `skills/skill-creator`, `skills/evidence-to-next-pass` suites | all PASS |
| `bash skills/task-spec/scripts/lint-skill-docs.sh` | PASS |
| Cockpit `check` / `build` / `test:browser` | **BLOCKED** — running builds writes artifacts into the tree and Playwright would download browsers; both forbidden by the review rules. Assessed from source instead (§5, C-13). |

**Totals: 31 project suites passed, 0 failed, 2 blocked** (the PyYAML leg of
`test-portability-e2e.sh`, and the Cockpit group). Counting the independent
smoke reproduction below as one test gives the 32 passed / 0 failed /
2 blocked recorded in §15. The suites are genuinely
hermetic — `git status --porcelain` after the full run showed no new
modifications attributable to the tests.

**My own independent reproduction** (not the project's suite), in a
throwaway `mktemp` git repo using the shipped CLI and scripts:

1. `cvg init` + `cvg setup signing` → key created at
   `.git/info/taskspec-signing-key` with mode `0600` (contents never read or
   printed).
2. `cvg tasks gate --stamp` on the golden fixture → `VERDICT: DELEGATE`,
   `TIER=1`, `signed_off_sig: hmac-sha256-v2:…` written.
3. One-byte edit inside an eval body → `cvg tasks validate` exits 1:
   *"spec body, authorization fields … or envelope modified after stamping —
   signed_off_sig HMAC mismatch"*; a bare `cvg tasks gate` on the tampered
   spec refuses (`DO NOT DELEGATE`). **Seal works as claimed.**
4. Hand-stamping attack (manually flipping `signed_off: true` /
   `signed_off_by:` in frontmatter, bypassing the gate) → validator exits 1:
   *"hand-stamping detected"*. **The bypass the FAQ worries about is really
   closed.**
5. `cvg agent-context` → valid JSON, 52 commands.
6. `check-gate.py --repo . --path auth/x.py` on the real repository →
   `REFUSED … (rule: **/auth/**)`, `CHECK_GATE=FORBIDDEN`. **The write fence
   refuses what it must.**

**Public CI status at review time — red, but not because of tests.** The six
most recent `ci.yml` runs (2026-08-03 23:42 through 2026-08-04 23:28, `main`
and `feat/e2e`) all show every job as failed. The job annotations read:
*"The job was not started because recent account payments have failed or your
spending limit needs to be increased"* (GitHub Actions run 30960115138,
retrieved via `gh` 2026-08-06). The jobs never executed a single step. The
last run that actually executed (2026-08-03T20:17Z, `main`) was green. So the
README badge currently displays failure while the codebase — per my full
local run — is green. This is an operational/billing lapse with a real cost:
the project's single public proof channel is dark, and any visitor today sees
a red badge on a repository whose entire pitch is verifiable proof.

**Coverage honesty.** The strongest properties are covered by meaningful
tests, not just same-named ones: the loop kernel suite drives stub engines
through exhaustion/stagnation/resume; the Pass-4 suite asserts the *negative*
shapes that must never be green (adversary-proposed resolution, unsigned
decision, open residual risk); the clean-room suite proves install-time
independence from the source checkout. Gaps: `cvg lint` cannot run on stock
macOS bash 3.2 (documented, open — `LINT=UNSUPPORTED`); tier-2 verification
and real engine dispatches are structurally untestable in CI and therefore
rest on live-use reports; the Cockpit's proving-ground gates are all open
(next section, C-13).

## 5. Claim-to-Evidence Audit

Legend: **Impl.** = implemented; **Enf.** = enforced at runtime; **Outside** =
enforcement sits outside the worker agent's authority; **Test** = covered by a
meaningful test I could run or read; **Evid.** = inspectable evidence shipped
in the repository; **Docs** = documentation states limitations honestly;
**E2E** = a normal user can reach the promised outcome end to end.
✓ = yes · ~ = partial / qualified · ✗ = no.

| # | Claim (source) | Impl. | Enf. | Outside | Test | Evid. | Docs | E2E |
|---|---|---|---|---|---|---|---|---|
| C-1 | "The eval decides done": no settlement unless the spec's Exit Check exits 0 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| C-2 | HMAC sign-off seal; editing an eval after stamping breaks the gate | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ✓ |
| C-3 | Referee holds zero model credentials, never writes product code | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| C-4 | Cross-family adversarial verification (Pass 4 and tier-2) | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ~ |
| C-5 | "Holdout criteria the builder never saw" | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ~ |
| C-6 | Loop brakes: 3-axis budgets, stagnation detector, 8 named terminal states, tighten-only flags | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| C-7 | Worktree isolation by default; settlement stages only contracted paths; external writes deny-by-default | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| C-8 | Harness-agnostic: one install serves Claude Code, Codex, Kimi, Grok Build | ✓ | ~ | n/a | ✓ | ✓ | ~ | ✓ |
| C-9 | Bash 3.2+, zero runtime dependencies | ~ | ~ | n/a | ✓ | ✓ | ✓ | ~ |
| C-10 | "CI is public and green on macOS and Linux" | ✓ | n/a | n/a | ✓ | ~ | ✗ | ~ |
| C-11 | Self-hosting: own backlog through the loop; nine tasks settled through merged PRs; one fully unattended | ✓ | n/a | n/a | ~ | ~ | ✓ | n/a |
| C-12 | Tier-2 graded real work in both directions (one UPHELD via merged PR, one REFUTED catching a fail-open bug) | ✓ | n/a | n/a | ✗ | ✗ | ✓ | n/a |
| C-13 | Cockpit: read-only observer; loopback-only; SHA-bound previews; Ask sandboxed (plan mode, no tools, no MCP, mode changes refused) | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ~ |

**Per-claim notes.**

- **C-1 (verified).** `run-issue-eval.sh` runs the spec's own evals and
  returns the Exit Check's exit code; `loop-kernel.sh` breaks to settlement
  only on GREEN; `open-issue-pr.sh` re-runs the gate before staging and
  refuses when the path policy fails. The README's "maximal stub attack lands
  all nine RED" is backed by the existence-only-eval block in
  `safe-to-delegate.sh` (Gate 1b) — existence-only specs cannot be delegated
  blind. Verified live by the clean-room suite and my smoke test.
- **C-2 (verified, with a boundary caveat).** Seal, tamper detection, and
  hand-stamp rejection all reproduced independently (§4). Two qualifications:
  (a) the key lives at `.git/info/taskspec-signing-key`, mode 0600 but
  readable by *any process running as the user* — including a worker engine
  with shell ability (the Codex adapter runs `codex exec --sandbox
  workspace-write`, which executes shell commands confined only in *writes*;
  reads of the main repo's `.git` are not prevented by Converge). A motivated
  worker could therefore re-seal a weakened eval. The mitigations are real
  but soft: the brief forbids it, the contract re-verifies the spec hash
  before every eval run (so the profile would also have to be rewritten),
  the Claude adapter is edit-only (no shell authority in headless
  `acceptEdits` mode), and settlement stages only contracted paths. The deep
  docs say this honestly — "tamper-evident, not tamper-proof … not a security
  boundary" (`skills/task-spec/SKILL.md:559-562`) — while the README/FAQ
  ("the only path to autonomy is through the gate") implies the stronger
  reading. (b) `--stamp` deliberately retires the prior signature before
  validation (`safe-to-delegate.sh:104-126`), which is the correct amendment
  path but also means re-sealing is one command away for any key holder.
- **C-3 (verified).** `bin/cvg` contains no network or model calls; engines
  authenticate themselves (`CVG_CLAUDE_CMD`/`claude`, `codex`, `kimi` on the
  user's own sign-in). The referee's only code execution is the *project's
  own* evals and scripts.
- **C-4 (mostly verified).** Pass 4's gate hard-fails a same-family adversary
  (`check-consensus-gate.sh:94-102`), requires at least one objection
  (default-to-refuted), requires owner-attributed resolutions, and re-hashes
  the live plans against the recorded provenance. The multi-adversary merge
  fails closed if no cross-family engine ran. What I could not verify: the
  quality of real adversarial runs (engines are stubbed or absent in tests by
  design) — that evidence lives in use reports, not in the repo.
- **C-5 (claim gap — the most important one in this review).** The README
  (lines 39, 54-56), `verify-work.py:75-77`, and the loop kernel header all
  describe holdout criteria "the builder never saw." Mechanically, the
  holdout is a `## Holdout` section *inside the same Task-Spec file*, and the
  loop's attempt brief instructs the worker: "Task-Spec (the only instruction
  source): `<path>`" — the engine adapters pass the whole sealed file to the
  worker (`claude.sh` header: "the brief points at it by path so the agent
  reads the sealed file itself"). Nothing in `loop-kernel.sh`, the adapters,
  or the binder strips or withholds the Holdout section. The only
  countermeasure is prose: the Pass-5 steering prompt tells the *authoring*
  agent "Never echo holdout content anywhere else in the spec" and claims
  "the section is excluded from the worker's brief" (`pass-prompt.md:23-25`)
  — which is not true of the shipped dispatch path: the brief does not quote
  it, but it points the worker at the file that contains it. A worker
  optimizing against the holdout is precisely the reward-hacking scenario the
  mechanism exists to prevent. Falsifier: a code path that emits a
  worker-view spec with `## Holdout` elided. I found none (`grep -ri holdout
  skills/` shows only documentation, the judge-side extractor, and
  skill-creator's unrelated eval splitter).
- **C-6 (verified).** Budgets are read from the spec, flags may only tighten
  (`tighter()`), checks run before each engine call, the stagnation
  fingerprint strips durations before hashing, and all eight terminal states
  are exercised by the 52-check kernel suite, which I ran green.
- **C-7 (verified).** Worktree default with exact fork-commit capture;
  staging comes from the contract's `fs.write` grant and every staged path is
  re-checked before commit; `external_writes` defaults to deny and yields
  `LOCAL_SETTLED`; the receipt is written last.
- **C-8 (qualified).** Skills do install into all four discovery trees
  (verified by the install tests), and loop engines exist for
  claude/codex/kimi. But Grok Build has **no loop engine adapter and no judge
  recipe** — execution and tier-2 cover three engines (+`gemini` as a judge
  in `verify-work.py`). "Works with … Grok Build" is true only at the
  skills-discovery layer. The README's table is honest if read carefully; the
  headline "one method … four harnesses" overstates execution parity.
- **C-9 (qualified).** Core gate paths are bash-3.2-clean with a dedicated
  portability suite and a macOS CI leg. Exceptions, all documented:
  `cvg lint` needs bash 4 (`LINT=UNSUPPORTED` on stock macOS); the
  binding/verification gates need `python3` (stdlib only); the optional
  reference consumer needs PyYAML (which blocked one suite here).
- **C-10 (currently false in presentation, not in fact).** §4: CI jobs have
  not executed since 2026-08-03 due to account billing; the badge reads
  failing. The claim was true when written and my local gauntlet says the
  code still holds it — but the public, checkable version of this claim is
  presently dark.
- **C-11 (substantially corroborated, not fully inspectable).** `gh pr list
  --state merged` shows 8 merged PRs with Task-Spec titles
  (`T-20260721-srv-core`, `…-tf-gold`, `T-20260729-obs-rowcounts`, etc.,
  2026-07-28/29); git history retains the sign-off commit for 8 backbone
  specs (`c521149`) and task/* branches on origin. The "nine tasks" and "one
  fully unattended" specifics, the receipts, and the specs themselves were
  dropped from the tree (`e23d358`), so the strongest version of the claim is
  not inspectable in the shipped repository — a strange choice for a project
  whose pitch is inspectable evidence.
- **C-12 (documented claim, unverifiable from the repo).** The UPHELD and
  REFUTED verdicts are described in README/CHANGELOG with plausible detail,
  but no objection log, verdict JSON, or transcript ships as an artifact.
  Classified as a credible but unproven report.
- **C-13 (verified from source; runtime unverified).** Loopback binding is
  enforced in `server/config.mjs:23,108` (non-loopback `--host` rejected);
  the Ask path refuses the `mode` config category
  (`server/ask-contract.mjs:170-173`) so a selection cannot move the session
  off plan mode; the Codex ACP adapter is statically blocked; artifact
  previews are snapshot- and SHA-bound per the README's API description.
  `PROVING-GROUNDS.md` is admirably honest: all four proving-ground gates are
  recorded as **open / not run**, and "no credentialed Codex or Claude turn
  is claimed." The Cockpit is well-engineered and genuinely unreleased —
  treat it as a promising liability (surface area without release evidence),
  not an asset, today.

## 6. Market Landscape

Market state as of **2026-08-06** (all sources retrieved that date; §14 lists
every URL). Context: coding agents are no longer the scarce resource — the
top of SWE-bench Verified sits in the mid-90s percent ([BenchLM, 2026-08-05
snapshot](https://benchlm.ai/benchmarks/swe-bench-verified); secondary
aggregator — figures vary by source, treated as directional only). The scarce
resources are *verification, orchestration, and trust*. That is precisely the
layer Converge competes in. The "dark factory" term Converge uses as its
tagline originates with StrongDM's publicized lights-out software factory
([Simon Willison, 2026-02-07](https://simonwillison.net/2026/Feb/7/software-factory/)),
so the phrase itself is not ownable; what could be owned is the *proof
machinery* underneath it.

| Alternative (category) | Primary user / use case | Unit of autonomy | Spec / planning model | Verification & acceptance | Agent / model portability | Execution & permission boundary | Observability & audit | Adoption signal (2026-08-06) |
|---|---|---|---|---|---|---|---|---|
| **Converge** (this review) | Solo dev / small team wanting gated, eval-proven delivery with their existing CLI agents | One signed Task-Spec → local commit or PR (single-task loop; merge human) | Nine-pass descent; Task-Spec with evals-first, HMAC seal, lanes | Deterministic sealed evals (tier-1) + cross-family refutation judge w/ holdout (tier-2, opt-in per lane) + path-fenced settlement | Harness-agnostic skills + 3 loop engines (claude/codex/kimi), 4th judge (gemini) | Referee holds no creds; worker confined by its own harness (edit-only or workspace sandbox); worktree isolation; write fence | Receipts, objection logs, STATE.md, snapshot contract for Cockpit | 1 star, 0 forks, 1 release ([repo API](https://github.com/luanmorenommaciel/converge)); CI dark (billing) |
| **GitHub Spec Kit** (spec-driven toolkit) | Teams adding spec-first process to the agent they already use | One feature: constitution → specify → plan → tasks → implement, agent-driven | Markdown templates + slash commands in 30+ agents | Whatever the host agent/repo does (tests, CI); no independent gate or seal | Excellent — works with Copilot, Claude Code, Gemini CLI, etc. | The host agent's own permissions; toolkit adds none | Specs/plans in-repo; no receipts or verdict provenance | 125,474 stars ([repo API](https://github.com/github/spec-kit)); overview: [Shiplight guide, 2026-08-04](https://www.shiplight.ai/blog/what-is-spec-driven-development) |
| **AWS Kiro** (spec-driven agentic IDE/CLI) | Teams standardizing on AWS wanting spec traceability in the editor | One spec'd feature; "autopilot" task execution; parallel agents | EARS requirements + design + task list as first-class files | Automated-reasoning checks of requirements + property-based tests ([kiro.dev](https://kiro.dev/)) | AWS/Bedrock-hosted models; IDE-centric | IDE agent permissions; no independent referee | Spec artifacts in-repo | GA May 2026, free tier + $20–$200/user/mo tiers ([pingax, 2026-06-28](https://pingax.com/kiro-aws-launch-announcement/), [AI Agent Square, 2026-07-04](https://aiagentsquare.com/agents/kiro)) |
| **OpenHands + Agent Canvas** (open autonomous agent / control center) | Teams self-hosting an open Devin alternative; platform builders | One issue → PR in a sandboxed environment; cloud or local | Agent-native planning; no enforced spec artifact | Repo tests inside sandbox; KVM sandboxes (v1.7); model scoring via OpenHands Index | Model-agnostic SDK; Canvas drives Claude Code, Codex CLI, Gemini CLI via ACP | Docker/KVM sandbox — real OS-level confinement | Web UI, trajectories; Canvas dashboard | 83,222 stars ([repo API](https://github.com/All-Hands-AI/OpenHands)); Canvas relaunch: [openclawlaunch comparison, 2026-07-22](https://openclawlaunch.com/compare/openhands) (secondary) |
| **Devin / Devin Desktop** (commercial autonomous engineer) | Enterprises delegating large bounded work (migrations) at scale | Cloud task → PR; parallel "army of Devins"; human approves PRs | Proprietary planning; playbooks; fine-tuning per customer | Customer CI + human PR review; benchmark-tuned per deployment | Cognition's models + IDE family (ex-Windsurf); ACP support for third-party agents | Cloud workspace isolation; enterprise controls | Devin Review, session UI; enterprise case studies | Nubank migration: 8–12x efficiency, 20x cost savings claimed ([devin.ai](https://devin.ai/)); Windsurf→Devin Desktop rebrand June 2026 ([Vynula, 2026-08-02](https://vynula.com/windsurf-ai-explained/)) |
| **StrongDM Attractor / dark factory** (method + manifesto, not a product) | Teams studying the frontier of no-human-code delivery | Scenario in → shipped code out; no human writes or reviews code | Natural-language spec repo (Attractor is ~3 markdown files) | Digital Twin Universe integration envs; LLM-judged satisfaction tests; **scenario holdouts against reward hacking** | Their own harness (Attractor); method is portable in principle | Factory-internal; humans structurally outside the loop | Extensive internal eval infrastructure (not shipped) | 1,262 stars ([repo API](https://github.com/strongdm/attractor)); analysis: [rywalker.com, 2026-02-13](https://rywalker.com/research/strongdm-factory), [Willison, 2026-02-07](https://simonwillison.net/2026/Feb/7/software-factory/) |
| **Gas Town / Beads** (multi-agent orchestration) | Power users running 20–30 parallel coding agents | Many concurrent agent sessions over git worktrees, tmux | Beads issue tracking (Dolt/versioned); Mayor/roles hierarchy | Host agents' tests + CI; no independent acceptance gate | Claude Code, Codex, Gemini, Copilot, etc. | Local sessions; orchestrator spawns/kills; per-agent git worktrees | Forensic audit trail via Beads/Dolt; dashboards | gastown 17,466 stars, beads 26,054 stars ([repos](https://github.com/gastownhall/gastown), […/beads](https://github.com/gastownhall/beads)); [rywalker, 2026-02-13](https://rywalker.com/research/gastown) |
| **Google Antigravity** (agentic IDE + manager view) | Developers wanting parallel agents with artifact review inside an IDE | Parallel agent tasks with artifact-based review | Implementation plans + artifacts (diffs, recordings) | Artifact review (plans, diffs, browser recordings); no independent gate | Google's models; subagents inherit tool permissions | Worktree support, scoped subagent permissions | Manager View "mission control" | Secondary source only: [augmentcode comparison, 2026-03-19](https://www.augmentcode.com/tools/kiro-vs-antigravity) |
| **Agent control planes** (Microsoft Agent 365, LangSmith Fleet, et al.) | Enterprises governing fleets of agents across frameworks | Governance over agents, not code delivery per se | n/a (registry/policy, not spec-driven) | Policy enforcement, approvals, eval integrations | Cross-framework ambition; strongest inside own estate | Identity, registry, approval routing, action boundaries | This *is* the product: traces, audit, governance | Category survey: [contro1 comparison, 2026-06-03](https://contro1.com/compare/best-ai-agent-control-plane-tools) (secondary); LangSmith Fleet: [montecarlo.ai, 2026-07-26](https://montecarlo.ai/blog-agent-observability-tools) (secondary) |

**Adjacent context (not tabled):** SWE-bench and its successors define the
eval culture Converge's sealed evals borrow from; CI/CD platforms (GitHub
Actions + Copilot coding agent, GitLab) are absorbing task→PR loops natively,
which is both a threat and the integration surface Converge's roadmap Manager
assumes.

**Per-competitor position (setup cost, Converge's advantage, Converge's disadvantage):**

- **Spec Kit** — setup trivial; enormous community. Converge advantage: its
  gates *execute* — a Spec Kit spec is prose an agent may ignore; a Converge
  spec is a sealed, runnable contract whose evals decide settlement.
  Disadvantage: Spec Kit rides every major agent's native UX with zero
  ceremony; Converge's nine passes are heavy, and nobody has heard of it.
- **Kiro** — polished spec-first IDE with automated-reasoning and
  property-based testing baked in, AWS distribution. Converge advantage:
  vendor-neutral (Kiro locks you into AWS's IDE and models), and its verdicts
  are harness-independent scripts rather than IDE features. Disadvantage:
  Kiro's correctness checking is deeper tech (formal-ish reasoning,
  fuzz/property tests) than Converge's hand-written bash evals, and it ships
  with a real editor and support org.
- **OpenHands / Agent Canvas** — real sandboxed autonomy and an emerging
  multi-agent control center over ACP, open source, huge community. Converge
  advantage: Converge's acceptance is spec-sealed and adversarially verified
  *outside* the worker, while OpenHands trusts repo tests inside the same
  loop that wrote them; Converge receipts and objection logs are stronger
  audit artifacts. Disadvantage: OpenHands actually delivers end-to-end
  autonomy today (sandboxed, cloud or local, at scale), which Converge does
  not attempt without its missing Manager; OpenHands has 83k stars and a
  company behind it.
- **Devin** — the enterprise proof that delegated task→PR loops produce ROI
  (Nubank). Converge advantage: Devin's verdicts are opaque and
  vendor-owned; Converge's are reproducible by anyone with bash. Devin
  cannot give you its referee. Disadvantage: Devin delivers the whole
  outcome as a managed service with support; Converge delivers machinery you
  operate yourself, and its evidence is one author's repo.
- **StrongDM (Attractor)** — the philosophical vanguard: humans structurally
  out of the loop, with holdouts against reward hacking already part of their
  pattern language. Converge advantage: Converge is installable, runnable,
  and harness-neutral *today*; Attractor is a manifesto plus internal
  infrastructure you cannot adopt. Converge also keeps a human barrier,
  which most enterprises will require. Disadvantage: StrongDM ships
  production code with no human review *in reality*, the thing Converge
  aspires to; and Converge's holdout is currently visible to the worker
  (F-KCC-02) — StrongDM's scenario holdouts are structurally separated.
- **Gas Town / Beads** — solves the *fleet* problem (dozens of parallel
  agents, forensic work tracking) that Converge explicitly defers. Converge
  advantage: Gas Town has no acceptance gate at all — it scales activity, not
  verified completion; Converge's per-task proof is exactly what a Gas
  Town-style fleet lacks. Disadvantage: when Converge builds its Manager, it
  re-enters territory Beads already occupies (versioned work tracking with an
  audit trail), with a fraction of the community.
- **Antigravity / control planes** — the platform vendors are converging on
  "mission control + governance" from above. Converge advantage: it is the
  only player whose control verdicts are computed by a referee with no vendor
  stake and no credentials to leak. Disadvantage: these are bundled free
  into platforms developers already pay for; Converge must be deliberately
  adopted.

**Market research status:** complete (web access available; 15 external
sources, §14). Two sources are flagged secondary where primary documentation
was not fetched (Antigravity; OpenHands Canvas relaunch details).

## 7. Competitive Position

**The clearest user** is a senior engineer or small platform team (1–10
people) who already pays for one or more coding-agent CLIs, works in repos
with real test suites, and wants autonomous-ish delivery they can *defend* —
to a security review, to a manager, to themselves at 3 a.m. The buyer in an
org is whoever owns "we let agents open PRs" and needs the paper trail.
Converge is a poor fit for: vibe-coding speed-seekers (the ceremony is the
point), teams without tests (evals-first authoring is the cost of entry), and
anyone wanting a managed service.

**The job it completes substantially better than alternatives:** making a
coding agent's claim of "done" *machine-checkable, tamper-evident, and
independently refutable*, without changing which agent you use or giving any
new system your credentials. No competitor offers that exact bundle: Spec
Kit/Kiro structure intent but don't enforce acceptance; OpenHands/Devin
deliver autonomy but grade themselves; Gas Town scales agents but not proof;
control planes observe fleets but don't seal work contracts. Converge's
verifiable niche is **acceptance infrastructure for agent-written code**.

**Genuinely differentiated:** (1) the sealed, self-verifying Task-Spec as a
portable artifact (verified in §5 C-1/C-2); (2) the referee architecture —
zero credentials, byte-parity pass-throughs, uniform machine tokens
(`TIER=1`, `TASK_LOOP=…`), agent-discoverable surface; (3) cross-family
adversarial verification as a *gate*, not a suggestion; (4) honest terminal
states and brakes (an exhausted budget is never success — most agent loops
silently treat it as one); (5) the documentation's adversarial honesty about
its own past gate bugs (the CHANGELOG's barrier-fix entries are the best
trust signal in the repo).

**Table stakes, not differentiation:** spec-driven workflow (Spec Kit, Kiro);
worktree-per-attempt isolation (every orchestrator); bounded loops with
budgets (OpenHands, Gas Town); skills/plugins per harness; read-only
dashboards; holdouts as a concept (StrongDM, and standard ML practice).

**Does it deliver autonomy?** Bounded, single-task autonomy with a human at
the barrier and at merge. It does not deliver the "dark factory" it invokes:
passes 0–4 are explicitly human-led, the loop needs an engine the user
operates, tier-2 is opt-in per lane, there is no fleet dispatch and no
server-side settlement gate. Today's honest label is **"supervised autonomy
with exceptional evidence"** — which is arguably the more adoptable position,
but it is not the marketing's position.

**"Autonomous Fabric" as a position:** defensible only if the Manager and
the server-side gate ship (§10). As of this commit the term is neither
accurate (no fabric — one task at a time, locally settled) nor ownable
("dark factory" belongs to StrongDM's public narrative). The ownable phrase
is closer to *the referee layer*: "any agent, one gate, proof not claims."

## 8. Scorecard

Scores are for the project **at the inspected commit**, per the rubric's
interpretation bands. Weighted points = score × weight ÷ 10.

| Dimension | Weight | Score | Weighted | Rationale |
|---|---:|---:|---:|---|
| Problem & product thesis | 10% | 7.5 | 7.50 | The problem (agents claiming done; reward hacking; process drift) is real and timely. Thesis is clear and correctly targets verification, not generation. Held back from 8+ because the thesis is shared by a suddenly crowded field and the "Autonomous Fabric" framing outruns the product. |
| Differentiation & market position | 15% | 5.5 | 8.25 | Real differentiation in the trust machinery, but zero adoption (1 star, 0 forks), an unownable category term, and platform vendors converging on the same layer from above. "Interesting," not yet "Distinct." |
| Method & architecture coherence | 15% | 8.0 | 12.00 | The nine-pass method, barrier placement, lane model, referee pattern, and wrap-don't-rewrite CLI are unusually coherent, and the codebase consistently implements the doctrine. Docked for the holdout contradiction (doctrine says hidden; implementation shows it) and the unreleased Cockpit floating beside the core. |
| Trust, verification & security model | 20% | 7.0 | 14.00 | Fail-closed gates, contract hash-pinning re-verified before every eval, human-only barrier resolution, settlement scope confinement, honest "tamper-evident" caveats — all verified. Docked for: holdout visible to the worker; worker-readable signing key (threat-model limit only admitted in deep docs); no server-side re-verification; tier-2 off the default path except FULL lane. |
| Implementation quality & reliability | 15% | 7.5 | 11.25 | 31/31 runnable suites green locally; hermetic tests; bash-3.2 discipline with a real macOS leg; CHANGELOG demonstrates a working find-fix-pin loop on its own gates. Docked for: 1,000-line bash kernel and 2,800-line Python snapshot (concentrated fragility), single maintainer, and a public CI currently dark for billing. |
| Autonomous end-to-end completeness | 10% | 5.5 | 5.50 | The single-task loop genuinely settles work unattended (clean-room proven; 8 merged PRs corroborate). But no Manager, no CI eval-gate, tier-2 optional, merge human, proving grounds open. "Autonomous" describes one task, not a fabric. |
| Developer experience & adoption readiness | 10% | 6.0 | 6.00 | Install is genuinely three-door, idempotent, and verified; `cvg next`/`setup`/`agent-context` are excellent agent-era DX. Docked for: nine-pass ceremony with no quick win under ~30 minutes, dense docs, `cvg lint` unsupported on stock macOS, and zero community support surface. |
| Evidence, credibility & project maturity | 5% | 6.5 | 3.25 | Self-hosting corroborated via PR history; exceptional internal honesty (proving grounds recorded open; tamper-evident caveat in writing). Docked for: strongest live claims (REFUTED case, unattended run, proving grounds) ship no inspectable artifacts; v0.1.0, five weeks old, CI badge red. |
| **Overall** | 100% | — | **67.8** | sum of weighted points = 7.50 + 8.25 + 12.00 + 14.00 + 11.25 + 5.50 + 6.00 + 3.25 |

- **Vision potential: High.** The referee/acceptance layer is a real market
  gap, and the method is sound enough to own it.
- **Current readiness: Alpha.** It self-hosts and its gates work, but the
  autonomy surface is single-task, key evidence is unshipped, and the second
  half of the product (Manager, server gate, Cockpit) is unbuilt or
  unreleased.
- **Market position: Interesting.** Distinct requires either adoption or a
  proof nobody else can show; Converge currently has neither externally.
- **Evidence confidence: Medium.** High confidence in everything verifiable
  locally (I ran it all); the live-operation claims rest on the author's
  reports and PR metadata, not shipped artifacts.

## 9. Prioritized Findings

Ordered by leverage, not by severity alone.

### F-KCC-01 — The core trust chain is real and independently reproducible

- Type: strength
- Surface: runtime | security | CLI
- Severity: positive
- Confidence: high
- Evidence: `skills/task-spec/scripts/safe-to-delegate.sh` (full read);
  `skills/task-spec/scripts/_lib.sh:601-637,820-854`; my smoke test (§4):
  stamp → `TIER=1`; one-byte eval tamper → validator HMAC mismatch, gate
  refuses; manual `signed_off: true` flip → "hand-stamping detected";
  `check-gate.py` refuses `auth/x.py`. Clean-room suite PASS.
- Claim: the signed, self-verifying Task-Spec — evals first, HMAC-sealed,
  hash-pinned into the runtime contract, re-verified before every loop
  iteration — works exactly as documented, with no dependency on trusting my
  word for it: anyone can reproduce the test above in five minutes.
- Why it matters: this is the only claim in the current market of this kind
  that survives inspection, and it is the foundation every other claim stands
  on.
- Falsifier: a shipped path where a tampered eval reaches settlement green.
  (None found; the closest hole is re-sealing via the worker-readable key —
  F-KCC-03.)
- Recommended move: keep it; make it the center of all public communication,
  with the reproduction script shipped as `docs/verify-the-seal.md`.
- Acceptance evidence: an external reader reproduces tamper detection from
  the published doc alone.

### F-KCC-02 — "Holdout the builder never saw" is not enforced — the worker reads the file that contains it

- Type: claim gap
- Surface: runtime | security | docs
- Severity: high
- Confidence: high
- Evidence: `verify-work.py:75-77` extracts `## Holdout` from the spec body;
  `loop-kernel.sh:851-859` briefs the worker with "Task-Spec (the only
  instruction source): `<path>`"; `engines/claude.sh:9-11` states the agent
  "reads the sealed file itself"; no stripping code exists (`grep -ri holdout
  skills/` — documentation and judge-side extraction only);
  `pass-prompt.md:23-25` claims the section "is excluded from the worker's
  brief," which the shipped dispatch path contradicts. README lines 39 and
  54-56 repeat the "never saw" phrasing.
- Claim: the tier-2 train/test separation is, in implementation, advisory.
  A worker that reads its instructions — as it must — can optimize directly
  against the holdout. The mechanism designed to catch reward hacking is
  itself gameable by construction.
- Why it matters: this is the project's signature safety claim ("holdout
  criteria the builder never saw" is in the README's second paragraph), and
  it is currently false. Every REFUTED/UPHELD verdict involving a holdout was
  produced under a weaker separation than advertised.
- Falsifier: evidence that the worker-facing brief or adapter elides
  `## Holdout` (none found), or that real workers never read whole files
  (implausible).
- Recommended move: at bind time, emit a worker-view spec with the Holdout
  section elided, brief the worker against that copy, and have the contract
  record both hashes (sealed original for the judge, elided view for the
  worker). Adjust docs to match whatever is actually enforced.
- Acceptance evidence: a test where a spec containing `## Holdout` is bound
  and looped with a stub engine that dumps its input; the holdout string
  appears in the judge's input and nowhere in the worker's.

### F-KCC-03 — The seal is tamper-evident, not a boundary against the worker — and the README implies otherwise

- Type: design risk
- Surface: security | runtime | docs
- Severity: high
- Confidence: high
- Evidence: key resolved from `.git/info/taskspec-signing-key`
  (`_lib.sh:601-637`) — readable by any process running as the user; the
  Codex adapter runs `codex exec --sandbox workspace-write`
  (`engines/codex.sh:42`), which permits shell execution with reads outside
  the workspace; `--stamp` retires the old signature by design
  (`safe-to-delegate.sh:104-126`), so re-sealing is one command for any key
  holder. Mitigations present: contract re-verifies the spec hash before
  every eval (`check-runtime-contract.py:56-75`), settlement stages only
  contracted paths, the Claude adapter is edit-only. Deep docs are honest:
  "tamper-evident, not tamper-proof … not a security boundary"
  (`skills/task-spec/SKILL.md:559-562`); README FAQ ("the only path to
  autonomy is through the gate") and loop-kernel header ("a level-1
  deterministic check the agent cannot edit") are not.
- Claim: against a *motivated* worker with shell ability, the seal raises the
  cost of eval-tampering but does not prevent it; the real boundary is the
  harness's tool confinement, which Converge does not control and does not
  verify at bind.
- Why it matters: the entire unattended-delivery story is marketed on a
  boundary whose strength depends on which engine adapter is in use. This is
  exactly the class of overstatement a security reviewer will publish first.
- Falsifier: demonstration that `workspace-write` confines reads to the
  workspace (then the key is unreachable for Codex), or a Converge check that
  attests worker tool confinement at bind time for every adapter.
- Recommended move: (a) state the threat model in the README, not just in
  SKILL.md; (b) at bind, attest the *worker's* confinement class per adapter
  (edit-only vs shell-in-sandbox) and require `--accept-unenforced` when the
  seal cannot be a boundary; (c) for high blast radius, support resolving the
  key from outside the repo (env-only) so the worker cannot reach it.
- Acceptance evidence: `cvg doctor runtime-contract` reports per-adapter
  worker-confinement class; a bind with a shell-capable worker and repo-local
  key on a high-blast-radius task fails closed unless waived.

### F-KCC-04 — Public CI is dark at review time (billing, not tests) — the proof channel contradicts the pitch

- Type: verified defect (operational)
- Surface: distribution
- Severity: medium
- Confidence: high
- Evidence: `gh run list --workflow=ci.yml` — six consecutive failed runs
  (2026-08-03 23:42 → 2026-08-04 23:28, `main` + `feat/e2e`); annotations on
  run 30960115138: "The job was not started because recent account payments
  have failed or your spending limit needs to be increased"; last executed
  run green 2026-08-03T20:17Z. All 31 locally runnable suites pass (§4).
- Claim: the README's "CI is public and green" is currently unverifiable by
  any visitor; the badge shows failing on a repository whose entire value
  proposition is checkable proof.
- Why it matters: for an evidence-first project, the public evidence channel
  *is* the product's storefront. Every day red costs the little attention a
  1-star repo gets.
- Falsifier: the Actions page showing green at read time (it does not, at
  2026-08-06).
- Recommended move: resolve the billing lock immediately; add a scheduled
  weekly CI run so staleness is visible even without pushes.
- Acceptance evidence: badge green; a dated green run within the last 7 days
  on the default branch.

### F-KCC-05 — The strongest evidence is not shipped: self-hosting artifacts were dropped from the tree

- Type: claim gap
- Surface: docs | distribution
- Severity: medium
- Confidence: high
- Evidence: `e23d358` "drop root tasks/ + temp/ scratch"; no `tasks/` or
  receipts in HEAD; `gh pr list --state merged` shows 8 task-titled merged
  PRs (2026-07-28/29); `c521149` retains backbone spec sign-offs in history.
  README "Provenance" claims nine settled tasks and one fully unattended run;
  README §Status describes UPHELD and REFUTED verdicts with no linked
  artifact.
- Claim: the project practices what it enforces — but the receipts, sealed
  specs, objection logs, and verdict JSONs a skeptic would ask for are not in
  the repository. The claims are plausible and partially corroborated by PR
  metadata; they are not inspectable.
- Why it matters: an evidence-first project gets held to its own standard;
  "trust us, it happened" is the one sentence Converge cannot afford.
- Falsifier: the artifacts existing somewhere public and linked (not found at
  review time).
- Recommended move: ship an `evidence/` directory (or a linked public
  evidence repo) with the actual sealed specs, receipts, the REFUTED verdict
  and its diff, and a dated proving-ground rerun per case.
- Acceptance evidence: a stranger can follow links from the README to the raw
  artifacts behind every live claim.

### F-KCC-06 — Zero external adoption in a market with 100k-star incumbents

- Type: market gap
- Surface: market | distribution
- Severity: high
- Confidence: high
- Evidence: GitHub API 2026-08-06 — converge: 1 star, 0 forks; spec-kit:
  125,474; OpenHands: 83,222; gastown: 17,466; beads: 26,054; attractor:
  1,262. Repo created 2026-07-01; single author.
- Claim: Converge has no users, no community proof, no third-party
  validation, and no organizational resilience (bus factor 1). Meanwhile the
  spec-driven category is consolidating fast (Kiro GA'd with AWS
  distribution; Spec Kit is the default answer; platform IDEs bundle
  orchestration free).
- Why it matters: the window for "the verification layer" is open now; in 12
  months it is likely either table stakes inside platforms or owned by
  whoever ships proof first. Adoption, not capability, is the binding
  constraint.
- Falsifier: external users, forks, or third-party write-ups existing (none
  found).
- Recommended move: §10 Move 3 — a deliberate proof-and-wedge program, not
  more features.
- Acceptance evidence: ≥3 external repos running the loop in public; ≥100
  stars; one third-party reproduction write-up.

### F-KCC-07 — The autonomy ceiling: single-task loop, no Manager, no server-side gate

- Type: design risk
- Surface: runtime | method
- Severity: high
- Confidence: high
- Evidence: README §Status ("What's deliberately not in 0.1.0: the Manager …
  and the CI eval-gate"); `bin/README.md:180-182`; `loop-kernel.sh:151`
  ("This loop never picks its own task"); settlement is local
  (`LOCAL_SETTLED`) unless external writes are granted.
- Claim: Converge today automates one task to one PR on one machine, with
  trust anchored in that machine. There is no fleet dispatch, no merge
  ordering, and no server-side re-verification — so "Autonomous Fabric" is
  unbuilt, and every settlement proof is only as trustworthy as the laptop it
  ran on.
- Why it matters: this is the gap between a credible tool and a category. It
  is also the gap a skeptic will use to dismiss the marketing.
- Falsifier: a shipped Manager or CI gate (both confirmed absent).
- Recommended move: §10 Moves 1 and 2, in that order.
- Acceptance evidence: a PR whose checks re-run the sealed evals
  server-side and block merge on red; two tasks dispatched from `cvg ready`
  without human selection, with receipts.

### F-KCC-08 — Test discipline is the best in its class

- Type: strength
- Surface: runtime | CLI | skills
- Severity: positive
- Confidence: high
- Evidence: 31/31 runnable suites green locally (§4); hermetic design
  (stub engines via `CVG_ENGINES_DIR`, throwaway config dirs, no network);
  `test-ci-covers-every-suite.sh` prevents silent rot; the one blocked suite
  fails loudly with the exact missing dependency; CHANGELOG records tests
  that previously *asserted the defect* being flipped red-then-green.
- Claim: the project's verification culture is not decorative — suites test
  negative shapes, and the CI workflow tests itself.
- Why it matters: reliability compounds; this is the substrate that makes
  every future claim cheap to prove.
- Falsifier: suites that pass while the product is broken in the way they
  name (not found; the PyYAML block shows the opposite behavior).
- Recommended move: keep the standard; require every new surface to ship its
  negative rows first.
- Acceptance evidence: continued green runs; the coverage gate catching at
  least one future unwired suite.

### F-KCC-09 — Execution parity across "four harnesses" is really three plus a judge

- Type: claim gap
- Surface: runtime | docs | distribution
- Severity: medium
- Confidence: high
- Evidence: loop engines only `engines/{claude,codex,kimi}.sh`; `verify-work.py`
  judges: codex, kimi, claude, gemini; no `grok` execution or judge recipe
  anywhere; `install.sh` does install skills into `.grok/skills/`.
- Claim: "Works with Claude Code · Codex · Kimi · Grok Build" is true for
  skills discovery; the autonomous machinery (worker, judge) excludes Grok
  Build entirely.
- Why it matters: a user who installs for Grok and tries `cvg loop --agent
  grok` hits "no engine adapter" — a first-run failure on the headline
  promise.
- Falsifier: a grok adapter or judge recipe (none at this commit).
- Recommended move: either ship a Grok adapter (one file, per the design) or
  qualify the README's harness table to "skills: 4 · loop engines: 3".
- Acceptance evidence: `cvg doctor` reports Grok's actual capability class;
  docs match reality.

### F-KCC-10 — The Cockpit is well-engineered, honestly unreleased, and currently a liability

- Type: design risk
- Surface: Cockpit
- Severity: medium
- Confidence: high
- Evidence: `apps/cockpit/PROVING-GROUNDS.md` — all four release gates open,
  "no credentialed Codex or Claude turn is claimed"; excluded from the
  published package (README:97-99); safety claims verified in source
  (`server/config.mjs:108` loopback-only; `server/ask-contract.mjs:170-173`
  mode category refused); I could not run its suites (review constraints).
- Claim: the Cockpit's architecture and safety boundary are genuinely good —
  but it has zero release evidence, and it consumed substantial recent commit
  volume while the core's biggest gaps (Manager, server gate, holdout)
  remained open.
- Why it matters: opportunity cost and surface area. An unreleased observer
  does not move the "Autonomous Fabric" claim; the missing autonomy layer
  does.
- Falsifier: dated proving-ground reruns recorded as passed (none at this
  commit).
- Recommended move: freeze new Cockpit surface; run the four proving grounds
  to close or cut; revisit only after Moves 1–3 land.
- Acceptance evidence: PROVING-GROUNDS.md shows 4/4 closed with dated
  evidence, or the app is split to a separate repo.

### F-KCC-11 — The barrier's human-judgment gate is enforced with provenance — and the project demonstrably repairs its own gates

- Type: strength
- Surface: skills | security | method
- Severity: positive
- Confidence: high
- Evidence: `check-consensus-gate.sh:94-160` — same-family adversary
  hard-fails, owner-attributed resolutions required, plan re-hash against
  recorded provenance; CHANGELOG [Unreleased]: the barrier self-pass fix
  (adversary's proposal demoted from `resolution`), the stale-text consent
  fix, plus suite rows flipped from asserting-the-defect to asserting RED.
- Claim: Pass 4 is not ceremonial — its failure modes were found live, fixed
  at the gate level, and pinned by regression rows.
- Why it matters: the barrier is the one place the method's human-in-the-loop
  claim must be mechanical, and it is.
- Falsifier: a path to `CHECK_CONSENSUS=OK` without cross-family attack and
  owner decisions (the suite now asserts none exists).
- Recommended move: publish these three bug narratives; they are the most
  credible marketing the project owns.
- Acceptance evidence: third-party write-ups citing them.

### F-KCC-12 — Documentation volume and ceremony are adoption friction

- Type: market gap
- Surface: docs | distribution | method
- Severity: medium
- Confidence: medium
- Evidence: 1,357-line CHANGELOG; README + blueprint PDF + 4 presentations +
  per-skill references; nine passes before first autonomy; no
  single-command quickstart producing a settled demo task.
- Claim: the fastest path to a believer — "watch one task settle itself in
  your repo in 15 minutes" — does not exist. The docs are excellent *for a
  convert* and forbidding for a skeptic.
- Why it matters: with zero adoption, every minute-to-first-proof multiplies
  churn.
- Falsifier: a timed new-user session reaching `TASK_LOOP=SETTLED` quickly
  (not measured here).
- Recommended move: a `cvg demo` (or `examples/quickstart/` repo) that
  installs, seeds one sealed XS task with a stub or real engine, and settles
  it, end to end, in one command.
- Acceptance evidence: a recorded session: clone → settled task + receipt in
  ≤15 minutes, no edits.

### F-KCC-13 — Concentrated fragility: 1,000-line bash kernel, 2,800-line snapshot, one author

- Type: design risk
- Surface: runtime | CLI
- Severity: low
- Confidence: high
- Evidence: `loop-kernel.sh` (1,024 lines bash 3.2, `set -uo pipefail`
  without `-e` by necessity); `bin/cvg-snapshot.py` (2,833 lines);
  `validate-task-spec.sh` (1,060 lines); git history shows one author.
- Claim: the most safety-critical components are the hardest to change
  safely, and exactly one person carries the context. The extensive suites
  mitigate but do not remove the risk class.
- Why it matters: reliability of the referee is the product; maintainer
  concentration is the top organizational risk to every finding above.
- Falsifier: additional maintainers or a successful refactor of the kernel
  into smaller tested units.
- Recommended move: no rewrite now; extract the kernel's settlement leg and
  budget accounting into separately suiteable units when Move 2 (Manager)
  forces the kernel to change anyway.
- Acceptance evidence: kernel coverage per unit after the first Manager
  milestone; a second committer landing a gated change.

## 10. The Top Three Moves

Exactly three, ordered by dependency and leverage. Together they convert
Converge from "an excellent single-task tool with big claims" into a credible
Autonomous Fabric: **portable proof → fleet autonomy → public belief.**

### Move 1 — Portable Proof: server-side eval gate, mechanical holdout separation, honest seal boundary

- **Problem it solves.** Today every settlement proof is local (F-KCC-07):
  the sealed evals ran on the same machine, often the same session, as the
  worker. The holdout is visible to the worker (F-KCC-02), and the seal's
  strength depends on the worker's harness confinement (F-KCC-03). Any
  security reviewer can currently deflate the strongest claims in an
  afternoon.
- **Why top three.** This is the credibility foundation. The Manager (Move 2)
  without a server-side gate would automate trust in local verdicts; the
  adoption push (Move 3) without it markets claims that don't survive
  inspection. It also fixes the two documentation-vs-implementation gaps a
  skeptic will find first.
- **Users affected.** Every adopter running unattended loops; security
  reviewers evaluating Converge; the author's own credibility.
- **Scope and surfaces.** (a) A GitHub Action / CI template
  (`actions/cvg-eval-gate/` plus docs) that, on any loop-produced PR,
  re-verifies the sign-off HMAC, re-runs the sealed evals server-side from a
  clean checkout, re-checks the path policy, and blocks merge on red — the
  "CI eval-gate" already on the roadmap. (b) Holdout separation in
  `bind-runtime-contract.py` / `context-pack.py` and the loop brief
  (`loop-kernel.sh:851-868`): emit a worker-view spec with `## Holdout`
  elided, record both hashes in the profile, judge reads the sealed original
  (`verify-work.py` unchanged in interface). (c) Worker-confinement
  attestation in `attest-runtime.py` + bind: per-adapter confinement class
  (edit-only vs shell-in-sandbox) recorded in the profile; high-blast-radius
  tasks fail closed when the seal cannot be a boundary unless explicitly
  waived; env-only key resolution option for unattended runs. (d) README
  threat-model paragraph aligning marketing with `SKILL.md`'s honest caveat.
- **Dependencies and sequencing.** None upstream; blocks Move 2's parallel
  settlement and should land before any publicity (Move 3).
- **Estimated effort: L** (the CI gate is new surface; holdout separation
  touches the bind→brief→judge chain; attestation extends an existing
  pattern).
- **Expected impact: 9.**
- **Principal risk.** CI environments differ subtly from local ones
  (shellcheck presence, python availability), producing flaky gates that
  teach users to bypass them — the same failure the local gates guard
  against. Mitigate by making the action hermetic and its failures as
  diagnostic as `cvg doctor host`.
- **30-day outcome.** The eval-gate action runs on Converge's own repo and
  one example consumer; a bound spec's worker view provably excludes the
  holdout (test per F-KCC-02 acceptance); README states the seal's threat
  model.
- **90-day outcome.** Every loop PR in Converge's own history is re-gated
  server-side; tier-2 with true holdout separation is the default for
  high-blast-radius tasks on every lane.
- **Acceptance tests / evidence.** (1) A PR whose checks re-run sealed evals
  and block merge on red — demonstrated on a deliberately weakened eval.
  (2) A stub-engine loop run where the worker's dumped input contains no
  holdout string and the judge's does. (3) `cvg doctor runtime-contract`
  printing per-adapter worker-confinement classes.
- **Estimated score effect: +7** (Trust 7.0→8.5, Autonomy 5.5→6.5,
  Evidence 6.5→7.5, small lifts elsewhere).

### Move 2 — The Manager: fleet dispatch with ordered settlement

- **Problem it solves.** The loop never picks its own task; there is no
  dispatch across the ready frontier, no merge ordering, no parallelism —
  the admitted missing half of the product (F-KCC-07) and the difference
  between "tool" and "fabric."
- **Why top three.** It is the only move that makes "Autonomous Fabric"
  literally true, and it compounds Move 1: server-gated settlement is what
  makes parallel autonomy safe. Deferring it further cedes the fleet layer to
  Gas Town/Beads and OpenHands Canvas, which scale activity without proof —
  Converge's entry is *fleet with proof*.
- **Users affected.** Teams with backlogs larger than one task; CI/CD owners;
  the future self of the project (its own backlog is the demo).
- **Scope and surfaces.** New `skills/fleet-manager/` (or
  `skills/task-loop/scripts/manager.sh` + `cvg fleet`): consume `cvg ready`
  (dependency-aware frontier), dispatch N loops into per-task worktrees with
  per-task budgets and a global token ceiling, serialize settlement through
  the Move-1 server gate, order merges topologically, write a fleet receipt
  per wave into `cvg/receipts/`. Deliberately small: no scheduling
  intelligence beyond the DAG, no retry policy beyond the loop's own, no UI —
  Cockpit reads the receipts it already snapshots.
- **Dependencies and sequencing.** After Move 1 (server gate) so parallel
  settlement has a trusted merge gate; before any Cockpit write-path dreams.
- **Estimated effort: XL** (new component class; concurrency, failure
  isolation, receipt semantics — though each dispatched loop is the proven
  single-task kernel).
- **Expected impact: 9.**
- **Principal risk.** Scope creep into a full orchestrator (Beads territory)
  and the loss of the simplicity that makes the loop auditable. The
  mitigation is the project's own doctrine: the Manager schedules; the gates
  score.
- **30-day outcome.** Serial Manager MVP: dispatches the ready frontier one
  task at a time, unattended, with receipts — self-hosted on Converge's own
  backlog.
- **90-day outcome.** Bounded parallelism (N=2–4), wave receipts, one
  external repo running it in public.
- **Acceptance tests / evidence.** A hermetic suite with stub engines:
  three-task DAG, two parallel, settlement order respects `depends_on`, a
  mid-wave STALL does not block independent tasks, every wave emits receipts
  and a single `FLEET=SETTLED|PARTIAL|HALTED` token. Public artifact: a
  merged PR series produced by a recorded unattended wave.
- **Estimated score effect: +6** (Autonomy 5.5→8.0, Differentiation 5.5→6.5,
  Thesis 7.5→8.0).

### Move 3 — Public Belief: the evidence program and the 15-minute first settle

- **Problem it solves.** Zero adoption (F-KCC-06), dark CI badge (F-KCC-04),
  strongest claims unshipped (F-KCC-05), and no fast path to first proof
  (F-KCC-12). Nothing about the code fixes these.
- **Why top three.** Capability is not the binding constraint — belief is.
  The market window for "the verification layer" is open now; whoever shows
  reproducible proof first owns the position. This move is also the cheapest
  of the three and de-risks the other two by creating external observers.
- **Users affected.** Every prospective adopter; the author's distribution
  problem; future contributors (a second maintainer is the top
  organizational need, F-KCC-13).
- **Scope and surfaces.** (a) Fix the Actions billing today; add a weekly
  scheduled CI run. (b) `evidence/` directory or linked public repo: the
  sealed specs and receipts behind the nine settled tasks, the REFUTED
  verdict with its diff and judge output, a dated rerun of
  `uc-01-analytics-engineering` (and closure or honest cut of the other
  proving grounds). (c) `examples/quickstart/` — a self-contained demo repo
  plus `cvg demo` that installs, seeds one sealed XS task, runs the loop
  (stub engine offline; real engine if signed in), and settles with a
  receipt, ≤15 minutes. (d) Publish the three barrier-bug narratives
  (F-KCC-11) as the credibility campaign they already are.
- **Dependencies and sequencing.** Starts immediately (billing, evidence);
  the demo lands after Move 1 so the public path includes the server gate;
  the big push after Move 2's MVP so the story includes the fabric.
- **Estimated effort: M.**
- **Expected impact: 8.**
- **Principal risk.** Marketing before the proof is portable (Move 1)
  invites the exact takedown this review's F-KCC-02/03 prefigures. Sequence
  discipline is the mitigation.
- **30-day outcome.** Badge green; evidence repo linked from README; one
  third party runs the quickstart and reports publicly.
- **90-day outcome.** ≥3 external repos running gated loops in public; ≥100
  stars; one independent reproduction write-up; a second committer.
- **Acceptance tests / evidence.** Dated artifacts a stranger can inspect
  for every live claim; a timed external quickstart session; the star/fork
  counts above as the market's own telemetry.
- **Estimated score effect: +5** (Evidence 6.5→8.5, Differentiation 5.5→7.0,
  DX 6.0→7.0).

*Projected overall after all three moves: ≈ 85/100 — the boundary between
"interesting" and "distinct."*

## 11. Suggested 30/60/90-Day Sequence

**Days 0–30 — stop the bleeding, close the honesty gaps.**
Fix Actions billing (badge green same day). Ship the holdout elision in bind
+ worker brief (F-KCC-02). Add worker-confinement attestation and the README
threat-model paragraph (F-KCC-03). Publish `evidence/` with the settled-task
receipts and the REFUTED artifact (F-KCC-05). Freeze new Cockpit surface and
rerun uc-01 (F-KCC-10). Resolve the four-vs-three harness parity by doc
qualification or a Grok adapter (F-KCC-09).

**Days 31–60 — make proof portable.**
Ship the CI eval-gate action; re-gate Converge's own merged PRs retroactively
as the demo. Default tier-2 ON for high blast radius on all lanes. Land the
quickstart demo repo + `cvg demo`. Begin Manager MVP (serial dispatch from
`cvg ready`, per-task receipts, `FLEET=` token). Recruit the first external
pilot repo.

**Days 61–90 — open the fabric.**
Manager bounded parallelism + wave receipts + topological merge order against
the server gate. Close all four Cockpit proving grounds or split the app out.
Two more external pilots; the barrier-bug narrative posts; v0.2.0 cut with
the Manager headline. Target telemetry: ≥3 external repos, ≥100 stars, first
outside committer.

## 12. What Should Not Be Built Yet

- **Cockpit write paths or execution from the UI.** The observation boundary
  is the Cockpit's only defensible property; the autonomy it would drive
  doesn't exist yet (Move 2), and its proving grounds are open (F-KCC-10).
- **More engine adapters (Grok/Gemini workers) before proof.** Adapter count
  is not the gap; belief is. Qualify the docs instead (F-KCC-09).
- **A hosted/SaaS control plane.** No evidence of demand (zero users), and it
  would inherit the liability of holding others' credentials — the precise
  thing the referee architecture exists to avoid.
- **Multi-repo / monorepo orchestration and the "Wasteland"-style
  federation.** The single-repo fabric is unproven; federation is Gas Town's
  occupied terrain.
- **Cost prediction beyond the ceiling.** The kernel's
  `ESTIMATE=CEILING` stance is honest; engines under-report usage, so
  predictive budgets would be invented numbers — against the project's own
  doctrine.
- **Rewriting the bash kernel in a "real" language.** The fragility is real
  (F-KCC-13) but the suites are the mitigation that exists; a rewrite now
  stalls Moves 1–3 for purity. Extract units when the Manager forces the
  change.

## 13. Open Questions and Falsifiers

1. **Does holdout visibility matter in practice?** Falsifier: telemetry or a
   controlled run showing real workers do not use `## Holdout` content even
   when present. My prior: they do — it is in-context, labeled, and
   reward-relevant. Move 1(b) settles it structurally regardless.
2. **Is the seal ever attacked by a real worker?** Falsifier: logs from a
   honeypot loop (a canary eval and a watched key) showing no worker attempts
   re-sealing. Worth running once the Manager exists.
3. **Will teams author evals-first?** The whole method's cost of entry.
   Falsifier: pilot data showing eval authoring time dominates task time
   without quality payoff; if so, the FAST lane and `tasks plan` need to
   absorb that cost, or the method stays boutique.
4. **Is "referee" a category buyers recognize?** Falsifier: pilot users
   describing Converge as "CI for agents" (a crowded, commoditizing frame)
   rather than acceptance infrastructure. Positioning research, not code,
   answers this.
5. **Can one maintainer sustain the gate quality bar?** Falsifier: a second
   committer landing a gated change within 90 days. Without one, every score
   in §8 decays.
6. **Was the REFUTED verdict as decisive as reported?** Falsifier: the
   shipped artifact (Move 3) — if the fail-open bug would have been caught by
   ordinary review anyway, the tier-2 story weakens.
7. **Does the cross-family judge add signal beyond a stronger same-family
   prompt?** Falsifier: an A/B over settled tasks where same-family judges
   catch what cross-family catches. The design assumes family-correlated
   blind spots; it has never been measured here.

## 14. Sources

Repository evidence is cited inline as `path:line`. External sources (all
retrieved 2026-08-06 UTC):

1. GitHub REST API — repo stats for `luanmorenommaciel/converge`,
   `github/spec-kit`, `All-Hands-AI/OpenHands`, `strongdm/attractor`,
   `gastownhall/gastown`, `gastownhall/beads` (via `gh api`, star/fork counts
   as of retrieval): <https://github.com/luanmorenommaciel/converge>,
   <https://github.com/github/spec-kit>, <https://github.com/All-Hands-AI/OpenHands>,
   <https://github.com/strongdm/attractor>, <https://github.com/gastownhall/gastown>,
   <https://github.com/gastownhall/beads>
2. GitHub Actions run 30960115138 (job annotations: billing/spending-limit
   failure) and run list for `ci.yml` (via `gh run list/view`):
   <https://github.com/luanmorenommaciel/converge/actions/runs/30960115138>
3. Merged PR list for the self-hosting claim (via `gh pr list --state merged`):
   <https://github.com/luanmorenommaciel/converge/pulls?q=is%3Apr+is%3Amerged>
4. What Is Spec-Driven Development? A 2026 Guide — Shiplight (Spec Kit
   mechanism, market context): <https://www.shiplight.ai/blog/what-is-spec-driven-development>
5. Kiro product page (executable specs, automated reasoning, property-based
   tests, parallel agents): <https://kiro.dev/>
6. AWS Kiro launch guide (GA May 2026, pricing tiers, Q Developer succession):
   <https://pingax.com/kiro-aws-launch-announcement/>
7. Kiro review — AI Agent Square (pricing $20–$200/user/mo):
   <https://aiagentsquare.com/agents/kiro>
8. Devin product site (Nubank case study: 8–12x efficiency, 20x cost
   savings): <https://devin.ai/>
9. Windsurf→Devin Desktop rebrand explainer (June 2026 rename; acquisition
   saga): <https://vynula.com/windsurf-ai-explained/>
10. Simon Willison — "How StrongDM's AI team build serious software without
    even looking at the code" (dark factory, DTU, holdouts):
    <https://simonwillison.net/2026/Feb/7/software-factory/>
11. Ry Walker Research — StrongDM Software Factory analysis:
    <https://rywalker.com/research/strongdm-factory>
12. Ry Walker Research — Gastown analysis (20–30 parallel agents, Beads):
    <https://rywalker.com/research/gastown>
13. OpenHands vs OpenClaw comparison (OpenHands ~80k stars, Agent Canvas June
    2026 relaunch driving Claude Code/Codex/Gemini via ACP — secondary):
    <https://openclawlaunch.com/compare/openhands>
14. Kiro vs Antigravity comparison (Antigravity Manager View, artifacts —
    secondary): <https://www.augmentcode.com/tools/kiro-vs-antigravity>
15. Agent control plane comparison (Microsoft Agent 365 et al. — secondary):
    <https://contro1.com/compare/best-ai-agent-control-plane-tools>
16. Agent observability tools guide (LangSmith Fleet — secondary):
    <https://montecarlo.ai/blog-agent-observability-tools>
17. BenchLM — SWE-bench Verified leaderboard snapshot (2026-08-05; top scores
    mid-90s; aggregator, directional only):
    <https://benchlm.ai/benchmarks/swe-bench-verified>

No traffic, revenue, funding, pricing, benchmark, or adoption figures are
asserted beyond what these URLs state; vendor-published case numbers (Devin,
Kiro) are attributed to their sources, not endorsed.

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "kimi-code-cli",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 67.8,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Interesting",
  "evidence_confidence": "Medium",
  "adopt_today": "conditional",
  "top_strength": "The sealed, self-verifying Task-Spec trust chain — evals-first, HMAC-sealed, hash-pinned, re-verified before every loop iteration — independently reproduced and working exactly as documented",
  "top_risk": "Autonomy and trust claims outrun the shipped ceiling: the holdout is visible to the worker, the signing key is worker-readable, settlement trust is local-only, and external adoption is zero",
  "top_3": [
    {
      "rank": 1,
      "name": "Portable Proof: server-side eval gate + holdout separation + honest seal boundary",
      "effort": "L",
      "impact": 9,
      "score_delta": 7.0
    },
    {
      "rank": 2,
      "name": "The Manager: fleet dispatch with ordered, server-gated settlement",
      "effort": "XL",
      "impact": 9,
      "score_delta": 6.0
    },
    {
      "rank": 3,
      "name": "Public Belief: evidence program + 15-minute first settle",
      "effort": "M",
      "impact": 8,
      "score_delta": 5.0
    }
  ],
  "critical_finding_ids": ["F-KCC-02", "F-KCC-03", "F-KCC-07"],
  "tests_run": {
    "passed": 32,
    "failed": 0,
    "blocked": 2
  },
  "external_sources": 17
}
```
