# Converge Independent Review — fable

## 1. Review Metadata

- **Reviewer/model identifier:** Claude Fable 5 (`claude-fable-5`), Anthropic — reviewer id `fable`
- **Reasoning mode:** extended reasoning, autonomous session (no human in the loop during the review)
- **Review timestamp:** 2026-08-05, ~22:15–23:30 America/Sao_Paulo (UTC−3)
- **Git HEAD:** `9c966884e37919c0f7e4c3e027b4b237670eb2ad` — `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi` (2026-08-04)
- **Branch:** `feat/e2e` (not detached)
- **Worktree state at start:** dirty — pre-existing: `M apps/cockpit/package-lock.json`, deletions of `review/deepseek.md`, `review/grok.md`, `review/kimi.md`. None of these were introduced or altered by this review.
- **Tools available:** full local filesystem read, bash execution (tests run locally on macOS, Darwin 25.5.0, repo-shipped suites only, no dependency installs, no model APIs invoked), and live web search/fetch for market research. `MARKET_RESEARCH=COMPLETE`.
- **Independence disclosure:** no file under `review/` was opened. One repo-wide `grep` for the phrase "autonomous fabric" incidentally surfaced a few matching lines from `review/glm.md` (a file created by a concurrent reviewer after this review began). Those lines were discarded; every finding, score, and conclusion below was derived from direct inspection performed before that grep, and the grep result confirmed only one fact used here: the phrase "Autonomous Fabric" does not occur in any of Converge's own files.
- **No source, documentation, test, configuration, Git state, or `.cvg` file was modified.** The only file created is this one.

## 2. Executive Verdict

**Overall score: 65.5 / 100.**

**Does Converge stand out today?** In mechanism, yes; in market presence, not at all. The specific combination it ships — HMAC-sealed task specs whose completion is decided by pre-authored runnable evals, a bounded attempt→verify→repeat loop with eight named terminal states, and a cross-family adversarial judge that has actually refuted real green-eval work — is not offered as a coherent unit by any of the eight alternatives examined (Section 6). But the repository is **private** (the GitHub URL returns 404), so every one of its three documented install paths fails for any external user, its CI badge resolves to nothing, and its adoption is zero. A differentiated product nobody can install does not stand out in a market; it stands out in a lab.

**Strongest defensible advantage:** settlement is a state-machine invariant enforced outside the worker's authority, and the project has honest, dated evidence of the mechanism working in both directions — including one REFUTED verdict (`obs-fence`, 2026-07-29) where a cross-family judge caught a fail-open bug that green evals could not see, and the kernel refused settlement. I verified the enforcement machinery locally: 128 hermetic checks across four suites, all green.

**Most dangerous weakness:** the gap between the trust language and the trust boundary. The "holdout the builder never saw" lives in the same spec file the worker is explicitly pointed at; the signing key is readable by the worker in most engine configurations; the tier-2 judge is prompt-injectable through the diff it grades. The skill documentation states the honest version ("tamper-evident, not tamper-proof"); the README markets the strong version. For a project whose entire thesis is *proof over claim*, overstating enforcement is the one unforgivable defect class.

**Would I adopt it today?** Conditionally — only if I (a) had access to the private repo, (b) ran at least two engine CLIs from different vendors already, and (c) scoped it to low-blast-radius tasks where the postflight guard model is acceptable. For anyone else the answer is no, for the trivial reason that they cannot install it. The condition for a general "yes" is the top move in Section 10: make the proof public and reproducible.

## 3. What Converge Actually Is

Converge is best described as **a methodology plus a referee CLI plus twelve harness-portable skills plus an observability app**, in that order of maturity:

1. **A methodology** (verified as documents + gates): a nine-pass "descent" from raw idea to settled task, with a mandatory cross-family adversarial review (Pass 4, "the barrier") and a human sign-off. Lane routing (`cvg lane`, deterministic and offline — verified by running it) lets small changes skip ceremony but never signing.
2. **A referee CLI** (verified as running code): `bin/cvg`, ~2,700 lines of bash 3.2-safe router over per-skill scripts, holding zero model credentials, exposing 52 commands with machine tokens, a uniform `--json` envelope, and an `agent-context` self-description manifest (all three probed directly and behaving as documented).
3. **An execution runtime** (verified): `loop-kernel.sh` (1,024 lines) runs attempt→verify→repeat with three-axis budgets, a stagnation detector, checkpoint/resume, capability-scoped staging, and receipts written last. This is a real runtime, not schema decoration — the budgets and terminal states are enforced in code paths I traced and exercised via the hermetic suite (57/57 checks).
4. **A verification layer** (verified with caveats): HMAC v2 sign-off envelope sealing eval bodies *and* authorization fields (`_lib.sh:773`), a tracked repo write fence (`.cvg/gate.yaml`), and a fail-closed tier-2 cross-family judge (`verify-work.py`). The caveats are Findings F-02, F-03, F-04.
5. **A Cockpit** (inspected, not fully verified): a React/ACP observation app whose read path is exactly one CLI command (`cvg snapshot --json`), loopback-bound, with SHA-256-bound artifact previews and a carefully constrained "Ask" interpretation path. Explicitly excluded from the shipped package. Its browser test suite was not run here (dependency installation was out of scope for this review).

It is **not** an autonomous fleet: dispatch across ready tasks (the "Manager") and server-side re-verification (the CI eval-gate) are explicitly absent, and the README says so. Converge today is one production cell with excellent brakes, not a factory.

**Who is the clearest user?** A senior engineer or small team already running two or more coding-agent CLIs (Claude Code, Codex, Kimi), delegating real backlog items, and burned at least once by an agent that claimed done. That user profile is currently a population of exactly one: the author.

## 4. Repository and Test Coverage

- 244 commits since 2026-07-01 (~5 weeks). Contributors: one human (245 commits across two identities), dependabot (3), "Claude" (2). **Bus factor: 1.**
- CI (`.github/workflows/ci.yml`) runs a two-OS matrix (ubuntu, macos — deliberately covering bash 3.2/BSD userland) with ShellCheck, per-skill validation, ~21 hermetic suites, an npm-pack surface check, and a meta-gate (`test-ci-covers-every-suite.sh`) that fails the build if a suite exists but is not wired in. Credential-free by design. This is a genuinely strong CI design for a bash project.
- **Suites executed by this reviewer** (exact commands, local macOS, 2026-08-05):
  - `bash tests/test-version-unity.sh` → **PASS**, 12/12, `VERSION_UNITY=PASS`
  - `bash skills/task-spec/tests/test-hmac-envelope.sh` → **PASS**, 38/38
  - `bash tests/test-loop-kernel.sh` → **PASS**, 57/57 (budgets, stagnation, exhaustion, resume, cancel, no-op, tracker authority)
  - `bash tests/test-clean-room-install-e2e.sh` → **PASS**, 21/21, `CLEAN_ROOM_E2E=PASS` (empty repo → install → init → sign → bind → RED→GREEN stub loop → acceptance → receipt hash chain)
  - Probes: `bin/cvg version` (0.1.0), `bin/cvg agent-context` (valid JSON, 52 commands, exit-code taxonomy), `bin/cvg lane "add a health endpoint"` (`LANE=NORMAL`, deterministic, offline) — all as documented.
- **Not run:** Cockpit browser/accessibility tests (`npm ci` + Playwright install are dependency installations, out of scope). CI claims they run on ubuntu; unverified here. 1 suite blocked.
- **Caveat that cannot be waived:** the CI badge and "CI is public and green" claim (`README.md:381`) are externally unverifiable because the repository is private (Section 5, F-01). Everything above is *my local reproduction*, which is exactly the kind of evidence the project should be able to point outsiders to and currently cannot.

## 5. Claim-to-Evidence Audit

| Claim (documented) | Verdict | Evidence |
|---|---|---|
| "The eval decides done — completion is a state-machine invariant" | **Verified** | `loop-kernel.sh` terminal-state machine; only SETTLED/LOCAL_SETTLED/NO_OP exit 0; 57 hermetic checks pass locally; stub-attack fixtures (`tests/fixtures/T-*-fake-envelope.md` etc.) in the HMAC suite |
| "A loop with brakes: three-axis budgets, stagnation, 8 terminal states" | **Verified** | `loop-kernel.sh:249–296` (spec budgets, `tighter()` — flags can only lower ceilings), `:828–840` (exhaustion landings); suite green |
| "Editing an eval breaks the seal" | **Verified as tamper-evidence** | HMAC v2 payload covers body digest + authorization fields (`_lib.sh:773–831`); injection-safe frontmatter writer (`_lib.sh:684`); 38/38 suite. **But** see F-03: the key is repo-shared and worker-readable; `task-spec/SKILL.md:559` honestly says "tamper-evident, not tamper-proof… not a security boundary" while `README.md:427–430` implies stronger |
| "Holdout criteria the builder never saw" | **Claim gap** | The worker's brief names the Task-Spec as "the only instruction source" (`loop-kernel.sh:854`); `## Holdout` lives in that same file (`task-spec/SKILL.md:564`; `verify-work.py:75–77` reads it from the spec body). Secrecy is an instruction, not an enforcement (F-02) |
| "Cross-family verification proven live in both directions" | **Verified in git history** | CHANGELOG `Proven` section (dated 2026-07-29): `obs-rowcounts` UPHELD → PR #9 (merge `bbdb788` confirmed in history); `obs-fence` REFUTED → BLOCKED. Commits `46601b2`, `ed87eb0`, `a3e7885` exist. **But** the proving ground was removed from the tree; receipts require archaeology (F-07) |
| "Referee holds zero model credentials, never writes product code" | **Verified** | `bin/cvg` contains no API calls; engine adapters shell out to vendor CLIs that self-authenticate; `verify-work.py:191` dispatches installed CLIs only |
| "Works with Claude Code · Codex · Kimi · Grok Build" | **Partially verified** | Three engine adapters exist (`skills/task-loop/scripts/engines/`), one file each as claimed; Grok Build has no loop adapter — its support is skills-discovery only. Cross-vendor loop execution is proven in history, not reproducible by an outsider today |
| "Three install doors" (marketplace / npm github: / curl one-liner) | **Contradicted today** | All three resolve to `github.com/luanmorenommaciel/converge`, which returns **404** (retrieved 2026-08-05). No public release, no public marketplace entry (F-01) |
| "CI is public and green on macOS and Linux" | **Unverifiable externally** | Workflow file is real and well-built; the public half of the claim fails while the repo is private |
| "Nine tasks settled through merged PRs, one fully unattended" | **Corroborated in history** | Merged PRs #2–#9 from `task/*` branches visible in `git log --merges`; CHANGELOG documents 9/9 sweep with 2 LOCAL_SETTLED + 7 SETTLED, and honestly documents the ninth task's post-hoc receipt |
| Codex sandbox = "prevented" capability; others "detected" | **Verified as honest design** | `engines/codex.sh:4–8` records OS-level confinement; `claude.sh` uses `acceptEdits` with postflight guard; the envelope's assurance field distinguishes them. The distinction is real and documented (partially mitigates F-03) |

## 6. Market Landscape

All retrievals 2026-08-05. Eight alternatives across the required areas; none was selected for fame alone — each occupies a seat Converge claims or borders.

| Product | Primary user / use case | Unit of autonomy | Spec/planning model | Verification & acceptance | Portability | Boundary | Observability | Adoption cost | Maturity signal | Converge advantage | Converge disadvantage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **GitHub Copilot coding agent / Agent HQ** ([press release](https://github.com/newsroom/press-releases/coding-agent-for-github-copilot); [2026 guide](https://baeseokjae.github.io/posts/github-copilot-coding-agent-guide-2026/)) | Any GitHub team; issue→PR | One issue → one PR in Actions sandbox | Issue + AGENTS.md; no signed spec | CI checks, CodeQL, human PR review; can drive CI to green | Copilot models only | Actions sandbox (strong, cloud) | PR trail, session logs | Near zero for GitHub orgs | ~90% of Fortune 100 use Copilot (secondary claim) | Pre-authored sealed evals + cross-family refutation; engine choice | Distribution, sandbox depth, zero-setup — all vastly stronger on Copilot's side |
| **OpenHands** ([repo](https://github.com/All-Hands-AI/OpenHands)) | OSS/self-hosting teams; autonomous SWE | Conversation/task in Docker sandbox | Freeform; no signed unit | Its own tests + human review; no adversarial second model built in | Any LLM; runs Claude Code/Codex/Gemini via ACP | Docker filesystem isolation | Session traces, REST server | Moderate (Docker, keys) | ~83.2k stars, MIT | Deterministic settlement contract; verification outside the agent | Community two orders of magnitude larger; real sandbox by default |
| **Devin (Cognition)** ([comparison, vendor-adjacent](https://www.openhands.dev/blog/devin-ai-alternatives)) | Teams buying hands-off delivery | Ticket → PR, cloud-managed | Internal planning; opaque | Own tests + human review | Closed; no model choice | Vendor cloud | Session replay | Low setup, ACU billing (~$20 self-serve entry) | Commercial, established | Open method, inspectable referee, no vendor trust required | Polish, integrations, funded go-to-market |
| **GitHub Spec Kit** ([repo](https://github.com/github/spec-kit)) | Any agent user; spec-first workflow | None — it structures, agents execute | Constitution→Specify→Plan→Tasks→Implement→Converge | Checklists/agent judgment; **no runtime gate, no signing** | 30+ agents (broadest) | None (docs only) | Markdown artifacts | Very low | **~125.5k stars**, MIT | Converge *enforces* what Spec Kit only writes down: seals, budgets, refutation | Spec Kit owns the mindshare and the word "Converge" is literally its phase 6 |
| **Amazon Kiro** ([site](https://kiro.dev)) | Product teams in an agentic IDE | Spec→sequenced tasks→parallel agents | requirements.md / design.md / tasks.md (EARS) | Property-based testing "beyond unit tests"; human review | AWS-hosted models | AWS cloud | IDE surfaces | Low; credit pricing | GA, AWS-operated | Harness-independence; referee holds no keys; local-first | AWS scale, IDE UX, property-testing investment |
| **Conductor** ([site](https://conductor.build)) | Mac devs running parallel agents | N parallel agents in git worktrees | None — task text | Human diff review | Claude Code, Codex, Cursor | Worktree isolation | Dashboard, diff-first UI | Very low | Commercial, v0.79 | Acceptance is *machine-decided* in Converge vs eyeballed diffs | Conductor is installable today and solves the parallelism Converge defers |
| **promptfoo** ([repo](https://github.com/promptfoo/promptfoo)) | LLM app teams; evals/red-team in CI | None — evaluation harness | Test-case configs | Assertions + LLM-as-judge in CI | Any model | N/A | Eval reports | Low | ~24k stars; "10M+ users in production" apps | Converge binds evals to *delivery settlement*, not app QA | promptfoo's judge tooling is hardened/battle-tested; Converge's judge is bespoke (F-04) |
| **AGENTS.md / Agent Skills ecosystem** ([agents.md](https://agents.md)) | Every agent vendor | N/A — a portability standard | Freeform conventions | None | Universal (60k+ projects; Linux Foundation stewarded) | N/A | N/A | Trivial | Industry standard | Converge builds *on* it (skills land in `.agents/skills/`) | The standard commoditizes the portability half of Converge's pitch |

Context signals: spec-driven development is on the Thoughtworks Radar as an industry technique ([Thoughtworks](https://www.thoughtworks.com/en-us/radar/techniques/spec-driven-development)); multi-agent orchestration is an acknowledged, crowded 2026 category ([Addy Osmani](https://addyosmani.com/blog/code-agent-orchestra/); [Tembo](https://www.tembo.io/blog/ai-agent-orchestration-tools)).

## 7. Competitive Position

**What is genuinely differentiated (verified in code, absent from all eight alternatives as a unit):**

1. **Settlement outside the worker's authority.** No surveyed tool makes "done" a cryptographically-sealed, pre-authored, machine-run contract whose failure modes are named terminal states. Copilot drives CI green but the tests are whatever the repo has; Spec Kit and Kiro structure intent but don't referee it; orchestrators leave acceptance to humans.
2. **Cross-family adversarial refutation wired into settlement**, with a documented live REFUTED verdict blocking settlement of green-eval work. promptfoo has LLM-as-judge for app QA; nobody wires a different-vendor judge with (intended) holdouts into *delivery*.
3. **Referee-holds-no-keys engine portability.** One adapter file per engine; the same signed spec dispatches to Claude/Codex/Kimi; assurance level (prevented vs detected) recorded per engine.

**What is table stakes dressed well:** spec-driven passes (Spec Kit, Kiro), skills portability (AGENTS.md ecosystem), worktree isolation (every orchestrator), machine-readable CLI output, observability dashboards (Cockpit's category is crowded).

**Does it deliver autonomy?** Mostly it delivers *accountability around externally-operated autonomy* — which is the more defensible half. The loop is real bounded autonomy for one task; the fleet, scheduling, and organizational surface are absent by declared design.

**Is "Autonomous Fabric" accurate and ownable?** The phrase appears nowhere in Converge's own repository — its actual positioning is "dark factory" / "compile intent into shipped software." As a category hypothesis: "fabric" implies a woven, always-on substrate spanning agents, repos, and CI. Converge today is a single-threaded loom. The term is not yet accurate; it is *ownable only through the two missing pieces* (fleet dispatch + CI-side re-verification), and it collides semantically with established "data fabric"/"service fabric" usage. The honest, currently-defensible position is narrower and better: **the settlement layer for coding agents** — the referee that decides done, whoever the players are. Inference, clearly labeled: I would not lead with "Autonomous Fabric" until the CI eval-gate exists.

**Strongest reason to adopt:** you get an enforcement layer no vendor ships, with no vendor lock, and the evidence culture to trust it.
**Strongest reason not to adopt:** you can't — the repo is private; and if you could, the trust boundary is honest only in the fine print (F-02/03/04), the ceremony is heavy, and one person maintains all of it.

## 8. Scorecard

| Dimension | Weight | Score | Weighted points |
|---|---:|---:|---:|
| Problem and product thesis | 10% | 8.0 | 8.00 |
| Differentiation and market position | 15% | 6.5 | 9.75 |
| Method and architecture coherence | 15% | 8.0 | 12.00 |
| Trust, verification, and security model | 20% | 6.5 | 13.00 |
| Implementation quality and reliability | 15% | 7.5 | 11.25 |
| Autonomous end-to-end completeness | 10% | 5.5 | 5.50 |
| Developer experience and adoption readiness | 10% | 3.5 | 3.50 |
| Evidence, credibility, and project maturity | 5% | 5.0 | 2.50 |
| **Overall** | **100%** | | **65.5 / 100 (6.6/10)** |

Arithmetic check: 8.00+9.75+12.00+13.00+11.25+5.50+3.50+2.50 = 65.50. ✓

Notes on the two most contested scores: *Trust (6.5)* — the enforcement that exists is above-average and honestly layered (prevented vs detected assurance), but three high findings target exactly this dimension's claims. *DX/adoption (3.5)* — the CLI's agent-facing DX is excellent (`next`, `doctor`, `agent-context`, `--json`), but a product with zero working install paths for outsiders cannot score adoption-ready.

- **Vision potential:** High
- **Current readiness:** Alpha
- **Market position:** Distinct (in mechanism; invisible in presence)
- **Evidence confidence:** Medium

## 9. Prioritized Findings

### F-fable-01 — The repository is private: every install door and every public-evidence claim fails
- Type: verified defect
- Surface: distribution
- Severity: critical
- Confidence: high
- Evidence: `README.md:106–127` (three install doors, all resolving to `github.com/luanmorenommaciel/converge`); https://github.com/luanmorenommaciel/converge → HTTP 404 (retrieved 2026-08-05); the owner's public profile lists no `converge` repo; local `git remote` confirms the same URL is the push target, so the repo exists but is not public
- Claim: no external user can install Converge by any documented path, verify the CI badge, or reproduce any claim; adoption readiness is zero regardless of product quality
- Why it matters: the project's thesis is *proof over claim* — while private, every README claim is unfalsifiable to its audience, which inverts the brand
- Falsifier: the URL serving a public repo with a tagged release and green public CI
- Recommended move: Section 10, Move 1
- Acceptance evidence: `curl -fsSL https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh | bash` succeeding on a machine that has never seen the repo; public Actions run green at the release tag

### F-fable-02 — "Holdout the builder never saw" is not enforced: the worker is pointed at the file containing it
- Type: claim gap
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `loop-kernel.sh:854` (brief: "Task-Spec (the only instruction source): <path>"); `skills/task-spec/SKILL.md:564–572` (`## Holdout` lives in the spec body); `verify-work.py:75–77` (`section(body, "Holdout")` reads the same file); no redaction exists at bind, brief, or dispatch (grep across `task-to-runtime-contract` and `task-loop` confirms)
- Claim: holdout secrecy rests on an instruction to the worker ("You may NOT edit the Task-Spec"), which restricts *editing*, not *reading*; a worker that reads its own spec — the designed behavior — reads the holdout, so tier-2 grades against criteria the builder could tune to
- Why it matters: train/test separation is the project's flagship anti-reward-hacking mechanism and README language ("criteria the builder never saw", `README.md:54–56`) states it as fact
- Falsifier: a redaction step in the dispatch path, or holdouts stored outside the worker-visible tree, that I failed to find
- Recommended move: Section 10, Move 2 (sealed holdout sidecar)
- Acceptance evidence: a test that greps every byte the worker's brief and workdir expose and asserts the holdout text is absent; the REFUTED proving-ground case re-run under the new mechanism

### F-fable-03 — The seal's threat model is honest in the fine print and oversold at the front door
- Type: claim gap
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `skills/task-spec/SKILL.md:559–562` ("tamper-evident, not tamper-proof… a drift/accidental-edit guard, not a security boundary"); `README.md:427–430` ("If an agent edits an eval… the seal breaks and the gate refuses… the only path to autonomy is through the gate"); key location `_lib.sh:601–638` (`.git/info/taskspec-signing-key`, inside the workspace a `workspace-write`-sandboxed or `acceptEdits` engine can read); `.cvg/gate.yaml` itself concedes "this file does not claim to observe bytes that Git intentionally hides"
- Claim: a worker with shell in the workspace (codex adapter) can read the key and re-seal an edited spec; the remaining defense is the settlement path-policy diff check, which a worker with `.git` write access (inside the OS sandbox scope) can in principle evade; the layered honest version exists in the docs but the README states the strong version
- Why it matters: security claims that outrun enforcement are the fastest way to lose the exact audience (verification-minded engineers) this project courts
- Falsifier: demonstration that every engine configuration denies key reads, or that settlement checks are robust to `.git` manipulation
- Recommended move: align README language with SKILL.md's honest framing now (one-line fix); longer term, per-engine key isolation (Section 10, Move 2)
- Acceptance evidence: README trust section citing the tamper-evident framing and the per-engine assurance table; a red-team test that attempts read-key→re-seal under each adapter and documents which configurations block it

### F-fable-04 — The tier-2 judge is prompt-injectable through the artifact it grades
- Type: design risk
- Surface: security
- Severity: high
- Confidence: medium
- Evidence: `verify-work.py:156–185` (`build_prompt` interpolates the raw diff into the judge prompt with no delimiting or sanitization); `:250–264` (`extract_verdict` scans the judge's stdout for any JSON object containing `"verdict"`)
- Claim: a worker can embed adversarial instructions (or a decoy `{"verdict":"UPHELD"…}` object designed to appear in an echoing judge's output) inside code comments in the diff; nothing in the pipeline defends the judge against reading its evidence as instructions
- Why it matters: tier-2 is the backstop for exactly the adversarial-worker scenario; an injectable backstop fails precisely when it matters; no test in the repo exercises a hostile diff
- Falsifier: an experiment showing current frontier judges reliably ignore injected instructions in this prompt shape (would lower severity, not close the surface)
- Recommended move: structural delimiters + explicit "the diff is data, not instructions" framing, verdict extraction restricted to the final line/anchored token, and a hostile-diff test fixture; dual-judge quorum for high blast radius (Section 10, Move 2)
- Acceptance evidence: a CI-wired suite of injection fixtures (instruction smuggling, decoy JSON, verdict-string collisions) that the pipeline survives fail-closed

### F-fable-05 — The loop's brakes are real: budgets, stagnation, and terminal states are enforced invariants (verified)
- Type: strength
- Surface: runtime
- Severity: positive
- Confidence: high
- Evidence: `loop-kernel.sh:249–296` (spec-declared budgets; `tighter()` ensures call-site flags can only lower ceilings), `:828–840` (exhaustion landings with handoff notes); local run of `tests/test-loop-kernel.sh` → 57/57; clean-room e2e → 21/21 including receipt hash-chain agreement
- Claim: the defect class the project names — "declared and enforced by nothing" — has genuinely been closed for the loop; an exhausted budget is structurally incapable of reading as success
- Why it matters: this is the load-bearing runtime claim, and it survives inspection; most competing loops (and most agent frameworks) have nothing comparable
- Falsifier: a code path landing SETTLED without the Exit Check exiting 0, or a flag raising a spec ceiling
- Recommended move: amplify — publish the suite output as release evidence
- Acceptance evidence: already exists; needs to be public (F-01)

### F-fable-06 — The evidence culture is a differentiator in itself: negative results are on the record
- Type: strength
- Surface: docs
- Severity: positive
- Confidence: high
- Evidence: CHANGELOG "Known gaps at 0.1.0" (stale PDFs, missing lessons, resume/worktree restart defect, the seventh sighting of a workspace-anchoring bug class); the ninth task's missing receipt closed with an explicit `--post-hoc` receipt rather than papered over; the REFUTED verdict celebrated as proof the mechanism works
- Claim: the project documents its own failures with a candor rare in this market; this is the credibility asset the brand should be built on
- Why it matters: in a category saturated with demo-ware claims, auditability of *failure* is what enterprise adopters actually buy
- Falsifier: discovery of a known material defect omitted from the record
- Recommended move: surface this ledger prominently in public positioning (it currently lives in a 86KB CHANGELOG few will read)
- Acceptance evidence: a public "evidence" page linking every README claim to its receipt, test, or known-gap entry

### F-fable-07 — The self-hosting proof was deleted from the tree; provenance claims now require git archaeology
- Type: claim gap
- Surface: docs
- Severity: medium
- Confidence: high
- Evidence: commit `e23d358` removed `tasks/done/T-*.md`, `tasks/_metrics.jsonl`; the `uc-analytics` proving ground was removed (CHANGELOG "Removed"; CI even enforces no live references remain, `ci.yml:286–301`); at HEAD, no receipts or settled specs exist outside test fixtures and Cockpit e2e fixtures; merged PRs #2–#9 remain visible only in history
- Claim: "every claim has a receipt behind it" (`README.md:379`) is true only for someone willing to excavate history; the shipped tree carries the machinery but not the artifacts
- Why it matters: distributed, inspectable evidence is one of the review's core tests, and the project fails it *at HEAD* while passing it *in history*
- Falsifier: a receipts/evidence directory at HEAD that I missed (none found by `git ls-files` sweep)
- Recommended move: a permanent public proving-ground repo (Section 10, Move 1) whose receipts are living artifacts, not history
- Acceptance evidence: a fresh clone answering "show me the nine settlements" without `git log`

### F-fable-08 — The factory is one cell: no fleet dispatch, no server-side re-verification
- Type: claim gap
- Surface: runtime
- Severity: medium
- Confidence: high
- Evidence: `README.md:396–398` and `bin/README.md:173–183` (Manager and CI eval-gate explicitly "not yet built"); `cvg ready` computes the dispatchable frontier but nothing consumes it autonomously
- Claim: "dark factory" and any fabric-shaped positioning describe the roadmap, not the product; today a human (or chat-driven agent) pulls each task through
- Why it matters: honest in the docs, but it bounds the autonomy score and the category claim; competitors (Copilot Agent HQ) already run the scheduling half natively
- Falsifier: n/a — the project agrees
- Recommended move: build the CI eval-gate before the Manager (Section 10, Move 3) — settlement-in-CI is the smaller, more differentiated half
- Acceptance evidence: a PR on a public repo blocked by a Converge check re-running seal + evals + tier-2 server-side

### F-fable-09 — Bus factor 1 on a 140KB bash monolith
- Type: design risk
- Surface: CLI
- Severity: medium
- Confidence: high
- Evidence: `git shortlog -sn` (one human author); `bin/cvg` 2,677 lines of bash routing 25+ scripts; bash 3.2 constraint excludes most modern tooling; discipline currently maintained by one person's standards (ShellCheck, wrap-don't-rewrite contracts)
- Claim: the implementation quality is high *now*, but the medium is hostile to contributors and the project has no second maintainer, no governance, and no contribution surface (no CONTRIBUTING.md found)
- Why it matters: adopters bet on continuity; a single-author bash system is a continuity risk however good the tests are
- Falsifier: sustained external contributions after publication
- Recommended move: publication (Move 1) plus a contribution guide; consider extracting the Python-side contracts (already stdlib-clean) as the stable core
- Acceptance evidence: ≥2 non-author contributors landing non-trivial changes within 90 days of going public

### F-fable-10 — The verification-referee seat is genuinely open in the August 2026 market, and the window is narrowing
- Type: market gap
- Surface: market
- Severity: high (as urgency)
- Confidence: medium
- Evidence: Section 6 table — Spec Kit (~125.5k stars) structures but does not enforce; Kiro invests in property-based testing; Copilot wires CodeQL/CI gates natively; no surveyed product ships sealed specs + budgeted loops + cross-family refutation as a unit (retrievals 2026-08-05)
- Claim: Converge's differentiated seat — vendor-neutral settlement — exists today, but every platform vendor is adding verification from their own side; a private repo cannot occupy a seat
- Why it matters: first credible occupant of "the referee layer" gets to define its vocabulary (the way AGENTS.md defined its niche); second place gets absorbed as a feature
- Falsifier: a platform vendor shipping vendor-neutral sealed-spec settlement before Converge publishes
- Recommended move: all three moves in Section 10, in order
- Acceptance evidence: external teams citing Converge's tokens (`TASK_LOOP=SETTLED`, `CHECK_VERIFY=REFUTED`) in their own CI logs

### F-fable-11 — First-success cost is high: ceremony, multi-engine prerequisites, and macOS sharp edges
- Type: design risk
- Surface: CLI
- Severity: medium
- Confidence: medium
- Evidence: quickstart requires `init` + `setup signing` + `setup` + `lane` + `tasks plan/new/validate/gate` + `bind` + `loop` before first settlement (`README.md:158–197`); differentiating features (Pass 4, tier-2) require ≥2 vendor CLIs installed and authenticated (`doctor` enforces this); `cvg lint` exits UNSUPPORTED on stock macOS bash (`README.md:331–334`); chat-driven steering mitigates but presumes a harness with the skills installed
- Claim: the distance from install to first proven settlement is long enough to lose most evaluators, and the full value proposition demands accounts with two+ model vendors
- Why it matters: adoption funnels die at first success; Copilot's equivalent is "assign an issue"
- Falsifier: telemetry from real external users succeeding quickly (none can exist yet)
- Recommended move: a `cvg demo` path — bundled stub engine + sample spec that lands a RED→GREEN→SETTLED loop in two minutes with zero vendor CLIs (the clean-room test already proves this is possible; productize it)
- Acceptance evidence: a screencast-reproducible zero-to-SETTLED in under 5 minutes on a fresh machine

### F-fable-12 — Cockpit is disciplined but premature relative to the core wedge
- Type: design risk
- Surface: Cockpit
- Severity: low
- Confidence: medium
- Evidence: `apps/cockpit/` — a full React/Vite/ACP app (12 runtime deps, Playwright e2e, its own CI job) explicitly excluded from the shipped package (`README.md:97–99`); its safety boundary (loopback-only, single read-only CLI command, SHA-bound previews, plan-mode-only Claude, Codex blocked pending isolation) is genuinely careful
- Claim: the observation-vs-execution boundary is well-engineered, but the app expands a single maintainer's surface while the core is unpublished and the CI eval-gate is unbuilt; observability dashboards are a crowded category (Conductor et al.), settlement referees are not
- Why it matters: focus is the scarcest resource in a bus-factor-1 project
- Falsifier: Cockpit proving to be the adoption hook in user evidence
- Recommended move: freeze Cockpit features until Moves 1–3 land; keep it as the demo surface
- Acceptance evidence: release notes showing core-first sequencing over the next two releases

## 10. The Top Three Moves

### Move 1 — Go public with reproducible proof
- **Problem it solves:** F-01, F-07, and half of F-09/F-10 — the product is unfalsifiable and uninstallable; its best asset (evidence culture) is invisible.
- **Why top three:** every other virtue is moot while this is false; it is also the cheapest of the three.
- **Affected:** every prospective adopter; the project's entire credibility.
- **Scope:** make the repo public; cut a `v0.1.x` tagged release; verify all three install doors from a clean machine; stand up a permanent public proving-ground repo containing the settled specs, receipts, objection logs, and PR links at HEAD (restoring what commit `e23d358` removed, as living artifacts); add an evidence page mapping each README claim → its public receipt/test/known-gap; add CONTRIBUTING.md. Surfaces: repo settings, `install.sh` verification, new `evidence/` or sibling repo, README.
- **Dependencies/sequencing:** none — first. (Pre-publication security pass on history for the signing-key path is prudent; the key itself is git-private by design.)
- **Effort:** M · **Impact:** 10 · **Principal risk:** public scrutiny finds the trust gaps before Move 2 closes them — mitigated by shipping the README honesty fix (F-03) in the same release.
- **30-day outcome:** all install doors succeed externally; public CI green at tag; first outside issue filed. **90-day outcome:** ≥2 external contributors (F-09 falsifier); first external team with a settled task.
- **Acceptance evidence:** fresh-VM screencast of curl-install → `cvg demo` → `TASK_LOOP=SETTLED`; public Actions run; evidence page live.
- **Score effect:** DX/adoption 3.5→6.5, Evidence 5.0→7.0, Differentiation 6.5→7.0 → **≈ +4.3 points (65.5→~69.8)**.

### Move 2 — Make the trust boundary as strong as the trust language
- **Problem it solves:** F-02, F-03, F-04 — the three high-severity gaps between claim and enforcement in the exact dimension (trust, 20% weight) the product leads with.
- **Why top three:** the target audience is verification-minded; one public blog post titled "Converge's holdout isn't hidden" would be existential. Closing these *before* they're found converts the biggest liability into the moat.
- **Affected:** every user relying on tier-2 for unattended settlement; security reviewers.
- **Scope:** (a) holdout sidecar: move `## Holdout` to a judge-only artifact outside the worker-visible tree (e.g. `.cvg/holdouts/<id>.md`, hash-referenced inside the sealed spec so tampering breaks the seal; excluded from brief, pack, and workdir), with a test asserting the worker's observable bytes never contain holdout text; (b) judge hardening: delimit the diff as data, anchor verdict extraction to a terminal token, add a hostile-diff fixture suite (instruction smuggling, decoy JSON), dual-judge quorum when blast radius is high; (c) honesty alignment: README trust section adopts SKILL.md's tamper-evident framing plus the per-engine prevented/detected table. Surfaces: `task-spec` (template, `_lib.sh` payload), `task-to-runtime-contract/scripts/verify-work.py`, `task-loop/scripts/loop-kernel.sh`, README, new test suites.
- **Dependencies/sequencing:** (c) ships with Move 1 immediately; (a)/(b) next — before any marketing push invites red teams.
- **Effort:** M–L · **Impact:** 8 · **Principal risk:** holdout ergonomics (humans must author criteria in a second location) — mitigated by `cvg tasks new` scaffolding the sidecar.
- **30-day outcome:** README aligned; injection fixture suite red-teaming the current judge (findings on the record). **90-day outcome:** sidecar + hardened judge shipped; the `obs-fence` REFUTED case reproduced under the new mechanism.
- **Acceptance evidence:** CI suite proving holdout invisibility to the worker and fail-closed behavior on all injection fixtures; updated envelope version (`hmac-sha256-v3`) sealing the holdout hash.
- **Score effect:** Trust 6.5→8.0 → **+3.0 points**.

### Move 3 — Ship the CI eval-gate: settlement where teams already settle
- **Problem it solves:** F-08 and F-10 — Converge's autonomy story stops at the laptop, while the industry's settlement point is the PR; it also converts Converge from "a workflow you adopt" into "a check you add," collapsing the adoption cost of F-11.
- **Why top three:** it is the roadmap's own declared next step, the smallest credible piece of the fabric/factory vision, and the one move that makes Converge complementary to (rather than competing with) Copilot, Devin, and OpenHands: *any* agent's PR can be settled by the neutral referee. That is the category-defining wedge.
- **Affected:** teams with existing agents and existing CI; platform-lock-averse enterprises.
- **Scope:** a GitHub Action (composite, no secrets beyond what evals need) that on PR: recomputes the sign-off HMAC, re-runs the spec's evals hermetically, invokes tier-2 with a CI-held judge, and posts `TASK_LOOP`/`CHECK_VERIFY` tokens as a required status check; `cvg ci` verb wrapping the same logic locally. Surfaces: new `action.yml` + `bin/cvg` verb + docs; depends on Move 2's judge hardening (a server-side injectable judge is worse than none) and Move 1's publication.
- **Dependencies/sequencing:** last of the three; needs 1 (public action) and 2b (hardened judge).
- **Effort:** L · **Impact:** 9 · **Principal risk:** judge cost/latency in CI and secret handling for the judge engine — mitigated by blast-radius-scoped invocation (tier-2 only when the lane demands it), which the lane classifier already computes.
- **30-day outcome:** design + hermetic prototype (stub judge) on the proving-ground repo. **90-day outcome:** the proving-ground repo's own PRs gated by the action; one external repo piloting it.
- **Acceptance evidence:** a public PR visibly blocked by `CHECK_VERIFY=REFUTED` and merged only after remediation — the `obs-fence` story, replayed in public CI.
- **Score effect:** Autonomy 5.5→7.0, Differentiation 7.0→7.8 → **≈ +2.7 points**.

**Coherence:** publish the proof → harden the boundary the proof invites attacks on → move the referee to where the industry settles. Combined estimated effect: 65.5 → ~75, i.e. from "credible prototype" to "strong and meaningfully differentiated" — with the category claim earned rather than asserted.

## 11. Suggested 30/60/90-Day Sequence

- **Days 0–30:** README trust-language alignment (F-03, hours); repo public + tagged release + install verification from clean machines; public proving-ground repo with receipts at HEAD; CONTRIBUTING.md; `cvg demo` stub-engine path (from F-11); begin hostile-diff fixture suite.
- **Days 31–60:** holdout sidecar + envelope v3; judge hardening (delimiters, anchored verdict, quorum option); reproduce both tier-2 verdicts under the new mechanism, publicly; freeze Cockpit features (F-12).
- **Days 61–90:** CI eval-gate action prototyped on the proving ground; its own PRs gated; publish the replayed REFUTED-blocks-merge case as the launch story; recruit 2–3 pilot teams from the multi-CLI user niche.

## 12. What Should Not Be Built Yet

- **The Manager (fleet dispatch):** the README's own reasoning is right — Git-native infrastructure supplies most of it, and the CI eval-gate (Move 3) is the higher-leverage half. Sequencing it first would add orchestration (a crowded category, Section 6) before settlement (an open one).
- **More Cockpit views or the Codex Ask path:** F-12; the isolation blocker is real, and the app is already ahead of the core's public existence.
- **More tracker adapters (Jira/GitHub projection tiers):** Pass 6 is opt-in and offline-proven; breadth here serves no one until there are external users.
- **New skills / a thirteenth pass:** the method is complete enough; every addition raises the F-11 ceremony cost.
- **Any "Autonomous Fabric" category marketing:** the term is unsupported by the current single-task reality (Section 7) and unclaimed in the repo itself; earn it via Move 3 or drop it for "the settlement layer."

## 13. Open Questions and Falsifiers

1. **Can any current engine configuration actually prevent key-read?** If yes (e.g. sandbox profiles excluding `.git/info`), F-03 drops to medium; if no, Tier-1 "crypto trust" should be renamed. Falsifier experiment: attempt read-key→re-seal under each adapter.
2. **Do frontier judges resist the injection shapes in F-04?** A fixture study would set severity empirically; my medium confidence reflects the untested surface, not a demonstrated exploit.
3. **Does the nine-pass ceremony survive contact with a second team?** All dogfooding evidence is single-author; the barrier sign-off and lesson gates may be load-bearing for one disciplined person and intolerable for five. Falsifier: a pilot team's retention after 30 days.
4. **Is the bash 3.2 constraint still the right portability floor** once a CI eval-gate (Linux containers) becomes the primary surface? The constraint costs contributor accessibility (F-09) and features (`cvg lint`); its beneficiary is stock macOS, which Move 3 de-centers.
5. **Was PR #9's task-branch hygiene representative?** The merge mixed package-wide changes with the task (observed in `git show bbdb788 --stat`); if loop settlements routinely carry unrelated changes, the write-scope story weakens in practice. Falsifier: diff audits of the next public settlements.
6. **Grok Build support** is claimed at the skills-discovery level with no loop adapter; either ship `engines/grok.sh` or scope the claim.

## 14. Sources

All retrieved 2026-08-05 (America/Sao_Paulo).

1. https://github.com/luanmorenommaciel/converge — HTTP 404 (repository private/unpublished)
2. https://github.com/luanmorenommaciel — owner profile; no public `converge` repository listed
3. https://github.com/github/spec-kit — Spec Kit: MIT, six-phase workflow (including a phase named "Converge"), 30+ agents, ~125.5k stars
4. https://agents.md — AGENTS.md standard: 60k+ projects, stewarded by the Agentic AI Foundation (Linux Foundation)
5. https://github.com/All-Hands-AI/OpenHands — OpenHands: MIT, ~83.2k stars, Docker sandbox modes, runs third-party agents via ACP
6. https://kiro.dev — Amazon Kiro: AWS-operated agentic IDE/CLI, spec-driven (requirements/design/tasks), property-based testing, GA, credit pricing
7. https://conductor.build — Conductor: parallel Claude Code/Codex/Cursor agents in isolated workspaces, Mac, commercial (v0.79.0)
8. https://github.com/promptfoo/promptfoo — promptfoo: MIT, ~24k stars, LLM evals/red-teaming with CI integration
9. https://github.com/newsroom/press-releases/coding-agent-for-github-copilot — GitHub press release: Copilot coding agent (issue → Actions sandbox → PR)
10. https://baeseokjae.github.io/posts/github-copilot-coding-agent-guide-2026/ — secondary: Copilot coding agent 2026 behavior (MCP, CI-to-green, CodeQL on agent PRs)
11. https://www.openhands.dev/blog/devin-ai-alternatives — vendor-adjacent comparison: Devin ACU self-serve entry ~$20 (mid-2026), positioning (treated as directional, not authoritative)
12. https://www.thoughtworks.com/en-us/radar/techniques/spec-driven-development — Thoughtworks Technology Radar: spec-driven development as a recognized technique
13. https://addyosmani.com/blog/code-agent-orchestra/ — independent practitioner survey of multi-agent coding orchestration
14. https://www.tembo.io/blog/ai-agent-orchestration-tools — secondary: 2026 orchestration tool landscape (Conductor, Vibe Kanban, Claude Squad et al.)

Repository evidence is cited inline as `path:line` throughout; test commands and outcomes in Section 4.

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "fable",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 65.5,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Distinct",
  "evidence_confidence": "Medium",
  "adopt_today": "conditional",
  "top_strength": "Settlement enforced outside the worker's authority: sealed pre-authored evals, budgeted loop with named terminal states, and cross-family refutation with a documented live REFUTED verdict — verified by 128 passing hermetic checks",
  "top_risk": "The repository is private (all install paths 404) and the trust language outruns the enforced boundary: worker-readable holdouts, worker-readable signing key, and a prompt-injectable tier-2 judge",
  "top_3": [
    {
      "rank": 1,
      "name": "Go public with reproducible proof",
      "effort": "M",
      "impact": 10,
      "score_delta": 4.3
    },
    {
      "rank": 2,
      "name": "Make the trust boundary as strong as the trust language",
      "effort": "L",
      "impact": 8,
      "score_delta": 3.0
    },
    {
      "rank": 3,
      "name": "Ship the CI eval-gate: settlement in the PR",
      "effort": "L",
      "impact": 9,
      "score_delta": 2.7
    }
  ],
  "critical_finding_ids": ["F-fable-01", "F-fable-02", "F-fable-03", "F-fable-04"],
  "tests_run": {
    "passed": 4,
    "failed": 0,
    "blocked": 1
  },
  "external_sources": 14
}
```
