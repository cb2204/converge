# Converge Independent Review — glm

## 1. Review Metadata

- **Reviewer / model identifier:** `openrouter/z-ai/glm-5.2` (self-identified; no external model-id disclosure available in-repo). Reviewer ID for this file: `glm`.
- **Reasoning mode / effort:** Default session reasoning effort; no explicit effort control exposed. Single-pass adversarial review.
- **Review timestamp & timezone:** 2026-08-05T22:20 (UTC-03, America/Argentina local; retrieved via `date`).
- **Git HEAD SHA:** `9c966884e37919c0f7e4c3e027b4b237670eb2ad`
- **Latest commit:** `9c966884` — `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi` (2026-08-04 20:28:35 -03)
- **Branch state:** `feat/e2e` (not detached).
- **Worktree dirty at start:** Yes — pre-existing changes preserved, not introduced by this review:
  - `M apps/cockpit/package-lock.json`
  - `D review/deepseek.md`, `D review/grok.md`, `D review/kimi.md`
  - (untracked: `.sc/`, `test-results/`)
  These deletions are other reviewers' files; per the independence rules I did **not** read, list, or inspect anything under `review/` and treated the deletions as pre-existing state to preserve.
- **Tools available for inspection:** `read`, `grep`, `glob`, `bash` (bash 5.3.9, Python 3.14.3, git 2.50.1, `shellcheck` present), `web_search`. Engine CLIs (`claude`, `codex`, `kimi`, `grok`) are installed on the host but were **not** invoked — the rules forbid invoking paid model APIs, so only hermetic stub-engine suites were run.
- **Market research:** `MARKET_RESEARCH=complete` (public-web research performed 2026-08-05).

## 2. Executive Verdict

- **Overall score: 67.3 / 100** (6.7 / 10).
- **Does Converge stand out today?** Yes, but as a *distinct method and trust model*, not as a category-defining product. The eval-decides-done invariant, the HMAC-sealed spec, the cross-family tier-2 holdout judge, and the referee-holds-no-credentials posture are a coherent, tested combination no inspected competitor matches in the same shape. It does not yet stand out as a *fabric* — the fleet-dispatch layer that would justify the name is unbuilt.
- **Strongest defensible advantage:** "Done is a state-machine invariant, not an agent's claim" — implemented end to end: evals are HMAC-sealed before delegation, the loop only settles when the sealed Exit Check exits 0, settlement stages only authorized paths (never `git add -A`), and an optional different-family judge refutes the diff against a holdout the builder never saw. The clean-room e2e proves the full chain from an empty repo with a stub engine (21/21).
- **Most dangerous weakness:** The autonomy and evidence claims outrun the shipped artifact. The Manager (fleet dispatch across ready tasks) and the CI eval-gate (server-side re-verification) — the two things that would make it a "fabric" rather than a single-task loop — are unbuilt and self-declared as the top roadmap gaps. The strongest *live* trust evidence (the cross-family UPHELD/REFUTED runs) lives only in git history and a removed proving ground; the four current proving-ground cases are "Not run / Open."
- **Would I adopt it today?** **Conditionally.** Adoptable now by a single team that already runs Claude Code / Codex / Kimi and wants sealed, cross-family-verified spec-driven delivery on well-scoped tasks — the hermetic evidence is strong enough to trust the mechanism. Not adoptable as an organizational "Autonomous Fabric": no fleet dispatch, no server-side re-verification, single author, no third-party adoption signal, and proving grounds incomplete.

## 3. What Converge Actually Is

Converge is a **method + CLI referee + portable skill chain**, with an optional **read-only Cockpit** UI. It is *not* a runtime that executes models, and it is *not* a model.

- **Method:** a nine-pass "descent" (0 Capture → 8 The Loop) split into a human-led design half (0–4) and a machine-led build half (5–8), separated by "THE BARRIER" (Pass 4 cross-family adversarial review + human sign-off). `cvg lane` routes work to FAST (5,7,8) / NORMAL (1,2,5,7,8) / FULL (0–8) and "routes but never waives." Verified: `skills/task-spec/scripts/classify-lane.py`, `skills/README.md:43-71`.
- **Unit of work:** the **Task-Spec** — a markdown file with YAML frontmatter, six zones, ≥3 runnable bash evals, an Exit Check, an effort budget, and an HMAC sign-off seal. Two dual gates: `safe-to-delegate.sh --stamp` (PRE, seals evals) and `accept-task.sh --stamp` (POST, certifies the work). Verified: `skills/task-spec/scripts/safe-to-delegate.sh`, `skills/README.md:189-203`.
- **CLI referee:** `bin/cvg` (bash 3.2, zero core deps) wraps the skill scripts as byte-exact pass-throughs; it holds no model credentials and makes no LLM calls. Engine CLIs authenticate themselves. Verified: `bin/cvg:1-45`, `bin/README.md:68-74`.
- **Skill chain:** twelve portable skills (nine passes + three utilities) installed into `.claude/skills/`, `.agents/skills/`, `.grok/skills/`. Verified: `install.sh`, `skills/README.md:1-10`.
- **Loop (Pass 8):** `loop-kernel.sh` runs attempt → verify → repeat over **one** assigned task, bounded on three axes (iterations · wall-clock · tokens, checked *before* each call), with a stagnation detector (same failure fingerprint twice → `STALLED`) and eight named terminal states — only `SETTLED|LOCAL_SETTLED|NO_OP` exit 0. Each attempt is a fresh engine process; worktree isolation is the default. Verified: `skills/task-loop/scripts/loop-kernel.sh:38-54,245-303,924-1002`.
- **Cockpit (optional):** a React/Node read-only projection of a workspace via exactly one CLI command, `cvg snapshot --json`; it cannot create, run, approve, bind, or settle. "Ask Converge" is a separate ACP interpretation path with Claude forced into plan-mode/no-tools. Verified: `apps/cockpit/README.md`, `bin/cvg-snapshot.py:1-17`. It is **excluded from the published zero-dependency package** while proving grounds are incomplete (`README.md:97-99`).

**Net:** Converge is a *spec-driven delivery method plus a credential-free referee CLI* that adds provable verification and cross-family adversarial review around externally operated agents. It delivers *process and verification around* agents more than it delivers *autonomy itself* — the autonomy is the single-task loop; the "fabric" (multi-task fleet) is not yet built.

## 4. Repository and Test Coverage

I ran a representative subset of the CI gauntlet (not all 21 suites) — the load-bearing ones. All green, no live models invoked.

| Suite | Command | Result |
|---|---|---|
| One package, one version | `bash tests/test-version-unity.sh` | **12/12 PASS** (`VERSION_UNITY=PASS`) |
| Loop kernel (Pass 8 brakes) | `bash tests/test-loop-kernel.sh` | **57/57 PASS** (README/deck claim "52" — safe-direction drift; the suite has grown) |
| HMAC sign-off envelope | `bash skills/task-spec/tests/test-hmac-envelope.sh` | **38/38 PASS** |
| JSON envelope + agent-context | `bash tests/test-cvg-json-envelope.sh` | **23/23 PASS** |
| Clean-room install e2e | `bash tests/test-clean-room-install-e2e.sh` | **21/21 PASS** — empty repo → init → sign → bind → RED→GREEN loop → acceptance → receipt hash chain, stub engine |
| Register (Pass 6, offline) | `bash skills/task-specs-to-issues/tests/test-register.sh` | **145/145 PASS** (matches deck's "145") |
| Gate policy | `python3 skills/task-to-runtime-contract/tests/test-gate-policy.py` | **10/10 OK** |
| CI coverage gate | `bash tests/test-ci-covers-every-suite.sh` | **PASS** |

**Total:** 8 suite invocations, ~307 individual checks, 0 failures, 0 blocked. CI matrix runs on `ubuntu-latest` + `macos-latest` (bash 3.2 portability floor), no secrets, no live services (`.github/workflows/ci.yml:1-50`). The clean-room e2e is the strongest single piece of inspectable end-to-end evidence: it proves the full chain reproducibly with a stub engine.

**Coverage caveats honestly self-reported** (`CHANGELOG.md:602-616`): two shipped PDFs say "eleven skills" (stale, unreproducible from this tree); `task-spec/SKILL.md` is 569 lines vs its own 500-line rule; lessons exist for passes 0–3 only; tier-2 judge timeout is fixed at 300s; `--resume` under worktree isolation cuts a fresh worktree and restarts at attempt 1 (checkpoint survives, working tree does not); `generate-task-spec.sh` still anchors `tasks/` at the git root (the "seventh sighting" of the D1 run-context defect class).

## 5. Claim-to-Evidence Audit

For each major claim: implemented? enforced at runtime? outside worker authority? tested? inspectable evidence shipped? documented honestly? reachable end to end?

**C1 — "The eval decides done" (completion is a state-machine invariant).**
Implemented & enforced: the loop only breaks to settlement after `verify` returns 0 (`loop-kernel.sh:924-933`); the Exit Check eval is HMAC-sealed and outside the contract's `fs.write` scope, so the worker cannot edit it. Outside worker authority: yes — the seal is verified by the referee, not the agent. Tested: `test-loop-kernel.sh` (57), `test-hmac-envelope.sh` (38), clean-room e2e (RED→GREEN). Inspectable: yes. Honest: yes. Reachable: yes (clean-room e2e). **VERIFIED.** The maximal-stub claim ("all nine specs faked → all nine RED") is a design argument, not a shipped test — it is sound by construction (a stub fails the sealed eval) but not separately proven.

**C2 — "The referee is never a player" (cvg holds no API keys, calls no models).**
Implemented: `cvg` only routes/wraps; engine adapters shell out to vendor CLIs that self-authenticate (`engines/{claude,codex,kimi}.sh`). Enforced: by construction — there is no credential-handling code path in the core. Tested: the hermetic suites use stub engines and never touch a real key. **VERIFIED.** This is the cleanest of the trust claims and genuinely unusual in the market.

**C3 — "Cross-family verification" (tier-2 holdout judge).**
Implemented: `verify-work.py` picks a different-family judge (`FAMILY` map), builds a refutation prompt from diff + intent + `## Holdout` block the worker never saw, fails closed (`UPHELD|REFUTED|UNAVAILABLE|ERROR`). Enforced at runtime: `loop-kernel.sh:977-1002` — `REFUTED` and any non-verdict land `BLOCKED`. Outside worker authority: yes — holdout is excluded from the 7B worker brief. Tested hermetically: stub verifiers exercise UPHELD/REFUTED/UNAVAILABLE/broken (`test-loop-kernel.sh:126-130`). **Live proof is a documented claim, not a shipped artifact:** the README/deck state the mechanism is "proven live in both directions" (one UPHELD via merged PR #9, one REFUTED that caught a fail-open `OSError`-swallowing fence). The `CHANGELOG.md:584-600` records these on the `uc-analytics` proving ground "since removed from the tree — the runs live in git history and the merged PRs." No `cvg/receipts/` ships in the current tree (`git ls-files | grep -i receipt` → none; `cvg/` workspace absent). So the mechanism is hermetically proven; the *live* cross-family verdict is reproducible only via git history/PRs, not from the current commit. **PARTIALLY VERIFIED (mechanism yes; live evidence in history only).**

**C4 — "A loop with brakes" (three-axis budgets, stagnation, eight terminal states, exhaustion never success).**
Implemented & enforced: `loop-kernel.sh:241-303` (budgets, `tighter()` so flags can only *tighten* spec ceilings), `:938-953` (stagnation), `:38-54` (terminal states; only first three exit 0). Tested: `test-loop-kernel.sh` 57 checks including brakes, stagnation, exhaustion, resume, cancel, honest no-op. **VERIFIED.** The "checked before the call, where the money has not yet been spent" claim is real (`:888-893` checkpoint-before-attempt, pre-call budget gate).

**C5 — "Harness-agnostic by construction" (one adapter file per engine; skills into every harness; same gate scores the work).**
Implemented: `engines/{claude,codex,kimi}.sh` are ~1–2 KB each, env-overridable (`CVG_CLAUDE_CMD` etc.); `install.sh` writes to `.claude/`, `.agents/`, `.grok/` skill dirs; the sealed spec + gate are identical across engines. Tested: clean-room e2e installs pinned copies for all harnesses. **VERIFIED.** Codex is the only engine with OS-level `fs.write` *prevention* (`--sandbox workspace-write`); Claude uses `--permission-mode acceptEdits` (no path prevent) and Kimi has none — the capability envelope honestly records this as `detect` vs `prevent` (`_runtime_contract.py:501-530`).

**C6 — Trust boundaries: signing, holdout, isolation, budget, independent review.**
- **Signing:** HMAC-SHA256 over an envelope that seals eval bodies *and* authorization fields (v2 closes the v1 hole where write-scope/budget/engine could change under a valid seal). Key is repo-private, Git-excluded, mode 0600; `--stamp-by` is injection-safe. Verified: `test-hmac-envelope.sh` scenarios 1–11. **VERIFIED.**
- **Capability envelope / authority closure:** authority is epoch-scoped (`<task>@<spec-sha12>`), revoked on `settle|block|budget_exhausted|epoch_change`; `fs.write` always required; `detect` is "evidence, never a boundary"; `unenforced` fails closed (`_runtime_contract.py:401-530`). **VERIFIED by design and tests;** but `fs.write` is *detect-only* (postflight) for Claude/Kimi/generic — a rogue/injected agent can write out-of-scope and is caught at settlement, not blocked. Only Codex prevents at the OS level. Honestly disclosed, but it is the soft edge of the trust pitch.
- **Repo write fence (`.cvg/gate.yaml`):** outside the signed payload (re-signing cannot buy access), protected paths beat contract, `max_changed_files: 12`, settlement loads it from the captured Git base and inspects every Git-visible changed path; staging is from the contract, never `git add -A` (`open-issue-pr.sh:168-220,378-382`). CI asserts both directions (`ci.yml:276-284`). **VERIFIED.** The fence itself notes ignored/secrets still rely on the runtime sandbox/credential boundary (`gate.yaml:9-13`) — an honest limitation, not a defect.

**C7 — "This repository's own backlog was driven through the loop — nine tasks settled through merged PRs."**
This is a **provenance claim in git history**, not an inspectable artifact in the current tree: there is no `cvg/tasks/done/` or `cvg/receipts/` here (`git ls-files` for `T-*` returns only fixtures/examples under `skills/task-spec/`). The 9/9 and PR #9 are real only if you walk git history / merged PRs. **DOCUMENTED, NOT INSPECTABLE HERE.**

**C8 — Installation & portability ("bash 3.2+, zero runtime dependencies").**
Scoped to the *core* package (`bin/cvg` + skills + `install.sh`): true — bash + stdlib Python, shellcheck-clean, idempotent install, `INSTALL=OK`. Caveats honestly documented: `cvg lint` needs bash 4+ and cannot run on stock macOS (`CHANGELOG.md:43-49`); Cockpit is a separate npm app (Node/Playwright) and is *excluded* from the published zero-dependency package. **VERIFIED with documented exceptions.**

## 6. Market Landscape

Research date 2026-08-05. Eight alternatives across the relevant areas; the spec-driven + agent-orchestration space is crowded and moving fast.

| Alternative | Primary user / use case | Unit of autonomy | Spec / planning model | Verification & acceptance | Agent / model portability | Execution & permission boundary | Observability / audit | Setup / adoption cost | Maturity / adoption signal | Converge advantage | Converge disadvantage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **GitHub Spec Kit** (`github/spec-kit`, open-source) [1][3] | Teams wanting "define before you code" with any agent | One feature/spec → PR | Spec → Plan → Tasks → Implement (markdown artifacts) | Checklists, governance extensions (CI Guard, Architecture Guard), tests | 35+ agent integrations (Copilot, Codex, Claude, Gemini, Zed…) | Agent-native; guardrails via extensions | Artifacts + slash commands | `specify init`; low | Official GitHub project, updated Jul 2026; 138 extensions | Sealed-eval invariant + cross-family holdout judge; referee-holds-no-creds | Far less ecosystem; no baked-in HMAC seal or different-family refutation |
| **OpenAI Codex + Symphony** (Codex CLI; Symphony open-source orchestration spec) [5][6][7] | Engineers running autonomous multi-agent delivery from a board | One task/workspace; board→fleet | Board-driven (Linear); AGENTS.md; traces | Cloud PR review, "golden principles" auto-merge, traces | Codex-centric; Agents SDK hand-offs | Cloud container sandbox; seccomp | Traces dashboard; run attempts; retry entries | Codex CLI + Symphony config; medium | OpenAI-published; agent-first repo case studies | Harness-agnostic (Codex/Claude/Kimi); eval-sealed done; fail-closed tier-2 | No fleet Manager yet; no built-in spec→plan→tasks design half |
| **Devin / Cognition** (commercial) [8][9][10] | Orgs delegating migrations, refactors, triage | A Devin instance / cloud agent | Task spec from prompt; multi-repo | Devin Review; human PR review | SWE-1.6/1.7 + frontier models; Windsurf | Cloud agents; collaborative UX | Analytics, audit, integrations | Free → Pro $20 → Max $200 → Teams → Enterprise | **$492M run-rate revenue; enterprise usage 10× in 2026; Citi, Mercedes-Benz, Goldman, U.S. Army; 89% of Cognition's own commits** | Open-source, self-hosted, no vendor lock-in; sealed evals | No hosted runtime, no adoption, no model of its own; competes on process not execution |
| **OpenHands** (open-source, MIT; ex-OpenDevin) [11][12] | Self-hosters running/monitoring coding agents | One agent session / automation | Issues → task decomposition | SWE-Bench evals; sandboxed exec | ACP-compatible (Claude Code, Codex, Gemini) | Docker/VM/on-prem backends | Agent Canvas control center | Self-host; medium | **~80k+ stars; 188+ contributors; ICLR paper** | Method + sealed-spec discipline; cross-family holdout | OpenHands is a *platform* with a GUI/SDK; Converge is a method+CLI with no runtime |
| **Aider** (open-source, Apache-2.0) [13] | Solo devs wanting multi-model pair programming | One edit/commit | Free-form prompt; repo map | Lint + test on change; git commits | Many LLMs (OpenAI, Anthropic, DeepSeek, local) | Local; git-integrated | Git history; diffs | `pip install aider`; very low | Mature, widely used solo tool | Spec-driven 9-pass discipline; provable done; cross-family | Aider is lower-ceremony and already multi-model; Converge adds process, not a better pair-programmer |
| **Inspect (UK AISI / Meridian)** (open-source eval framework) [14][15] | Eval engineers scoring frontier models/agents | One sample/task | Dataset + solver + scorer | Model grading, custom scorers, sandboxed tools | Agent bridges (Claude Code, Codex CLI, Gemini CLI) | Sandboxed Docker; tool controls | Logs, scorers, metrics | Python framework; medium | UK AISI-maintained; 20+ ready evals | Converge ships a *delivery method*, not just an eval harness; sealed evals travel with the work | Inspect is purpose-built for evaluation breadth; Converge's evals are task-local bash, not a general eval platform |
| **Claude Code** (harness; subagents, hooks, dynamic workflows) [16][17] | Devs steering agents in-repo | One conversation / workflow | Plan mode; AGENTS.md; dynamic workflow scripts | Hooks (PreToolUse/PostToolUse); plan-mode read-only | Claude-native (subagents); ACP for others | Permission modes; sandbox; hooks | Traces; workflow scripts | `claude`; low | Anthropic flagship; dynamic workflows v2.1.154+ | Harness-agnostic + sealed-spec discipline that any harness can drive | Converge leans *on* Claude Code; the harness keeps adding orchestration Converge would have to interop with |
| **LangGraph / CrewAI** (orchestration frameworks) [18] | Builders composing stateful multi-agent systems | A graph node / crew member | Explicit state machine / role-based crews | Human-in-the-loop; checkpoints; guards | Model-agnostic | Framework-managed | LangSmith tracing; durable exec | Python; medium | Mature, widely adopted for agent pipelines | Converge is a *vertical* software-delivery method with proven gates, not a general graph runtime | No fleet/graph orchestration of its own yet (the Manager is unbuilt) |

**Market shape:** the "spec-driven development + agent orchestration" niche is converging fast. GitHub Spec Kit owns the spec→plan→tasks→implement mindshare with 35+ integrations and governance guards; OpenAI's Symphony owns board-driven Codex orchestration with retry/stall handling; Devin owns commercial autonomous SWE at scale ($492M run-rate). Converge's *distinct* slice — sealed-eval-done + cross-family holdout judge + credential-free referee — is not yet claimed by any of them, but it is a thin slice executed by a single author against well-funded incumbents.

## 7. Competitive Position

- **What is genuinely differentiated:** (1) "done" as an HMAC-sealed, fail-closed state invariant; (2) a credential-free referee that never calls a model; (3) cross-family tier-2 holdout verification that fails closed; (4) harness-agnostic one-adapter-per-engine with an identical gate. No inspected competitor combines these four. This is a real, defensible niche.
- **What is table stakes:** spec→plan→tasks decomposition (Spec Kit), board-driven loop orchestration with retry/stall (Symphony), sandboxed execution (Codex/OpenHands), multi-model support (Aider/Inspect), checklists/governance guards (Spec Kit CI/Architecture Guard), git-integrated commits (Aider).
- **Where it is behind:** fleet dispatch (Symphony, Devin, Claude dynamic workflows all schedule multiple agents; Converge's Manager is unbuilt), hosted runtime (Devin/OpenHands run agents; Converge never does), server-side re-verification (none — the CI eval-gate is a roadmap item), adoption scale (Devin $492M run-rate; OpenHands ~80k stars; Converge has no verifiable adoption signal), and ecosystem breadth (Spec Kit's 138 extensions vs Converge's 12 skills).
- **"Autonomous Fabric" assessment:** the term is **clear and ambitious but not yet defensible as an owned category.** "Fabric" implies a woven substrate that dispatches and verifies *across* the fleet; today Converge is a single-task loop plus a method. The closest owned concepts in the market are "spec-driven development" (Spec Kit), "orchestration" (Symphony), and "autonomous software engineer" (Devin). Converge can *credibly claim* "sealed-spec delivery with cross-family verification"; it cannot yet credibly claim "fabric" until fleet dispatch + server-side re-verification exist and at least one proving ground completes end to end in the current tree.

## 8. Scorecard

| Dimension | Weight | Score /10 | Weighted |
|---|---:|---:|---:|
| Problem and product thesis | 10% | 7.0 | 7.0 |
| Differentiation and market position | 15% | 6.0 | 9.0 |
| Method and architecture coherence | 15% | 7.5 | 11.25 |
| Trust, verification, and security model | 20% | 7.5 | 15.0 |
| Implementation quality and reliability | 15% | 7.5 | 11.25 |
| Autonomous end-to-end completeness | 10% | 5.5 | 5.5 |
| Developer experience and adoption readiness | 10% | 5.5 | 5.5 |
| Evidence, credibility, and project maturity | 5% | 5.5 | 2.75 |
| **Overall / 100** | 100% | — | **67.25 → 67.3** |

Formula: `Σ(score × weight / 10)` with weight in percent points; max = 100. Arithmetic: 7.0+9.0+11.25+15.0+11.25+5.5+5.5+2.75 = **67.25** → **67.3/100**.

- **Vision potential:** High
- **Current readiness:** Alpha (strong, tested core; feature-incomplete for the "fabric" claim; no org adoption)
- **Market position:** Distinct (not Category-leading; not Undifferentiated)
- **Evidence confidence:** Medium (hermetic evidence strong; live cross-family proof in git history only; proving grounds open; no third-party signal)

## 9. Prioritized Findings

### F-glm-01 — "Eval decides done" is a real, enforced, fail-closed state invariant
- Type: strength
- Surface: runtime, skills, security
- Severity: positive
- Confidence: high
- Evidence: `skills/task-loop/scripts/loop-kernel.sh:924-933` (settle only after `verify` rc 0); `safe-to-delegate.sh` HMAC seal; `test-hmac-envelope.sh` 38/38; `test-loop-kernel.sh` 57/57; clean-room e2e 21/21 (RED→GREEN)
- Claim: Completion is enforced by a sealed Exit Check the worker cannot edit, not by the agent's word; the loop, settlement, and tests all honor it.
- Why it matters: This is the load-bearing trust claim and it is genuinely implemented and tested, not aspirational.
- Falsifier: A worker editing a sealed eval and still settling, or a `set -e`-style loop that dies on RED — both absent.
- Recommended move: Amplify in positioning; keep the maximal-stub claim as a shipped reproducible test (currently a design argument).
- Acceptance evidence: A CI test that fakes all N specs and asserts all land RED.

### F-glm-02 — Cross-family tier-2 holdout is implemented and fail-closed, but the *live* proof lives only in git history
- Type: claim gap
- Surface: runtime, docs, evidence
- Severity: high
- Confidence: high
- Evidence: `verify-work.py` (holdout + `FAMILY` map); `loop-kernel.sh:977-1002` (REFUTED/no-verdict → BLOCKED); `CHANGELOG.md:584-600` ("since removed from the tree — the runs live in git history and the merged PRs"); `git ls-files` shows no `cvg/receipts/`, no `cvg/tasks/done/` in current tree
- Claim: The strongest trust narrative (live UPHELD + REFUTED, cross-family, no shared vendor) is reproducible only from git history / merged PRs, not from the inspected commit.
- Why it matters: The single most differentiated claim has no in-tree receipt; a skeptical adopter cannot reproduce it without walking history.
- Falsifier: A dated, runnable proving-ground workspace in the current tree that regenerates the REFUTED/UPHELD receipts.
- Recommended move: Ship a reproducible proving-ground harness (or a pinned, dated workspace snapshot) so the cross-family verdicts are inspectable now.
- Acceptance evidence: `cvg verify --judge <other-family>` on the shipped workspace emits `CHECK_VERIFY=UPHELD` and `=REFUTED` reproducibly.

### F-glm-03 — `fs.write` is detect-only (postflight) for Claude/Kimi/generic; only Codex prevents at the OS level
- Type: design risk
- Surface: security, runtime
- Severity: high
- Confidence: high
- Evidence: `_runtime_contract.py:501-530` (claude/kimi/generic `fs.write` = `detect`; codex = `prevent` via `--sandbox workspace-write`); `engines/claude.sh:39-42` (`--permission-mode acceptEdits`, no path prevent); `engines/codex.sh:42`
- Claim: For 3 of 4 runtimes, an out-of-scope write is caught at settlement, not blocked before it happens; the capability envelope honestly says "detect is evidence, never a boundary."
- Why it matters: An injected/rogue agent can write out-of-scope files and they are only reverted/flagged post-run; the hard-sandbox story is Codex-only. This is the soft edge of the "Autonomous Fabric" trust pitch.
- Falsifier: A Claude/Kimi run that attempts an out-of-scope write and is blocked pre-write by an enforced guard.
- Recommended move: Wire the emitted PreToolUse fragment into the dispatchers so `fs.write` is `prevent`ed for Claude (at minimum), and surface "detect-only" prominently at bind time.
- Acceptance evidence: `cvg bind` reports `fs.write: prevent` for Claude and a test proves an out-of-scope Edit/Write is blocked mid-attempt.

### F-glm-04 — The Manager (fleet dispatch) and CI eval-gate (server-side re-verification) are unbuilt — the explicit top roadmap items that cap "fabric" claims
- Type: claim gap / opportunity
- Surface: runtime, method, market
- Severity: blocker (for the "Autonomous Fabric" positioning)
- Confidence: high
- Evidence: `README.md:396-398` ("What's deliberately not in 0.1.0: the Manager … and the CI eval-gate … Both are next on the roadmap"); `bin/README.md:173-183` ("What the surface still owes is dispatch across the fleet — the Manager"); `loop-kernel.sh:151` (`--issue` required; single-task)
- Claim: Converge completes one task to a terminal state well; it does not dispatch, schedule, or re-verify across a fleet.
- Why it matters: "Fabric" implies fleet; without the Manager + CI eval-gate, Converge is a single-task loop + method, and competitors (Symphony, Devin, Claude dynamic workflows) already schedule multiple agents.
- Falsifier: A `cvg` command that picks the next unblocked spec, runs N loops concurrently, and a CI step that re-verifies a settled diff server-side.
- Recommended move: Build the Manager + a server-side CI eval-gate as the #1 priority (see Top Move 1).
- Acceptance evidence: A multi-task run settles ≥3 ready specs concurrently with per-task receipts; CI re-runs the sealed eval on the PR and gates merge.

### F-glm-05 — Proving grounds are open / not run; Cockpit excluded from the published package while live cases are incomplete
- Type: claim gap
- Surface: Cockpit, distribution, evidence
- Severity: medium
- Confidence: high
- Evidence: `apps/cockpit/PROVING-GROUNDS.md` (all four cases "Open"/"Not run"; "release-ready only when all four cases have exercised the same WorkspaceSnapshot 3.0 contract"); `README.md:97-99`
- Claim: The product version does not imply the release gates passed; no proving-ground case is currently complete in-tree.
- Why it matters: The Cockpit and the end-to-end product claim rest on proving grounds that are explicitly unfinished; an adopter evaluating the UI gets replay fixtures, not live-workspace evidence.
- Falsifier: A dated WorkspaceSnapshot 3.0 rerun + owner review recorded for `uc-01` (and the other three cases run).
- Recommended move: Complete `uc-01` against the v3 snapshot and record a dated rerun; ship it as the reference workspace.
- Acceptance evidence: `PROVING-GROUNDS.md` shows "Closed" for `uc-01` with a dated snapshot and owner sign-off.

### F-glm-06 — Harness-agnostic by construction is real and verified
- Type: strength
- Surface: skills, distribution, CLI
- Severity: positive
- Confidence: high
- Evidence: `engines/{claude,codex,kimi}.sh` (1–2 KB each, env-overridable); `install.sh` writes `.claude/`, `.agents/`, `.grok/`; `test-cvg-json-envelope.sh` 23/23 (`agent-context` non-mutating); clean-room e2e installs pinned copies for all harnesses
- Claim: One install covers four harnesses; the sealed spec + gate are identical across engines; the CLI spells no vendor.
- Why it matters: This is the correct portability story and a genuine differentiator vs vendor-locked orchestration.
- Falsifier: An engine change that silently alters the gate verdict — absent by design.
- Recommended move: Keep the adapter contract minimal; add a `grok` adapter to match the install claim (README cites Grok Build but no `grok.sh` ships).
- Acceptance evidence: `engines/grok.sh` + a doctor row for Grok.

### F-glm-07 — The recurring D1 "anchored to git root instead of workspace" defect class (7 sightings) is a load-bearing sharp edge
- Type: design risk
- Surface: CLI, runtime
- Severity: medium
- Confidence: high
- Evidence: `bin/README.md:136-145` (the single defect re-learned four times: register, ready, loop); `CHANGELOG.md:613-614` (`generate-task-spec.sh` still anchors `tasks/` at the git root — "seventh sighting")
- Claim: Workspace-vs-git-root anchoring has repeatedly broken register, ready, and the loop in real layouts (nested workspaces, `<repo>/projects/demo/cvg/`).
- Why it matters: This is the class of bug that bites on the first non-trivial repo layout and erodes trust in "it just works."
- Falsifier: A single canonical resolver used by every task command, proven by a test that builds a workspace below the repo root (already pinned) — extended to `generate-task-spec.sh`.
- Recommended move: Funnel `generate-task-spec.sh` through the same project-root backlog resolver as the rest of the task family.
- Acceptance evidence: `cvg tasks new` in a nested workspace creates the spec under `cvg/tasks/`, not `<git-root>/tasks/`.

### F-glm-08 — Test rigor is strong and claims are largely accurate, with minor count drift
- Type: strength
- Surface: tests, docs
- Severity: positive
- Confidence: high
- Evidence: 8 representative suites green (~307 checks); register 145 matches deck; `test-ci-covers-every-suite.sh` keeps the workflow honest; loop-kernel reports 57 vs deck's "52" (safe-direction drift)
- Claim: The hermetic evidence is genuinely load-bearing and the self-reported counts are largely faithful.
- Why it matters: A "the eval decides done" project that runs its own evals in public and asserts suite-wiring is practicing what it preaches.
- Falsifier: A suite in CI that is never invoked — the coverage gate exists precisely to prevent this.
- Recommended move: Reconcile the "52" loop-kernel count in the deck/README to the actual 57 (or the suite's current number) so claims and code don't drift.
- Acceptance evidence: README/deck loop-kernel number equals the suite's emitted count.

### F-glm-09 — "Autonomous Fabric" is a clear, ambitious, but unproven category hypothesis
- Type: market gap / positioning
- Surface: market, docs
- Severity: medium
- Confidence: medium
- Evidence: No inspected competitor uses "fabric"; nearest owned concepts are Spec Kit "spec-driven", Symphony "orchestration", Devin "autonomous SWE"; the fleet-dispatch layer that would justify "fabric" is unbuilt (F-glm-04)
- Claim: The term is clear and ownable in principle but not yet defensible — it asserts a category the implementation does not yet populate.
- Why it matters: A category claim ahead of the artifact invites skepticism and hands critics the gap.
- Falsifier: A competitor co-opting "fabric" first, or Converge shipping fleet dispatch + a completed proving ground under that banner.
- Recommended move: Anchor positioning on the defensible claim ("sealed-spec delivery with cross-family verification") and earn "fabric" after the Manager ships.
- Acceptance evidence: Messaging leads with the verified mechanics; "fabric" appears only where fleet dispatch is demonstrated.

### F-glm-10 — Single-author v0.1.0 with no third-party adoption signal; organizational-adoption risk
- Type: market gap
- Surface: market, distribution
- Severity: medium
- Confidence: high
- Evidence: `package.json`/`plugin.json` single author; no in-repo adoption data (I do not fabricate stars/customers); proving grounds open; rivals have 80k+ stars (OpenHands) or $492M run-rate (Devin)
- Claim: Project maturity is early-single-author; bus factor and adoption momentum are real risks for a category-defining ambition.
- Why it matters: "Definitive Autonomous Fabric" is a network-effects game; first-party rigor alone does not win it.
- Falsifier: Public third-party pilots, contributors beyond the author, or a documented org adoption.
- Recommended move: Recruit 1–2 external pilot teams and a second maintainer; publish a dated case study once a proving ground closes.
- Acceptance evidence: A merged external PR or a published pilot write-up with before/after workspace hashes.

### F-glm-11 — `--resume` under worktree isolation restarts at attempt 1 in a fresh tree; tier-2 judge timeout fixed at 300s
- Type: claim gap
- Surface: runtime, recovery
- Severity: medium
- Confidence: high
- Evidence: `CHANGELOG.md:608-612` (self-reported: "--resume under worktree isolation cuts a FRESH worktree and restarts at attempt 1 — the checkpoint survives, the working tree does not"; judge timeout fixed at 300s default)
- Claim: Two operational recovery/verification controls are limited: resume loses the working tree, and a slow judge can BLOCK work it never graded.
- Why it matters: Both bite exactly when an operator needs the system most (long runs, slow judges).
- Falsifier: `--resume` reusing the prior worktree's uncommitted state; a configurable per-task judge timeout that propagates to `verify-work.py`.
- Recommended move: Make worktree `--resume` preserve the prior attempt's tree (or branch), and let the spec/contract set the judge timeout that the kernel forwards.
- Acceptance evidence: A `--resume` test that resumes with the prior tree intact; a spec `verify_timeout` honored by the kernel.

### F-glm-12 — The repo write fence is outside the signed payload and enforced at settlement, but secrets/ignored-state rely on the runtime boundary
- Type: design risk (honestly disclosed)
- Surface: security
- Severity: low
- Confidence: high
- Evidence: `.cvg/gate.yaml:9-13` ("Ignored local state and secrets still require the runtime sandbox/credential boundary; this file does not claim to observe bytes that Git intentionally hides"); `check-gate.py`; `open-issue-pr.sh:168-220` (settlement guard over Git-visible paths)
- Claim: The fence is strong for Git-visible paths and correctly out of the worker's signing authority, but it is not a secrets/ignored-file boundary by design.
- Why it matters: Adopters may over-trust the fence for secret-shaped paths; the docs are honest but the boundary must be stated at adoption time.
- Falsifier: A settlement that catches an ignored secret file — it will not, by design.
- Recommended move: Add a `cvg doctor` check that warns when a workspace has untracked secret-shaped files in scope, distinct from the path fence.
- Acceptance evidence: `cvg doctor` flags an untracked `.env` in the workspace even when the fence would not see it.

### F-glm-13 — Documentation density / ceremony is an adoption barrier; `task-spec/SKILL.md` exceeds its own 500-line rule
- Type: opportunity
- Surface: docs, DX
- Severity: low
- Confidence: medium
- Evidence: 24.9 KB README, 9 passes, dense token glossary; `CHANGELOG.md:606` (SKILL.md 569 lines vs 500-line rule); `cvg lane`/`cvg next` mitigate but the descent is still steep
- Claim: First-success requires grasping the whole descent; the surface is engineer-dense and the on-ramp is heavy even on FAST.
- Why it matters: Adoption friction for the "skeptical prospective adopter" persona the review targets.
- Falsifier: A new user reaching `TASK_LOOP=SETTLED` on FAST in <30 min from install with only the quickstart.
- Recommended move: Add a guided "FAST in 5 commands" path with a runnable example spec, and split the 569-line SKILL.md.
- Acceptance evidence: A telemetry-free quickstart test that an agent follows to a settled FAST task with no external doc.

## 10. The Top Three Moves

### Move 1 — Build the Manager and the CI eval-gate (fleet dispatch + server-side re-verification)
- **Problem it solves:** Converge completes *one* task well but cannot dispatch, schedule, or re-verify *across* a fleet — the exact gap that makes "fabric" aspirational rather than real (F-glm-04).
- **Why it belongs in the top three:** This is the single highest-leverage change. The README and `bin/README` both name it as the top roadmap item. Without it, Converge is a single-task loop + method; with it, it becomes the substrate the name implies. It also closes the largest gap vs Symphony/Devin/Claude dynamic workflows.
- **Users/adopters affected:** Every team adopting Converge for real delivery; the Manager is the surface a "Manager" persona selects from (`cvg ready` already emits the frontier).
- **Implementation scope & surfaces:** A `cvg manager` (or `cvg fleet`) command that consumes `cvg ready`, runs N `loop-kernel.sh` instances concurrently (worktree per task), watches PRs, and respects per-task budgets; a `.github/workflows` re-verification step that re-runs the sealed Exit Check on the PR diff and gates merge. Likely surfaces: new `skills/task-loop/scripts/manager.sh` or a `manager` skill, `bin/cvg` routing, a new CI workflow, and a `cvg verify --ci` mode.
- **Dependencies & sequencing:** Depends on F-glm-07 (canonical workspace resolver) being solid so the Manager doesn't re-hit the anchoring bug; can start in parallel with Move 2.
- **Effort:** XL
- **Expected impact:** 9
- **Principal risk:** Concurrency correctness (orphaned worktrees, race on `cvg ready` frontier, PR/branch collisions) and re-verification determinism in CI environments that differ from the bind host.
- **30-day outcome:** A `cvg manager --max-parallel N` that settles ≥3 ready specs in one run with per-task receipts; hermetic suite for the Manager (brakes, stall, frontier races).
- **90-day outcome:** A CI eval-gate that re-verifies a settled PR server-side and blocks merge on a red sealed eval; one real multi-task run merged through the gate.
- **Acceptance tests/evidence:** `tests/test-manager.sh` (concurrent settle, frontier correctness, budget enforcement); a CI step that fails a PR whose sealed eval is red.
- **Estimated score delta:** +0.8 (Autonomous e2e 5.5→7.5; Differentiation 6.0→7.0; Trust 7.5→8.0).

### Move 2 — Ship reproducible proving-ground evidence into the current tree
- **Problem it solves:** The most differentiated trust claim (live cross-family UPHELD/REFUTED) and the product/Cockpit claim rest on evidence that is in git history or an open gate, not in the inspected commit (F-glm-02, F-glm-05).
- **Why it belongs in the top three:** A "fabric" whose proof is narrative cannot be category-defining. Reproducible, in-tree evidence is what converts "documented claim" to "verified implementation behavior" for the strongest claim.
- **Users/adopters affected:** Every skeptical adopter evaluating the cross-family verification and the Cockpit; reviewers and security auditors.
- **Implementation scope & surfaces:** A pinned, dated proving-ground workspace (or a runnable harness that regenerates it) under a versioned path; a `cvg verify --judge <other-family>` reproducible on the shipped workspace producing `UPHELD` and `REFUTED` receipts; complete `uc-01` against WorkspaceSnapshot 3.0 and record a dated rerun in `PROVING-GROUNDS.md`. Surfaces: `apps/cockpit/PROVING-GROUNDS.md`, a new `proving-grounds/` dir or a pinned `cvg-use-cases-e2e` submodule/tag, `tests/` harness.
- **Dependencies & sequencing:** Independent; can run in parallel with Move 1. Requires two engine families available (claude/codex/kimi) — the host has them, but CI is credential-free, so the reproducible artifact (receipts) must be checked in while the *regeneration* is a manual/dated step.
- **Effort:** M
- **Expected impact:** 8
- **Principal risk:** Live model output is non-deterministic; the "reproducible" framing must be "receipts + dated rerun + owner review," not byte-identical replay (which the Cockpit already handles via fixtures).
- **30-day outcome:** `uc-01` closed in `PROVING-GROUNDS.md` with a dated v3 snapshot and owner sign-off; UPHELD + REFUTED receipts checked into the tree.
- **90-day outcome:** A documented, dated cross-family rerun workflow that any adopter with two engines can run to regenerate the two verdicts.
- **Acceptance tests/evidence:** `git ls-files` shows the receipts; `cvg verify` on the shipped workspace emits both verdicts; `PROVING-GROUNDS.md` shows "Closed" for `uc-01`.
- **Estimated score delta:** +0.5 (Evidence/maturity 5.5→7.0; Trust 7.5→8.0; Autonomous e2e +0.2).

### Move 3 — Harden `fs.write` from detect to prevent, and make tier-2 verification default-on-and-bounded
- **Problem it solves:** The trust model's soft edge is that `fs.write` is only *detected* (postflight) for Claude/Kimi/generic — a rogue/injected agent writes out-of-scope and is caught at settlement, not blocked (F-glm-03); and the fail-closed tier-2 judge can BLOCK green work it never graded when the 300s timeout fires (F-glm-11).
- **Why it belongs in the top three:** Trust is the heaviest-weighted dimension (20%) and the core differentiator. A "fabric" that detects out-of-scope writes only after the fact, and that can stall on a slow judge, undermines the very trust story it sells.
- **Users/adopters affected:** Any unattended run on Claude/Kimi/generic; high-blast-radius tasks that depend on tier-2.
- **Implementation scope & surfaces:** Wire the already-emitted PreToolUse fragment into the loop dispatchers so `fs.write` is `prevent`ed for Claude (Edit/Write/NotebookEdit blocked on out-of-scope paths); update `_runtime_contract.py` `RUNTIME_CONTROLS` so claude `fs.write` becomes `prevent` when the dispatcher installs the guard; let the spec/contract set `verify_timeout` and forward it through `loop-kernel.sh` to `verify-work.py --timeout`; add a doctor check for untracked secret-shaped files (F-glm-12).
- **Dependencies & sequencing:** Independent; pairs naturally with Move 1 (the Manager wants prevent-class confinement before scaling concurrency).
- **Effort:** M
- **Expected impact:** 7
- **Principal risk:** A PreToolUse guard that is too strict blocks legitimate in-scope writes and regresses success rate; must be exactly the contract's `fs.write` scope.
- **30-day outcome:** `cvg bind` reports `fs.write: prevent` for Claude; a test proves an out-of-scope Edit is blocked mid-attempt; spec `verify_timeout` honored by the kernel.
- **90-day outcome:** Kimi/generic gain a path-prevention story (or are honestly demoted to "supervised-only" at bind); no green task BLOCKED by a judge timeout that the spec could have raised.
- **Acceptance tests/evidence:** `tests/test-runtime-contract-prevent.sh` (out-of-scope write blocked pre-write for Claude); a `verify_timeout` propagation test; `cvg doctor` flags an untracked `.env`.
- **Estimated score delta:** +0.4 (Trust 7.5→8.5; Implementation 7.5→8.0).

**Coherence:** Move 1 builds the fleet (autonomy), Move 2 proves the trust claim is reproducible (evidence), Move 3 hardens the trust boundary from detect to prevent (security). Together they move Converge from "credible single-task method with strong hermetic tests" to "credible Autonomous Fabric."

## 11. Suggested 30/60/90-Day Sequence

**Days 0–30 — Evidence + hardening (parallel tracks, no fleet yet).**
- Close `uc-01` against WorkspaceSnapshot 3.0; check in UPHELD + REFUTED receipts; record dated owner review (Move 2).
- Wire Claude PreToolUse `fs.write` prevention; make `verify_timeout` spec-set; add the `doctor` secret-shape check (Move 3).
- Funnel `generate-task-spec.sh` through the canonical workspace resolver (F-glm-07) so the Manager doesn't inherit the anchoring bug.
- Reconcile the loop-kernel count in docs to the suite's real number (F-glm-08).

**Days 31–60 — The Manager (single host first).**
- Ship `cvg manager --max-parallel N` over `cvg ready`, worktree per task, per-task budgets, PR watch; hermetic suite for brakes/stall/frontier races (Move 1).
- Add the `grok` adapter to match the install claim (F-glm-06).
- Recruit 1–2 external pilot teams + a second maintainer; start a dated case study (F-glm-10).

**Days 61–90 — Server-side re-verification + positioning.**
- Ship the CI eval-gate that re-runs the sealed Exit Check on the PR and gates merge (Move 1 completion).
- Re-position messaging to lead with "sealed-spec delivery with cross-family verification"; reserve "Autonomous Fabric" for where fleet dispatch is demonstrated (F-glm-09).
- Publish a dated multi-task run merged through the gate as the reference evidence.

## 12. What Should Not Be Built Yet

- **A hosted runtime / model.** The "referee never a player" posture is the cleanest differentiator; hosting a model would dissolve it and pit a single author against Devin/OpenHands. Stay the credential-free referee.
- **A general-purpose eval platform.** Inspect already owns that; Converge's evals are task-local bash that travel with the work. Broadening them dilutes the delivery focus.
- **More passes / ceremony.** The descent is already steep (F-glm-13). The leverage is fewer, sharper gates and the fleet layer, not a 10th or 11th pass.
- **A proprietary Cockpit-as-product push.** Cockpit is a read-only projection; selling it as a product before proving grounds close (F-glm-05) would repeat the "product version ≠ release gates passed" gap.
- **Lock-in adapters / a Converge model.** Harness-agnosticism (F-glm-06) is the moat; any vendor lock-in erodes it.

## 13. Open Questions and Falsifiers

- **Q1.** Does a real, multi-task, cross-family run settle ≥3 specs concurrently through a CI eval-gate today? *No — the Manager and CI eval-gate are unbuilt (F-glm-04).* Falsifier: such a run, merged.
- **Q2.** Is the cross-family REFUTED verdict reproducible from the current commit? *No — only from git history / merged PRs (F-glm-02).* Falsifier: in-tree receipts + a dated rerun.
- **Q3.** Can an out-of-scope write by Claude/Kimi/generic be blocked *before* it lands? *No — only detected postflight (F-glm-03).* Falsifier: a pre-write block.
- **Q4.** Is "Autonomous Fabric" an owned category? *Not yet — no competitor uses it and the fleet layer is unbuilt (F-glm-09).* Falsifier: a competitor co-opts it, or Converge ships fleet dispatch under that banner with a closed proving ground.
- **Q5.** Is there third-party adoption? *Not verifiable in-repo; I do not fabricate signals (F-glm-10).* Falsifier: a public pilot or external contributor.
- **Q6.** Does `--resume` preserve uncommitted work under worktree isolation? *No — it cuts a fresh worktree and restarts at attempt 1 (F-glm-11).* Falsifier: a resume that reuses the prior tree.

## 14. Sources

All retrieved 2026-08-05.

1. GitHub Spec Kit — repository: https://github.com/GitHub/spec-kit
2. Spec Kit Agents: Context-Grounded Agentic Workflows (arXiv 2026): https://arxiv.org/abs/2604.05278
3. Spec Kit documentation: https://github.github.io/spec-kit/
4. Spec-driven development with AI (GitHub blog): https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
5. OpenAI Codex with the Agents SDK: https://developers.openai.com/codex/guides/agents-sdk
6. OpenAI Symphony — open-source Codex orchestration spec: https://openai.com/index/open-source-codex-orchestration-symphony/
7. OpenAI — Harness engineering: leveraging Codex in an agent-first world: https://openai.com/index/harness-engineering/
8. Devin — The AI Software Engineer: https://devin.ai/
9. Cognition — More Devins in More Places (Series D, $492M run-rate, enterprise 10×): https://cognition.ai/blog/series-d
10. Devin pricing (Free/Pro $20/Max $200/Teams/Enterprise): https://devin.ai/pricing/
11. OpenHands — open-source platform (GitHub): https://github.com/OpenHands/OpenHands
12. OpenHands: An Open Platform for AI Software Developers as Generalist Agents (arXiv): https://arxiv.org/html/2407.16741
13. Aider — open-source AI pair programming: https://aider.chat/ and https://github.com/Aider-AI/aider
14. Inspect (UK AISI / Meridian) — framework home: https://inspect.aisi.org.uk/
15. Inspect — Using Agents (agent bridges: Claude Code, Codex CLI, Gemini CLI): https://inspect.aisi.org.uk/agents.html
16. Claude Code — subagents: https://code.claude.com/docs/en/subagents
17. Claude Code — dynamic workflows orchestration: https://code.claude.com/docs/en/workflows
18. LangGraph overview (LangChain): https://docs.langchain.com/oss/python/langgraph/overview and CrewAI: https://github.com/crewaiInc/crewai

(Converge-internal evidence is cited inline as `path:line` throughout Sections 4, 5, and 9.)

## 15. Machine-Readable Summary

```json
{
  "reviewer_id": "glm",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 67.3,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Distinct",
  "evidence_confidence": "Medium",
  "adopt_today": "conditional",
  "top_strength": "Eval-decides-done enforced as a sealed, fail-closed state-machine invariant with cross-family tier-2 holdout verification",
  "top_risk": "Autonomous-completeness gap: the Manager (fleet dispatch) and CI eval-gate are unbuilt, and the strongest live trust evidence lives only in git history",
  "top_3": [
    {
      "rank": 1,
      "name": "Build the Manager and the CI eval-gate",
      "effort": "XL",
      "impact": 9,
      "score_delta": 0.8
    },
    {
      "rank": 2,
      "name": "Ship reproducible proving-ground evidence into the tree",
      "effort": "M",
      "impact": 8,
      "score_delta": 0.5
    },
    {
      "rank": 3,
      "name": "Harden fs.write from detect to prevent and bound tier-2",
      "effort": "M",
      "impact": 7,
      "score_delta": 0.4
    }
  ],
  "critical_finding_ids": ["F-glm-04", "F-glm-02", "F-glm-03"],
  "tests_run": {
    "passed": 8,
    "failed": 0,
    "blocked": 0
  },
  "external_sources": 18
}
```
