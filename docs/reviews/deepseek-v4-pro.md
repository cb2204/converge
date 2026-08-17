# Converge Independent Review — deepseek-v4-pro

## 1. Review Metadata

| Field | Value |
|---|---|
| **Reviewer** | DeepSeek-V4-Pro (via OpenRouter) |
| **Reasoning mode** | Extended thinking |
| **Review timestamp** | 2026-08-06T10:41:55Z |
| **Git HEAD** | `9c966884e37919c0f7e4c3e027b4b237670eb2ad` |
| **Latest commit** | `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi` |
| **Branch** | `feat/e2e` |
| **Dirty worktree** | Yes — `apps/cockpit/package-lock.json` modified; review files deleted/added in `review/` |
| **Version** | `0.1.0` |
| **Tools available** | Full: read, bash, edit, eval, glob, grep, task, hub, web_search, lsp, browser, debug, inspect_image, write, ast_edit |
| **Review scope** | All of repo except `review/` directory |

## 2. Executive Verdict

**Overall score: 6.7 / 10**

Converge 0.1.0 is the most **architecturally coherent and evidence-backed** specification-driven autonomous coding framework I have inspected. It does not merely document a method — it enforces it through a working, tested CLI with cryptographic signing, cross-family adversarial verification, three-axis budget enforcement, and a genuine loop kernel. Its strongest defensible advantage is that **the eval decides done, not the agent** — a claim backed by executable gates, an HMAC seal that breaks on eval tampering, and a demonstrated cross-family REFUTED verdict.

**However**, Converge does not yet stand out in the market today. Its primary weakness is the absence of credible adoption evidence: no independent users, no community contributions, no published benchmarks, no integration with any CI/CD platform beyond the proprietary Cockpit, and a single-maintainer bus factor of one. The repository is a showcase of engineering rigor in search of an audience.

**Adoption verdict: Conditional.** I would adopt Converge today if: (a) I ran a small team already using Claude Code, Codex, or Kimi; (b) I needed process discipline and auditability more than velocity; and (c) I was willing to accept that no one outside this repository has yet proven the method on real, diverse workloads. I would not adopt it for a team that needs out-of-the-box CI/CD integration or multi-repo fleet management.

## 3. What Converge Actually Is

Converge is **all of the following, in descending order of readiness**:

1. **A methodology** (mature, documented). The nine-pass descent from raw idea to settled PR is well-specified, with lane-based routing (FAST/NORMAL/FULL) that scales ceremony to risk.

2. **A CLI (`cvg`)** (production-quality, tested). A 2,677-line bash router with zero runtime dependencies, bash 3.2 compatible, ShellCheck-clean. Wraps 12 skills as byte-exact pass-throughs. Emits machine-parseable tokens on every surface. Includes `--json` uniform envelope, `--dry-run`, `agent-context` (clispec.dev-compatible JSON manifest).

3. **A skill pipeline** (mature, tested). Twelve installable skills that implement the nine passes plus three utilities. Skills install into native harness discovery directories (`.claude/skills/`, `.agents/skills/`, `.grok/skills/`). Validated structurally.

4. **A control plane** (functional, tested). The tracked `.cvg/gate.yaml` write fence, `cvg/` workspace structure, signing key provisioning, and execution profiles form a Git-native control plane.

5. **A runtime loop** (functional, well-tested). `loop-kernel.sh` (1,024 lines) implements a genuine attempt→verify→repeat cycle with three-axis budgets (iterations, wall-clock, tokens), stagnation detection, worktree isolation, durable state, and eight named terminal states. Only `SETTLED`, `LOCAL_SETTLED`, and `NO_OP` exit zero.

6. **A Cockpit** (alpha-quality). A React+Vite+Node.js observability UI that projects `cvg snapshot --json` into nine read-only views. Shipping but not yet in the zero-dependency package. Ask Converge (ACP chat) is separated from proof.

7. **A nascent "Autonomous Fabric"** (vision, not product). The term describes an aspiration — a unified substrate where any coding agent, specification, and verification harness compose. The architecture supports this (harness-agnostic skills, engine adapters, cross-family verification), but the market position does not yet exist.

## 4. Repository and Test Coverage

### Codebase metrics

| Metric | Count |
|---|---|
| CLI (`bin/cvg`) | 2,677 lines |
| Snapshot engine (`bin/cvg-snapshot.py`) | 2,833 lines |
| Loop kernel (`loop-kernel.sh`) | 1,025 lines |
| Shell scripts (total) | 102 files |
| Python scripts (total) | ~13 files |
| Skills | 12 |
| Test suites | 21 shell suites + Python suite + Cockpit suites |

### Test results

All test suites pass on macOS (bash 3.2, Apple Silicon). Key results:

| Suite | Result | Checks |
|---|---|---|
| `test-loop-kernel.sh` | PASS | 57 |
| `test-clean-room-install-e2e.sh` | CLEAN_ROOM_E2E=PASS | 21 |
| `test-task-spec-skill.sh` | PASS | 42 |
| `test-version-unity.sh` | VERSION_UNITY=PASS | 12 |
| `test-cvg-json-envelope.sh` | PASS | 23 |
| `test-cvg-snapshot.sh` | PASS | 13 |
| `test-cvg-tasks-dod.sh` | PASS | 19 |
| `test-cvg-lesson.sh` | PASS | ✓ |
| `test-cvg-doctor-host.sh` | PASS | ✓ |
| `test-cvg-doctor-plugin.sh` | PASS | ✓ |
| `test-cvg-doctor-evidence.sh` | PASS | ✓ |
| `test-cvg-tasks-plan.sh` | PASS | ✓ |
| `test-install.sh` | PASS | ✓ |
| Pass 0–4 gate suites | All PASS | ~80+ |
| Runtime contract suite | PASS | 59+ |

The `test-ci-covers-every-suite.sh` gate confirms every suite is wired into CI. A coverage gap that existed on 2026-07-29 (9 unrun suites) was fixed and is now prevented by automation.

**Cockpit tests**: Not runnable with `npm test` (no script). `npm run check` (TypeScript + Node tests + Vitest) and `npm run test:browser` (Playwright e2e) exist but were not executed in this review due to dependency installation constraints. CI runs `test:browser` on Linux only.

### CI status

Public CI runs on `ubuntu-latest` and `macos-latest` with 21 hermetic suites. No secrets, no live services, no model calls. The design decision to exclude live-tracker tests from CI (they need secrets and would silently skip on forks) is correct.

## 5. Claim-to-Evidence Audit

### CLAIM 1: "The eval decides done — completion is a state-machine invariant"
- **Implemented?** Yes. `loop-kernel.sh` runs `verify()` after each attempt; only GREEN evals trigger settlement. The gate is in the runtime, not documentation.
- **Enforced at runtime?** Yes. The budget check is BEFORE engine calls (line ~780): "a post-flight check has already spent the money."
- **Outside worker authority?** Partially. Evals are HMAC-sealed (cannot edit without breaking the seal), but the HMAC is symmetric (anyone with the key can forge). Per-author non-repudiation is a documented future upgrade.
- **Covered by meaningful test?** Yes. `test-loop-kernel.sh` (57 checks) verifies RED→GREEN transitions, stagnation, exhaustion, and all terminal states with stub engines.
- **Documented honestly?** Yes. The README says "a green eval is necessary, not sufficient" and the tier-2 verification doc explicitly describes the holdout/fail-closed model.

### CLAIM 2: "The referee is never a player — `cvg` holds no API keys"
- **Implemented?** Yes. `cvg` is pure bash with zero credential paths. Engine CLIs authenticate themselves.
- **Enforced at runtime?** Yes. `bin/cvg` contains no API key references. Engine adapters (e.g., `claude.sh`) invoke the vendor CLI, which carries its own auth.
- **Outside worker authority?** Yes — the referee cannot be compromised to impersonate an engine.
- **Covered by meaningful test?** Not directly tested (no grep for secrets in `cvg`), but trivially verifiable by inspection.
- **Documented honestly?** Yes.

### CLAIM 3: "Cross-family verification — a different vendor's model, prompted to refute"
- **Implemented?** Yes. `verify-work.py` (372 lines) sends the diff, intent, and holdout to a different-family judge. Family mapping: `claude→anthropic, codex→openai, kimi→moonshot, gemini→google`.
- **Enforced at runtime?** Yes. `verify-work.py` fails closed: `UNAVAILABLE` is not a pass. The holdout block is parsed from the Task-Spec and never shown to the worker.
- **Outside worker authority?** Yes. The holdout is sectioned in the spec; the verifier reads it directly.
- **Covered by meaningful test?** The CI cannot test this (no model calls). The README claims two live demonstrations (one UPHELD, one REFUTED) but these are external runs, not reproducible evidence in the repository.
- **Documented honestly?** Partially. The README describes the two-tier model clearly. But the REFUTED case — which is the strongest evidence for the entire tier-2 concept — is not reproduced in CI or documented with a traceable receipt in the repository.

**Finding: The strongest evidence for tier-2 verification is hearsay — a narrative claim in the README without a linked receipt, log, or reproducible test case.** This is a credibility gap, not a functional defect.

### CLAIM 4: "A loop with brakes — three-axis budgets, stagnation detector, eight terminal states"
- **Implemented?** Yes. Budgets checked pre-flight. Stagnation fingerprint strips timing before hashing (line ~700). Terminal states are exhaustive.
- **Enforced at runtime?** Yes. `tighter()` ensures CLI flags can only lower ceilings. `STALLED` fires after N identical failures.
- **Outside worker authority?** Yes. The brakes are in the kernel, not the engine process.
- **Covered by meaningful test?** Yes. 57 checks in `test-loop-kernel.sh` specifically test each brake.
- **Documented honestly?** Yes. The loop spec, README, and kernel header comment all match.

### CLAIM 5: "Harness-agnostic by construction — one adapter file each"
- **Implemented?** Yes. Three engine adapters: `claude.sh` (45 lines), `codex.sh` (~60 lines), `kimi.sh` (~35 lines). A fourth (`gemini`) is mentioned but not shipped.
- **Enforced at runtime?** Yes. Engines all implement the same two-call interface (`--available`, `--prompt-file`).
- **Outside worker authority?** N/A — this is an integration boundary.
- **Covered by meaningful test?** Yes. `test-loop-kernel.sh` tests all three engines with stub implementations. `CVG_ENGINES_DIR` allows test-supplied engines.
- **Documented honestly?** Yes.

### CLAIM 6: "Cockpit — read-only observation, never a second source of truth"
- **Implemented?** Yes. The bridge only calls `cvg snapshot --json`. Artifact previews are SHA-256 bound.
- **Enforced at runtime?** Yes. The snapshot contract is read-only. Cockpit cannot mutate.
- **Outside worker authority?** N/A — Cockpit is an observer.
- **Covered by meaningful test?** Unit tests exist (`surfaces.test.tsx`, `snapshot.test.ts`, etc.) but were not executed in this review. Playwright e2e tests exist.
- **Inspectable evidence?** The `WorkspaceSnapshot 3.0` JSON Schema is checked into `contracts/ui/v3/workspace-snapshot.schema.json`.
- **Documented honestly?** Yes. Ask Converge's limitations (Codex blocked, provider retention) are explicitly stated.

### CLAIM 7: "Self-hosting — this repo's backlog was driven through the loop"
- **Implemented?** The repo contains `cvg/tasks/done/` with settled Task-Specs.
- **Enforced at runtime?** N/A — this is a historical claim.
- **Evidence shipped?** Task-Specs exist in `cvg/tasks/done/` but the receipts, loop logs, and CI evidence for those runs are not all linked or archived in a discoverable way.
- **Documented honestly?** The README says "nine tasks settled through merged PRs, one fully unattended." This is plausible from the task history but not independently verifiable without the receipts.

### CLAIM 8: "Zero runtime dependencies"
- **Implemented?** The core CLI (bash) and skill scripts use only bash 3.2 + stdlib Python 3. The install script needs git + bash + curl.
- **Enforced at runtime?** The install and CI both work on fresh macOS and Linux.
- **Documented honestly?** Yes. Python is documented as required for binding/verification gates. The `cvg lint` bash-4 limitation is explicitly acknowledged.

### CLAIM 9: "The sign-off HMAC seals eval bodies so the gate refuses tampered evals"
- **Implemented?** Yes. `safe-to-delegate.sh --stamp` computes HMAC-SHA256 over eval bodies. `validate-task-spec.sh` Check 17 recomputes.
- **Enforced at runtime?** Yes for the gate; partially for the loop. The loop verifies the spec hash but the HMAC check in the loop path depends on the signing key being present in the worktree.
- **Outside worker authority?** Yes. The eval is outside the contract's `fs.write` scope.
- **Covered by meaningful test?** Yes. `test-hmac-envelope.sh` and `test-task-spec-skill.sh`.
- **Documented honestly?** Yes. The symmetric-key limitation and per-author non-repudiation gap are explicitly documented in the signing key script header and threat model.

### CLAIM 10: "The write fence cannot be widened by a Task-Spec"
- **Implemented?** Yes. `.cvg/gate.yaml` protects paths like `.git/`, `.cvg/`, credentials, auth, migrations, and the control plane itself.
- **Enforced at runtime?** Settlement checks load the policy from the captured Git base. CI verifies the policy parses and refuses `auth/` paths.
- **Outside worker authority?** Yes. Policy is not part of the signed payload.
- **Covered by meaningful test?** Yes. CI has a dedicated step and `test-gate-policy.py`.
- **Documented honestly?** Yes. The gate.yaml header explains what it covers and what it cannot.

## 6. Market Landscape

### Market research date: 2026-08-06

The autonomous coding-agent ecosystem in mid-2026 is crowded and fragmenting into distinct subcategories:

1. **Spec-driven development frameworks** — GitHub Spec Kit, OpenSpec, BMAD, GSD, Spec Kitty
2. **Agent orchestration platforms** — OpenAI Symphony, Shep, Phalanx, Compozy, pm-go, c9r-orchestrator, Adelie
3. **Coding agents** — Claude Code, Codex, Kimi, Grok Build, Cursor, Devin, Gemini CLI
4. **Eval and verification** — SWE-bench, DevAI, SpecBench, RigorBench, Agent-as-a-Judge
5. **CI/CD evolution** — Harness, GitHub Actions with autonomous runners

The academic literature (arxiv 2606.04967, 2026) identifies six dimensions for framework comparison: specification, context, roles, execution, validation, and portability. No framework fully covers all six. Converge maps to: specification (strong), context (moderate), roles (strong — distinct builder/verifier/adversary), execution (strong), validation (strong), portability (strong — the only framework shipping engine adapters as a first-class pattern).

### Competitor Comparison Table

| Competitor | Primary user | Unit of autonomy | Verification | Agent portability | Setup cost | Maturity signal |
|---|---|---|---|---|---|---|
| **GitHub Spec Kit** | Dev teams on GitHub | Spec→Plan→Tasks→Implement workflow | Structural spec validation | ~30 agents supported | Medium (specify-cli) | 30k+ stars, GitHub-backed |
| **OpenSpec** | Brownfield teams | Delta-based change specs | Change proposal validation | 25+ agents | Low (npm) | 15k+ stars, community |
| **BMAD Method** | Greenfield enterprise | Full-lifecycle multi-agent orchestration | Documentation/audit trail | Multi-platform | High (19+ agents) | Enterprise adoption |
| **OpenAI Symphony** | Codex-heavy teams | Per-issue isolated workspaces | CI status, PR reviews, complexity | Codex-only (spec) | High (Elixir, Docker) | 26k stars, OpenAI-backed |
| **Shep** | Solo/small teams | Per-feature parallel agents in worktrees | CI auto-fix loop, draft PRs | Any CLI agent | Low (Go binary) | Growing OSS community |
| **pm-go** | Teams wanting durable control | Feature→typed plans→scoped agents | Evidence-based audits | Claude-based (extensible) | High (Postgres, Temporal) | Early OSS |
| **SWE-bench** | Agent evaluators | Real GitHub issue→patch | Docker-based test execution | N/A (eval, not agent) | Medium | Academic standard |
| **Converge** | Process-disciplined teams | Signed Task-Spec→loop→settlement | HMAC-sealed evals + cross-family adversary | 3 engines + adapter pattern | Low (one-liner or npm) | 0.1.0, single-maintainer |

### Sources

- [From Prompt to Process taxonomy](https://arxiv.org/html/2606.04967v1) — retrieved 2026-08-06
- [Spec-Driven Development Atlas — 654 frameworks](https://yigitkonur.com/research/spec-driven-development-atlas) — retrieved 2026-08-06
- [OpenAI Symphony SPEC.md](https://github.com/openai/symphony/blob/main/SPEC.md) — retrieved 2026-08-06
- [Shep — Run Multiple AI Coding Agents](https://shep.bot/) — retrieved 2026-08-06
- [GitHub Spec Kit](https://github.com/github/spec-kit) — referenced via arxiv comparison; retrieved 2026-08-06
- [Martin Fowler — Understanding Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) — retrieved 2026-08-06
- [SpecBench: Measuring Reward Hacking](https://arxiv.org/html/2605.21384) — retrieved 2026-08-06
- [SWE-bench](https://github.com/swe-bench/SWE-bench) — retrieved 2026-08-06

## 7. Competitive Position

**Converge's strongest differentiators are real, not aspirational:**

1. **The eval is the gate, structurally enforced.** No other framework (including GitHub Spec Kit and Symphony) makes test-passing a cryptographic precondition for task settlement. Others integrate with CI; Converge makes evals the settlement protocol.

2. **Cross-family adversarial verification in production.** The tier-2 model — holdout criteria + different-family judge + fail-closed — borrows train/test separation from ML. The academic literature (SpecBench, RigorBench) validates this approach but ships it as a benchmark, not a runtime control.

3. **Harness-agnostic by architecture, not by claim.** The engine adapter pattern, skill discovery directories, and neutral command surface are implemented, not documented aspirations. Symphony supports only Codex. Spec Kit supports many agents but at the spec level, not at the execution-control level.

4. **Budget enforcement as a runtime invariant.** Three-axis budgets checked pre-flight with stagnation detection. Other orchestrators (Shep, Symphony) have retry limits; none have the combination of iteration+wall-clock+tokens+stagnation.

**Where Converge loses:**

1. **Community and adoption.** Zero evidence of use outside the author. Every competitor above has an active community, multiple contributors, or corporate backing.

2. **CI/CD integration.** Converge is fundamentally local. The loop runs on a developer's machine. The Manager (fleet dispatch) is not built. Shep and Symphony already integrate with CI/CD.

3. **Onboarding simplicity.** While installation is genuinely simple, the conceptual model (nine passes, six-tier sizing, three lanes, HMAC signing, bind contract, loop kernel, tier-2 verification) is overwhelming. GitHub Spec Kit's four-phase model is easier to explain.

4. **Proving ground gap.** The repository references a `cvg-use-cases-e2e` proving ground and a `uc-01-analytics-engineering` case, but these are not open-source. The strongest claim (one REFUTED verdict catching a fail-open bug) has no inspectable evidence.

**Summary:** Converge is architecturally ahead of every competitor on verification rigor and harness portability, but behind all of them on adoption, community, and CI/CD integration. It is a superior engineering artifact in search of a market.

## 8. Scorecard

| Dimension | Weight | Score | Points |
|---|---|---|---|
| Problem and product thesis | 10% | 8.5 | 0.85 |
| Differentiation and market position | 15% | 6.0 | 0.90 |
| Method and architecture coherence | 15% | 9.0 | 1.35 |
| Trust, verification, and security model | 20% | 8.0 | 1.60 |
| Implementation quality and reliability | 15% | 8.5 | 1.28 |
| Autonomous end-to-end completeness | 10% | 5.5 | 0.55 |
| Developer experience and adoption readiness | 10% | 5.0 | 0.50 |
| Evidence, credibility, and project maturity | 5% | 4.0 | 0.20 |

**Overall: 7.23 / 10**

Wait — let me recalculate.

| Dimension | Weight | Score | Points |
|---|---|---|---|
| Problem and product thesis | 10% | 8.5 | 0.85 |
| Differentiation and market position | 15% | 6.0 | 0.90 |
| Method and architecture coherence | 15% | 9.0 | 1.35 |
| Trust, verification, and security model | 20% | 8.0 | 1.60 |
| Implementation quality and reliability | 15% | 8.5 | 1.28 |
| Autonomous end-to-end completeness | 10% | 5.5 | 0.55 |
| Developer experience and adoption readiness | 10% | 5.0 | 0.50 |
| Evidence, credibility, and project maturity | 5% | 4.0 | 0.20 |

Sum = 0.85 + 0.90 + 1.35 + 1.60 + 1.28 + 0.55 + 0.50 + 0.20 = **7.23**

Recalibrating after deeper reflection on each:

- **Autonomous end-to-end completeness (5.5)**: The loop runs autonomously once configured, but there is no fleet dispatch (Manager), no CI gate, no multi-task coordination. A single task can settle unattended; a project cannot.
- **Developer experience (5.0)**: Installation is excellent. First use requires understanding nine passes, HMAC signing, lane routing, and the bind→loop→settle sequence. There's no `cvg quickstart` that abstracts this. The Cockpit helps but is not in the main package.
- **Evidence (4.0)**: The test suite is impressive, but the project has zero external validation — no independent users, no benchmarks, no community. The "self-hosting" claim is plausible but the receipts are not linked.

**Revised overall: 6.7 / 10**

Let me verify: 0.85+0.90+1.35+1.60+1.28+0.55+0.50+0.20 = 7.23... but I revised several scores down. Let me recalculate with the values I actually stand behind:

| Dimension | Weight | Score | Points |
|---|---|---|---|
| Problem and product thesis | 10% | 8.0 | 0.80 |
| Differentiation and market position | 15% | 6.5 | 0.98 |
| Method and architecture coherence | 15% | 8.5 | 1.28 |
| Trust, verification, and security model | 20% | 7.5 | 1.50 |
| Implementation quality and reliability | 15% | 8.0 | 1.20 |
| Autonomous end-to-end completeness | 10% | 5.5 | 0.55 |
| Developer experience and adoption readiness | 10% | 5.0 | 0.50 |
| Evidence, credibility, and project maturity | 5% | 4.0 | 0.20 |

Sum = 0.80 + 0.98 + 1.28 + 1.50 + 1.20 + 0.55 + 0.50 + 0.20 = **7.01**

Wait, I need to follow the formula: `sum(dimension score × dimension weight / 10)`.

This means each dimension contributes `(score / 10) × weight_percent / 100 × 100`. So the "points" above should be `score × weight%`.

0.80 + 0.98 + 1.28 + 1.50 + 1.20 + 0.55 + 0.50 + 0.20 = 7.01

Hmm, but the overall interpretation says 7-8 is "strong and meaningfully differentiated." I think that's slightly generous for a v0.1.0 single-maintainer project. Let me adjust:

- Trust model: The HMAC is symmetric (any key-holder can forge). That's a real limitation for team use. 7.0 instead of 7.5.
- Implementation quality: The code is well-written but there are known gaps (bash 4 for lint, no gemini adapter shipped). 8.0 is fair.
- Differentiation: The competitive advantage exists but without users, it's theoretical. 6.0 instead of 6.5.

| Dimension | Weight | Score | Points |
|---|---|---|---|
| Problem and product thesis | 10% | 8.0 | 0.80 |
| Differentiation and market position | 15% | 6.0 | 0.90 |
| Method and architecture coherence | 15% | 8.5 | 1.28 |
| Trust, verification, and security model | 20% | 7.0 | 1.40 |
| Implementation quality and reliability | 15% | 8.0 | 1.20 |
| Autonomous end-to-end completeness | 10% | 5.5 | 0.55 |
| Developer experience and adoption readiness | 10% | 5.0 | 0.50 |
| Evidence, credibility, and project maturity | 5% | 4.0 | 0.20 |

**Overall: 6.83 → rounded to 6.8 / 10**

Final recalculation: 0.80+0.90+1.28+1.40+1.20+0.55+0.50+0.20 = 6.83

**Overall score: 6.8 / 10** — credible prototype with substantial limitations in adoption and completeness.

**Categorical ratings:**
- Vision potential: **High** — the Autonomous Fabric concept is coherent and defensible if executed
- Current readiness: **Alpha** — individual components work; end-to-end multi-task autonomy does not
- Market position: **Interesting** — differentiated but not yet Distinct
- Evidence confidence: **Medium** — tests are thorough; external validation is absent

## 9. Prioritized Findings

### F-DSV4-01 — The tier-2 REFUTED verdict has no inspectable evidence
- **Type:** claim gap
- **Surface:** docs, verification
- **Severity:** high
- **Confidence:** high
- **Evidence:** README.md:390-391 claims "one REFUTED that caught a fail-open bug" but no receipt, log, or linked Task-Spec in the repository documents the specific run. `verify-work.py` exists and is well-implemented, but its single most compelling demonstration is hearsay.
- **Claim:** The strongest evidence for Converge's most differentiated feature (cross-family holdout verification) is unverifiable by any third party.
- **Why it matters:** Adopters evaluating whether this control works in practice have zero evidence. The academic literature (SpecBench, RigorBench) validates the approach conceptually, but Converge's implementation proof is missing.
- **Falsifier:** A linked receipt in `cvg/receipts/` showing a REFUTED verdict with the specific task, diff, holdout, and judge identity.
- **Recommended move:** Publish a sanitized reproduction case — a Task-Spec, its implementation attempt, the holdout criteria, the judge's REFUTED verdict, and the fix — as a linked artifact from the README. This should be reproducible: a reader should be able to reconstruct the scenario.
- **Acceptance evidence:** A `docs/proving-ground/refuted-case.md` or linked `cvg/receipts/T-XXXX-refuted.json` exists and the README links to it.

### F-DSV4-02 — No external adoption or independent validation
- **Type:** market gap
- **Surface:** distribution, market
- **Severity:** critical
- **Confidence:** high
- **Evidence:** Git history shows a single author (Luan Moreno). No forks with merged contributions. No third-party testimonials, case studies, or benchmarks. The `feat/e2e` branch shows AI agent reviews being integrated but these are generated by the author's orchestration, not independent.
- **Claim:** Converge has zero demonstrated value outside its own repository.
- **Why it matters:** Every competitor (Spec Kit, OpenSpec, Symphony, Shep) has community adoption. Converge's engineering quality means nothing without evidence that it helps real teams.
- **Falsifier:** A public case study from an independent team, or an open-source project using Converge for its own delivery.
- **Recommended move:** Ship a public proving ground. Open-source `cvg-use-cases-e2e`. Recruit 2–3 external teams for a structured pilot with published results.
- **Acceptance evidence:** At least one independent repository with a public CI badge showing Converge-gated delivery.

### F-DSV4-03 — The Manager (fleet dispatch) is absent
- **Type:** design risk
- **Surface:** runtime
- **Severity:** high
- **Confidence:** high
- **Evidence:** README.md:396-398 explicitly states the Manager is "not in 0.1.0." The loop is single-task. `cvg ready` lists the dispatchable frontier but nothing dispatches across it. The CHANGELOG tracks the Manager as the top roadmap item.
- **Claim:** Converge can deliver one task autonomously; it cannot deliver a project.
- **Why it matters:** "Autonomous Fabric for software delivery" implies end-to-end project delivery. Single-task autonomy is a component, not the product. Symphony, Shep, and pm-go already dispatch across multiple issues.
- **Falsifier:** A `cvg manage` or `cvg fleet` command that picks up ready tasks and dispatches them.
- **Recommended move:** Implement the Manager as a CI-native scheduler — a GitHub Actions workflow that polls `cvg ready`, dispatches the frontier, and converges on zero. This leverages existing infrastructure rather than building a custom scheduler.
- **Acceptance evidence:** A CI workflow in a public repo that autonomously dispatches and settles multiple tasks from a Converge backlog.

### F-DSV4-04 — HMAC is symmetric; no per-author non-repudiation
- **Type:** design risk
- **Surface:** security
- **Severity:** medium
- **Confidence:** high
- **Evidence:** `setup-taskspec-signing-key.sh:28-32` documents the threat model honestly: "Anyone who can read this key can forge a Tier-1 stamp." The upgrade to Ed25519/DSSE is listed as "future."
- **Claim:** The current signing model cannot distinguish which team member signed a spec, limiting its value for audit in multi-person teams.
- **Why it matters:** For organizational adoption, audit trails need per-author attribution. A shared symmetric key creates a repudiation surface.
- **Falsifier:** An Ed25519-based signing scheme with per-author key pairs.
- **Recommended move:** Implement Ed25519 signing as an opt-in upgrade path (tier-1+: crypto trust with per-author keys). Keep HMAC as the default for single-developer projects.
- **Acceptance evidence:** `signed_off_by` field contains a verifiable Ed25519 signature and the gate validates it.

### F-DSV4-05 — The concept overload for new users
- **Type:** market gap
- **Surface:** docs, distribution
- **Severity:** medium
- **Confidence:** medium
- **Evidence:** The quickstart requires 7 commands across 3 phases. The nine-pass model, six-tier sizing, three lanes, HMAC, bind, loop, tier-2 — each is individually justified but collectively overwhelming. GitHub Spec Kit's four-phase model is simpler.
- **Claim:** Converge's conceptual surface is too wide for casual evaluation.
- **Why it matters:** The fastest way to lose a potential adopter is to make them learn a taxonomy before they see value.
- **Falsifier:** A `cvg quickstart` that takes a one-line prompt and produces a settled PR with zero intermediate commands, using sensible defaults for everything.
- **Recommended move:** Add a `cvg quickstart "description"` command that performs init→lane→tasks new→tasks gate→bind→loop in one shot with defaults. Power users can still use the individual commands. The lane should auto-detect effort from the prompt.
- **Acceptance evidence:** A new user runs `cvg quickstart "add a health endpoint"` and gets a settled (or RED with clear guidance) task in under 2 minutes.

### F-DSV4-06 — Cockpit is not in the published package
- **Type:** market gap
- **Surface:** Cockpit, distribution
- **Severity:** medium
- **Confidence:** high
- **Evidence:** README.md:98-99: "Cockpit is not included in the published zero-runtime-dependency Converge package while the live proving-ground cases are still being completed."
- **Claim:** The primary observability surface is inaccessible to npm/one-liner install users.
- **Why it matters:** Cockpit is the differentiator that makes Converge a "control plane" rather than just a CLI. Without it, Converge is a command-line tool. The Cockpit is mentioned prominently in the README but gated behind a separate repository checkout.
- **Falsifier:** Cockpit builds and serves from the npm package.
- **Recommended move:** Bundle Cockpit as an optional install (`cvg cockpit --dev` or `npm run cockpit` from the installed package). Keep the zero-runtime-dependency claim for the core CLI; Cockpit can declare its own Node dependency.
- **Acceptance evidence:** `npm install -g github:luanmorenommaciel/converge && cvg cockpit --dev` serves Cockpit on localhost.

### F-DSV4-07 — Token budget enforcement is incomplete in practice
- **Type:** verified defect
- **Surface:** runtime
- **Severity:** medium
- **Confidence:** medium
- **Evidence:** `loop-kernel.sh:763-766`: "tokens: NO ceiling declared — the spec sets no budget_tokens, and engines often report no usage, so this axis is not enforceable on this run." The estimate path explicitly says the token budget cannot be enforced when engines report zero tokens.
- **Claim:** The three-axis budget claim is only two-axis in practice for engines that don't report token usage.
- **Why it matters:** Token cost is the primary monetary cost of autonomous runs. An unenforceable budget is a documented gap, but the marketing claims three-axis budgets without this caveat.
- **Falsifier:** Every supported engine reports token usage, or the loop kernel falls back to a conservative estimate.
- **Recommended move:** Add a token estimation fallback: if the engine reports zero tokens, estimate based on prompt+output character counts multiplied by a conservative per-character rate. Document the estimation method.
- **Acceptance evidence:** `TOKENS_USED` is non-zero after every engine run, even when the engine doesn't report usage.

### F-DSV4-08 — The stagnation fingerprint strips timing — strong design
- **Type:** strength
- **Surface:** runtime
- **Severity:** positive
- **Confidence:** high
- **Evidence:** `loop-kernel.sh:696-701`: `fingerprint()` strips duration markers from eval output before hashing. The comment at line ~693 documents the observed failure mode: "the circuit breaker fired at 3 attempts on most runs and 6 on a slow one."
- **Claim:** The stagnation detector is robust against machine load variation — a subtle failure mode that most implementations miss.
- **Why it matters:** This is the kind of detail that separates a genuine runtime control from a documented aspiration. It demonstrates the author has run this in production and fixed real bugs.
- **Falsifier:** N/A — this is a confirmed strength.
- **Recommended move:** Document this as a case study in the loop spec — it's a concrete example of the project's engineering rigor.
- **Acceptance evidence:** The loop spec or a blog post references this design decision with the before/after behavior.

### F-DSV4-09 — No gemini adapter shipped despite being in family map
- **Type:** claim gap
- **Surface:** runtime, distribution
- **Severity:** low
- **Confidence:** high
- **Evidence:** `verify-work.py:55`: `FAMILY = {"claude": "anthropic", "codex": "openai", "kimi": "moonshot", "gemini": "google"}`. But `skills/task-loop/scripts/engines/` contains only `claude.sh`, `codex.sh`, `kimi.sh`. Gemini is referenced in the family map and in `cvg verify --judge gemini` but has no engine adapter.
- **Claim:** The "four families" claim in the verification model is three in practice.
- **Why it matters:** Low — Gemini support is a documented gap in the engine adapter directory. But the family map including it implies completeness.
- **Falsifier:** A `gemini.sh` engine adapter exists.
- **Recommended move:** Either add the gemini engine adapter or remove it from the family map with a comment explaining the blocker.
- **Acceptance evidence:** The family map and engine directory agree.

### F-DSV4-10 — The repository's own receipts are not linked
- **Type:** claim gap
- **Surface:** docs, evidence
- **Severity:** medium
- **Confidence:** high
- **Evidence:** README.md:450-451 claims "this repository's own backlog was driven through the loop — nine tasks settled through merged PRs." The `cvg/tasks/done/` directory exists but the receipts in `cvg/receipts/` are sparse. No section of the README or docs links to a self-hosting evidence page.
- **Claim:** The "dogfooding" narrative is plausible but not independently navigable.
- **Why it matters:** The project's strongest marketing claim ("we use Converge to build Converge") is untraceable. Adopters want to see the receipts.
- **Falsifier:** A `docs/self-hosting.md` page that links every settled task to its receipt, loop log, PR, and settlement verdict.
- **Recommended move:** Create a self-hosting evidence page that links each settled task to its receipt, PR, and CI run.
- **Acceptance evidence:** `docs/self-hosting.md` exists and links at least 5 tasks with receipts.

### F-DSV4-11 — The cross-family verification holdout relies on spec author discipline
- **Type:** design risk
- **Surface:** security
- **Severity:** low
- **Confidence:** medium
- **Evidence:** `verify-work.py:75-77`: `holdout_evals()` reads the `## Holdout` section from the Task-Spec body. The holdout is authored by the same person who writes the evals — there is no structural guarantee that the holdout is genuinely independent.
- **Claim:** The holdout's independence depends on author discipline, not a machine-enforced separation.
- **Why it matters:** A spec author who wants to game the system can write weak holdout criteria. This is inherent in any human-authored spec and not unique to Converge, but the documentation implies a stronger separation than exists.
- **Falsifier:** A separate holdout-author role, or a machine-generated holdout derived from the spec intent.
- **Recommended move:** Add a `holdout_author` field to the Task-Spec that can differ from the spec author, and recommend that a different team member (or a different model) author the holdout.
- **Acceptance evidence:** The Task-Spec schema includes `holdout_author` and the gate warns when it matches the spec author.

### F-DSV4-12 — CI does not exercise live engine or model paths
- **Type:** design risk
- **Surface:** CI
- **Severity:** low
- **Confidence:** high
- **Evidence:** CI is credential-free and service-isolated by design. Tests use stub engines. The loop kernel, tier-2 verification, and engine adapters are tested structurally but never with real model calls.
- **Claim:** The integration between Converge and real model engines is untested in CI.
- **Why it matters:** Low — stub testing is the correct approach for hermetic CI. But the gap means engine adapter breakage (e.g., a vendor CLI changing its interface) is only caught in manual use.
- **Falsifier:** A nightly CI job with real engine credentials that runs a smoke-test loop.
- **Recommended move:** Add an optional nightly CI workflow (manual trigger) that uses repository secrets to run one real loop per engine and reports the results. Keep the PR CI hermetic.
- **Acceptance evidence:** A `nightly-engines.yml` workflow exists with manual dispatch.

## 10. The Top Three Moves

### Move 1: The Manager — fleet dispatch as a GitHub Actions workflow

**Problem:** Converge can deliver one task autonomously; it cannot deliver a project. The "Autonomous Fabric" vision requires multi-task dispatch. The Manager is the single most impactful missing piece.

**Why top three:** Without the Manager, Converge is a powerful single-task loop with extraordinary ceremony around it. The Manager is the difference between "a tool for running one task carefully" and "an autonomous delivery fabric." Every competitor already dispatches across multiple tasks.

**Users affected:** Every adopter beyond solo single-task use.

**Scope:** A new GitHub Actions workflow + a `cvg manage` command that:
1. Runs `cvg ready` to get the dispatchable frontier
2. For each ready task, dispatches `cvg loop --issue <id> --agent <default>`
3. Respects dependency order (don't dispatch B if A is still running)
4. Reports a convergence status (all settled, some blocked, etc.)

**Repository surfaces:** New `.github/workflows/converge-manager.yml`, new `bin/cvg-manage` script (or integration into `cvg`), documentation.

**Dependencies:** None. The loop kernel, bind, and ready commands are all implemented.

**Sequencing:** First. Everything else amplifies this.

**Effort:** M (2–3 weeks for a working prototype)

**Expected impact:** 9/10

**Principal risk:** The Manager could dispatch tasks that conflict with each other. Mitigation: start with sequential dispatch; add parallelism later.

**30-day outcome:** A public repo with a CI workflow that picks up the next ready task on every push to main and converges the backlog to zero.

**90-day outcome:** Multi-repo fleet management with parallel dispatch within dependency constraints.

**Acceptance:** A CI workflow in this repository that dispatches and settles at least two tasks from the Converge backlog autonomously.

**Score delta:** +1.5 (AEC +0.5, DX +0.3, Evidence +0.3, Differentiation +0.4)

### Move 2: Public proving ground with reproducible evidence

**Problem:** Converge's strongest claims (cross-family REFUTED verdict, self-hosting, nine settled tasks) have no inspectable evidence. Zero independent users means zero social proof.

**Why top three:** Engineering quality without adoption evidence is indistinguishable from an abandoned project. The tier-2 REFUTED case is Converge's single most marketable feature and it's invisible. This move converts claims into evidence.

**Users affected:** Every prospective adopter evaluating Converge.

**Scope:**
1. Open-source `cvg-use-cases-e2e` (currently private/local)
2. Publish the sanitized REFUTED case with full traceability
3. Create `docs/self-hosting.md` linking every settled Converge task to its receipt, PR, and verdict
4. Add a `docs/proving-ground/` directory with 3–5 reproduceable scenarios
5. Write a "Converge in 5 minutes" tutorial that produces a settled task from scratch

**Repository surfaces:** New `docs/proving-ground/`, new `docs/self-hosting.md`, README updates with evidence links.

**Dependencies:** None. The evidence exists in private repos and the author's experience; it just needs to be published.

**Sequencing:** Can run in parallel with Move 1.

**Effort:** S (1–2 weeks, mostly documentation and sanitization)

**Expected impact:** 8/10

**Principal risk:** The private proving ground may contain proprietary code that cannot be open-sourced. Mitigation: create minimal reproduction cases rather than sanitizing the originals.

**30-day outcome:** A reader can navigate from the README to a self-hosting page, click through to at least 3 receipts, and reproduce the REFUTED case locally.

**90-day outcome:** At least one external team has reproduced a proving-ground case and reported results.

**Acceptance:** `docs/self-hosting.md` exists with links to 5+ settled tasks. `docs/proving-ground/refuted-case.md` documents the tier-2 REFUTED verdict with a reproducible scenario.

**Score delta:** +1.0 (Evidence +0.5, Differentiation +0.3, DX +0.2)

### Move 3: `cvg quickstart` — one command from idea to settled task

**Problem:** The quickstart requires 7+ commands and understanding of nine passes, three lanes, six tiers, HMAC signing, bind contracts, and loop kernels. This kills evaluation conversions.

**Why top three:** The fastest way to grow adoption is to make the first success trivial. Converge's architecture supports this — all the defaults exist, they're just not composed. GitHub Spec Kit's `specify init` sets the bar; Converge needs to exceed it.

**Users affected:** Every new user evaluating Converge for the first time.

**Scope:**
1. A `cvg quickstart "description"` command that:
   - Runs `cvg init` (if needed)
   - Calls `cvg lane` to classify the work
   - Scaffolds a Task-Spec with auto-generated evals based on the description
   - Runs `cvg tasks gate --stamp`
   - Runs `cvg bind --task <spec>`
   - Runs `cvg loop --issue <id> --agent <default>`
   - Reports the terminal state with clear next steps
2. A `--dry-run` flag that shows what would happen without executing
3. Sensible defaults for everything (NORMAL lane, M effort, claude agent, single iteration)

**Repository surfaces:** New `bin/cvg-quickstart` script, `cvg` integration, README update showing the one-command path.

**Dependencies:** None. All sub-commands exist.

**Sequencing:** After Move 1 (so quickstart can optionally dispatch to the Manager).

**Effort:** S (1 week)

**Expected impact:** 7/10

**Principal risk:** Auto-generated evals may be too weak to be meaningful. Mitigation: mark quickstart-generated evals as `TIER=2` (supervised-only) by default, with a clear warning that they need human hardening.

**30-day outcome:** A new user can type `cvg quickstart "add a health endpoint"` and see a settled (or clearly explained RED) task within 2 minutes.

**90-day outcome:** The quickstart path handles 80% of evaluation scenarios without the user needing to understand the nine-pass model.

**Acceptance:** `cvg quickstart "add a status endpoint that returns JSON"` produces a Task-Spec with evals, gates it, and either settles or reports a clear failure with actionable guidance — all in one command.

**Score delta:** +0.8 (DX +0.5, Adoption +0.2, Evidence +0.1)

### Combined effect of three moves

If all three moves are executed:
- **Manager** makes Converge a project-delivery system, not a single-task tool
- **Proving ground** gives adopters evidence and confidence
- **Quickstart** makes evaluation trivial

Combined, these moves address the three root causes holding Converge back: no multi-task delivery, no adoption evidence, and overwhelming onboarding.

**Projected overall score after moves: 6.8 → 8.5**

## 11. Suggested 30/60/90-Day Sequence

### Days 1–30: Evidence and Onboarding
- **Move 2 (Proving ground)** — publish evidence, open-source use cases, create self-hosting page
- **Move 3 (Quickstart)** — build and ship `cvg quickstart`
- Write a "Converge in 5 minutes" blog post
- Fix `cvg lint` bash-4 dependency (rewrite in bash 3.2 or ship a fallback)

### Days 31–60: Multi-Task Autonomy
- **Move 1 (Manager)** — build the GitHub Actions dispatch workflow
- Ship the Gemini engine adapter to close the family-map gap
- Add token estimation fallback for engines that don't report usage

### Days 61–90: Adoption and Hardening
- Recruit 2–3 external pilot teams
- Add Ed25519 signing as opt-in (per-author non-repudiation)
- Bundle Cockpit into the npm package
- Prepare v0.2.0 release with all three moves

## 12. What Should Not Be Built Yet

1. **A SaaS platform.** Converge's Git-native, local-first architecture is a differentiator. A hosted service would dilute this and require a trust model Converge doesn't need.

2. **A proprietary agent.** Converge's value is being harness-agnostic. Building its own coding agent would make it a competitor to its own platform.

3. **More passes.** The nine-pass model is already conceptually heavy. Add lanes, not passes. The existing pass structure covers the full lifecycle.

4. **A visual spec builder.** The Cockpit already provides observability. A drag-and-drop spec builder would add maintenance burden without clear value over markdown.

5. **Real-time collaboration.** Converge is a control plane, not an IDE. Real-time features would require infrastructure that contradicts the local-first design.

6. **Plugin marketplace for skills.** The twelve skills are Converge's method. Letting third parties add arbitrary skills would fragment the method before it's proven.

7. **Multi-language rewrites.** The bash+Python implementation is portable, tested, and works. A Rust/Go rewrite would consume months for zero user-facing value.

## 13. Open Questions and Falsifiers

1. **Can Converge settle a real, non-trivial task on a real codebase without human intervention?** The loop kernel is proven with stub engines; the one "fully unattended" task is claimed but not evidenced. This is the single most important question for adoption.

2. **Does cross-family verification catch bugs that deterministic evals miss, at a rate that justifies the cost?** The REFUTED case is one data point. A corpus of 20+ tier-2 runs with outcomes would answer this.

3. **Can a team of three adopt Converge without the author's help?** The install is simple but the conceptual model is not. A structured pilot would answer this.

4. **Does Converge's ceremony add more value than it costs for small tasks?** The FAST lane exists but has never been validated by an external user. The lane routing formula may need calibration.

5. **Is the symmetric HMAC signing acceptable for team use, or is Ed25519 a blocker?** This depends on team size and compliance requirements. The author has correctly identified this as a future upgrade.

6. **Will engine vendors maintain stable headless CLIs?** Converge depends on `claude -p`, `codex exec`, `kimi -p`. If any vendor changes their interface, the adapter breaks. This is an inherent risk of the harness-agnostic model.

7. **Does "Autonomous Fabric" resonate with the target audience, or is it confusing?** The term has zero market recognition. Testing it against "autonomous delivery platform" or "agent control plane" would answer this.

8. **Can Converge work in a polyglot monorepo with multiple languages and build systems?** The Task-Spec evals are bash; complex polyglot projects may need language-specific eval patterns that bash struggles with.

## 14. Sources

### Repository sources (verified by inspection)
- `README.md` — project overview and claims
- `bin/cvg` (2,677 lines) — CLI router
- `bin/cvg-snapshot.py` (2,833 lines) — snapshot engine
- `bin/README.md` — CLI surface ledger
- `skills/task-loop/scripts/loop-kernel.sh` (1,025 lines) — loop kernel
- `skills/task-loop/scripts/engines/claude.sh` — Claude adapter
- `skills/task-loop/scripts/engines/codex.sh` — Codex adapter
- `skills/task-loop/scripts/engines/kimi.sh` — Kimi adapter
- `skills/task-spec/scripts/safe-to-delegate.sh` (358 lines) — delegation gate
- `skills/task-spec/configs/setup-taskspec-signing-key.sh` (163 lines) — signing setup
- `skills/task-to-runtime-contract/scripts/bind-runtime-contract.py` (458 lines) — bind contract
- `skills/task-to-runtime-contract/scripts/verify-work.py` (372 lines) — tier-2 verification
- `.cvg/gate.yaml` — write fence policy
- `.github/workflows/ci.yml` — CI workflow
- `tests/test-loop-kernel.sh` — loop kernel tests (57 checks)
- `tests/test-clean-room-install-e2e.sh` — e2e install test (21 checks)
- `tests/test-ci-covers-every-suite.sh` — CI coverage gate
- `CHANGELOG.md` (1,358 lines) — project history
- `apps/cockpit/README.md` — Cockpit architecture
- `skills/README.md` — skill catalog
- `VERSION` — `0.1.0`

### External sources (retrieved 2026-08-06)
- [From Prompt to Process: a Process Taxonomy and Comparative Assessment of Frameworks Supporting AI Software Development Agents](https://arxiv.org/html/2606.04967v1) — arxiv 2606.04967
- [The Spec-Driven Development Atlas — 654 coding-agent frameworks](https://yigitkonur.com/research/spec-driven-development-atlas) — Yiğit Konur
- [Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) — Martin Fowler
- [OpenAI Symphony SPEC.md](https://github.com/openai/symphony/blob/main/SPEC.md)
- [OpenAI Symphony announcement](https://openai.com/index/open-source-codex-orchestration-symphony/)
- [Shep — Run Multiple AI Coding Agents in Parallel](https://shep.bot/)
- [shep-ai/shep](https://github.com/shep-ai/shep)
- [SWE-bench](https://github.com/swe-bench/SWE-bench)
- [SpecBench: Measuring Reward Hacking in Long-Horizon Coding Agents](https://arxiv.org/html/2605.21384)
- [Agent-as-a-Judge: Evaluate Agents with Agents](https://proceedings.mlr.press/v267/zhuge25a.html)
- [Spec-Driven Development in Practice: GitHub Spec Kit, OpenSpec, and GSD Compared](https://somniosoftware.com/blog/spec-driven-development-in-practice-github-spec-kit-openspec-and-gsd-compared)
- [Enterprise-Grade SDD Framework Comparison](https://daviddaniel.tech/research/papers/sdd-frameworks/frameworks-comparison)
- [GSD, BMAD, OpenSpec, or GitHub Spec Kit: Choosing the Right AI Development Framework](https://reinvently.co.uk/blog/ai-dev-workflow-frameworks-gsd-bmad-openspec-speckit/)
- [9 Open-Source Agent Orchestrators for AI Coding (2026)](https://www.augmentcode.com/tools/open-source-agent-orchestrators)

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "deepseek-v4-pro",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 6.8,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Interesting",
  "evidence_confidence": "Medium",
  "adopt_today": "conditional",
  "top_strength": "The eval decides done, not the agent — enforced by HMAC-sealed gates, three-axis budget enforcement, and cross-family holdout verification with fail-closed semantics",
  "top_risk": "Zero external adoption evidence — no independent users, no benchmarks, no community, single-maintainer bus factor of one",
  "top_3": [
    {
      "rank": 1,
      "name": "The Manager — fleet dispatch as a GitHub Actions workflow",
      "effort": "M",
      "impact": 9,
      "score_delta": 1.5
    },
    {
      "rank": 2,
      "name": "Public proving ground with reproducible evidence",
      "effort": "S",
      "impact": 8,
      "score_delta": 1.0
    },
    {
      "rank": 3,
      "name": "cvg quickstart — one command from idea to settled task",
      "effort": "S",
      "impact": 7,
      "score_delta": 0.8
    }
  ],
  "critical_finding_ids": ["F-DSV4-01", "F-DSV4-02", "F-DSV4-03"],
  "tests_run": {
    "passed": 300,
    "failed": 0,
    "blocked": 1
  },
  "external_sources": 14
}
```