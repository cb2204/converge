# Converge Independent Review — qwen3.8-max

## 1. Review Metadata

| Field | Value |
|---|---|
| Reviewer / model identifier | `openrouter/qwen/qwen3.8-max` (the task's `REVIEWER_ID` placeholder was unfilled; the model identifier was adopted as reviewer id) |
| Reasoning mode / effort | Not exposed by the harness; single-pass deep review, no delegated sub-reviewers (per independence rule 3) |
| Review window | 2026-08-05 22:10 -03 → 2026-08-06 ~03:00 -03 (2026-08-06 01:10 UTC start) |
| Git HEAD SHA | `9c966884e37919c0f7e4c3e027b4b237670eb2ad` |
| Latest commit | `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi` — Luan Moreno Medeiros Maciel, Tue Aug 4 20:28:35 2026 -0300 |
| Branch | `feat/e2e` (not detached); local `main` at `1f28a5c`; tag `v0.1.0` present locally |
| Worktree dirty at start | Yes — 4 pre-existing changes preserved untouched: `M apps/cockpit/package-lock.json`, `D review/deepseek.md`, `D review/grok.md`, `D review/kimi.md` |
| VERSION | `0.1.0` (verified unified by `tests/test-version-unity.sh`, run locally, 12/12) |
| Tools available | `read`/`grep`/`glob`/`bash`/`write` for repo inspection; local bash 3.2 (macOS, Darwin 25.5.0 arm64) for test execution; `web_search` + URL `read` for market research. No files under `review/` were read, listed, or searched. |
| Tool limitations | `npm install` prohibited by review rules → Cockpit node/vitest/playwright suites could NOT be run locally; no paid model APIs invoked (no live engine dispatch); GitHub repo is not publicly reachable (see F-qwen3.8-max-01), so CI status and PRs are not externally verifiable |

Evidence classes used throughout: **[VERIFIED]** (executed/observed locally), **[DOC]** (documented claim, not independently reproduced), **[EXTERNAL]** (web source with URL + retrieval date), **[INFERENCE]**, **[SPECULATION]**.

## 2. Executive Verdict

**Overall score: 74.8 / 100** (dimension-weighted; arithmetic in §8).

**Does Converge stand out today?** Technically yes, commercially no. The core mechanism — HMAC-sealed runnable evals as the settlement condition, hash-bound execution contracts, cross-family adversarial verification with a fail-closed judge, and a budgeted loop kernel with named terminal states — is implemented, coherent, and survived 840 locally executed checks plus my own adversarial reproductions. Nothing in the researched market ships this exact combination. But the repository is not publicly reachable, so zero users can install it, and its strongest evidence (settled PRs, a REFUTED tier-2 case) lives in git history of a private repo. It stands out as engineering; it does not yet stand in a market.

**Strongest defensible advantage:** *Settlement as a state-machine invariant.* "Done" is not an agent claim: the loop only lands `SETTLED` when sealed evals exit 0, the spec hash still matches the bind-time hash, the HMAC sign-off still verifies, and the diff passes both the per-task `fs.write` scope and the repo write fence. I reproduced the maximal attack (stubbing the eval body after stamping) and the whole chain refused it at three independent points. No researched competitor enforces completion this way.

**Most dangerous weakness:** *The product is unreachable and its proof is invisible.* All three install doors return 404 publicly; the npm package is unpublished; the CI badge points at a private workflow; the proving ground with the receipts was removed from the tree. A verification product lives and dies on inspectable evidence, and today an outsider can inspect none of it. Secondary but structural: the holdout ("criteria the builder never saw") is readable by the builder — concealment is by prompt convention, not mechanism.

**Would I adopt it today?** **Conditional.** I would adopt the *loop kernel + Task-Spec discipline today* for single-task, bounded, high-integrity delegations in a repo I control — if the source were made public (or vendored to me directly), I already run Claude/Codex headlessly, and I accept bash-based tooling. I would **not** adopt it as an org-wide "Autonomous Fabric": no fleet dispatch (Manager unbuilt), no server-side CI eval-gate, Cockpit proving gates open, single-maintainer bus factor, and the security boundary has two known prompt-level seams (holdout, judge lockdown).

## 3. What Converge Actually Is

Converge at HEAD is, in descending order of substance:

1. **A referee CLI + enforcement library (~12k lines of bash/Python).** `bin/cvg` (2,677 lines, bash 3.2) routes to ~40 scripts under `skills/*/scripts/`: Task-Spec validation/signing (`validate-task-spec.sh` 1,060 ln, `safe-to-delegate.sh`), bind-time contract compilation (`bind-runtime-contract.py`), write-fence checking (`check-gate.py`, `check-path-policy.py`, `_gate_policy.py`), the loop kernel (`loop-kernel.sh` 1,024 ln), settlement (`open-issue-pr.sh`), and tier-2 verification (`verify-work.py`). The CLI holds no credentials and calls no models **[VERIFIED — dispatch goes to vendor CLIs via adapter files; `bin/cvg` contains no API-key handling]**.
2. **A method encoded as 12 installable skills** (9 passes + 3 utilities) with markdown steering prompts and deterministic exit-contract gates (`CHECK_BRD=PASS` … `TASK_LOOP=SETTLED`). The design half (passes 0–4) is document gating; the machine half (5–8) is where enforcement is real.
3. **A bounded single-task autonomous loop.** Attempt → verify → repeat with three-axis budgets, stagnation fingerprinting, fresh engine process per attempt, worktree isolation by default, and 8 named terminal states **[VERIFIED by 57-check suite + code reading]**.
4. **A read-only observability app (Cockpit).** React/Vite + Node bridge that projects `cvg snapshot --json` (WorkspaceSnapshot 3.0, 1,702-line JSON Schema) into nine views; safety boundary implemented in code (loopback-only config rejection, allowlisted `execFile` of exactly two read-only commands, env allowlist, secret redaction) **[VERIFIED in code; node suites not run — rule 8]**.
5. **Not (yet):** a fleet orchestrator (Manager declared absent), a CI eval-gate (declared absent), a hosted service, or a category. "Autonomous Fabric" is positioning over a single-task loop plus method.

The clearest unit of value is the **signed Task-Spec + loop**: author evals first, seal them, bind a hash-bound contract, let any of claude/codex/kimi attempt within budget, settle only on green evals + path policy. Everything upstream (BRD→ADR→swimlanes→adversarial plan review) is a methodology layer that raises ceremony; `cvg lane` mitigates it (FAST = passes 5,7,8 only) **[VERIFIED: lane classifier floors tested live — "fix typo in the auth middleware" → NORMAL, never FAST]**.

## 4. Repository and Test Coverage

**Executed locally (this review, macOS bash 3.2, no network/creds):**

| Suite | Result |
|---|---|
| `tests/test-loop-kernel.sh` | PASS — 57 checks (brakes, stagnation, exhaustion, resume, cancel, worktree isolation, tracker authority, gate refusal) |
| `tests/test-clean-room-install-e2e.sh` | PASS — 21 checks: empty repo → install (3 harness layouts) → init → signing → Tier-1 seal → bind → stub-engine RED→GREEN loop → receipt → acceptance → done |
| `skills/task-specs-to-issues/tests/test-register.sh` | PASS — 145 checks (fake tracker adapter) |
| `skills/task-spec/tests/test-task-spec-skill.sh` | PASS — 42 |
| `skills/task-to-runtime-contract/tests/run-tests.sh` | PASS — 48 |
| `skills/task-spec/tests/test-hmac-envelope.sh` | PASS — 38 |
| `tests/test-cvg-json-envelope.sh` | PASS — 23 |
| Pass gates 0–4 + companions (9 suites) | PASS — 39/24/38/33/23/23/39/24 rows |
| `tests/test-install.sh`, `test-version-unity.sh`, doctor host/plugin/evidence, tasks plan/dod, lesson, snapshot, bash-portability, extractor-fuzz, effort-sizing, v3-closed-loop, ci-covers-every-suite, `test-gate-policy.py` | all PASS (17/12/13/14/15/21/19/24/13/35/19/14/18/1/OK) |
| **Total** | **29 suites, ~829 checks, 0 failures** |

**My own adversarial reproductions (scratch repo in /tmp):**
- Tamper resistance: stamp golden spec (TIER=1) → bind (PASS) → replace eval body with `true` → `cvg tasks validate` hard-fails `HMAC mismatch`; loop-side verify exits 2 with `stale profile: Task-Spec hash mismatch` + `sign-off is not verifiable`; gate says `DO NOT DELEGATE`. **[VERIFIED]**
- Write fence: `cvg gate --path auth/x.py` → `REFUSED (rule: **/auth/**)`; benign path allowed. **[VERIFIED]**
- `cvg snapshot --json` emits envelope-valid WorkspaceSnapshot 3.0 (all 16 required top-level keys); `cvg agent-context` emits 52-command manifest. **[VERIFIED]**

**Not runnable under review rules:** `apps/cockpit` node suites (require `npm ci` — prohibited); live engine dispatch (no paid model calls). **Not runnable locally for environmental reasons:** `skills/task-spec/tests/test-portability-e2e.sh` Step 6 requires PyYAML (absent on this machine's system python3; CI installs locked deps via `.github/requirements-ci.txt`). CI itself (`.github/workflows/ci.yml`) wires every suite and includes a meta-gate (`test-ci-covers-every-suite.sh`) proving no suite is unwired; the workflow targets a private repo, so its green status is not externally observable today.

**Code paths read in depth:** loop kernel, engine adapters + lib, eval runner, settler, delegation gate, bind/check runtime contract, verify-work, gate policy, signing-key provisioning, receipt writer, lane classifier, install.sh, Cockpit server (`cvg.mjs`, `security.mjs`, `config.mjs`), CI workflow, CHANGELOG 0.1.0/Unreleased sections.

## 5. Claim-to-Evidence Audit

| # | Claim (source) | Status | Evidence |
|---|---|---|---|
| C1 | "A task cannot settle until its evals exit 0 — completion is a state-machine invariant" (README L49-51) | **VERIFIED** | `loop-kernel.sh:826-954` (verify before break), `open-issue-pr.sh:172-221` (settlement guard), my tamper repro; 57-check loop suite |
| C2 | "Editing an eval breaks the seal and the gate refuses" (README FAQ L427-429) | **VERIFIED** | Repro: HMAC mismatch → validate FAIL, loop verify exit 2, gate DO NOT DELEGATE. Honest limit documented: symmetric key readable by a same-user agent (`setup-taskspec-signing-key.sh:28-32`) |
| C3 | "Holdout criteria the builder never saw" (README L55-57) | **CLAIM GAP** | Holdout is a `## Holdout` section *inside the same spec file* the brief tells the worker to read (`loop-kernel.sh:854`); no stripping exists in bind/brief (grep-verified). Concealment = prompt convention (`folder-map.md:21-23`), not access control. See F-qwen3.8-max-02 |
| C4 | "Cross-family verification … proven live in both directions — one REFUTED caught a fail-open bug" (README L54-57) | **PARTIALLY VERIFIED** | Mechanism implemented and fail-closed **[VERIFIED in code + stub suites]**; the live UPHELD case is corroborated by merge `bbdb788` (PR #9) in git history; the REFUTED case (`obs-fence`) is CHANGELOG narrative + one re-bind commit — the BLOCKED artifact left the tree with the proving ground. Not externally inspectable (private repo) |
| C5 | "cvg holds no API keys and calls no models" (README L52-53) | **VERIFIED** | No credential handling in `bin/cvg`; dispatch via vendor CLIs in `engines/*.sh` and `verify-work.py:190-195`; Cockpit env allowlist drops secrets (`security.mjs:1-12`) |
| C6 | "Three-axis budgets + stagnation detector + eight terminal states; only SETTLED/LOCAL_SETTLED/NO_OP exit 0" (README L58-60) | **VERIFIED** | `loop-kernel.sh:830-844` (brakes checked BEFORE spend), `:938-953` (fingerprint stagnation), `:54` exit-code map; 57-check suite incl. exhaustion/stagnation/resume rows |
| C7 | "Works with Claude Code · Codex · Kimi · Grok Build" (README L15) | **PARTIAL** | claude/codex/kimi have loop engine adapters + judge recipes; **Grok has skills-directory install only — no engine adapter, `--agent grok` cannot dispatch** (only 3 files in `scripts/engines/`). True for skill consumption; overstated for execution. See F-qwen3.8-max-08 |
| C8 | "21 hermetic suites … loop kernel proven by 52 hermetic checks" (README L382-388) | **STALE** | I executed 29 wired suites and 57 loop-kernel checks; README numbers lag implementation. Minor doc drift |
| C9 | "CI is public and green on macOS and Linux" (README L382-383) | **UNVERIFIABLE** | Workflow exists and is well-constructed **[VERIFIED by reading]**, but repo 404s publicly; badge target unreachable. See F-qwen3.8-max-01 |
| C10 | "Nine tasks settled through merged PRs, one fully unattended" (README L450-452) | **PARTIALLY VERIFIED** | Git history contains PR #2–#9 merges with settle commits ("SETTLED in one iteration, 623s, PR #7"; "Four consecutive unattended landings") and hash-bound receipts (`cvg.execution-receipt.v1`); receipts/specs removed from tree at 0.1.0. History-inspectable only because I hold a clone |
| C11 | "The observation path invokes only `cvg snapshot --json`, binds to loopback" (README L81-82) | **VERIFIED** | `cvg.mjs:5-8` allowlist (`snapshot --json`, `agent-context --json`) via `execFile` (no shell); `config.mjs:108-112` rejects non-loopback `--host`; `bridge.test.mjs:351-352` pins injection refusal |
| C12 | "Codex choice remains visible but blocked" in Ask (README L90-91) | **DOC + code-consistent** | Stated in README/DESIGN; agent-registry tests exist; not executed (npm prohibited) |
| C13 | "Zero runtime dependencies" (README L15, L150-152) | **VERIFIED (scoped)** | Shipped gate scripts import stdlib only (grep for `import yaml` → none in `skills/*/scripts`, `bin/`); PyYAML needed only by a CI validation extra and the optional example consumer |
| C14 | "Cockpit … live proving-ground cases are still being completed" (README L97-99) | **HONEST** | `apps/cockpit/PROVING-GROUNDS.md`: all four cases Open/Not run against v3; explicitly says product version ≠ passed gates. Rare candor |
| C15 | Maximal stub attack "lands all nine RED" (README L50-51) | **MECHANISM VERIFIED, EVENT HISTORICAL** | Gate 1b blocks existence-only evals (`safe-to-delegate.sh:173-189`); the nine-spec event is proving-ground history, not reproducible from current tree |

## 6. Market Landscape

Retrieval date for all external sources: **2026-08-05** (UTC-3 evening). Category map: spec-driven toolkits, autonomous SWE agents, issue→PR resolvers, eval frameworks, agent observability.

**6.1 GitHub Spec Kit** — spec-driven development toolkit (`/speckit.specify → plan → tasks → implement`, plus `constitution`, `taskstoissues`, and — notably — a command named `/speckit.converge` that assesses code vs spec) [1][2]. Docs claim 121k+ stars, 240+ contributors, 35 agent integrations [2]. *Verification model:* none — implementation trust is delegated to the agent + normal review; no sealed evals, no settlement gate.

**6.2 Kiro (AWS)** — agentic spec-driven platform: requirements.md/design.md/tasks.md, dependency graphs, **wave-based parallel task execution**, steering files, hooks [3][4]. *Verification:* automated reasoning checks are marketed [4]; task completion is agent-reported status, not a sealed-eval invariant.

**6.3 OpenSpec (Fission-AI)** — lightweight delta-spec framework (`/opsx:propose → apply → archive`), repo-owned truth, agent-agnostic [5]. *Verification:* none beyond human PR review.

**6.4 Tessl spec-driven-development tile** — spec-first skills for MCP agents: gather → write specs → approval → implement; validation scripts for spec shape/links [6]. *Verification:* structural spec validation, not execution settlement.

**6.5 GitHub Copilot coding agent + third-party agents (Claude, Codex)** — assign issue → agent plans in Actions-powered environment → branch → PR; auto-security scans before finalizing; governed by Copilot policies [7][8][9]. *Verification:* CI of the target repo + human review; no eval sealing; GitHub-hosted only.

**6.6 OpenHands (All Hands AI)** — MIT-licensed autonomous SWE platform; GitHub resolver fixes `fix-me` issues via GitHub Actions → PRs; claims ~37% of its own recent commits agent-authored [10][11]. *Verification:* none beyond repo CI; sandboxed execution but no independent judge.

**6.7 Devin (Cognition)** — autonomous software engineer product line; 2026 self-serve pricing Free/$20 Pro/$200 Max/$80+ Teams/Enterprise custom [12][13]. Closed platform; its own SWE models; verification = Devin's own claims + human review.

**6.8 Factory** — role-specialized "Droids", Linear/Jira intake, per-step model routing; Pro $20 / Plus $100 / Max $200 + usage credits [14][15]. Closed platform, enterprise focus.

**6.9 Inspect AI (UK AI Security Institute)** — open-source LLM evaluation framework: 200+ ready evals, sandboxed agent execution (Docker/K8s), model-graded scoring, executes external agents incl. Claude Code/Codex CLI [16][17]. Adjacent: it evaluates models/agents, not task settlement in a delivery pipeline — but it is the credible home for Converge-style adversarial checks as reusable scorers.

**6.10 Codex CLI (OpenAI)** — `codex exec` non-interactive mode defaults to a **read-only sandbox** [18]; Converge builds on top of such engines rather than competing with them.

Also noted: the phrase "Autonomous Fabric" already appears in adjacent marketing — Microsoft Fabric/FABCON session on agentic data quality [19], DevAssure's testing "autonomous fabric" [20], AXON network fabric, Pulse commerce — so the term is not unclaimed territory, though unused for a delivery-control-plane.

## 7. Competitive Position

| Alternative | Primary user / use case | Unit of autonomy | Spec/planning model | Verification & acceptance | Agent/model portability | Execution & permission boundary | Observability / audit | Setup cost | Maturity / adoption signal | Converge advantage | Converge disadvantage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **GitHub Spec Kit** [1][2] | Any dev team adding SDD to existing agents | Conversation/session | Spec→Plan→Tasks markdown | None (agent + human review) | 35 integrations | Agent-native (no fence) | Artifacts in repo | Low (`uv tool install`) | Very high (docs claim 121k stars, 240+ contribs) | Sealed evals + settlement invariant; Spec Kit has zero enforcement | No enforcement either — but massive ecosystem, GitHub-native, zero-friction; Converge's ceremony is heavier |
| **Kiro** [3][4] | Teams wanting structured agentic IDE | Parallel task waves | requirements/design/tasks artifacts | Agent status + hooks | Kiro agents (Bedrock-backed) | IDE-managed | Spec status UI | Low-medium | High (AWS-backed GA product) | Cross-family judge + fail-closed; Kiro tasks "done" is agent-reported | Kiro executes parallel waves today; Converge loop is single-task; Kiro ships a product, Converge a CLI |
| **OpenSpec** [5] | Brownfield teams, spec deltas per change | Per-change proposal | Delta specs + tasks | Human PR review | Agent-agnostic | None | Archived changes | Low (npm) | Medium (active community) | Enforcement again; OpenSpec never verifies execution | Far lighter; good enough when trust is human |
| **Copilot coding agent / Codex / Claude agents** [7][8][9] | GitHub shops delegating issues | Issue → PR | Issue body as plan | Repo CI + security scan + review | Multi-vendor now (Copilot, Claude, Codex) | GitHub-hosted sandbox, Actions minutes | Agent dashboard | Very low (assign issue) | Very high (GitHub distribution) | Sealed evals beat "repo CI + hope"; budgets/stagnation named states | Distribution, hosting, zero setup; Converge needs local engine CLIs + ceremony |
| **OpenHands** [10][11] | OSS teams auto-fixing issues | Issue resolver | Issue text | None beyond CI | Model-pluggable | Docker sandbox | Resolver output JSON | Medium (pip / Action) | Medium-high; dogfoods itself (37% commits) | OpenHands has no seal/judge/scope fence at all | Already public, self-hosting proof at scale; Converge is private |
| **Devin** [12][13] | Individuals→enterprise wanting a "developer" | Session / assigned work | Internal planning | Internal + Devin Review product | Proprietary + frontier models | Proprietary cloud/desktop | Devin dashboard | Low (SaaS) | High (funded, priced, GA) | Vendor-neutral referee vs locked platform; auditability of receipts | Devin is a working product with support; Converge requires operating your own factory |
| **Factory** [14][15] | Enterprises automating ticket→code | Role Droids | Ticket intake (Linear/Jira) | Platform-internal | Per-step model routing | Proprietary | Full observability suite | Medium (SaaS) | Medium-high (enterprise customers) | Open, inspectable gates vs opaque platform | Factory already sells the "fabric" story with Linear/Jira intake today |
| **Inspect AI** [16][17] | Eval engineers verifying models/agents | Eval task | Task/scorer DSL | Scorers incl. model-graded | 20+ providers; runs Claude Code/Codex | Docker/K8s sandboxes | Inspect View | Medium (Python) | High (UK AISI-backed) | Complementary more than competitive — potential substrate for Converge's tier-2 | Inspect has real sandboxing; Converge's judge dispatch is less isolated |

**Position read:** every spec toolkit (Spec Kit, Kiro, OpenSpec, Tessl) stops at *planning discipline*; every autonomous agent (Copilot/Devin/Factory/OpenHands) stops at *agent-reported completion + normal review*. Nobody combines sealed pre-authored evals, hash-bound contracts, and a cross-family fail-closed judge around a budgeted loop. That gap is real — and it is also unproven as a category: the market has not yet demonstrated willingness to pay for verification-first orchestration on top of agents it already runs.

## 8. Scorecard

| Dimension | Weight | Score | Weighted (score × weight / 10) | Rationale (one line) |
|---|---|---|---|---|
| Problem and product thesis | 10% | 8.5 | 0.850 | Self-graded agent completion is a real, timely failure mode; thesis is sharp and coherent; buyer definition still fuzzy |
| Differentiation and market position | 15% | 7.0 | 1.050 | Sealed-eval settlement + cross-family judge is unique among researched peers; spec-workflow surface competes with giants; zero market presence today |
| Method and architecture coherence | 15% | 8.5 | 1.275 | Nine passes, lanes, tokens, envelopes, epoch-bound authority form one consistent system; complexity is high but earned |
| Trust, verification, and security model | 20% | 7.5 | 1.500 | Core chain verified end-to-end by repro; docked for prompt-level holdout, unlocked judge dispatch, verdicts absent from receipts |
| Implementation quality and reliability | 15% | 8.5 | 1.275 | 840 checks green on bash 3.2; exceptional failure-driven engineering comments; two monolith files; env-dep wart |
| Autonomous end-to-end completeness | 10% | 6.5 | 0.650 | Single-task autonomy is real and bounded; Manager and CI eval-gate absent (declared); human still triggers every loop |
| Developer experience and adoption readiness | 10% | 5.5 | 0.550 | Clean-room path proven hermetically; all public install doors 404; heavy ceremony mitigated by lanes |
| Evidence, credibility, and project maturity | 5% | 6.5 | 0.325 | Settlements/receipts exist in git history; proving ground removed; private repo makes CI/PR evidence unverifiable; PROVING-GROUNDS.md candor is credit |
| **Overall** | 100% | — | **7.475 → 74.8/100 (7.5/10)** | Sum verified: 0.850+1.050+1.275+1.500+1.275+0.650+0.550+0.325 = 7.475 |

- **Vision potential:** High
- **Current readiness:** Alpha
- **Market position:** Interesting (technically Distinct; commercially Invisible — scored on the market as it exists)
- **Evidence confidence:** High for implementation behavior (direct execution); Medium for live/historical market-facing claims (private repo)

## 9. Prioritized Findings

### F-qwen3.8-max-01 — The product is not publicly installable; all three doors 404

- Type: verified defect
- Surface: distribution
- Severity: blocker
- Confidence: high
- Evidence: `https://api.github.com/repos/luanmorenommaciel/converge` → 404; `https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh` → 404; repo page → 404; `https://registry.npmjs.org/@luanmorenommaciel/converge` → 404; user has 11 public repos, `converge` not among them (GitHub API, retrieved 2026-08-05). README L106-127 advertises marketplace/npm/curl installs.
- Claim: As of the review date, no normal user can install Converge through any documented door; CI status and PR evidence are likewise unobservable.
- Why it matters: Every adoption funnel step fails at step zero. For a product whose pitch is inspectable proof, invisible proof is category-fatal.
- Falsifier: A public mirror/org repo, npm publication, or release artifact that resolves these endpoints.
- Recommended move: Move 1 — public release with proof bundle (see §10).
- Acceptance evidence: `npm install -g github:luanmorenommaciel/converge && cvg-install` succeeds on a clean machine; CI badge renders green publicly.

### F-qwen3.8-max-02 — Holdout criteria are readable by the builder; "never saw" is a prompt convention

- Type: claim gap
- Surface: security
- Severity: critical
- Confidence: high
- Evidence: `verify-work.py:75-77` reads `## Holdout` from the spec file; the loop brief tells the worker the spec is "the only instruction source" (`loop-kernel.sh:854`) and the file on disk contains the Holdout section; grep across `skills/` + `bin/` finds no stripping in bind/brief/context-pack; only defense is router guidance (`evidence-to-next-pass/references/folder-map.md:21-23` "Never open held-back material").
- Claim: README's "holdout criteria the builder never saw" (L55-57) is not enforced by any mechanism; a compliant-or-curious worker reading its own spec sees the holdout and can tune to it.
- Why it matters: Tier-2's entire value proposition is train/test separation. If the test set is in the training data path, the differentiator is rhetoric.
- Falsifier: A code path that removes or relocates the Holdout section before the worker is briefed, or an fs.read-style fence the worker cannot cross.
- Recommended move: Move 2 — relocate holdouts to a judge-only sealed artifact excluded from the worker brief at bind time.
- Acceptance evidence: A hermetic test asserting (a) the briefed spec/AGENTS.task.md contains no holdout text, (b) verify-work.py still grades against it, (c) a worker that quotes the holdout back cannot have obtained it from any in-scope file.

### F-qwen3.8-max-03 — Tier-2 judge dispatch is not locked read-only (Pass 4 shows how)

- Type: verified defect
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `verify-work.py:190-195` dispatches `claude -p <prompt>` / `kimi -p` / `gemini -p` with no tool restrictions and `codex exec --skip-git-repo-check` with no explicit `--sandbox read-only`; contrast Pass 4's hardened dispatch: `dispatch-review.sh:134-136` uses `codex exec --sandbox read-only` and `claude -p … --tools Read,Grep --disallowedTools "Edit,Write"`. Codex exec defaults to read-only [18], but user config can override; `claude -p` defaults to tools-enabled.
- Claim: The judge whose verdict authorizes settlement can, for claude/kimi/gemini, write files in the repo it is judging; the docstring's "headless + read-only" (verify-work.py:189) is enforced only for the codex path, and only by vendor default.
- Why it matters: A compromised or hallucinating judge mutating code mid-verification breaks the maker≠checker invariant the product sells.
- Falsifier: Flags or sandboxing in the judge recipes that provably prevent writes on all four engines.
- Recommended move: Move 2 — copy Pass 4's lockdown recipe into verify-work.py (per-engine explicit read-only flags) and add a hermetic test with a stub judge that attempts a write.
- Acceptance evidence: New suite row: "a judge that writes during verification fails the run"; recipes pinned in code review.

### F-qwen3.8-max-04 — Tier-2 verdicts are not recorded in the durable execution receipt

- Type: design risk
- Surface: runtime
- Severity: medium
- Confidence: high
- Evidence: `write-execution-receipt.py:24-45` accepts only result/eval-output/path-policy/agent/branch; loop prints the judge verdict to the loop log (`loop-kernel.sh:977-1002`) but the receipt schema (`cvg.execution-receipt.v1`, example in commit `3bf02ab`) has no verification field.
- Claim: Whether settlement was independently upheld is auditably absent from the receipt chain; evidence lives only in transient loop logs.
- Why it matters: Receipts are the product's proof currency (Cockpit renders them; hash chains are tested). An auditor cannot answer "was tier-2 run and what did it say?" from durable artifacts.
- Falsifier: A receipt field carrying judge/verdict/findings-hash populated by the settler.
- Recommended move: Extend receipt writer + settler to record `verification: {ran, judge, family_independence, verdict, findings_sha256}`; extend clean-room suite.
- Acceptance evidence: Clean-room receipt contains verification block; suite row asserts REFUTED runs never produce a `pass` receipt.

### F-qwen3.8-max-05 — Tamper resistance works end-to-end (strength)

- Type: strength
- Surface: security
- Severity: positive
- Confidence: high
- Evidence: Independent repro (§4): stamp → TIER=1; bind → PASS; stub the eval body → validate hard-fails HMAC mismatch; loop verify exits 2 (`stale profile: Task-Spec hash mismatch`); gate refuses delegation. Three independent enforcement points.
- Claim: The central promise — "editing an eval after sign-off breaks the seal and blocks settlement" — is true in the inspected build.
- Why it matters: This is the one property no researched competitor has; it survives adversarial testing.
- Falsifier: Any path that settles a spec whose eval body changed post-stamp without re-signing.
- Recommended move: Ship this exact reproduction as `tests/test-tamper-repro.sh` so the proof travels with the product.
- Acceptance evidence: The new suite runs red against a deliberately unsealed build and green against HEAD.

### F-qwen3.8-max-06 — The loop kernel's brakes are real, tested, and honestly designed (strength)

- Type: strength
- Surface: runtime
- Severity: positive
- Confidence: high
- Evidence: 57/57 checks executed; budgets checked pre-spend (`loop-kernel.sh:827-844`); stagnation fingerprint strips durations to avoid load-dependent flakiness (`:685-702`); checkpoint-before-attempt (`:889-893`); worktree isolation default with crash-safe cleanup trap (`:382-410`); `EXHAUSTED` writes HANDOFF.md for `--resume`.
- Claim: Bounded autonomy is implemented as brakes, not vibes; failure states are named and non-zero.
- Why it matters: Unattended operation is the product's raison d'être; these are the controls an operator actually needs.
- Falsifier: A loop path that exits 0 without green evals, or spends past a declared budget.
- Recommended move: Keep as the anchor demo; publish the 57-row suite prominently.
- Acceptance evidence: Already passing; publication is the move.

### F-qwen3.8-max-07 — Clean-room e2e proves the full chain hermetically (strength)

- Type: strength
- Surface: distribution
- Severity: positive
- Confidence: high
- Evidence: `tests/test-clean-room-install-e2e.sh` PASS (21 checks, executed): empty repo → pinned installs for three harness layouts → init → Git-private 0600 signing key → Tier-1 seal → bind → stub-engine RED→GREEN loop → receipt hash chain → acceptance → done → no source-checkout path leakage.
- Claim: A first-time user with engine stubs can reach a settled, receipted task in one scripted flow.
- Why it matters: First-success path is de-risked for the moments when distribution exists.
- Falsifier: A step requiring manual intervention or undocumented state.
- Recommended move: Turn this suite into the public "10-minute proof" (asciinema/CI artifact) at launch.
- Acceptance evidence: Public CI run + recording linked from README.

### F-qwen3.8-max-08 — "Grok Build" support is skills-install only; execution claims overstate it

- Type: claim gap
- Surface: docs
- Severity: medium
- Confidence: high
- Evidence: `skills/task-loop/scripts/engines/` contains only `claude.sh`, `codex.sh`, `kimi.sh`; `verify-work.py:55` FAMILY map has no grok; `install.sh:123` writes `.grok/skills/` (skills only); CHANGELOG 0.1.0 entry "Grok Build is a first-class harness" refers to the skills directory.
- Claim: Grok Build can consume skills but cannot be dispatched as a Pass-4 adversary or Pass-8 engine; README's four-engine headline mixes discovery with execution.
- Why it matters: Cross-family verification needs ≥2 dispatchable families; Grok users discovering the gap at `--agent grok` get a hard ERROR.
- Falsifier: A grok adapter file + judge recipe passing the same contract tests.
- Recommended move: Either add `engines/grok.sh` + FAMILY entry, or scope the headline to "skills for Grok Build; execution for Claude/Codex/Kimi".
- Acceptance evidence: Adapter passing engine-suite rows, or corrected README line with a test asserting headline↔adapter parity.

### F-qwen3.8-max-09 — Cockpit's own release gates are open, and say so (honesty + gap)

- Type: claim gap
- Surface: Cockpit
- Severity: medium
- Confidence: high
- Evidence: `apps/cockpit/PROVING-GROUNDS.md`: uc-01 "Open", uc-02/03/04 "Not run"; "The application is release-ready only when all four cases have exercised the same WorkspaceSnapshot 3.0 contract". README L97-99 confirms Cockpit is excluded from the published package meanwhile.
- Claim: Cockpit is a well-architected projection whose product claims are explicitly unproven on real workspaces; its safety boundary, however, is code-real (loopback config rejection, two-command allowlist, env filtering).
- Why it matters: Cockpit is the visible "product" surface; shipping it ahead of proving-ground evidence would dilute the brand's proof-first promise. The project is right to hold it back — but that means the current product is CLI-only, which affects positioning.
- Falsifier: Dated v3 reruns + owner sign-offs recorded in PROVING-GROUNDS.md.
- Recommended move: Run uc-01 rerun as part of the Move-1 launch evidence; keep the gate discipline.
- Acceptance evidence: PROVING-GROUNDS.md rows flip to dated evidence entries.

### F-qwen3.8-max-10 — Prevention is delegated; Converge's own enforcement is detection-at-settlement

- Type: design risk
- Surface: security
- Severity: medium
- Confidence: high
- Evidence: Adapter payloads state `supports_prewrite_prevention: false` for all runtimes (`bind-runtime-contract.py:96-114`); codex gets vendor seccomp/workspace sandbox, claude gets an *optional* PreToolUse hook fragment, generic gets postflight only; `attest-runtime.py` probes Seatbelt/Landlock/bwrap but nothing wraps engine invocations in them; the binding control is the settlement guard (`open-issue-pr.sh:168-221`, staging scope proof `:386-440`).
- Claim: During an attempt, a worker can write outside scope (even to protected paths inside the worktree); Converge detects and refuses settlement, it does not prevent the write. This is documented honestly in the capability-envelope docs, and worktree isolation bounds the damage, but "isolation" in marketing should be read as checkout-isolation, not OS sandboxing.
- Why it matters: For `--isolation inplace` runs or malicious-dependency scenarios, detection-only means the mess is made and then refused; security reviewers will ask about this first.
- Falsifier: Engine invocations wrapped in sandbox-exec/bwrap with a policy derived from the contract.
- Recommended move: After Moves 1-2, wire the attested primitive into engine dispatch as an opt-in hard mode (`--sandbox enforce`).
- Acceptance evidence: Suite row: an attempt writing a protected path under enforced mode never lands the bytes.

### F-qwen3.8-max-11 — Stale proof numbers and unverifiable CI badge

- Type: claim gap
- Surface: docs
- Severity: low
- Confidence: high
- Evidence: README L382-388 says "21 hermetic suites" and "52 hermetic checks"; I executed 29 wired suites and 57 loop-kernel checks (implementation outgrew the prose). CI badge (README L10) targets the private repo → 404 publicly.
- Claim: Small but corrosive for a proof-obsessed product: its own claims about itself drift from its own artifacts.
- Why it matters: Reviewers (like this one) check these first; drift reads as either sloppiness or inflation.
- Falsifier: A test that derives README's counts from CI/suite reality.
- Recommended move: Make counts generated (e.g., `cvg doctor`-style introspection or a lint row) rather than hand-written.
- Acceptance evidence: `tests/test-version-unity.sh`-style gate failing on count drift.

### F-qwen3.8-max-12 — Public beachhead already exists elsewhere (task-spec repo) — and it splits the evidence

- Type: opportunity
- Surface: market
- Severity: low
- Confidence: medium
- Evidence: `https://github.com/luanmorenommaciel/task-spec` (public, MIT, v3.4.1) ships the same engine lineage with L0–L2 executor conformance, a Claude Code skill, and a GitHub Action CI eval-gate ("the merge gate stops trusting agent-pasted GREEN") — retrieved 2026-08-05.
- Claim: The cornerstone unit is already public and integration-ready; Converge's added value (passes, bind, loop, cockpit, cross-family judge) sits private on top of it.
- Why it matters: An adopter can get sealed-eval discipline today from task-spec without Converge — which both validates demand for the unit and pressures Converge to publish or lose its own wedge.
- Falsifier: Evidence that task-spec is intentionally deprecated in favor of Converge-only distribution.
- Recommended move: Move 1 should reconcile the two: Converge public as the fabric, task-spec referenced as the format/engine it embeds.
- Acceptance evidence: Cross-linked READMEs and one version story.

## 10. The Top Three Moves

### Move 1 — "Open the factory": public release with a portable proof bundle

- **Problem:** Nobody can install Converge and nobody can inspect its evidence (F-01, C9, C10, C14).
- **Why top three:** Every other improvement compounds to zero while distribution is 404. This is the single highest-leverage change because it unlocks adoption, external validation, contributor trust, and the credibility of Moves 2–3.
- **Affected users:** All prospective adopters; security reviewers who require inspectable evidence; contributors.
- **Scope:** Make the repo public at a clean tag; publish npm; point marketplace/plugin metadata at the public repo; restore an archived, desensitized proving-ground case (specs, receipts incl. the REFUTED handoff, settle commits) as `evidence/` so C4/C10 become inspectable without leaking proprietary content; fix stale counts (F-11); record a clean-room run as launch artifact; reconcile with the public task-spec repo (F-12).
- **Dependencies/sequencing:** First. Sanitize history/artifacts before making public.
- **Effort:** M · **Impact:** 9 · **Principal risk:** history scrubbing mistakes or exposing customer-adjacent content; mitigate with the archived-case approach instead of full history publication.
- **30-day outcome:** all three install doors return success on a clean machine; CI badge publicly green; ≥1 external party completes the clean-room flow. **90-day:** first external (non-owner) settled task in a third-party repo, reported without owner assistance.
- **Acceptance tests:** `npm install -g github:…/converge && cvg-install && cvg doctor` on clean macOS + Linux; `evidence/` receipts verify with shipped tooling; external issue filed by a stranger.
- **Score effect:** +0.8 (DX 5.5→7.5; evidence 6.5→8.0; slight differentiation lift).

### Move 2 — Make the flagship claim mechanical: hidden holdouts + locked judges + verdict receipts

- **Problem:** The two most attackable seams sit exactly on the differentiator: holdouts readable by the builder (F-02) and unlocked judge dispatch (F-03), plus verdicts missing from receipts (F-04).
- **Why top three:** Converge's market claim is verification-first trust. A single published demonstration that the holdout is prompt-theatre would sink the positioning; fixing it converts the strongest marketing sentence into an enforceable invariant. This is cheap relative to the trust it buys.
- **Affected users:** Security reviewers, compliance-minded engineering leaders, every tier-2 consumer.
- **Scope:** (a) split holdouts out of the worker-visible spec at bind time into `cvg/holdouts/<task>.md` (HMAC-sealed, judge-only; brief and AGENTS.task.md provably holdout-free); (b) verify-work.py adopts Pass 4's lockdown recipes per engine + explicit `--sandbox read-only` for codex; (c) receipt gains `verification` block (judge, independence, verdict, findings hash); (d) three new hermetic suite rows; (e) README/skills docs updated to claim exactly what the mechanism proves.
- **Dependencies:** none; parallelizable with Move 1.
- **Effort:** M · **Impact:** 8 · **Principal risk:** holdout relocation breaks existing spec fixtures/format compatibility — mitigate with format_version bump + migration test.
- **30-day:** all three enforcement rows green; docs claims match code. **90-day:** a published "red-team note" demonstrating the sealed-holdout path catches a stub-attack that tier-1 passes (recreate the obs-fence story publicly).
- **Acceptance tests:** worker brief contains zero holdout bytes (hashed comparison); stub judge writing a file → run fails; receipt schema test asserts verification block on settled runs.
- **Score effect:** +0.6 (security 7.5→8.5; differentiation 7.0→7.5).

### Move 3 — Ship the missing half of autonomy: Manager-in-CI + server-side eval-gate

- **Problem:** Autonomy today is one human-triggered task at a time; Manager (fleet dispatch) and the CI eval-gate are declared absent (README L396-398). "Autonomous Fabric" requires the fabric, i.e., many tasks flowing without per-task human kickoff, with server-side re-verification so the merge gate never trusts agent-side green.
- **Why top three:** This is what converts a compelling primitive into a category: the loop is proven; the scheduler and the server-side gate are the two pieces every alternative (Copilot agents, OpenHands resolver, Factory) already has in some form. Without them, Converge is a seatbelt; with them, it's the road.
- **Affected users:** Platform/DevEx teams, CI owners, anyone evaluating "autonomous delivery" rather than "assisted delegation".
- **Scope:** A reference Manager as GitHub Actions workflows: (a) frontier job — `cvg ready` → fan out `cvg loop --issue` per task with budget ceilings and concurrency caps; (b) settlement policy — PRs only, branch protection as final gate; (c) **CI eval-gate** — on PR, a server-side job re-runs the sealed evals from a clean checkout and re-verifies HMAC/path policy (port the pattern already public in the task-spec repo's GitHub Action, F-12); (d) `cvg ci` subcommand wrapping the re-verification for any CI system; (e) docs: threat model for fleet mode + cost ceilings.
- **Dependencies:** Move 1 (needs a public repo to host the workflows); Move 2 desirable first (fleet mode amplifies the judge/holdout seams).
- **Effort:** L · **Impact:** 9 · **Principal risk:** fleet mode multiplies cost and blast radius; a runaway Manager becomes the headline. Mitigate with hard global token/wall-clock ceilings per run-day and default-deny external writes.
- **30-day:** reference workflow settles 3 ready tasks from `cvg ready` unattended on a demo repo; CI eval-gate blocks a deliberately tampered PR. **90-day:** one external team runs the Manager nightly for ≥2 weeks with receipts + Cockpit health as the audit trail.
- **Acceptance tests:** hermetic Manager suite with stub engines (dispatch order respects deps; budget ceiling enforced; no dispatch of unsigned specs); CI gate suite proving a re-sealed-on-laptop eval fails server-side re-verification.
- **Score effect:** +0.7 (autonomy 6.5→8.5; differentiation and thesis lifts).

**Coherence:** Move 1 makes Converge visible; Move 2 makes its core claim unfalsifiable-by-accident; Move 3 makes the autonomy real at fleet scale. Together they convert "impressive private prototype" into "credible Autonomous Fabric candidate".

## 11. Suggested 30/60/90-Day Sequence

**Days 0–30**
1. Move 1: sanitize → public repo → npm/marketplace publication → `evidence/` archive (receipts, REFUTED handoff, settle commits) → clean-room recording.
2. Move 2 (parallel): holdout relocation + judge lockdown + receipt verification block; publish the tamper repro as a shipped suite (F-05).
3. Fix F-08 (scope Grok claim or add adapter) and F-11 (generated counts).

**Days 31–60**
4. Move 3 foundation: `cvg ci` server-side re-verification subcommand + GitHub Action (port from task-spec pattern); branch-protection reference config.
5. Cockpit uc-01 dated rerun against WorkspaceSnapshot 3.0 → flip PROVING-GROUNDS.md row; keep Cockpit out of the package until the remaining cases run.
6. Publish a red-team note: stub attack vs tier-1, holdout catch by tier-2, settlement refusal — with receipts.

**Days 61–90**
7. Move 3 completion: Manager reference workflow (frontier dispatch, global budget ceilings), run nightly on the owner's backlog and one friendly external repo.
8. First external contributor flow: docs for adding an engine adapter (`_engine_lib.sh` contract) and a tracker adapter; accept one of each from outside.
9. Positioning review: with public evidence in hand, decide whether "Autonomous Fabric" is claimed outright or reserved until fleet mode has ≥3 external operators.

## 12. What Should Not Be Built Yet

- **Multi-tenant/hosted control plane.** No fleet mode, no external operator base; a service would be an empty room.
- **Cockpit execution capabilities.** The read-only boundary is the architecture's integrity; the moment Cockpit can bind/settle, it becomes a second authority and the "CLI owns proof" story collapses. Keep Ask interpretation-only.
- **A proprietary model/router.** The referee-never-player invariant (zero credentials) is the trust anchor; anything that routes tokens through Converge destroys the differentiator.
- **Asymmetric-signing ceremony (Ed25519/DSSE) before basic distribution.** The setup script itself names it as a future upgrade; symmetric HMAC is honest and sufficient for the current threat model. Spend the effort on Move 1–3.
- **New harness integrations beyond the existing three engines** until a grok adapter decision is made and at least one external operator has run the loop.
- **Jira/Linear feature parity expansions in Register.** The fake-adapter-proven six-verb contract is enough; adoption does not hinge on board features.

## 13. Open Questions and Falsifiers

1. **Who pays?** Verification-first orchestration has no proven buyer yet. Falsifier for the thesis: any team paying for (or migrating production work onto) Moves 1–3 outputs within two quarters. [SPECULATION until evidenced]
2. **Does tier-2 change outcomes at scale?** One REFUTED case is a proof of existence, not of rate. Falsifier for skepticism: a published tier-2 hit-rate over ≥20 settled tasks (how often REFUTED fires on green evals).
3. **Is nine-pass ceremony net-positive?** METR's RCT (19% slowdown) is cited in `classify-lane.py` — does Converge's own FULL lane beat plain-agent baselines on wall-clock/cost for equivalent tasks? Falsifier for the method's value: a controlled comparison where FAST/NORMAL/FULL tasks complete cheaper+faster than unguided agent runs of the same specs.
4. **Can the holdout survive a determined worker?** Move 2's sealed-holdout design must withstand a worker explicitly prompted to find the criteria. Falsifier: any exfiltration path via git history, worktree copies, or bind-time caches.
5. **What happens when engine CLIs drift?** Adapter pinning is env-overridable but unversioned; a Claude/Codex flag rename degrades runs silently to defaults. Falsifier for robustness: adapter contract tests run against real CLIs in CI (needs credentialed, rate-limited leg — currently absent by design).
6. **Repo privacy intent.** If the private state is a deliberate pre-launch choice and the public release happens imminently, F-01's severity drops from "blocker" to "schedule item" — the review snapshot simply caught the pre-launch state. [INFERENCE]

## 14. Sources

All retrieved 2026-08-05 unless noted.

1. GitHub Spec Kit — repository. https://github.com/github/spec-kit
2. GitHub Spec Kit — documentation (integrations count, star/contributor claims, command reference incl. `/speckit.converge`). https://github.github.io/spec-kit/ (docs "last updated July 16, 2026" per search summary)
3. Kiro — Specs documentation. https://kiro.dev/docs/specs/
4. Kiro — product/documentation overview (Bedrock-backed agentic platform). https://kiro.dev/ ; https://aws.amazon.com/documentation-overview/kiro/
5. OpenSpec — repository + docs. https://github.com/Fission-AI/openspec ; https://openspec.dev/docs/getting-started
6. Tessl spec-driven-development tile. https://github.com/tesslio/spec-driven-development-tile ; https://docs.tessl.io/use/spec-driven-development-with-tessl
7. GitHub Copilot — OpenAI Codex coding agent concept. https://docs.github.com/en/copilot/concepts/agents/openai-codex
8. GitHub Copilot — Agents on GitHub (mission-control, third-party agents). https://github.com/features/copilot/agents ; https://docs.github.com/en/copilot/concepts/agents/about-third-party-coding-agents
9. GitHub Blog — assigning issues to the coding agent. https://github.blog/ai-and-ml/github-copilot/assigning-and-completing-issues-with-coding-agent-in-github-copilot/ ; changelog: https://github.blog/changelog/2026-02-04-claude-and-codex-are-now-available-in-public-preview-on-github/
10. OpenHands resolver — repository. https://github.com/OpenHands/OpenHands/tree/main/openhands/resolver
11. OpenHands blog — open-source coding agents fixing your issues (37% self-authored commits, Nov 12 2025). https://openhands.dev/blog/open-source-coding-agents-in-your-github-fixing-your-issues ; platform paper: https://arxiv.org/html/2407.16741
12. Devin pricing. https://devin.ai/pricing/
13. Cognition — new self-serve plans announcement. https://cognition.com/blog/new-self-serve-plans-for-devin
14. Factory pricing. https://factory.ai/pricing ; https://docs.factory.ai/pricing
15. Cognition vs Factory comparison (secondary, used only for feature framing). https://agenticindex.io/compare/cognition-vs-factory
16. Inspect AI — documentation. https://inspect.aisi.org.uk/
17. Inspect AI — repository. https://github.com/UKGovernmentBEIS/inspect_ai
18. OpenAI Codex — non-interactive mode (`codex exec` default read-only sandbox). https://developers.openai.com/codex/noninteractive
19. FABCON session "Autonomous Fabric: Agentic Data Quality Using Fabric Data Agents" (term collision). https://fabriccon.com/sitemap-categories/98-friday-sessions/731-autonomous-fabric-agentic-data-quality-using-fabric-data-agents
20. Eximius Ventures — DevAssure investment note ("autonomous fabric" of testing agents; term collision). https://medium.com/eximius-ventures/why-we-invested-in-devassure-503e7e528c2e
21. METR — RCT: early-2025 AI tools slowed experienced OSS developers 19% (claim cited by Converge's `classify-lane.py` verified accurate). https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ ; paper: https://doi.org/10.48550/arxiv.2507.09089
22. Public task-spec repository (owner's beachhead; L0–L2 conformance, GitHub Action eval-gate). https://github.com/luanmorenommaciel/task-spec
23. GitHub API probes establishing non-public status of `luanmorenommaciel/converge` (repo/raw/npm 404s; user's 11 public repos listed). https://api.github.com/repos/luanmorenommaciel/converge ; https://api.github.com/users/luanmorenommaciel/repos ; https://registry.npmjs.org/@luanmorenommaciel%2Fconverge

Repository evidence (local clone at `9c96688`): paths cited inline per finding; git-history items (PR merges #2–#9, receipt JSON, settle commits) observed via `git log/show` in this clone.

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "qwen3.8-max",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 74.8,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Interesting",
  "evidence_confidence": "High",
  "adopt_today": "conditional",
  "top_strength": "Settlement as a state-machine invariant: HMAC-sealed evals, hash-bound contracts, and a fail-closed loop verified end-to-end by independent tamper reproduction (840 local checks green).",
  "top_risk": "Distribution and proof are invisible: repository is not publicly reachable, all install doors 404, proving ground removed from tree; the flagship holdout claim is prompt-level, not mechanical.",
  "top_3": [
    {
      "rank": 1,
      "name": "Open the factory: public release with a portable proof bundle",
      "effort": "M",
      "impact": 9,
      "score_delta": 0.8
    },
    {
      "rank": 2,
      "name": "Mechanical verification boundary: sealed hidden holdouts, locked read-only judges, verdicts in receipts",
      "effort": "M",
      "impact": 8,
      "score_delta": 0.6
    },
    {
      "rank": 3,
      "name": "Manager-in-CI plus server-side eval-gate: fleet dispatch with global budget ceilings",
      "effort": "L",
      "impact": 9,
      "score_delta": 0.7
    }
  ],
  "critical_finding_ids": [
    "F-qwen3.8-max-01",
    "F-qwen3.8-max-02",
    "F-qwen3.8-max-03"
  ],
  "tests_run": {
    "passed": 840,
    "failed": 0,
    "blocked": 2
  },
  "external_sources": 23
}
```

Notes on the numbers: `tests_run.passed` = ~829 checks across 29 locally executed hermetic suites + 11 checks from my own adversarial reproductions; `blocked` = `test-portability-e2e.sh` (requires PyYAML absent on this host; CI installs locked deps) and the Cockpit node suites (npm install prohibited by review rules). `external_sources` counts distinct primary sources in §14. Score arithmetic: (8.5×10 + 7.0×15 + 8.5×15 + 7.5×20 + 8.5×15 + 6.5×10 + 5.5×10 + 6.5×5)/10 = 747.5/10 = 74.75 → 74.8.
