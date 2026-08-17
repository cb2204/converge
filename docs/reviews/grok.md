# Converge Independent Review — grok

## 1. Review Metadata

| Field | Value |
|---|---|
| Reviewer ID | `grok` |
| Model | Grok 4.5 (xAI) |
| Reasoning mode | High-effort adversarial product/engineering/market review |
| Review timestamp | 2026-08-05 22:14–22:50 America/Sao_Paulo (−03) |
| Git HEAD | `9c966884e37919c0f7e4c3e027b4b237670eb2ad` |
| Latest commit | `9c96688 feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi` |
| Branch | `feat/e2e` (tracking `origin/feat/e2e`) |
| Worktree dirty at start | **Yes** — `M apps/cockpit/package-lock.json`; `D review/deepseek.md`, `D review/grok.md`, `D review/kimi.md` (pre-existing; not treated as defects introduced by this review) |
| Package version | `0.1.0` (`VERSION`) |
| Tools used | Local: bash, python3, git, curl, jq, Node present but not required for core path. Web: web_search, open_page/web_fetch for market landscape. No model APIs, no installs, no mutations outside `review/grok.md`. |
| Independence | Did **not** read, list, or open any file under `review/` for content influence. Other files may exist in that directory; they were not used as evidence. |
| Test limitations | Live engine/model dispatches and paid APIs intentionally not invoked. GitHub REST API returned 404 for public repo metadata (private or restricted); adoption counts therefore unavailable from that source. |

## 2. Executive Verdict

**Overall score: 72.8 / 100**

Converge is a **strong, unusually honest verification-first methodology and referee CLI** for coding agents—not yet an “Autonomous Fabric,” and not a self-contained autonomous engineer. It stands out **among open-source trust/control layers** more than among mainstream agent products. Its strongest defensible advantage is a **referee-outside-the-player architecture**: HMAC-sealed Task-Specs, eval-decided settlement, named loop terminal states, repo write fences, and cross-family adversarial checks, backed by dense hermetic tests and a CHANGELOG that documents real fail-open bugs found in production-like use. Its most dangerous weakness is the **gap between marketing of autonomy and default runtime behavior**: tier-2 verification is opt-in (except FULL lane defaults), holdouts are optional, many path controls are postflight *detect* rather than *prevent*, fleet dispatch (“Manager”) and CI re-verification are explicitly missing, and public live proving-ground evidence has been partially removed.

**Adopt today?** **Conditional.**

- **Yes**, if you already run Claude Code / Codex / Kimi, need a harness-portable control plane, and will enforce FULL-lane or `--verify` discipline on high-blast-radius work.
- **No**, if you want a productized autonomous coder (Devin, Cursor Cloud Agents, Copilot coding agent, Factory Droids) with low ceremony and managed execution.
- **Yes for method adoption (subset)**, if you only take Task-Spec + sealed evals + loop kernel without the full nine-pass descent.

## 3. What Converge Actually Is

**Verified combination (this commit):**

1. **Methodology** — nine gated passes (Capture → Loop) with lane routing FAST / NORMAL / FULL.
2. **Portable skill pack** — twelve skills (markdown + scripts) installable into Claude / Codex / Kimi / Grok skill directories.
3. **Referee CLI (`cvg`)** — bash 3.2+ router; holds **no model credentials**; wraps skill scripts; machine tokens + exit-code contracts; optional `--json` / `agent-context`.
4. **Task-Spec engine** — signed, eval-first work units with effort tiers, state transitions, backlog tooling.
5. **Runtime contract + loop** — bind freezes execution profile; loop does attempt → verify → settle under budgets; default isolation is git worktree.
6. **Optional Cockpit** — observation UI over `cvg snapshot --json`; Ask is interpretation-only ACP; **not** in the zero-dep published core package while proving grounds remain open.

**What it is not (today):**

- Not a coding agent (engines are external).
- Not a multi-task fleet orchestrator (Manager explicitly deferred).
- Not a managed cloud runtime.
- Not a complete OS-level sandbox for every engine (enforcement strength varies by adapter; generic/kimi leave several controls unenforced).

**Clearest user:** Principal / staff engineers and platform owners who already multi-home coding agents and need **delegated work to be sealed, budgeted, and settleable with receipts**—especially teams burned by agent self-grading.

**Who pays:** Today, no clear commercial packaging. Likely buyers later: regulated/platform engineering orgs needing audit trails over multi-vendor agents; OSS power users already paying Claude/Codex/Kimi. End-user product engineers will default to IDE/cloud agents unless Converge compresses time-to-first-settled-task.

**Job done better than alternatives:** “Make autonomous coding **accountable** across harnesses without owning the model.” Most competitors optimize *completion*; Converge optimizes *settlement integrity*.

**Autonomy vs process:** Primarily **process and verification around externally operated agents**. The loop *does* autonomously retry under budgets, but the intelligence and most prevention sandboxes live in vendor CLIs. That is intentional and often correct—but it means “dark factory” / “autonomous fabric” language oversells if tier-2 and multi-task orchestration remain incomplete.

## 4. Repository and Test Coverage

### Structure (inspected)

| Surface | Evidence |
|---|---|
| CLI | `bin/cvg` (~2.7k lines), `bin/_ui.sh`, `bin/cvg-snapshot.py`, `bin/README.md` |
| Skills | 12 under `skills/` with scripts, fixtures, SKILL.md |
| Contracts | `contracts/ui/v{1,2,3}/workspace-snapshot.schema.json` |
| Gate policy | `.cvg/gate.yaml` (repo write fence) |
| CI | `.github/workflows/ci.yml` — dual OS (ubuntu + macos), hermetic gauntlet + separate cockpit job |
| Cockpit | `apps/cockpit/` (Vite/React + Node bridge, Playwright, Vitest) |
| Install | `install.sh`, npm package files whitelist, plugin marketplace metadata |
| Root docs | `README.md`, `CHANGELOG.md` (extensive honest defect history), PDFs/presentation |

### Tests run in this review (hermetic, local)

| Suite | Command | Outcome |
|---|---|---|
| Loop kernel | `bash tests/test-loop-kernel.sh` | **PASS — 57/57** |
| HMAC envelope | `bash skills/task-spec/tests/test-hmac-envelope.sh` | **PASS — 38/38** |
| Version unity | `bash tests/test-version-unity.sh` | **PASS — 12/12** |
| Gate policy | `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py` | **PASS — 10/10** |
| Doctor host | `bash tests/test-cvg-doctor-host.sh` | **PASS — 13/13** |
| Pass 4 consensus | `bash skills/sketch-plans-adversarial-review/tests/run-tests.sh` | **PASS — 23/23** |
| Runtime contract | `bash skills/task-to-runtime-contract/tests/run-tests.sh` | **PASS — 48/48** |
| Clean-room e2e | not re-run (long); present in CI workflow | **Not re-executed here** |
| Cockpit browser | not re-run (Playwright + Chromium install cost) | **Not re-executed here** |
| Live model UPHELD/REFUTED | not run (paid APIs forbidden by brief) | **Blocked by policy** |

**Inference:** CI wiring is serious: suite-coverage gate (`tests/test-ci-covers-every-suite.sh`), shellcheck, skill validation, npm pack anchors, dual bash portability. Implementation quality of the *control plane* is high relative to project age.

**Smoke:** `bash bin/cvg version` → `cvg 0.1.0`; `cvg help` renders referee surface.

## 5. Claim-to-Evidence Audit

For each major claim: implemented? enforced at runtime? outside worker authority? tested? inspectable evidence? honest docs? end-user reachable?

| Claim | Implemented | Runtime enforced | Outside worker | Meaningful tests | Repo evidence | Honest docs | E2E user reach |
|---|---|---|---|---|---|---|---|
| Eval decides done | Yes — Exit Check in loop | Yes for settle path | HMAC + write scope aim to keep evals out of agent write surface | Yes (loop kernel, task-spec suites) | Scripts + fixtures | Yes | Yes with engines or stubs |
| Referee holds no model keys | Yes — design of `cvg` / `.cvg/config` | Yes | N/A | Design + install docs | `bin/cvg`, setup surfaces | Yes | Yes |
| HMAC sign-off seal | Yes — hmac-sha256-v2 | Yes on validate/gate | Key in git-private state | **38/38 HMAC suite** | `safe-to-delegate.sh`, tests | Yes | Requires `cvg setup signing` |
| Cross-family Pass 4 | Yes — dispatch + gate | Gate re-hashes plans; human must decide objections | Adversary ≠ owner | **23/23** including adversary-proposal-only fail | CHANGELOG live bugs fixed | Yes, detailed | Needs ≥2 engines for full strength |
| Tier-2 holdout judge | Yes — `verify-work.py` | **Only when enabled** (`--verify` / FULL lane / cost profile) | Judge ≠ worker family preferred | Runtime suite tests fail-closed & empty-diff | README claims live UPHELD/REFUTED | Docs admit opt-in cost tradeoff | Holdout **optional** in authoring |
| Loop budgets + named terminals | Yes — loop-kernel | Yes | Kernel not agent | **57/57** | Terminal token contract | Yes | Yes |
| Worktree isolation default | Yes | Default `worktree` | OS/git boundary | Loop suite | loop-kernel | Yes | Yes if git present |
| Write fence `.cvg/gate.yaml` | Yes | Settlement + candidate guards | Policy not in signed payload | Gate policy tests + CI refuse `auth/` | `.cvg/gate.yaml` | Yes | Yes |
| Path policy prevent vs detect | Partial | **Mostly detect** portable; prevent only via vendor sandboxes when installed | Settlement cannot unring bell | Runtime manifest explicit | `_runtime_contract.py` RUNTIME_CONTROLS | Honest in code | Engine-dependent |
| Harness-agnostic | Yes install targets | Skills install; adapters thin | Engines still vendor-specific | Install + portability tests | install.sh | Yes | User must install engines |
| Manager / multi-task autonomy | **No** | N/A | N/A | N/A | README “not in 0.1.0” | **Honest absence** | No |
| CI server-side eval re-verify | **No** | N/A | N/A | N/A | README roadmap | Honest absence | No |
| Cockpit proving grounds complete | **No** | Observation only | Yes (cannot settle) | Hermetic UI tests | `PROVING-GROUNDS.md` all open/not run | **Refreshingly honest** | Dev-only |
| Self-host / dogfood settled tasks | Claimed in README | Not re-verified here with live agents | N/A | Hermetic clean-room with **stubs** | CHANGELOG; `uc-analytics` removed | Partial—claims strong, artifacts partly gone | Medium |
| Zero runtime deps for core | Yes bash+stdlib python | Yes | N/A | CI dual OS | package.json files list | Cockpit correctly excluded | Yes |
| bash 3.2 portability | Core yes; **lint needs bash 4+** | Documented gap | N/A | Portability suite; lint skip on 3.2 | README/CHANGELOG | Yes after fix | macOS stock lint = UNSUPPORTED |

**Critical claim gap:** Marketing emphasizes “done is proven by runnable evals” and “cross-family verification,” but the **default settlement path can complete on sealed evals alone** without holdout or independent judge unless lane FULL or operator opts in. That is an architectural choice documented in loop-kernel comments (cost/timeouts), not a silent lie—but it undercuts the strongest product story when users follow the quickstart with `--agent claude` only.

## 6. Market Landscape

Research date: **2026-08-05**. Primary sources preferred. No fabricated adoption metrics. GitHub public API for this repo returned 404; star/download counts for Converge are **unavailable** here.

### Alternatives (direct / adjacent)

| Product | Primary user / use case | Unit of autonomy | Spec / plan model | Verification / acceptance | Agent/model portability | Execution boundary | Observability / audit | Setup cost | Maturity signal (external) | Converge advantage | Converge disadvantage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Devin (Cognition)** | Enterprise eng teams; async software tasks | End-to-end SWE agent | Natural language + agent planning | Agent self-test + human PR review | Proprietary stack | Managed/cloud sandboxes | Product UI | High (commercial) | Goldman Sachs hybrid workforce pilot coverage; product site active 2026 | Open, referee-owned settlement; multi-harness; signed specs | No managed agent; much less turnkey autonomy |
| **Cursor Cloud / Background Agents** | IDE-centric developers | Parallel cloud agents → PR | Chat/task prompts | Tests if user configured; human merge | Multi-model in Cursor | Isolated cloud env | Product history UI | Low–medium | Broad consumer/pro adoption via Cursor product | Vendor-neutral control plane; HMAC eval integrity | Far weaker UX; no IDE gravity |
| **GitHub Copilot coding agent** | GitHub-native teams | Issue → draft PR via Actions | Issue/prompt | CI + PR review | GitHub/Microsoft stack | Actions environment | PR + Actions logs | Low if already on GitHub | GA for paid Copilot (2025 announcements) | Cross-tracker; deeper Task-Spec formality | No native GitHub embedding; higher ceremony |
| **OpenHands / Agent Canvas** | OSS teams wanting self-hosted agent control center | Multi-agent sessions + automations | Conversations, issue decompose | Runtime tests / user-defined | ACP multi-agent (Claude, Codex, Gemini, etc.) | Local/Docker/VM/cloud backends | Canvas UI | Medium | Large OSS footprint; beta Agent Canvas | Stronger sealed Task-Spec + settle tokens; referee purity | Weaker productized agent runtime & multi-backend ops |
| **Aider** | CLI pair programmers | Local edit+commit loop | Chat + git map | User/tests | Many LLMs | Local filesystem | Git history | Very low | High OSS install/star signals historically | Production-line gates, signing, multi-pass method | Heavier than “just code with me” |
| **Factory Droids** | Startups/enterprises SDLC automation | Ticket-to-code Droids | Tickets + integrations | Product workflows | Multi-model product claim | Product-managed | Product surfaces | Commercial | Terminal-Bench claims; funding coverage 2025–2026 | Open auditability; no vendor lock on control plane | Not a commercial factory product |
| **SWE-agent / mini-SWE-agent + SWE-bench** | Research & eval | Issue→patch in harness | Issue text | Containerized unit tests | Model-swappable harness | Docker eval sandboxes | Benchmark scores | Medium research setup | SWE-bench Verified ecosystem | Org delivery method, not only benchmark | No benchmark product surface; less research mindshare |
| **Claude Code / Codex (engines alone)** | Individual & team builders | Headless or interactive session | CLAUDE.md / prompts | User-defined | Single-vendor strong | Local + optional sandbox | Session logs | Low–medium | Anthropic usage research; Codex product | Converge adds independent settle layer across engines | Engines already “good enough” for many without ceremony |

Sources (retrieval 2026-08-05):  
https://cognition.com/ · https://devin.ai/ · https://cursor.com/ · https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent · https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/ · https://github.com/OpenHands/OpenHands · https://aider.chat/ · https://factory.ai/ · https://www.swebench.com/ · https://www.anthropic.com/research/claude-code-expertise · https://www.anthropic.com/engineering/how-we-contain-claude · market context https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf · https://www.deloitte.com/us/en/insights/industry/technology/technology-media-and-telecom-predictions/2026/ai-agent-orchestration.html

### Market reading (inference)

2026 market gravity is **productized autonomous agents** (cloud async PR machines) and **IDE-native fleets**, not open control-plane methodologies. Governance, observability, and multi-agent orchestration are recognized enterprise needs (Deloitte, Gartner-cited industry pieces), but buyers usually buy them *attached* to an agent product. Converge’s open “referee” wedge is real and under-served—but **category ownership requires either default-on trust that users feel without study, or undeniable public settlement evidence.**

## 7. Competitive Position

**Position today: Distinct (trust/control plane), not category-leading (autonomous delivery).**

Differentiation that survives inspection:

1. **Eval-sealed Task-Spec as unit of work** with HMAC that seals authorization fields and eval bodies.
2. **Referee never player** — rare purity among agent products.
3. **Named terminal states** and three-axis budgets with stagnation (implemented, tested).
4. **Cross-family adversarial review at plan barrier** with provenance re-hash (hardened after live failures).
5. **Honest fail-closed culture** in code comments, CHANGELOG, and Cockpit proving-grounds doc.

Table stakes (not differentiating alone):

- Multi-model support  
- Git worktrees / branch isolation  
- PR settlement  
- Tracker projection  
- Observation dashboards  

**“Autonomous Fabric” as a position:** The term is **aspirational, weakly present** in the product voice (README leads with “dark factory” / compile intent). As a category label it is **not yet ownable**: fabric implies multi-node continuous delivery; the implementation is a **single-task control loop plus design descent**. Defensible if Manager + CI gates + multi-workspace orchestration land; currently better claimed as **“the open referee for multi-harness agent delivery.”**

## 8. Scorecard

| Dimension | Weight | Score (0–10) | Weighted points (score × weight / 10) |
|---|---:|---:|---:|
| Problem and product thesis | 10% | 8.0 | 8.00 |
| Differentiation and market position | 15% | 7.2 | 10.80 |
| Method and architecture coherence | 15% | 8.6 | 12.90 |
| Trust, verification, and security model | 20% | 7.4 | 14.80 |
| Implementation quality and reliability | 15% | 8.7 | 13.05 |
| Autonomous end-to-end completeness | 10% | 5.2 | 5.20 |
| Developer experience and adoption readiness | 10% | 5.4 | 5.40 |
| Evidence, credibility, and project maturity | 5% | 5.3 | 2.65 |
| **Overall** | **100%** | | **72.80** |

**Vision potential:** High  
**Current readiness:** Alpha (control plane Beta-ish; product autonomy Alpha)  
**Market position:** Distinct  
**Evidence confidence:** Medium (high on hermetic implementation; medium-low on live multi-agent production outcomes shipped in-tree)

## 9. Prioritized Findings

### F-grok-01 — Tier-2 verification is opt-in on the default settle path

- Type: claim gap  
- Surface: runtime · docs  
- Severity: critical  
- Confidence: high  
- Evidence: `skills/task-loop/scripts/loop-kernel.sh` (VERIFY defaults false unless FULL/`--verify`; message “settling on the sealed eval alone”); `skills/task-to-runtime-contract/references/verification.md` (“optional ## Holdout”); loop-kernel test row “FULL turns tier 2 on without being asked twice”  
- Claim: Green sealed evals can settle without independent holdout judgment on FAST/NORMAL unless operator opts in.  
- Why it matters: Undermines the core differentiation vs self-grading agents.  
- Falsifier: Default `--verify` on, or gate that refuses settle without UPHELD/UNAVAILABLE-policy for all lanes.  
- Recommended move: Default tier-2 on for NORMAL+; require holdout section for high blast radius; keep `--no-verify` audited.  
- Acceptance evidence: Loop suite proves NORMAL settles only after tier-2 path; docs/quickstart match.

### F-grok-02 — Holdout criteria are not required to sign or delegate

- Type: design risk  
- Surface: skills · security  
- Severity: high  
- Confidence: high  
- Evidence: no holdout checks in `safe-to-delegate.sh`; verification.md marks Holdout optional; validate-task-spec required zones omit Holdout  
- Claim: A worker can optimize against all sealed visible evals with no hidden criteria.  
- Why it matters: Train/test separation is incomplete if the test set is empty by default.  
- Falsifier: Sign-off fails without `## Holdout` when blast radius high or profile full.  
- Recommended move: Make holdout mandatory for L+ / sensitive paths / FULL profile.  
- Acceptance evidence: Gate suite fixtures for missing holdout → fail.

### F-grok-03 — Portable path control is primarily postflight detect

- Type: design risk  
- Surface: security · runtime  
- Severity: high  
- Confidence: high  
- Evidence: `_runtime_contract.py` RUNTIME_CONTROLS: generic/kimi `fs.write` detect; claude Bash broader; proc/net unenforced on generic/kimi; settlement uses `check-path-policy.py`  
- Claim: Unauthorized writes can happen during the attempt; settlement refuses commit—not preemptive containment for all engines.  
- Why it matters: Side effects, secret reads, and non-git-visible damage can occur before detect.  
- Falsifier: Default prevent sandbox for all supported engines with attestation.  
- Recommended move: Require prevent-level fs/net for unattended SETTLED external writes; refuse engines that only detect.  
- Acceptance evidence: Bind fails closed without prevent when `external_writes=allow`.

### F-grok-04 — No Manager: single-task loop is not a fabric

- Type: market gap  
- Surface: method · runtime  
- Severity: high  
- Confidence: high  
- Evidence: README “What’s deliberately not in 0.1.0: the Manager”; bin/README “fleet — the Manager”  
- Claim: Multi-task scheduling, parallel ready frontier, PR watch are out of scope.  
- Why it matters: Category language and enterprise adoption expect fleet behavior.  
- Falsifier: Shipped manager that selects from `cvg ready`, parallel loops, requeues failures.  
- Recommended move: Minimal Manager over ready queue + CI scheduler.  
- Acceptance evidence: Clean-room multi-task settle with dependency order.

### F-grok-05 — Live proving-ground evidence partially removed / Cockpit gates open

- Type: claim gap  
- Surface: evidence · Cockpit · docs  
- Severity: high  
- Confidence: high  
- Evidence: CHANGELOG notes `uc-analytics` removed; `apps/cockpit/PROVING-GROUNDS.md` all cases open/not run; CI forbids residual `uc-analytics` refs  
- Claim: Strong live UPHELD/REFUTED narrative is not currently reproducible from in-repo proving grounds.  
- Why it matters: Trust product without public receipts becomes faith-based.  
- Falsifier: Versioned evidence pack with logs, hashes, PRs, judge transcripts redacted.  
- Recommended move: Publish `evidence/` pack for at least two bidirectional tier-2 cases.  
- Acceptance evidence: Scripted replay or linkable artifacts with commit pins.

### F-grok-06 — Ceremony and multi-engine requirements block first success

- Type: market gap  
- Surface: docs · distribution · DX  
- Severity: high  
- Confidence: medium  
- Evidence: Quickstart requires init, signing, lane, tasks, validate, gate, bind, loop; doctor wants ≥2 engines + cross-family for full method; lint unsupported on bash 3.2  
- Claim: Time-to-first-settled-task for a newcomer is high vs Cursor/Copilot/Aider.  
- Why it matters: Distinct method dies if only authors can operate it.  
- Falsifier: Documented <30 min path with one engine and stub judge producing LOCAL_SETTLED.  
- Recommended move: “Steel thread” installer that scaffolds health-endpoint task + stub engine demo.  
- Acceptance evidence: Clean-room timed tutorial suite.

### F-grok-07 — Strength: hermetic brakes and fail-closed culture

- Type: strength  
- Surface: runtime · tests  
- Severity: positive  
- Confidence: high  
- Evidence: loop-kernel 57/57; runtime-contract 48/48; HMAC 38/38; CHANGELOG records barrier self-pass, conductor past barrier, DoD comma truncation, untracked provenance, etc., then fixes  
- Claim: Engineering culture treats unenforced policy as a defect class and ships tests that go red against real bugs.  
- Why it matters: Rare credibility in agent tooling.  
- Falsifier: Silent skip of major suites in CI (currently guarded).  
- Recommended move: Keep suite-coverage gate sacred; expand to live-evidence CI optional job.  
- Acceptance evidence: CI remains green dual-OS without secrets.

### F-grok-08 — Strength: referee purity and agent-native CLI contracts

- Type: strength  
- Surface: CLI  
- Severity: positive  
- Confidence: high  
- Evidence: `cvg` wrap-not-rewrite; no LLM calls; machine tokens; `agent-context`; `--json` envelope tests in CI  
- Claim: Agents and scripts can drive Converge without scraping prose.  
- Why it matters: Enables future Manager and external orchestrators.  
- Falsifier: Commands that only print human prose without tokens.  
- Recommended move: Stabilize schema_version of agent-context as public API.  
- Acceptance evidence: Published contract tests for consumers.

### F-grok-09 — Cross-family Pass 4 is real but human-gated and expensive

- Type: design risk  
- Surface: method  
- Severity: medium  
- Confidence: high  
- Evidence: barrier requires owner decisions; adversary dispositions alone fail (`adversary-proposal-only` test); dispatch needs engines; timeout paths exist  
- Claim: The barrier is a genuine control, not theater—but it is a human bottleneck and multi-engine cost center.  
- Why it matters: FULL autonomy claims collide with required human sign-off (good for safety, bad for “dark factory” rhetoric).  
- Falsifier: Fully unattended consensus without weakening owner consent.  
- Recommended move: Keep human barrier; productize objection resolution UX in Cockpit.  
- Acceptance evidence: Cockpit resolve flow with provenance intact.

### F-grok-10 — Engine adapters are thin; autonomy quality inherits vendors

- Type: design risk  
- Surface: runtime  
- Severity: medium  
- Confidence: high  
- Evidence: `engines/claude.sh` etc. headless wrappers; RUNTIME_CONTROLS variance; engines authenticate themselves  
- Claim: Settlement integrity ≠ implementation quality; Converge cannot make a weak engine strong.  
- Why it matters: Users may blame Converge for agent failure modes it does not own.  
- Falsifier: Converge-owned planner/executor with competitive SWE scores (out of scope today).  
- Recommended move: Position as control plane; publish engine matrix of expected isolation strength.  
- Acceptance evidence: Doctor prints prevent/detect matrix per installed engine.

### F-grok-11 — Cockpit safety boundary is carefully designed but incomplete product

- Type: strength (security) + claim gap (product)  
- Surface: Cockpit  
- Severity: medium  
- Confidence: high  
- Evidence: loopback bind; snapshot-only observe path; Ask isolation (Claude plan/no-tools; Codex blocked); SHA-bound artifacts; PROVING-GROUNDS open  
- Claim: Observation path does not become a second control plane—good—but release readiness is not claimed and should not be.  
- Why it matters: Avoids the classic “dashboard reimplements truth” failure.  
- Falsifier: Bridge that runs gates or mutates workspace without cvg.  
- Recommended move: Finish one proving-ground rerun before marketing Cockpit.  
- Acceptance evidence: Dated WorkspaceSnapshot 3.0 case closed in PROVING-GROUNDS.md.

### F-grok-12 — Opportunity: open standard for signed Task-Specs

- Type: opportunity  
- Surface: market · skills  
- Severity: positive  
- Confidence: medium  
- Evidence: schemas under task-spec; dispatch recipes for multiple engines; consume examples in TS/Python  
- Claim: Task-Spec could become an interop standard other harnesses emit/consume.  
- Why it matters: Category ownership via protocol > ownership via UI.  
- Falsifier: No external consumers after 12 months.  
- Recommended move: Extract Task-Spec as versioned spec + conformance suite package.  
- Acceptance evidence: Third-party engine adapter outside this monorepo.

### F-grok-13 — macOS bash 3.2 lint gap remains a real product hole

- Type: verified defect (acknowledged)  
- Surface: CLI · DX  
- Severity: medium  
- Confidence: high  
- Evidence: README `LINT=UNSUPPORTED` on stock macOS; CHANGELOG documents gap; CI still runs bash 3.2 for core  
- Claim: Backlog lint—the graph health tool—is unavailable on the primary developer OS without brew bash.  
- Why it matters: Cycles/overlaps can slip on the OS the project markets portability for.  
- Falsifier: bash 3.2 rewrite of lint-backlog.  
- Recommended move: Port lint or provide python stdlib equivalent.  
- Acceptance evidence: test-cvg-lint green on bash 3.2 CI image without brew bash.

## 10. The Top Three Moves

### Move 1 — Default-on independent verification for non-trivial work

- **Problem:** Strongest trust claim is not the default settle path.  
- **Why top three:** Closes the integrity gap without inventing a new product category; raises defensibility vs every self-grading agent.  
- **Users:** Anyone settling NORMAL/FULL or sensitive paths.  
- **Scope:** `loop-kernel.sh` defaults; `safe-to-delegate.sh` / validate holdout rules; lane classifier; docs/quickstart; loop + task-spec tests.  
- **Dependencies:** None hard; better with second engine install story.  
- **Effort:** M  
- **Impact:** 9  
- **Principal risk:** Cost/latency backlash → users force `--no-verify` everywhere.  
- **30-day outcomes:** NORMAL defaults verify; high blast radius requires holdout; audited waiver token.  
- **90-day outcomes:** Public metrics of REFUTED catch rate; waiver rate dashboard via receipts.  
- **Acceptance tests:** Suite proves settle blocked without tier-2 on NORMAL; holdout-missing fails stamp for high risk.  
- **Score delta:** +4.0 to +6.0 overall (trust + autonomy dimensions).

### Move 2 — Evidence pack + steel-thread first success (credibility + adoption)

- **Problem:** Live claims outrun in-repo reproducible evidence; first success is ceremonial.  
- **Why top three:** Without believable receipts and a fast win, distinct tech stays niche.  
- **Users:** Prospective OSS adopters, design partners, security reviewers.  
- **Scope:** Restored minimal proving ground or `evidence/v0.1/`; timed tutorial; optional stub-judge path; PROVING-GROUNDS close one Cockpit case; marketing copy alignment.  
- **Dependencies:** Move 1 makes evidence more interesting.  
- **Effort:** M  
- **Impact:** 8  
- **Principal risk:** Evidence that only works on authors’ machines.  
- **30-day outcomes:** One bidirectional tier-2 case with redacted transcripts + hashes; 30-minute steel thread scripted.  
- **90-day outcomes:** Monthly public settlement report; external design partner quote.  
- **Acceptance tests:** CI optional job or script verifies artifact hashes; clean-room tutorial exits LOCAL_SETTLED.  
- **Score delta:** +3.0 to +5.0 (evidence + DX).

### Move 3 — Minimal Manager + CI re-verify gate (fabric skeleton)

- **Problem:** Single-task loop cannot own “Autonomous Fabric” or enterprise delivery.  
- **Why top three:** Completes the product hypothesis; matches market expectation of fleet autonomy while keeping referee purity.  
- **Users:** Platform teams, dark-factory operators, CI owners.  
- **Scope:** New `cvg manage` or Actions workflow: consume `cvg ready`, dispatch N loops with concurrency, re-run evals server-side, refuse merge without receipt chain; tracker updates.  
- **Dependencies:** Stable agent-context; reliable loop; Move 1 recommended.  
- **Effort:** L  
- **Impact:** 9  
- **Principal risk:** Premature orchestration complexity before single-task reliability is universal.  
- **30-day outcomes:** Serial manager over ready queue in one repo; CI job re-runs Exit Check on PR.  
- **90-day outcomes:** Parallel workers with dependency respect; org-wide template Action.  
- **Acceptance tests:** Multi-task clean-room; PR without receipt fails check.  
- **Score delta:** +5.0 to +8.0 if reliable (autonomy + market position).

**Coherent strategy:** Prove integrity by default (1), make the proof legible and easy to try (2), then scale dispatch (3). Reverse order risks a larger autonomous surface that still self-grades.

## 11. Suggested 30/60/90-Day Sequence

**Days 0–30**

- Implement Move 1 defaults + holdout rules.  
- Ship steel-thread tutorial and one pinned evidence pack (Move 2 start).  
- Close bash 3.2 lint gap or explicitly demote lint from “must.”  
- Publish engine isolation matrix via `cvg doctor`.

**Days 31–60**

- Serial Manager MVP over `cvg ready` + GitHub Action eval re-verify.  
- Cockpit: one proving-ground WorkspaceSnapshot 3.0 rerun recorded.  
- Objection resolution UX or CLI polish for Pass 4 bottleneck.  
- Conformance suite extract for Task-Spec consumers.

**Days 61–90**

- Parallel Manager with concurrency limits and dependency DAG.  
- Design partner program (2–3 teams) measuring settle rate, REFUTED catch rate, time-to-first-settle.  
- Revisit positioning: own “open referee for multi-harness delivery”; use “Autonomous Fabric” only if Manager+CI evidence supports it.  
- Optional: prevent-level sandbox requirement for external_writes=allow.

## 12. What Should Not Be Built Yet

- Full multi-tenant SaaS control plane  
- Converge-owned coding model or competitive Devin clone  
- Expanding pass count beyond nine without Manager  
- Auto-resolving Pass 4 critical objections without humans  
- Cockpit mutation APIs that bypass `cvg`  
- Broad marketplace of third-party skills before Task-Spec conformance is externalized  
- Complex knowledge-accretion / self-improving doctrine generators (scaffold-router already refuses doctrine generation—keep that discipline)

## 13. Open Questions and Falsifiers

1. **What is the real REFUTED catch rate** on non-author workloads over 100 tasks? Falsifier: public anonymized metrics.  
2. **Can a single-engine team** get most value, or is cross-family a hard requirement for the product thesis?  
3. **Will enterprises pay for a referee** separate from agents they already buy?  
4. **Does HMAC-in-repo-key** meet org secret management norms, or must signing move to HSM/KMS?  
5. **Is postflight-only path policy** acceptable under realistic agent tool use (bash side effects)?  
6. **Does FULL-lane cost** cause systematic under-routing to FAST?  
7. **Would Task-Spec interop** attract engine vendors, or only this monorepo?  

## 14. Sources

### Repository (primary evidence)

- `README.md`, `CHANGELOG.md`, `VERSION`, `package.json`, `install.sh`  
- `bin/cvg`, `bin/README.md`, `bin/cvg-snapshot.py`  
- `.cvg/gate.yaml`, `.github/workflows/ci.yml`  
- `skills/task-loop/scripts/loop-kernel.sh`, `engines/*`  
- `skills/task-spec/scripts/*`, HMAC/validate/safe-to-delegate  
- `skills/task-to-runtime-contract/scripts/*`, `references/verification.md`  
- `skills/sketch-plans-adversarial-review/scripts/*`  
- `apps/cockpit/README.md`, `PROVING-GROUNDS.md`, `server/security.mjs`  
- Local test runs listed in §4  

### External (market; retrieved 2026-08-05)

- https://cognition.com/  
- https://devin.ai/  
- https://cursor.com/  
- https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent  
- https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/  
- https://github.com/OpenHands/OpenHands  
- https://aider.chat/  
- https://factory.ai/  
- https://factory.ai/news/terminal-bench  
- https://www.swebench.com/  
- https://github.com/SWE-agent/SWE-agent  
- https://www.anthropic.com/research/claude-code-expertise  
- https://www.anthropic.com/engineering/how-we-contain-claude  
- https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf  
- https://www.deloitte.com/us/en/insights/industry/technology/technology-media-and-telecom-predictions/2026/ai-agent-orchestration.html  
- https://ibm.com/think/news/goldman-sachs-first-ai-employee-devin (secondary coverage of Devin enterprise pilot)

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "grok",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 72.8,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Distinct",
  "evidence_confidence": "Medium",
  "adopt_today": "conditional",
  "top_strength": "Referee-outside-player architecture with sealed Task-Specs, named loop terminals, and fail-closed hermetic tests",
  "top_risk": "Default settle path can skip independent holdout verification while marketing implies autonomy with proven done",
  "top_3": [
    {
      "rank": 1,
      "name": "Default-on independent verification for non-trivial work",
      "effort": "M",
      "impact": 9,
      "score_delta": 5.0
    },
    {
      "rank": 2,
      "name": "Evidence pack and steel-thread first success",
      "effort": "M",
      "impact": 8,
      "score_delta": 4.0
    },
    {
      "rank": 3,
      "name": "Minimal Manager and CI re-verify gate",
      "effort": "L",
      "impact": 9,
      "score_delta": 6.5
    }
  ],
  "critical_finding_ids": [
    "F-grok-01",
    "F-grok-02",
    "F-grok-03",
    "F-grok-04",
    "F-grok-05"
  ],
  "tests_run": {
    "passed": 201,
    "failed": 0,
    "blocked": 3
  },
  "external_sources": 16
}
```
