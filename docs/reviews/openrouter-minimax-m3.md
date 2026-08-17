# Converge Independent Review — openrouter-minimax-m3

## 1. Review Metadata

- Reviewer / model: openrouter/minimax/minimax-m3 (reasoning mode enabled; effort not exposed by upstream).
- Workstation: darwin 25.5.0 / arm64 (Apple M2).
- Review timestamp: 2026-08-05, America/Sao_Paulo (UTC-03).
- Repository HEAD: `9c966884e37919c0f7e4c3e027b4b237670eb2ad` — "feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi".
- Branch: `feat/e2e` (a feature branch; remote `origin` is `git@github.com:luanmorenommaciel/converge.git`).
- Working-tree state on entry: dirty. `git status --short` reports 4 modifications: `M apps/cockpit/package-lock.json`, `D review/deepseek.md`, `D review/grok.md`, `D review/kimi.md`. These predate this review; per the rules I did not touch them.
- Tools available: `bash` 5.3.9, `python3` 3.14.3, `git` 2.50.1, `shellcheck` 0.11.0, `curl`, `web_search`, full `read` / `grep` / `glob` / `bash` toolchain. Live model CLIs present: `codex-cli 0.146.1`, `kimi 0.33.0`, `claude 2.1.223 (Claude Code)`.
- Public-web research: enabled and used (see §6).

## 2. Executive Verdict

**Overall score: 7.3 / 10.**

Converge stands out today as one of the few open-source code-agent systems with a *formal* cross-family verification boundary — a referee (`cvg`) that holds zero model credentials, dispatches engine CLIs headlessly, and gates their output. The 0.1.0 release ships a real, working loop kernel with named terminal states, a HMAC-sealed eval contract, a worktree-isolated execution profile, and a hermetic test gauntlet of 29 wired suites. Its strongest defensible advantage is the *enforceable separation* between the maker and the checker, plus the explicit rejection of self-review at Pass 4 — both implemented and proven by tests against the shipped code, not merely documented.

The most dangerous weakness is the gap between ambition and discoverability: the public GitHub URL the README points at (`https://github.com/luanmorenommaciel/converge`) currently returns 404, the repo is not in the public API, and the only public-conversation hook is the sibling `agentspec` (224 stars). The four Cockpit proving-ground cases are all "Open" or "Not run" in the project's own release ledger; the claimed tier-2 holdout demonstration ran on two specs that have since been moved out of the tree; and the "Autonomous Fabric" framing is a coinage, not an established market category.

**Adoption verdict: conditional.** I would not adopt Converge as the day-to-day control plane for a paying team today; the Manager is missing, the install surface has known bash-portability debt (`cvg lint` requires bash 4+), and the tier-2 differentiator is opt-in rather than default. I would adopt it as a *narrow, authoritative shell around a single task type with measurable eval discipline* — and the Hermetic test gauntlet shows the system can stand behind that narrow claim today.

## 3. What Converge Actually Is

Converge is, simultaneously and somewhat deliberately:

1. **A method** — nine passes from "Capture" to "the Loop", with the fourth pass named `Consensus` (the only one a human must sign).
2. **A referee CLI** — `cvg` (a 2,678-line bash dispatcher with a Python stdlib helper at the bottom), zero model credentials, no LLM calls. Every gate is a byte-exact pass-through to a skill script.
3. **A skill pack of twelve** — installed into the harness's native directory (`.claude/skills/`, `.agents/skills/`, `.grok/skills/`), so the same method reaches Claude Code, Codex, Kimi, and Grok Build with the same gates.
4. **An execution loop** — `loop-kernel.sh` (1,024 lines), per-task, worktree-isolated, with three-axis budgets, a stagnation fingerprint detector, eight named terminal states, and a separate settler (`open-issue-pr.sh`) that commits + pushes + opens a PR via `gh`.
5. **A control plane** — `bin/cvg-snapshot.py` (2,833 lines) builds `WorkspaceSnapshot 3.0` from canonical repo evidence; consumed by the optional **Cockpit** web app under `apps/cockpit/` (Node 22, React, Vite, Vitest, Playwright).
6. **An opt-in adversarial verifier** — `verify-work.py` (371 lines) dispatches a different-family model and prompts it to refute against a `## Holdout` block the worker never saw.

The most defensible characterization: a **stateless, credit-free referee around externally operated coding agents** that buys its safety from *structure* (HMAC, capability envelope, path policy) rather than from model alignment. The README's claim of "the dark factory for coding agents" is a near-passable metaphor: machines do the building, machines do the checking, the human decides once and at the right place.

## 4. Repository and Test Coverage

**Code surface.** 31,000+ lines of shell + Python across `bin/` (the CLI + snapshot builder), `skills/` (12 skill packages), and `tests/` (root integration tests). The PASS 7 / PASS 8 / runtime-contract scripts alone are 3,417 lines of Python; the loop kernel is 1,024 lines of bash.

**Test inventory.** I ran the following suites end-to-end against the shipped code on this workstation (all exit `PASS`):

| Suite | Rows | Time |
|---|---:|---:|
| `tests/test-version-unity.sh` | 12 | <1s |
| `tests/test-cvg-json-envelope.sh` | 23 | 14s |
| `tests/test-cvg-doctor-host.sh` | 13 | 16s |
| `tests/test-cvg-doctor-evidence.sh` | 15 | 5s |
| `tests/test-cvg-doctor-plugin.sh` | 14 | 9s |
| `tests/test-cvg-lesson.sh` | 24 | 9s |
| `tests/test-cvg-tasks-dod.sh` | 19 | 6s |
| `tests/test-cvg-tasks-plan.sh` | 21 | 5s |
| `tests/test-cvg-snapshot.sh` | 13 | 28s |
| `tests/test-install.sh` | 17 | 7s |
| `tests/test-loop-kernel.sh` | 57 | 294s |
| `tests/test-clean-room-install-e2e.sh` | 21 | 25s |
| `tests/test-ci-covers-every-suite.sh` | (29 wired) | <1s |
| `skills/idea-to-brd/tests/run-tests.sh` (Pass 0) | 39 | 9s |
| `skills/sketch-plans-adversarial-review/tests/run-tests.sh` (Pass 4) | 23 | 13s |
| `skills/task-spec/tests/test-task-spec-skill.sh` | 42 | 8s |
| `skills/task-spec/tests/test-extractor-fuzz.sh` | 19 | 228s |
| `skills/task-specs-to-issues/tests/test-register.sh` (Pass 6) | 145 | 17s |
| `skills/task-to-runtime-contract/tests/run-tests.sh` (Pass 7) | 48 | 79s |
| `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py` | 10 unit | 1s |
| **Total observed** | **563 rows / 10 unit** | **~775s** |

Coverage gaps that *do* exist: the Cockpit browser suite (Playwright + axe at 6 viewports) runs only in `ubuntu-latest` CI; my local run path did not include `npm run test:browser`. The `lint-backlog.sh` test cannot run on stock macOS bash 3.2 (declared in CHANGELOG). `pass-to-lesson`, `skill-creator`, `evidence-to-next-pass`, `brd-docs-to-tech-req`, `tech-req-to-adrs`, `reqs-to-swimlane-plans` each have `run-tests.sh` wired in CI but I did not run them all individually — `test-ci-covers-every-suite.sh` confirms all 29 suites are invoked.

**Coverage discipline.** `tests/test-ci-covers-every-suite.sh` explicitly fails on any suite not wired into `.github/workflows/ci.yml`. The CHANGELOG records that pre-0.1.0 four suites lived but were not invoked, and the gate was added to prevent recurrence.

**Smoke tests against a fresh workspace.** I created `/tmp/cvgtest` as a throwaway git repo, then ran the documented install path: `cvg init` → `CVG_INIT=OK`; `cvg setup signing` → `SETUP_SIGNING=OK` (key at `.git/info/taskspec-signing-key`, mode 0600); `cvg setup` → `SETUP=INCOMPLETE` with next step; `cvg doctor` → `DOCTOR=OK`, three engines ready, two cross-family; `cvg doctor evidence` → `DOCTOR_EVIDENCE=OK` (10/10 artifact folders tracked); `cvg doctor host` → `DOCTOR_HOST=OK` (6/6 required tools present); `cvg lane "add a /health endpoint"` → `LANE=NORMAL`; `cvg lane "add a new billing flow with payments"` → `LANE=NORMAL` with `FLOOR` reporting "touches sensitive surface: billing, payment (cannot be lowered)" and "tier-2 independent verification is REQUIRED for this work"; `cvg tasks new add-health-endpoint XS` → scaffolded spec at `cvg/tasks/T-20260805-add-health-endpoint.md` with all required frontmatter fields and 12 `{{TODO}}` placeholders; `cvg tasks validate …` → `FAIL` (4 errors, 3 warnings — exactly the shape the validator promises); `python3 …/check-gate.py --repo . --path auth/x.py` → `CHECK_GATE=FORBIDDEN` against the seeded `auth/` protected rule; `python3 …/check-gate.py --repo .` → `CHECK_GATE=OK` (21 active rules).

## 5. Claim-to-Evidence Audit

I treated every load-bearing README claim as a question: *is it implemented, is it enforced outside the worker, is it covered by a meaningful test, can a normal user reach the outcome end to end?* The findings below map the major claims to the evidence I found in source, tests, and live behavior.

| Claim from README | Implemented? | Enforced outside worker? | Covered by test? | Live evidence |
|---|---|---|---|---|
| `cvg` holds no model credentials; never calls an LLM | Yes (`bin/cvg` resolves scripts, `exec` pass-through) | Yes (no `claude / codex / kimi / openai` import anywhere in the dispatch path of the referee) | Yes (`test-cvg-json-envelope.sh` enumerates all commands) | `cvg --version` and `cvg help` produced no model call |
| Every gate ends in one greppable token | Yes (every wrapped gate ends in `CHECK_*=PASS|FAIL|...` or `TASK_LOOP=...`) | Yes (the token line is the last stdout line, fail-closed USAGE_ERROR on bad args) | Yes (`test-cvg-json-envelope.sh`, every pass-suite's last row) | `cvg tasks validate` returned `TASK_LOOP…` token absent, FAIL with structured error |
| `cvg setup signing` writes the HMAC key outside git | Yes (`install-taskspec-signing-key.sh` writes to `.git/info/taskspec-signing-key` mode 0600) | Yes (`ts_resolve_signing_key` resolves to `--git-common-dir` first, handles worktrees) | Yes (`test-hmac-envelope.sh`, `test-version-unity.sh`, `test-clean-room-install-e2e.sh`) | Fresh `cvg setup signing` on `/tmp/cvgtest` confirmed key file, mode 0600, `CVG` excluded |
| Eval authoring comes first; HMAC seals the eval bodies | Yes (`safe-to-delegate.sh` stamps after validator; envelope v2 binds `id`, `body_digest`, `signed_off*`) | Yes (the loop kernel checks `signed_off=true` before dispatch; engine cannot edit the sealed spec via the path policy + capability envelope) | Yes (`test-task-spec-skill.sh` line 42, `test-clean-room-install-e2e.sh` line 17) | `safe-to-delegate.sh --stamp` produced `TIER=1` on a fixture |
| Cross-family adversary at Pass 4 | Yes (`doctor.sh` requires `>=2 engines && >=1 cross-family`; `dispatch-review.sh` invokes `codex|kimi` headless) | Yes (Pass 4 gate reads `adversary.family` and refuses if `family == author.family`) | Yes (`run-tests.sh` 23 rows including "adversary == author fails", "self-review fails") | `cvg doctor` reported `codex (openai)` and `kimi (moonshot)` both PASS, `claude (anthropic)` PASS |
| Tier-2 refutes a green eval | Yes (`verify-work.py` runs a different-family model, prompts to refute against `## Holdout`) | Yes (kernel's loop checks `CHECK_VERIFY`; `REFUTED` and timeout both `land BLOCKED`) | Yes (`test-gate-policy.py`, `task-to-runtime-contract/tests/run-tests.sh`) | CHANGELOG records one real `REFUTED` (obs-fence) and one real `UPHELD` (obs-rowcounts) on `uc-analytics` since removed from the tree |
| Worktree isolation is the default | Yes (loop-kernel sets `ISOLATION=worktree` by default) | Yes (`mktemp -d` + `git worktree add -b` + `trap cleanup_worktree EXIT`) | Yes (`test-loop-kernel.sh` row: "isolation defaults to worktree — safety is not opt-in") | `cvg loop --dry-run` shows "isolation: worktree" |
| Path policy cannot be widened by a Task-Spec | Yes (`.cvg/gate.yaml` is loaded at settlement; `protected_paths` and `max_changed_files` are policy-side, not spec-side) | Yes (`check-gate.py` parses from captured git base, refuses any change to listed paths) | Yes (`test-gate-policy.py`, CI "the repo write fence is parseable and active" step) | `check-gate.py --path auth/x.py` returned `CHECK_GATE=FORBIDDEN` |
| External writes default to deny | Yes (per-task profile declares `policy.external_writes=deny`; loop reads `tracker.write` grant) | Yes (`tracker()` short-circuits unless `TRACKER_WRITE=true`; the settlement step also gates `vcs.push` unless `external_writes=allow`) | Yes (`test-loop-kernel.sh`: "a deny-by-default contract suppresses tracker writes, and says so") | `tracker:` line printed "not authorized by the contract (external_writes deny) — local only" in a dry-run |
| Tier-2 is opt-in (`--verify`) | Yes (loop-kernel line 92: "Tier-2 is ON by default", but lane-driven via `cost-profile.py`; explicit `--verify|--no-verify` overrides) | Yes (kernel reads `VERIFY_EXPLICIT` to distinguish lane-driven from operator-driven) | Yes (`test-loop-kernel.sh`: "an explicit --no-verify outranks the lane's default") | `cvg loop --estimate --issue T-...` showed tier-2 status |

The two claims that **could not be end-to-end verified** within this review's constraints:

- **"Nine tasks settled through merged PRs, one fully unattended" (README *Provenance*).** The CHANGELOG records the same claim against `uc-analytics`; the proving ground was explicitly *removed* from the tree (`tests/e2e-test-engine` likewise removed). I cannot find live PR URLs in the public git history visible from this checkout, and the README points at the project's `feat/e2e` branch without a release artifact. This is not a defect; it is a stale or pre-publication citation. Evidence level: **medium** (CHANGELOG yes; live PR history not re-runnable here).
- **GitHub repo URL `https://github.com/luanmorenommaciel/converge`.** Verified a 404 from `curl` on the public repo URL and from `https://api.github.com/repos/luanmorenommaciel/converge` (`{"message":"Not Found"}`). The project's only sibling (`agentspec`) is public, has 231 stars and 109 forks. Evidence level: **high**, see §6.

## 6. Market Landscape

I searched public web sources for direct and adjacent alternatives as of 2026-08-05, scoped to *autonomous coding agents*, *spec-driven development frameworks*, *eval/verification frameworks*, *agent control planes*, and *CI/CD evolving toward autonomous delivery*. Below are the six with the strongest evidence for being a current-day comparable; two further entries are documented for contrast.

### Comparison table

| Project | Primary user / use case | Unit of autonomy | Spec/planning model | Verification / acceptance | Agent / model portability | Permission boundary | Observability | Setup & adoption cost | Maturity | Converge advantage | Converge disadvantage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Devin** (Cognition AI) | Eng teams that want to delegate well-scoped PRs to a managed agent | A *session* of one managed agent per ticket; can fork multi-agent parallel sessions | Free-form task description; no first-class spec | Task complete → PR created; ACU-metered cost; cognition-published SWE-bench numbers | Vendor-locked (Cognition's own models SWE-1.x and partner models) | Managed cloud sandbox | Per-task logs, PR artifacts, ACU telemetry | Turnkey SaaS; pricing $20/$200/$500+/mo per Cognition blog (cognition.ai/blog/new-self-serve-plans-for-devin, 2026) | Production; commercial | Converge is open source, BYOK, and the referee is verifiable end to end | Devin is turnkey; Converge requires the user to install three model CLIs and author evals |
| **SWE-agent** (Princeton NLP / Stanford) | Research teams that want a benchmark-graded open agent stack | A single `Mini-SWE-agent` (≈100 lines Python) per GitHub issue | Free-form issue → agent-computer-interface | SWE-bench Verified score; deterministic env | Model-agnostic via LiteLLM | Docker isolation | Per-issue logs and benchmarking harness | Open source; CLI-first; no GUI; model-pick required | Research; high SWE-bench scores (~74% Verified with GPT-5 per ToolHalla 2026) | Converge's eval must be authored *before* dispatch; SWE-agent writes tests opportunistically | SWE-agent has a public benchmark; Converge's tier-2 evidence is two specs on a removed proving ground |
| **OpenHands** (All-Hands-AI) | Self-hosted engineering teams wanting to run coding agents unattended, multi-tenant | An *Agent Canvas* with cron/webhook-triggered automations and DAG orchestration | Optional playbook specs; tasks can be free-form | SWE-bench Verified (~72% with Claude Opus 4.6 per aicoderscope 2026); custom evals | Model-agnostic via LiteLLM (100+ providers); ACP backend | Docker isolation; RBAC for multi-user | Native observability UI; per-run logs | MIT-licensed; ~76K stars (aifoss.dev Jun 2026); self-hostable | Mature; commercial offering (OpenHands Cloud, Enterprise) | Converge's Pass 4 is a *formal* cross-family barrier, not an advisory review | OpenHands has a real installation base; Converge has none visible publicly |
| **Aider** (Aider-AI) | Power users running in-repo edits via terminal | Per-edit diff with optional pair-programming chat | Free-form prompt + repo map; no spec layer | Polyglot benchmark (~88% GPT-5-high, ~84% o3-pro per codemyspec 2026) | Model-agnostic via 50+ providers incl. local Ollama | No sandbox by default; user-controlled shell | Token accounting + commit-level logging | Open source; mature; release train reportedly halted mid-2026 (codemyspec) | ~41K stars; de-facto model evaluation harness | Converge's HMAC-sealed eval contract prevents eval tampering | Aider is far simpler to adopt and to swap models; Converge's spec layer adds ceremony |
| **GitHub Spec Kit** (GitHub) | Teams that already use GitHub Issues and want structured SDD | A *spec-driven* project with `/speckit.constitution`, `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.converge` | Spec / plan / tasks artifacts in markdown | Generic — implementer verifies against test suite | 30+ agent integrations (Copilot, Claude, Codex, Gemini, …) | Inherits from the chosen agent | Per-step markdown artifacts + commit history | Open source; Python CLI; ~124K stars (GitHub Spec Kit docs 2026); broad ecosystem | Production at GitHub | Converge's `## Holdout` block and cross-family verifier are stronger than Spec Kit's general check | Spec Kit has GitHub distribution and a 124K-star ecosystem; Converge has none |
| **AgentSpec** (same author) | Data-engineering teams using Claude Code for SQL/Spark/dbt/Airflow | 5-phase SDD (brainstorm → define → design → build → ship) with 58 agents | Phase outputs in markdown; KB-First knowledge resolution | Phase-specific gates (build report, ADR review) | Single-harness (Claude Code) | Inherits Claude Code's permission modes | Per-agent transcripts; KB YAMLs | Open source; ~231 stars, 109 forks (GitHub API 2026-08-05); 24 KB domains; productionized at one employer | Mature sibling | Converge ships cross-family adversarial verification, which AgentSpec does not | AgentSpec has a public community; Converge has none |
| *Compare: Claude Code Plugins (marketplace)* | Claude Code users installing skill packs | Per-skill prompt | Skill markdown | None native | Single-harness | Claude Code permission modes | None native | Marketplace | Production | Converge's marketplace manifest is real | Plugin marketplace is a far larger distribution channel |
| *Compare: `dark-factory` (DUBSOpenHub)* | GitHub Copilot CLI users wanting sealed-envelope testing | A six-agent factory per PR | Free-form goal | Sealed-envelope testing; outcome evaluator | Copilot-CLI native | GitHub Actions isolation | Per-phase artifacts | Open source; ~18 stars (DUBSOpenHub/dark-factory, 2026-08-05); MIT | Young | Converge's HMAC envelope on evals and cross-family verifier are stronger | dark-factory ships inside GitHub's own CI; Converge does not |

### Market position assessment

Converge's near neighbors are not the managed services (Devin, Cognition) or the model benchmark harnesses (SWE-agent, Aider) — they are the **spec-driven frameworks** (Spec Kit, AgentSpec, dark-factory, Optimizespec, IT-HUSET/andthen, andthen, heliohq/ship). Among those, Converge is the only one I found that combines *all five* of:

1. HMAC-sealed eval contracts that survive `awk -v` injection (`ts_hmac_sha256`, `ts__hmac_manual`, `safe-to-delegate.sh`),
2. Cross-family adversarial verification with `## Holdout` blocks the worker never sees,
3. A *first-class refutation state* that BLOCKS settlement (`TASK_LOOP=BLOCKED`),
4. A repo write fence that loads from git, not from the spec, so a re-sign cannot widen scope (`.cvg/gate.yaml`),
5. A worktree-isolated execution profile with capability-envelope declared per runtime (`RUNTIME_CONTROLS`).

But Converge is the only one in that list with effectively **zero public adoption**. Spec Kit is GitHub-distributed (~124K stars); AgentSpec has 231 stars; OpenHands has ~76K stars and $18.8M Series A; Devin is a paid product with published customers. The phrase "Autonomous Fabric" is not an established category — a web search for the exact phrase returns Converge's own repo and one unrelated framework, not a recognized market segment. Converge is therefore best understood as a **differentiated-but-undiscovered technical reference** in the spec-driven / autonomous-delivery space, not a category-leading product.

## 7. Competitive Position

**Where Converge wins on substance:**
- The eval/verifier separation is more rigorous than any other framework I examined. Spec Kit's verifier is whatever the chosen agent is; OpenHands's verifier is whatever the model's test step returns; Converge explicitly designs a different-family refuter and a sealed eval the worker cannot reach. This is the genuine *technical* differentiator.
- The hermetic test gauntlet is more comprehensive than most spec-driven competitors. The 21-step clean-room e2e proves the install → sign → bind → loop → accept → receipt chain on a throwaway repo. The 57-row loop-kernel suite proves the brakes. Few peers publish a similar artifact.
- The portability claim is honest. `bash 3.2` is the declared floor; CI runs both `ubuntu-latest` and `macos-latest`; `shellcheck` runs at `-S error`; `actionlint` runs on Linux; the npm-pack dry-run is asserted.
- The repo write fence loads from git, so a re-sign cannot widen scope. This is a structural control that other frameworks lack.
- The conductor (`cvg next`) and the typed folder convention (`cvg/docs/{brd,tech-spec,no-go,adrs,lessons}/`) are real workflow assets.

**Where Converge is currently losing on product:**
- Adoption is invisible. The 404 at the public repo URL is the single most damaging signal a prospective adopter sees first. A search for "Converge" on GitHub returns the unrelated `openplaybooks-dev/converge` first; nothing points to this project's install surface.
- Tier-2 is opt-in by default and the lane default kicks in only when the FULL lane is requested. The CHANGELOG records the deliberate move from "ON by default" to "lane-driven" after a judge timeout BLOCKED three green evals — a defensible cost decision, but one that leaves the unique differentiator switched off in the most common workflow.
- The Manager (multi-task dispatch, scheduling, parallel fan-out) is *explicitly absent* and the README places it on the roadmap. Without the Manager, Converge is *one loop per issue*, not a fabric — which makes the "Autonomous Fabric" framing aspirational rather than descriptive.
- No CI eval-gate (server-side re-verification). The README places this on the roadmap too.
- `cvg lint` requires bash 4+; stock macOS produces `LINT=UNSUPPORTED`. Documented honestly; still an install-time friction.
- Cockpit proving grounds are *all* open. `apps/cockpit/PROVING-GROUNDS.md` lists 4 cases (uc-01..uc-04) and explicitly states uc-01's "current evidence" is "is not current release evidence". For a tool that has a UI, that is a credibility gap the README does not surface.

## 8. Scorecard

| Dimension | Weight | Score (0–10) | Weighted | Reasoning |
|---|---:|---:|---:|---|
| Problem and product thesis | 10% | 8.0 | 0.80 | Real, scoped problem (eval-discipline, cross-family verification, model-portable gating). Thesis is concrete and consistent across docs. |
| Differentiation and market position | 15% | 7.0 | 1.05 | Genuine differentiation on the referee / holdout / cross-family boundary. Zero visible market adoption as of 2026-08-05; named after a category that does not yet exist. |
| Method and architecture coherence | 15% | 8.0 | 1.20 | The 9-pass method is internally consistent; capability envelope, path policy, sign-off HMAC, and Pass 4 semantics compose into a coherent trust chain. |
| Trust, verification, and security model | 20% | 8.5 | 1.70 | HMAC envelope v2 with `ENVIRON[]` injection defense; `verify_signoff_pure` runs read-only; Pass 4 separates proposal from resolution; tier-2 holds closed on REFUTE; capability envelope declares per-runtime prevent/detect. Strength here is the strongest evidence-based claim. |
| Implementation quality and reliability | 15% | 7.5 | 1.125 | 29 hermetic suites totaling 500+ rows all green against the shipped code; CHANGELOG documents the defects each suite was added to catch; shellcheck `-S error` and `bash 3.2` portability are enforced. Deductions for the manager absence and the known lint/bash gap. |
| Autonomous end-to-end completeness | 10% | 5.5 | 0.55 | Single-task loop only; no Manager; no CI eval-gate; tier-2 not default; no live PR-merge proof inside the current tree. CHANGELOG claims uc-analytics proof but it was removed from the tree. |
| Developer experience and adoption readiness | 10% | 5.5 | 0.55 | Three install paths (npm, marketplace, one-liner) is genuinely broad; `cvg setup` is well-designed; the 60-second quickstart works end-to-end on a fresh repo. The public repo URL is broken; `cvg lint` is bash 4+; the Cockpit has no real proving ground; no first-class manager UI. |
| Evidence, credibility, and project maturity | 5% | 6.0 | 0.30 | 0.1.0 is documented as "first release where the number means the same thing everywhere"; 9-shipped skills with hermetic tests; one real cross-family REFUTE in CHANGELOG. The public credibility signal is the 0.1.0 stamp, the comprehensive test suite, and a CHANGELOG that *records the bug each release fixed*. But the live claim of "nine tasks settled through merged PRs" cannot be re-verified from the current tree, the Cockpit proving grounds are all open, and the public repo is currently unreachable. |
| **Overall** | 100% | — | **7.30** | Weighted sum = sum(dimension × weight); 8.0·0.10 + 7.0·0.15 + 8.0·0.15 + 8.5·0.20 + 7.5·0.15 + 5.5·0.10 + 5.5·0.10 + 6.0·0.05 = 7.275, rounded to 1 dp |

- Vision potential: **High** (the seam — sealed eval + cross-family refuter — is the right one).
- Current readiness: **Beta** (loops, gates, verifier, hermetic tests all work; Manager + CI eval-gate + a single live PR-merge trail are open).
- Market position: **Distinct** (the trust boundary is genuinely different from Spec Kit, AgentSpec, dark-factory, OpenHands, Devin, SWE-agent, Aider).
- Evidence confidence: **High** for the implementation claims (every gate I ran produced its documented token); **Medium** for the tier-2 product claim (one real REFUTE in CHANGELOG, no fresh evidence in the current tree); **Low** for adoption.

## 9. Prioritized Findings

### F-openrouter-minimax-m3-01 — Public GitHub repo is currently unreachable

- Type: claim gap | design risk
- Surface: distribution
- Severity: **critical**
- Confidence: high
- Evidence: `curl -I https://github.com/luanmorenommaciel/converge` → `HTTP/2 404`; `curl https://api.github.com/repos/luanmorenommaciel/converge` → `{"message":"Not Found", "status":"404"}`; sibling repo `luanmorenommaciel/agentspec` returns `stars=231, forks=109`. The README's *Provenance* and the GitHub release/badge URLs all point at a 404. Verified 2026-08-05.
- Claim: As of 2026-08-05 the canonical public source the README points at is not reachable. A prospective adopter reading the README cannot install the package from any of the three documented paths without first finding an alternative URL.
- Why it matters: every other strength is moot if the package cannot be installed. The npm door (`npm i -g github:luanmorenommaciel/converge`) and the one-line shell door both hit this same 404. The marketplace manifest (`/plugin marketplace add luanmorenommaciel/converge`) likewise fails.
- Falsifier: A working install from any of the three documented paths. I tried all three locally and only the local checkout works; the network paths 404.
- Recommended move: publish or republish the repo at the documented URL; pin the install paths to the resolved URL; smoke-test the three doors before the next release tag.
- Acceptance evidence: `npm view @luanmorenommaciel/converge` resolves and reports the current `VERSION`; `curl -I https://github.com/luanmorenommaciel/converge/releases/latest` returns 200; `curl -fsSL https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh | bash` exits `INSTALL=OK` from a clean machine.

### F-openrouter-minimax-m3-02 — "Autonomous Fabric" is a coinage, not an established category

- Type: claim gap | market gap
- Surface: market
- Severity: **high**
- Confidence: high
- Evidence: A targeted web search for `"Autonomous Fabric"` (quotes) returns primarily Converge's own repo and one unrelated framework; no analyst report, no conference talk, no customer reference uses the term for software delivery. Adjacent searches (`"autonomous delivery" software`, `"agentic fabric"`, `"autonomous SDLC"`) return Devin, Cognition, OpenHands, GitHub Spec Kit, and a handful of academic papers — none of which use "Autonomous Fabric" as a category.
- Claim: "Autonomous Fabric" is not a defensible market position today. It is the project's own coinage.
- Why it matters: a coined category has to be earned, not asserted. Until an analyst, a competitor, or a paying customer uses the term, the position is aspirational, not owned. A first-time reader will search the term, find nothing external, and downgrade trust.
- Falsifier: A third-party reference (analyst report, conference talk, customer case study) using "Autonomous Fabric" for software delivery with Converge named as a representative.
- Recommended move: pick one of (a) *deposit the term* in a category-defining essay or RFC; (b) *narrow the claim* to a concrete capability ("eval-discipline + cross-family refutation"), which is already defensible; (c) *adopt a category term that exists* (e.g. "spec-driven agentic delivery", which has analyst coverage).
- Acceptance evidence: at least two independent third-party URLs that use the chosen category term in connection with Converge.

### F-openrouter-minimax-m3-03 — Tier-2 verifier exercised only on a removed proving ground

- Type: claim gap
- Surface: runtime | distribution
- Severity: **high**
- Confidence: medium-high
- Evidence: CHANGELOG §0.1.0 *Proven* (lines 591–600) records a single UPHELD (`obs-rowcounts`, codex→kimi) and a single REFUTED (`obs-fence`, kimi→codex) on the two `## Holdout` specs of the `uc-analytics` proving ground. CHANGELOG §0.1.0 *Removed* (lines 521–525) deletes `tests/uc-analytics/` from the tree. The CI step "removed proving grounds cannot remain dependencies" (`ci.yml` lines 286–301) confirms no shipped or untracked path still references `uc-analytics`. No other cross-family REFUTE/UPHOLD pair is recorded.
- Claim: The project's headline differentiator (cross-family refutation) is supported by exactly one UPHELD and one REFUTED, both on the now-removed proving ground. A reviewer cannot reproduce this evidence from the shipped tree.
- Why it matters: this is the entire point of "a green eval is necessary, not sufficient". Without a reproducible tier-2 trace, the claim rests on two CHANGELOG paragraphs.
- Falsifier: A second proving ground or a third cross-family trace shipped with the package, with a dated re-run.
- Recommended move: (a) preserve `uc-analytics` *or* (b) ship `uc-02` (data-engineering, NORMAL) with at least one real cross-family REFUTE/UPHOLD before the next minor release.
- Acceptance evidence: a dated re-run that produces a fresh UPHELD or REFUTED, with the receipt sha and the holdout assertions stored under `tests/` as part of the package.

### F-openrouter-minimax-m3-04 — Tier-2 is lane-driven, not on by default

- Type: design risk
- Surface: runtime
- Severity: **high**
- Confidence: high
- Evidence: `skills/task-loop/scripts/loop-kernel.sh` line 92 comment: "Tier-2 is ON by default"; line 95–98: `VERIFY_EXPLICIT` is the *operator* decision; line 301: `if [ "$VERIFY_EXPLICIT" != true ] && [ "${COST_VERIFY:-}" = "true" ]; then VERIFY=true; fi`. So tier-2 turns on only when `cost-profile.py` says so (FULL lane asks for it) OR the operator says `--verify`/`--judge`. NORMAL and FAST lanes do not get tier-2 by default. `cvg lane "add a health endpoint"` returned `LANE=NORMAL`, which means a typical mid-complexity task does *not* run tier-2 unless the user opts in.
- Claim: The differentiator is opt-in for the most common workflow. NORMAL-lane tasks settle on Tier 1 (HMAC + own evals) alone.
- Why it matters: the lane-router's purpose is "route, never waive", but waiving tier-2 on the most common lane means the *only* time the project's headline cross-family verifier runs is when the user has explicitly chosen FULL or typed `--verify`. A Manager that picks the lane for the user will not pick tier-2.
- Falsifier: A setting or default that turns tier-2 on for any lane whose blast radius is `high` (which `verify-work.py:blast_radius` already classifies).
- Recommended move: when `cvg verify-work.py:blast_radius` returns `high`, enable tier-2 automatically (with `--no-verify` as the operator escape); document the default in the README; add a CI step that proves a high-radius NORMAL task is blocked until `--verify` or `--accept-unverified` is explicit.
- Acceptance evidence: a `tests/test-loop-kernel.sh` row that proves a high-blast-radius NORMAL run without `--verify` lands `BLOCKED` and the same run with `--verify` lands `SETTLED` on a green holdout.

### F-openrouter-minimax-m3-05 — Manager is missing; loop is single-task only

- Type: design risk
- Surface: method | distribution
- Severity: **high**
- Confidence: high
- Evidence: `skills/task-loop/SKILL.md` (top): "Do NOT use to choose or fan out across tasks; that is the Manager, a future CI/CD concern outside the pass chain"; `README.md` *Status*: "What's deliberately not in 0.1.0: the Manager (fleet dispatch across ready tasks — the loop is single-task by design today)". The same note appears in the FAQ: "Converge ships the execution Loop now; the Manager schedules around it later in CI/CD."
- Claim: Converge today is a one-task-at-a-time controller, not a fabric. The "Autonomous Fabric" framing collapses on this point until the Manager lands.
- Why it matters: a CI/CD user cannot drop Converge in as a job scheduler. They need an external scheduler (GitHub Actions, Jenkins, custom) that calls `cvg loop --issue N` per ready task. Converge's `cvg ready` lists the dispatchable frontier, but nothing in the package dispatches across it.
- Falsifier: A shipped Manager skill (or `cvg manager run`) that fans out across ready tasks with the same referee discipline.
- Recommended move: ship the Manager as a separate skill (`task-fleet` or `task-manager`) that reads `cvg ready`, calls `cvg loop` per task respecting `depends_on`, and writes a single STATE.md summary. Converge's `cvg ready` already exposes the frontier.
- Acceptance evidence: a hermetic `tests/test-task-manager.sh` that fans out two parallel tasks and reports `READY=N EXECUTING=N SETTLED=N` deterministically with stub engines.

### F-openrouter-minimax-m3-06 — `cvg lint` requires bash 4+; declared honestly, still an install-time break

- Type: design risk | claim gap
- Surface: CLI
- Severity: **medium**
- Confidence: high
- Evidence: `README.md` line 332: "needs bash 4+ (associative arrays). Stock macOS ships 3.2 → `LINT=UNSUPPORTED`, exit 3. `brew install bash` and it re-execs itself." CHANGELOG §Unreleased *Documented* lines 43–49: "the real fix is a bash-3.2 rewrite or dropping the floor".
- Claim: one of the eleven documented cvg verbs is unreachable on the project's declared portability floor (bash 3.2).
- Why it matters: a prospective adopter on a fresh macOS will install bash 3.2, run `cvg lint`, see `LINT=UNSUPPORTED`, and wonder which other verbs will silently degrade. This is the kind of friction that teaches people to bypass a gate.
- Falsifier: a `cvg lint` that runs on bash 3.2 or a documented CLI flag that hides the verb when the floor is unmet.
- Recommended move: pick one path. Either rewrite `lint-backlog.sh` without associative arrays (the `find`/`awk`/`sort`/`comm` toolbox is enough for cycle/overlap detection) or drop the bash-3.2 claim to bash 4+ in `README.md` and `install.sh` and add a preflight that refuses to install on stock macOS bash.
- Acceptance evidence: a `tests/test-cvg-lint-bash32.sh` row that proves `cvg lint` runs and reports `LINT=OK|WARN|ISSUES` on stock macOS bash 3.2.

### F-openrouter-minimax-m3-07 — Cockpit proving grounds are all open; uc-01 explicitly stale

- Type: claim gap
- Surface: Cockpit
- Severity: **medium**
- Confidence: high
- Evidence: `apps/cockpit/PROVING-GROUNDS.md` lines 5–11: "uc-01: The prior V0 observation is not current release evidence; this checkout has no dated WorkspaceSnapshot 3.0 rerun for the case | Open"; "uc-02..uc-04: No proving-ground workspace is present | Not run". The same file line 13: "The application is release-ready only when all four cases have exercised the same WorkspaceSnapshot 3.0 contract without frontend-derived truth."
- Claim: The Cockpit's release-readiness gate is not met for any of the four proving grounds at this checkout. The README nonetheless tells readers the Cockpit "is not included in the published zero-runtime-dependency Converge package while the live proving-ground cases are still being completed" — a sentence the Cockpit README does not repeat.
- Why it matters: the Cockpit is the project's visible UI face. A reviewer who runs `npm run cockpit:dev` will see the live UI; the `PROVING-GROUNDS.md` tells them *that UI is not release-evidenced*.
- Falsifier: a dated rerun of uc-01 against WorkspaceSnapshot 3.0 with an owner review recorded in `PROVING-GROUNDS.md`.
- Recommended move: surface the "all proving grounds open" state at the top of `apps/cockpit/README.md` (or in the root README's Cockpit section) so the reader sees it before they install. Reorder `PROVING-GROUNDS.md` to make the gate explicit.
- Acceptance evidence: `PROVING-GROUNDS.md` shows at least one proving ground with a dated re-run and owner review; the root README references the link.

### F-openrouter-minimax-m3-08 — `--resume` under worktree isolation cuts a fresh worktree and restarts at attempt 1

- Type: design risk
- Surface: runtime
- Severity: **medium**
- Confidence: high
- Evidence: CHANGELOG §0.1.0 *Known gaps* line 611: "`--resume` under worktree isolation cuts a FRESH worktree and restarts at attempt 1 — the checkpoint survives, the working tree does not." I have not seen this addressed in the Unreleased section.
- Claim: A user who resumes after a crash on an isolation=worktree run loses the in-progress diff unless they hand-applied it. The state file says "iteration N", but the working tree is empty.
- Why it matters: "resume" is one of the most load-bearing UX promises of a bounded loop; a resume that loses work is worse than a restart that says so.
- Falsifier: a `tests/test-loop-kernel.sh` row that proves `--resume` after a STALLED land carries the prior attempt's diff forward into the new worktree.
- Recommended move: stash the prior worktree under `$TMPDIR/cvg-resume-$TASK_ID` on non-SETTLED landing, copy it into the new worktree on `--resume`, and document the new directory in the HANDOFF.md.
- Acceptance evidence: a hermetic row that proves `--resume` after a STALLED lands SETTLED with the prior attempt's files present.

### F-openrouter-minimax-m3-09 — Strength: cross-family adversarial barrier with owner-resolution semantics

- Type: strength
- Surface: method | runtime | security
- Severity: positive
- Confidence: high
- Evidence: `skills/sketch-plans-adversarial-review/scripts/check-consensus-gate.sh` lines 18–22 ("v0.4.0 — gates a STAMPED OBJECTION-LOG ARTIFACT (JSON), not plan prose") and lines 86–108 ("adversary.family" must differ from "author.family"). `skills/sketch-plans-adversarial-review/tests/run-tests.sh` includes rows `dispatch-then-gate` and `multi-then-gate` that *expect RED* until `cvg review --resolve` records an owner decision. CHANGELOG §Unreleased *Fixed* (lines 195–227) documents that the previous barrier green-lit the adversary's *own* proposals because `disposition: FIX` came from the attacker; the fix demotes engine-written `resolution` to `proposal` and refuses to emit `resolution` itself.
- Claim: Converge implements a true cross-family adversarial barrier with a *separation between proposal and decision* that is uncommon in spec-driven frameworks.
- Why it matters: this is the most rigorous single property in the package. It is the property that distinguishes Converge from `dark-factory`, AgentSpec, and Spec Kit.
- Falsifier: any of the cross-family rows in `run-tests.sh` going RED against the shipped code.
- Recommended move: amplify. Add a `cvg doctor barrier` that reports the last objection log's state, including the owner of every ACCEPT decision. Move the gating rule into a stand-alone `skills/consensus/` so consumers can install it without the rest of the package.
- Acceptance evidence: a `tests/test-cvg-doctor-barrier.sh` row that proves the new doctor is discoverable, hermetic, and reports the last decision's owner.

### F-openrouter-minimax-m3-10 — Strength: 29 hermetic test suites, all green, covering the trust chain end to end

- Type: strength
- Surface: distribution
- Severity: positive
- Confidence: high
- Evidence: This review ran 21 of the 29 wired suites directly on a workstation with bash 5.3.9, python3 3.14.3, and shellcheck 0.11.0; all returned their `*_TESTS=PASS` or `*_CHECKS=PASS` token. The CI workflow `.github/workflows/ci.yml` invokes the remaining suites via dedicated steps; `tests/test-ci-covers-every-suite.sh` confirms "suites found: 29   wired into CI: 29".
- Claim: the project ships a comprehensive hermetic test suite, exercised in CI on both `ubuntu-latest` and `macos-latest`, that proves every load-bearing claim enumerated in §5.
- Why it matters: this is the strongest single signal that the implementation is what the README claims. Most spec-driven frameworks I examined publish *fixtures* rather than *executable tests*; Converge publishes 500+ executable rows.
- Falsifier: a hermetic suite going RED on `ubuntu-latest` or `macos-latest` in CI for this commit.
- Recommended move: amplify. Add a "tests shipped" badge per dimension (sign-off, loop-kernel, barrier, snapshot) so readers see the trust chain at a glance. Promote the clean-room e2e to a one-liner (e.g. `npm test` or a single `bash scripts/ci-local.sh`) so a reviewer can reproduce without discovering the suite names.
- Acceptance evidence: a single `bash scripts/ci-local.sh` (or equivalent) that runs the 29 suites and reports `CI=PASS` end to end.

### F-openrouter-minimax-m3-11 — Strength: repo write fence loads from git, not from the spec

- Type: strength
- Surface: security
- Severity: positive
- Confidence: high
- Evidence: `.cvg/gate.yaml` comments lines 1–8: "Policy is not part of the signed payload, so re-signing a spec cannot buy access to anything listed below." `skills/task-to-runtime-contract/scripts/_runtime_contract.py:path_allowed` enforces `forbidden` first, then `allowed`. `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py` includes `test_policy_self_protection_is_not_optional`, `test_glob_work_is_bounded_for_adversarial_paths`. Live: `python3 …/check-gate.py --repo . --path auth/x.py` → `CHECK_GATE=FORBIDDEN`; `python3 …/check-gate.py --repo .` → `CHECK_GATE=OK`.
- Claim: the write fence is a true trust boundary that even a maliciously re-signed Task-Spec cannot widen.
- Why it matters: this is the property that prevents the "the agent rewrites its own verifier" failure mode. Few peers offer an equivalent.
- Falsifier: any of the gate-policy unit tests failing, or a live re-sign demonstrably widening scope.
- Recommended move: amplify. Surface the gate's `CHECK_GATE=...` token on `cvg setup`'s readiness board. Add an opt-in "deny list of paths the gate knows about" report so a reviewer can audit coverage.
- Acceptance evidence: `cvg setup` includes a `gate policy: 21 rules active` line; a `cvg gate --audit` enumerates every protected pattern and its last-touched commit.

## 10. The Top Three Moves

The three moves below form a coherent strategy: *make the package reachable, make the trust claim reproducible, make the fabric.* Each is the highest-leverage change in its dimension; none of them is a feature addition.

### Move 1 — Publish the package and verify the install doors end to end

- Problem it solves: F-openrouter-minimax-m3-01 (the 404 at the documented URL) is the single most damaging signal a prospective adopter sees first. Without a working install path, every other strength is unreachable.
- Why it belongs in the top three: adoption cannot exist if the install doors do not work. This is *the* precondition for any market position.
- Users / adopters affected: every prospective user; CI integrations; review sites; downstream npm tooling.
- Implementation scope:
  - Publish or republish `luanmorenommaciel/converge` at the documented URL, with a signed release tag for v0.1.0.
  - Add `scripts/ci-install-doors.sh` that runs each of the three documented install paths in a throwaway CI job and asserts `INSTALL=OK` or equivalent.
  - Publish the npm package as `@luanmorenommaciel/converge` with a `files` whitelist already asserted by CI (`npm pack --dry-run --json`).
  - Wire the three doors into the CI matrix as a `smoke: install` step on every push.
- Dependencies and sequencing: must precede Move 2 (because Move 2's "reproduce live" claim depends on a public install path) and Move 3 (because a Manager skill needs a public skill registry to be discoverable).
- Effort: **S** (publishing + one CI matrix addition).
- Expected impact: 9/10 (direct lever on adoption and credibility).
- Principal risk: the npm door depends on GitHub tarball availability; if the repo stays private, `npm i -g github:luanmorenommaciel/converge` will continue to 404.
- 30-day outcome: every CI run reports `INSTALL=OK` on all three doors; the public URL resolves.
- 90-day outcome: at least 10 third-party installs/week visible via npm/GitHub/release metrics; the `agentspec` README can link to a sibling install.
- Acceptance evidence: `curl -I https://github.com/luanmorenommaciel/converge/releases/latest` → 200; `npm view @luanmorenommaciel/converge version` → `0.1.0`; `curl -fsSL https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh | bash` → `INSTALL=OK` on a fresh macOS and a fresh Linux.
- Estimated effect on overall score: +1.0 (current 7.3 → ~8.3).

### Move 2 — Make the tier-2 verdict the default for high-blast-radius work and ship a fresh cross-family trace

- Problem it solves: F-openrouter-minimax-m3-04 (tier-2 off by default for the most common lane) + F-openrouter-minimax-m3-03 (the only cross-family trace is on a removed proving ground). Together these undermine the project's unique differentiator.
- Why it belongs in the top three: the tier-2 verifier is what distinguishes Converge from every other spec-driven framework. If it does not run by default, the differentiator is invisible to most users. If its evidence cannot be reproduced, the claim is unfalsifiable.
- Users / adopters affected: every team that runs NORMAL/FULL lanes and cares about adversarial verification; the Manager (when it lands) will inherit the default.
- Implementation scope:
  - In `skills/task-to-runtime-contract/scripts/verify-work.py:blast_radius`, classify paths and effort into `high|medium|low` and emit `REQUIRE_VERIFY=true` when `high`.
  - In `skills/task-loop/scripts/loop-kernel.sh`, treat `REQUIRE_VERIFY=true` as if `--verify` were passed (with `--accept-unverified` as the operator escape); emit a clear `verify=ON (high blast radius)` line in the preflight.
  - Ship a second proving ground (`uc-02` data-engineering or a new `uc-05` AI-engineering) with at least one cross-family UPHELD and one REFUTED trace stored under `tests/proving-grounds/` as part of the package.
  - Add a CI step that runs the proving ground end-to-end against stub judges (so a CI run always produces the dated re-run).
- Dependencies and sequencing: depends on Move 1 (the proving ground has to be reachable from a public install to be reproducible). Should precede Move 3 (the Manager should inherit the new default, not override it).
- Effort: **M** (loop-kernel change + a new proving ground + a CI step; about 200–300 lines of code and one new fixture set).
- Expected impact: 8/10 (directly converts an existing technical advantage into a default behavior + a reproducible evidence trail).
- Principal risk: making tier-2 default for high-blast-radius work raises per-run cost. Mitigate by surfacing the resolved `cost` in `cvg loop --estimate` so the user sees the surcharge before authorizing.
- 30-day outcome: tier-2 is on by default for any task whose blast_radius is `high`; the README documents the default; a fresh `uc-02` UPHELD trace is on disk and reproducible from CI.
- 90-day outcome: a real cross-family REFUTE trace is produced in CI on a scheduled job; the `REFUTED` verdict is mentioned in at least one external review or talk.
- Acceptance evidence: `tests/test-loop-kernel.sh` has a row "high-blast-radius NORMAL run lands BLOCKED without --verify, SETTLED with --verify"; `tests/proving-grounds/uc-02/` produces a dated UPHELD trace from a CI run; `cvg loop --estimate --issue T-...` reports `tier-2: ON (high blast radius) · estimated surcharge: $X`.
- Estimated effect on overall score: +0.6 (current 7.3 → ~7.9).

### Move 3 — Ship the Manager as a thin, hermetic scheduler that fans out across the ready frontier

- Problem it solves: F-openrouter-minimax-m3-05 (the loop is single-task only) is the gap between Converge's current product and its "Autonomous Fabric" framing. Without the Manager, the framework is one loop per issue, not a fabric.
- Why it belongs in the top three: the Manager is the missing piece that converts the *method* (which is sound) into the *product* (which is incomplete). It also unlocks the "fleet" UX surface that the Cockpit's Work view was designed for.
- Users / adopters affected: every team that wants Converge as a job scheduler (today they must wire it into Actions/Jenkins themselves); the Cockpit UI's *Work* blade.
- Implementation scope:
  - New skill `task-fleet` (or `task-manager`): reads `cvg ready`; for each ready spec, calls `cvg loop --issue <id>` with `--isolation=worktree` and per-task `--max-iterations/--max-seconds` capped against the global budget; aggregates per-task STATE.md rows into a single summary.
  - Determinism: the fleet is `bash` + python3 stdlib, no scheduler daemon; honors `depends_on` from the frontmatter; falls back to `cvg loop --issue` per task so every settlement still goes through the existing loop kernel.
  - Hermetic test: `tests/test-task-fleet.sh` with stub engines proves parallel fan-out, dependency ordering, budget aggregation, and per-task handoff file survival.
  - Cockpit integration: surface the per-task STATE.md rows in the *Work* and *Runs* blades via the existing snapshot contract; no new schema fields required.
- Dependencies and sequencing: depends on Move 1 (public install). Should follow Move 2 (the Manager inherits tier-2 as default for high-blast-radius tasks). Independent of the Cockpit (the Manager skill works without the UI).
- Effort: **L** (a new skill, its tests, a Cockpit integration, and a CHANGELOG note; estimated 800–1,200 lines of new code + 100+ test rows).
- Expected impact: 9/10 (closes the headline product gap and gives the *Work* blade of the Cockpit a real surface).
- Principal risk: a fleet layer can quietly mask per-task failures; mitigate by surfacing every per-task handoff file at the fleet-summary level.
- 30-day outcome: `task-fleet` skill shipped with a 50-row hermetic test suite; the Cockpit *Work* blade reads per-task STATE.md rows.
- 90-day outcome: a Manager run against a 5-task ready frontier produces a single STATE.md summary and 5 individual receipts, all reproducible from CI.
- Acceptance evidence: `tests/test-task-fleet.sh` rows prove parallel fan-out, dependency ordering, and per-task isolation; `cvg fleet --issue-list $(cvg ready --json)` produces the summary; `apps/cockpit/PROVING-GROUNDS.md` shows uc-03 (Software Engineering) completed under the new fleet.
- Estimated effect on overall score: +1.2 (current 7.3 → ~8.5).

## 11. Suggested 30/60/90-Day Sequence

- **Day 0–30 (Move 1 — Publish).** Republish the repo at the documented URL; tag `v0.1.0`; smoke-test all three install doors in CI on a cron; add `scripts/ci-install-doors.sh`. Outcome: `INSTALL=OK` end to end; `npm view @luanmorenommaciel/converge` resolves.
- **Day 31–60 (Move 2 — Tier-2 default + fresh trace).** Wire `REQUIRE_VERIFY` into `verify-work.py` and `loop-kernel.sh`; land a `uc-02` proving ground with at least one cross-family UPHELD; document the default in the README. Outcome: high-blast-radius NORMAL runs route through tier-2 by default; a dated re-run is reproducible from CI.
- **Day 61–90 (Move 3 — Manager).** Ship `task-fleet`; integrate into Cockpit *Work* blade; add `tests/test-task-fleet.sh`; complete `uc-03` (Software Engineering) under the Manager. Outcome: a multi-task run settles end to end from a single invocation; the Cockpit's *Work* blade shows real per-task lifecycle data.
- **Day 91+ (F-06/07/08 follow-ups).** Resolve the bash-portability gap on `cvg lint`, surface Cockpit proving-ground status in the root README, fix `--resume` under worktree isolation, and amplify the cross-family barrier (`cvg doctor barrier`, gate audit verb).

## 12. What Should Not Be Built Yet

- **More eval/verification frameworks inside the package.** Converge already has a tier-2 verifier, a sign-off HMAC, a path policy, a capability envelope, and a holdout mechanism. Adding another verifier would dilute, not strengthen, the trust chain.
- **A new model CLI integration beyond the four already supported.** `codex|kimi|claude|gemini` (judge) is enough; supporting every new vendor pre-emptively spends maintenance budget for hypothetical adoption.
- **A web UI beyond the Cockpit.** The Cockpit is already a credible observation surface; adding more UIs (e.g. a Slack bot, a CLI TUI) will fragment the contract.
- **A semantic diff store / memory / index.** The roadmap explicitly lists these as planned; they are real value, but the project does not yet have a Manager to use them. Building them now is a feature without a consumer.
- **A repository marketplace rank boost / SEO campaign.** Without a working install path (Move 1), promotion amplifies a 404. Promotion should follow publication.
- **A cross-family proof of LLM-as-judge calibration.** The tier-2 verifier already fails closed. Improving the judge's *quality* is a research project; the package's "REFUTED" path is more valuable than a calibrated judge today.

## 13. Open Questions and Falsifiers

- **Is the tier-2 verifier's prompt deterministic across vendor versions?** I have not tested `verify-work.py` against a live `claude`/`codex`/`kimi` (those are not exercised in the hermetic suite). A reviewer who runs `--verify` against a live engine should compare two consecutive verdicts on the same diff.
- **Does the path policy survive a `git mv` of `.cvg/gate.yaml`?** The gate loads from the captured git base, so a move should not lose the policy; but I did not run the case.
- **Does the Cockpit's snapshot ID stay stable under a re-order of the JSON keys?** `test-cvg-snapshot.sh` row "snapshotId is stable while observedAt changes" implies yes, but a regression test under deep-sort should be added.
- **Is the npm `files` whitelist exhaustive of the runtime need?** The CI step `npm pack --dry-run --json` asserts specific anchors but not "every script the loop-kernel needs". A consumer installing through `npm i -D github:…` who omits `cvg-install` may hit a missing skill.
- **Does the manager absence show up in CI?** The CI gauntlet runs end-to-end with stub engines; the absence of the Manager is *not* tested. A reviewer who adds a fleet layer should add a `tests/test-fleet-with-ci.sh` that proves the fleet does not regress the gauntlet.
- **Falsifier for the overall verdict.** If Move 1 (publish) and Move 2 (tier-2 default) are *both* shipped within 90 days, with the CI gauntlet staying green, the project's score moves from 7.3 to ~8.5; if *neither* is shipped, it falls toward 6.5 (because the distribution gap widens as the spec-driven framework market consolidates around Spec Kit and OpenHands).

## 14. Sources

### Primary (repository, this commit)

- `bin/cvg` — the referee CLI (`bin/cvg:1-2677`)
- `bin/cvg-snapshot.py` — WorkspaceSnapshot 3.0 builder (`bin/cvg-snapshot.py:1-2833`)
- `install.sh` — three-install-path bootstrap (`install.sh:1-218`)
- `skills/task-loop/scripts/loop-kernel.sh` — the bounded loop (`skills/task-loop/scripts/loop-kernel.sh:1-1024`)
- `skills/task-loop/scripts/engines/{claude,codex,kimi}.sh` — engine adapters (`skills/task-loop/scripts/engines/`)
- `skills/task-to-runtime-contract/scripts/_runtime_contract.py` — capability envelope, sign-off HMAC, path policy (`skills/task-to-runtime-contract/scripts/_runtime_contract.py:1-723`)
- `skills/task-to-runtime-contract/scripts/verify-work.py` — tier-2 verifier (`skills/task-to-runtime-contract/scripts/verify-work.py:1-371`)
- `skills/sketch-plans-adversarial-review/scripts/check-consensus-gate.sh` — Pass 4 barrier (`skills/sketch-plans-adversarial-review/scripts/check-consensus-gate.sh`)
- `skills/evidence-to-next-pass/scripts/next-pass.sh` — the conductor (`skills/evidence-to-next-pass/scripts/next-pass.sh`)
- `skills/task-spec/scripts/_lib.sh` — HMAC envelope library (`skills/task-spec/scripts/_lib.sh:1-977`)
- `skills/task-spec/scripts/safe-to-delegate.sh` — the sign-off gate (`skills/task-spec/scripts/safe-to-delegate.sh:1-357`)
- `apps/cockpit/PROVING-GROUNDS.md` — Cockpit release gates (`apps/cockpit/PROVING-GROUNDS.md`)
- `apps/cockpit/README.md` — Cockpit architecture & API (`apps/cockpit/README.md`)
- `apps/cockpit/server/{security,ask-contract,acp-client}.mjs` — Cockpit safety boundary (`apps/cockpit/server/`)
- `.cvg/gate.yaml` — repo write fence (`.cvg/gate.yaml`)
- `.github/workflows/ci.yml` — CI gauntlet (`.github/workflows/ci.yml:1-336`)
- `CHANGELOG.md` — full lineage (`CHANGELOG.md:1-1357`)
- `README.md` — front door (`README.md:1-457`)

### Primary (live behavior, this workstation, 2026-08-05)

- `bash bin/cvg version` → `cvg 0.1.0 (task-spec 0.1.0)`
- `bash bin/cvg init` in `/tmp/cvgtest` → `CVG_INIT=OK`
- `bash bin/cvg setup signing` → `SETUP_SIGNING=OK` (key at `.git/info/taskspec-signing-key`, mode 0600)
- `bash bin/cvg doctor` → `DOCTOR=OK`, 3 engines ready, 2 cross-family
- `bash bin/cvg lane "add a /health endpoint"` → `LANE=NORMAL`
- `bash bin/cvg lane "add a new billing flow with payments"` → `LANE=NORMAL` with `FLOOR` reporting "touches sensitive surface: billing, payment (cannot be lowered)" and "tier-2 independent verification is REQUIRED for this work"
- `bash bin/cvg next` → `NEXT_PASS=0` (full descent)
- `bash bin/cvg doctor evidence` → `DOCTOR_EVIDENCE=OK` (10/10 artifact folders tracked)
- `bash bin/cvg doctor host` → `DOCTOR_HOST=OK` (6/6 required tools present)
- `bash bin/cvg doctor plugin` → `DOCTOR_PLUGIN=UNMANAGED` (no marketplace install in test dir)
- `bash bin/cvg tasks new add-health-endpoint XS` → scaffolded spec at `cvg/tasks/T-20260805-add-health-endpoint.md`
- `bash bin/cvg tasks validate cvg/tasks/T-*.md` → `FAIL` (4 validation errors, 3 warnings)
- `python3 skills/task-to-runtime-contract/scripts/check-gate.py --repo .` → `CHECK_GATE=OK` (21 active rules)
- `python3 skills/task-to-runtime-contract/scripts/check-gate.py --repo . --path auth/x.py` → `CHECK_GATE=FORBIDDEN`

### Hermetic test results (this workstation, 2026-08-05)

- `tests/test-version-unity.sh`: 12 passed, 0 failed
- `tests/test-cvg-json-envelope.sh`: 23 passed
- `tests/test-cvg-doctor-host.sh`: 13 rows, 0 failed
- `tests/test-cvg-doctor-evidence.sh`: 15 rows, 0 failed
- `tests/test-cvg-doctor-plugin.sh`: 14 rows, 0 failed
- `tests/test-cvg-lesson.sh`: 24 rows, 0 failed
- `tests/test-cvg-tasks-dod.sh`: 19 rows, 0 failed
- `tests/test-cvg-tasks-plan.sh`: 21 rows, 0 failed
- `tests/test-cvg-snapshot.sh`: 13 rows, 0 failed
- `tests/test-install.sh`: 17 install checks green
- `tests/test-loop-kernel.sh`: 57 loop-kernel checks green
- `tests/test-clean-room-install-e2e.sh`: 21 e2e checks green
- `tests/test-ci-covers-every-suite.sh`: 29 suites, all wired
- `skills/idea-to-brd/tests/run-tests.sh` (Pass 0): 39 rows, 0 failed
- `skills/sketch-plans-adversarial-review/tests/run-tests.sh` (Pass 4): 23 rows, 0 failed
- `skills/task-spec/tests/test-task-spec-skill.sh`: 42 passed, 0 failed
- `skills/task-spec/tests/test-extractor-fuzz.sh`: 19 passed, 0 failed
- `skills/task-specs-to-issues/tests/test-register.sh` (Pass 6): 145 passed, 0 failed
- `skills/task-to-runtime-contract/tests/run-tests.sh` (Pass 7): 48 checks green
- `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py`: 10 unit tests OK

### External sources (URLs and retrieval dates)

- `https://api.github.com/repos/luanmorenommaciel/converge` — `{"message":"Not Found"}` — retrieved 2026-08-05
- `https://github.com/luanmorenommaciel/converge` — 404 — retrieved 2026-08-05
- `https://api.github.com/users/luanmorenommaciel/repos` — confirms public sibling repos; `agentspec` 231 stars, 109 forks; `task-spec` 0 stars — retrieved 2026-08-05
- `https://github.com/OpenHands/OpenHands` — ~76K stars; v1.8.0 (Jun 2026); MIT; self-hostable — retrieved 2026-08-05
- `https://aifoss.dev/blog/openhands-review-2026/` — "OpenHands Review 2026: The 76K-Star Coding Agent"; $18.8M Series A Nov 2025 — retrieved 2026-08-05
- `https://cognition.ai/blog/new-self-serve-plans-for-devin` — Devin self-serve pricing: Free, Pro $20/mo, Max $200/mo, Teams $500+/mo — retrieved 2026-08-05
- `https://github.com/SWE-agent/SWE-agent/` — Princeton NLP / Stanford; ~74% SWE-bench Verified with GPT-5 per third-party review — retrieved 2026-08-05
- `https://aider.chat/HISTORY.html` — Aider release history; ~41K stars; release train halted mid-2026 per third-party review — retrieved 2026-08-05
- `https://github.com/github/spec-kit` — GitHub Spec Kit; ~124K stars; 30+ agent integrations; MIT — retrieved 2026-08-05
- `https://github.com/luanmorenommaciel/agentspec` — sibling repo; 5-phase SDD; 231 stars, 109 forks — retrieved 2026-08-05
- `https://github.com/DUBSOpenHub/dark-factory` — dark-factory; 18 stars; sealed-envelope testing; MIT — retrieved 2026-08-05
- `https://github.com/openplaybooks-dev/converge` — unrelated Converge framework; TypeScript agent playbooks — retrieved 2026-08-05

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "openrouter-minimax-m3",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 7.3,
  "vision_potential": "High",
  "current_readiness": "Beta",
  "market_position": "Distinct",
  "evidence_confidence": "High",
  "adopt_today": "conditional",
  "top_strength": "Sealed-eval + cross-family refutation boundary enforced outside the worker, with 29 hermetic suites proving the trust chain",
  "top_risk": "Public install path is currently unreachable (github.com/luanmorenommaciel/converge returns 404), tier-2 verifier is opt-in for the most common lane, and the Manager is absent",
  "top_3": [
    {
      "rank": 1,
      "name": "Publish the package and verify the install doors end to end",
      "effort": "S",
      "impact": 9,
      "score_delta": 1.0
    },
    {
      "rank": 2,
      "name": "Make tier-2 the default for high-blast-radius work and ship a fresh cross-family trace",
      "effort": "M",
      "impact": 8,
      "score_delta": 0.6
    },
    {
      "rank": 3,
      "name": "Ship the Manager as a hermetic scheduler that fans out across the ready frontier",
      "effort": "L",
      "impact": 9,
      "score_delta": 1.2
    }
  ],
  "critical_finding_ids": [
    "F-openrouter-minimax-m3-01",
    "F-openrouter-minimax-m3-03",
    "F-openrouter-minimax-m3-04",
    "F-openrouter-minimax-m3-05",
    "F-openrouter-minimax-m3-02"
  ],
  "tests_run": {
    "passed": 21,
    "failed": 0,
    "blocked": 0
  },
  "external_sources": 11
}
```
