# Converge Independent Review — codex-gpt5

## 1. Review Metadata

- Reviewer ID: `codex-gpt5`
- Reviewer/model identifier: Codex, described by the runtime as based on GPT-5; the exact backend model identifier was not exposed.
- Reasoning mode/effort: not exposed by the runtime.
- Review start: `2026-08-05T22:14:28-0300`, America/Maceio (`UTC-03:00`).
- Repository root: `/Users/luanmoreno/GitHub/converge`.
- Git HEAD: `9c966884e37919c0f7e4c3e027b4b237670eb2ad`.
- Latest commit: `9c96688`, 2026-08-04T20:28:35-03:00, Luan Moreno Medeiros Maciel, `feat(e2e): Integrate AI agent reviews from DeepSeek, Grok, and Kimi`.
- Git state: branch `feat/e2e`, not detached.
- Pre-existing worktree state: dirty before review. The only observed non-review change was `M apps/cockpit/package-lock.json`; it remained the only non-review change after testing and is not attributed to this review.
- Repository inspection tools: Git, `rg`, Bash/Zsh, `jq`, Node/npm, Python 3, ShellCheck, and standard Unix tools. `bun`, `pnpm`, and `bats` were not installed.
- Test capability: local shell/Python/Node suites were available. Existing Cockpit dependencies were present, so its check suite ran without installing anything. Live model, tracker, push, PR, or paid-API tests were intentionally not run under the review rules.
- Web research: available and completed with primary documentation, repositories, and research papers. `MARKET_RESEARCH=complete`. Retrieval date for all external sources is 2026-08-05.
- Independence: no other model or agent was asked to help. No file under `review/` was read, listed, searched, or summarized. The only repository write made by this review is this file.

Evidence labels used below: **Verified** means observed in implementation or a local command; **Documented** means asserted by repository prose; **External fact** means supported by a dated URL; **Inference** is the reviewer's conclusion from those facts; **Speculation** is explicitly marked.

## 2. Executive Verdict

**Overall score: 56.8/100.** Converge is a credible, unusually thoughtful alpha workflow runtime, not yet an autonomous software-delivery fabric.

It stands out today in a narrow but valuable way: it makes a provider-neutral Markdown Task-Spec, its executable acceptance checks, its authority fields, and a bounded local repair loop into inspectable Git artifacts. Its strongest defensible advantage is the combination of eval-first task contracts, deterministic state-machine landings, portable engine adapters, and meaningful negative-path tests. Most competing coding agents complete tasks more easily; few make the delivery contract this explicit and repository-native.

Its most dangerous weakness is that its advertised independence is stronger than its actual trust boundary. Holdout criteria live in the same Task-Spec the worker is told to read; cross-family review can degrade to same-family or unavailable; the verifier process is not launched with an explicit read-only boundary; host attestation is not consumed by bind or loop; and the signing key is intentionally visible from the worker worktree. These choices can be reasonable for cooperative automation, but they do not support a security-grade claim that the worker cannot influence or anticipate the grader.

I would adopt Converge **conditionally** for a pilot in a team already using multiple local coding agents, where a senior engineer owns the Task-Specs and every PR still passes ordinary protected CI and human acceptance. I would not use it today as an unattended merge authority, a hostile-worker security boundary, or a fleet control plane.

Readiness: **Alpha**. Vision potential: **High**. Market position: **Interesting**. Evidence confidence: **High**.

## 3. What Converge Actually Is

Converge is currently a combination of five things:

1. A **methodology**: a nine-pass descent from brief through requirements, architecture, decomposition, adversarial plan review, Task-Specs, issue projection, runtime binding, and execution.
2. A **portable skill distribution**: twelve Markdown-and-script skills installed into Claude, Codex/Kimi, and Grok discovery directories (`install.sh:123-157`).
3. A **referee CLI and workflow framework**: the 2,600-line Bash `cvg` front door dispatches validators and gates, emits stable tokens/JSON, and deliberately avoids holding model credentials.
4. A **single-task autonomous repair runtime**: Pass 8 creates or uses an isolated worktree, launches a fresh provider CLI process, reruns the Task-Spec eval, applies iteration/wall-clock/stagnation brakes, optionally calls Tier-2, checks the path policy, commits, and may push/open a PR (`skills/task-loop/scripts/loop-kernel.sh:780-1024`; `skills/task-loop/scripts/open-issue-pr.sh:168-531`).
5. A **read-only Cockpit prototype**: it projects `cvg snapshot --json`, serves bounded artifact previews, and offers a separately isolated interpretation-only ACP path. It is not an operational control plane and explicitly cannot create, approve, run, transition, or settle work (`apps/cockpit/README.md:3-13`).

It is **not yet** a fleet scheduler, merge manager, CI acceptance service, durable multi-task control plane, secret-holdout service, or complete autonomous delivery system. The repository says the Manager and server-side CI eval gate are absent (`README.md:396-398`; `bin/README.md:173-182`). The loop stops at a local commit or attempted PR; the clean-room test separately invokes acceptance and transition (`tests/test-clean-room-install-e2e.sh:195-221`).

The clearest user is a principal/staff engineer, platform team, or AI-development-tools lead who already operates Claude/Codex/Kimi-style agents and values reproducible procedure more than a frictionless chat experience. A plausible paying adopter is a regulated or audit-sensitive engineering organization wanting a vendor-neutral policy/evidence layer around existing agents. That buyer does not yet receive enough centralized enforcement, identity, fleet operation, or distributed proof to justify enterprise reliance.

The job Converge completes better than most alternatives is: **turn one prepared engineering task into a bounded, provider-portable, eval-gated local execution attempt with explicit terminal state and Git-inspectable artifacts**. It does not yet complete “idea to merged software” better than vendor agent platforms or CI/CD systems.

Autonomy is therefore real but bounded. Pass 8 can operate unattended within one prepared task. The larger product primarily adds method, contracts, and verification around externally authenticated and operated agents; humans or external systems still supply intent, author/approve the grader, select work, accept output, and merge it.

“Autonomous Fabric” is evocative but presently overbroad. “Fabric” implies a continuously operating substrate coordinating multiple workers, durable state, policy enforcement, scheduling, recovery, and delivery across repositories. Converge has a strong protocol/thread and one execution loom; it does not yet have the fleet, server-side authority, or distributed proof that would make the fabric claim literal. A more defensible current position is **agent-neutral delivery contract and verification runtime**.

## 4. Repository and Test Coverage

The review followed the load-bearing paths rather than relying on the README. It examined `README.md`, `CHANGELOG.md`, the CLI surface, installer/package manifests, all major Task-Spec gates, HMAC implementation, runtime binder/checker/attester, loop kernel and engine adapters, Tier-2 verifier, settlement/receipt writer, Pass-4 consensus barrier, CI, current/historical proving-ground evidence, and Cockpit contracts/server/tests.

Representative commands run from the repository root:

| Command | Outcome |
|---|---:|
| `bash skills/task-spec/tests/test-hmac-envelope.sh` | PASS — 38 checks |
| `bash skills/task-to-runtime-contract/tests/run-tests.sh` | PASS — 48 checks |
| `bash tests/test-loop-kernel.sh` | PASS — 57 checks |
| `bash tests/test-clean-room-install-e2e.sh` | PASS — 21 checks |
| `bash skills/sketch-plans-adversarial-review/tests/run-tests.sh` | PASS — 23 checks |
| `bash tests/test-install.sh` | PASS — 17 checks |
| `bash tests/test-cvg-snapshot.sh` | PASS — 13 checks |
| `npm run cockpit:check` | PASS — 40 Node server tests and 62 Vitest tests |

Total reported assertions/checks: **319 passed, 0 failed, 0 blocked** across eight commands. The 57 loop tests exceed the README's stale claim of 52 (`README.md:387-388`). The tests are unusually good at failure semantics: mismatched engines, stale contracts, out-of-scope writes, stagnation, cancellation, unavailable/refuting judges, unsafe artifact reads, and protocol mismatch are exercised.

Important limits:

- CI is intentionally hermetic: no live engine, tracker, credentials, or external writes (`.github/workflows/ci.yml:1-8`, `:217-226`). That makes it fork-safe, but provider-CLI drift and real delivery behavior are not continuously proven.
- The clean-room chain uses a stub engine and calls `tasks accept` and `transition ... done` after the loop (`tests/test-clean-room-install-e2e.sh:195-221`). It proves mechanics, not autonomous merged delivery.
- `npm run cockpit:check` excludes Playwright browser tests; the CI workflow runs those separately (`.github/workflows/ci.yml:320-335`). No dependencies or browsers were installed during this review.
- Historical Git evidence shows a nine-task proving ground and both Tier-2 directions. For example, commit `46601b2` contains a `result: pass` receipt for `T-20260729-obs-rowcounts` and `cvg/STATE.md` records Codex settlement plus Kimi blocked/refuted landings. The evidence was removed from the current tree by design (`CHANGELOG.md:521-531`, `:584-600`), so a source archive or npm consumer cannot reproduce it without full Git history.

## 5. Claim-to-Evidence Audit

| Major claim | Audit verdict | Runtime/outside-worker enforcement | Meaningful test or shipped evidence | Limitation |
|---|---|---|---|---|
| “Intent … comes out … as merged, proven work” (`README.md:32-39`) | **Documented; contradicted as an end-to-end product claim** | Loop can commit/push/request a PR, but does not accept, transition, merge, or schedule | Clean-room mechanics pass; historical merged PR claims exist in Git history | Manager and CI gate are explicitly absent; current loop stops before merge |
| Twelve skills and one cross-harness CLI | **Verified** | Packaging/copying is deterministic, not a security boundary | Install suite: 17/17; clean room: 21/21 | Installation copies 36 skill trees across three directories and needs agent restart |
| Task completion is decided by executable evals | **Largely verified for loop settlement** | Eval runs in the workspace; postflight path gate is outside the model's textual claim | Loop/runtime suites exercise RED→GREEN and path failures | The spec author controls the eval; gold-sanity is optional; later acceptance remains separate |
| HMAC-sealed, signed Task-Spec | **Verified cryptography; limited authority** | V2 seals body plus authorization fields (`_lib.sh:759-773`) | HMAC suite: 38/38 including tamper and injection cases | Symmetric repo key is readable from a linked worker worktree; deeper docs correctly call it drift evidence, not a security boundary (`SKILL.md:559-562`) |
| Three-axis loop budget | **Two axes verified; token axis disconnected** | Iteration and wall time are enforced; token use depends on adapter output | Loop tests cover iteration/time, but only a stub emits `ENGINE_TOKENS` | None of the three shipped adapters reports tokens |
| Different-family judge with unseen holdouts | **Not established** | Judge selection prefers but does not require another family; holdout resides in worker-readable Task-Spec | Tier-2 has hermetic and historical live evidence | Same-family and low-risk unavailable outcomes can settle; judge command lacks explicit read-only flags; holdout secrecy is false |
| Runtime bind proves “this host can actually enforce it” (`README.md:284`) | **Claim gap** | Bind/check validates declarations and hashes; separate doctor probes host presence | Runtime suite passes 48 checks, including doctor output | Bind and loop do not consume attestation; default required control is only `fs.write`, and `detect` satisfies it |
| Receipt proves settlement | **Partial** | Receipt hashes spec/profile/eval/path result | Receipt chain tested; historical receipts exist | Receipt failures are ignored during settlement; receipt schema omits Tier-2 verdict and host attestation |
| Cockpit is a safe operational projection | **Verified architecture; alpha product** | Fixed read-only commands, loopback binding, environment allowlist, snapshot/hash binding, ACP isolation | 102 local Cockpit checks passed | Current proving-ground gates are open; fake ACP tests are explicitly not credentialed provider proof |
| Self-hosted proving ground validates product claims | **Historical evidence, not distributed current evidence** | N/A | Full Git history contains state and receipts; changelog is candid | Current tree removes the case; CI uses stubs; Cockpit's four live cases are not complete |

Normal users can reach `init → sign → bind → one-task loop → local commit/PR attempt` with substantial setup. They cannot reach the headline idea-to-merged autonomous outcome solely through the shipped runtime. Recovery is better than first success: named terminal states, disk checkpoints, handoff notes, preserved worktrees, archived receipts, and stable tokens are strong operational choices.

## 6. Market Landscape

All facts in this section were retrieved on **2026-08-05**. Current product capabilities and adoption signals are linked directly in each row; no traffic, revenue, customer, funding, or benchmark number is inferred.

| Alternative | Primary user/use | Unit of autonomy and specification | Verification/acceptance | Model portability and execution boundary | Observability, adoption cost, maturity signal | Converge advantage / disadvantage |
|---|---|---|---|---|---|---|
| OpenAI Codex | Individual and team developers delegating local/cloud coding tasks | Prompt/issue/session; repository instructions and skills; agent edits and runs tests | Agent runs tests; user reviews diff/PR | OpenAI models; local OS sandbox or isolated cloud container with network controls | One-command binary/npm install; public OSS repo showed ~90.7k stars and hundreds of releases | **+** provider-neutral signed contract and explicit terminal receipts. **−** Codex has a far more mature execution sandbox, UX, parallel surface, and direct task completion. [Repo](https://github.com/openai/codex), [security architecture](https://cdn.openai.com/pdf/ac7c37ae-7f4c-4442-b741-2eabdeaf77e0/oai_5_2_Codex.pdf) — retrieved 2026-08-05. |
| GitHub Copilot cloud agent / Agentic Workflows | GitHub-native teams assigning issues, PR work, triage, or scheduled repository automation | Cloud-agent session or Markdown workflow with triggers, permissions, and safe outputs | GitHub Actions, PR review, and platform security checks | GitHub platform; Copilot plus supported partner agents; isolated cloud/local sandboxes | Central session management, branches/PRs, Actions logs, existing repository policy; partner agents were in public preview | **+** Converge artifacts can remain local and vendor-neutral. **−** GitHub already supplies the missing scheduler, isolated execution, PR lifecycle, audit log, and organizational policy. [Cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent), [sandboxes](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/about-cloud-and-local-sandboxes), [agentic workflows](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows), [partner agents](https://docs.github.com/en/copilot/concepts/agents/about-third-party-coding-agents) — retrieved 2026-08-05. |
| Claude Code / Agent SDK | Developers and platform teams automating repository work or building agent products | Interactive/headless session, CLAUDE.md, skills, subagents, hooks, SDK callbacks | Tests plus user/CI review; hooks can block pre-tool actions | Anthropic models; OS-enforced filesystem/network sandbox, permission rules, managed settings | CLI setup; detailed managed policy, hooks, telemetry, and sandbox documentation | **+** Converge supplies a portable delivery method and spec/evidence schema. **−** Claude's native sandbox and managed controls are substantially more concrete than Converge's generated-but-not-installed adapter fragments. [Sandbox](https://code.claude.com/docs/en/sandboxing), [permissions/hooks](https://code.claude.com/docs/en/permissions) — retrieved 2026-08-05. |
| Google Jules | GitHub users delegating asynchronous changes and PRs | One task in its own VM, generated plan, optional approval, background execution | Activity/diff review, tests, PR review; changelog documents automatic CI-failure repair | Google model/service; short-lived per-task VM | Low setup after GitHub connection; task logs, diffs, branches, PRs, parallel tasks | **+** Converge is open, local, and model-neutral. **−** Jules provides a simpler plan-to-PR loop and operational UI with less ceremony. [Getting started](https://jules.google/docs/), [changelog](https://jules.google/docs/changelog) — retrieved 2026-08-05. |
| OpenHands | OSS developers, platform teams, and enterprises running or embedding software agents | Conversation/task/automation through Agent Server/Canvas; supports multiple backends and models | Tests, event trajectories, benchmark harness, human/automation review | BYOM and ACP-compatible agents; Docker, process, remote, cloud, or enterprise sandboxes | Full UI/server/automation platform; public repo showed ~83.2k stars; academic platform lineage | **+** Converge's Task-Spec and gate protocol are more opinionated about delivery proof. **−** OpenHands is already a real multi-agent runtime/control surface with remote sandboxes and automation. [Repository](https://github.com/OpenHands/OpenHands), [sandbox providers](https://docs.openhands.dev/openhands/usage/sandboxes/overview), [paper](https://arxiv.org/abs/2407.16741) — retrieved 2026-08-05. |
| GitHub Spec Kit | Teams wanting specification-driven development across coding agents | Spec → Plan → Tasks → Implement; workflows support gates, loops, pause/resume, and fan-out/fan-in | Checklists, analysis, extensions, workflow gates, ordinary CI/human review | 35 documented agent integrations plus generic integration; runs locally/offline | Very low pilot cost; official site reported 121k+ stars and 240+ contributors | **+** Converge adds signed authorization fields, executable task evals, receipts, and a concrete repair loop. **−** Spec Kit has much broader agent/platform reach, workflow composition, community adoption, and a simpler category. [Overview](https://github.github.com/spec-kit/index.html), [workflow/CLI reference](https://github.com/github/spec-kit/blob/main/docs/reference/overview.md) — retrieved 2026-08-05. |
| SWE-agent | Researchers and advanced users turning GitHub issues into patches and benchmarking agents | Issue/task configuration to autonomous patch; model of choice | SWE-bench and custom evaluation harness; patch inspection | Multi-model; containerized execution in common deployments | Academic, benchmark-centered project; main repo recommends its newer mini-SWE-agent successor | **+** Converge covers intent, architecture, policy, settlement, and audit beyond issue repair. **−** Converge publishes no comparable benchmark corpus or effectiveness measurement. [Repository](https://github.com/swe-agent/swe-agent), [NeurIPS 2024 paper](https://proceedings.neurips.cc/paper_files/paper/2024/hash/5a7c947568c1b1328ccc5230172e1e7c-Abstract-Conference.html) — retrieved 2026-08-05. |
| LangSmith | Teams building, evaluating, deploying, and operating general agents | Agent run/thread/graph, dataset, evaluator, deployment | Offline and online code/human/LLM evaluators, experiment comparison, production sampling | Broad model/framework support, but centered on LangChain/LangGraph services; cloud/hybrid/self-hosted | Rich traces, datasets, evaluators, control/data plane; self-hosted production topology is operationally heavy | **+** Converge is Git-native, offline, and specialized for software delivery. **−** Its observability, datasets, evaluation lifecycle, production control plane, and organizational operations are minimal by comparison. [Evaluation](https://docs.langchain.com/langsmith/evaluation), [self-hosted control plane](https://docs.langchain.com/langsmith/self-hosted) — retrieved 2026-08-05. |

The market has converged on several table-stakes capabilities: isolated workspaces, parallel tasks, tests, plan review, PR production, hooks/permissions, logs, and repository instructions. Multi-model choice is also becoming a platform feature rather than a unique category: GitHub exposes partner agents, OpenHands supports multiple backends, and Spec Kit documents dozens of integrations.

Converge's differentiated wedge is narrower and more credible: **a harness-independent, repository-native acceptance and evidence protocol that can grade work independently of the maker's conversational claim**. The current implementation weakens exactly that wedge where holdouts, signer authority, judge independence, and host enforcement are concerned.

## 7. Competitive Position

Genuinely differentiated today:

- The Task-Spec V2 envelope seals both prose/eval bodies and execution-critical authorization fields (`skills/task-spec/scripts/_lib.sh:759-773`).
- The local runtime has explicit `NO_OP`, `STALLED`, `EXHAUSTED`, `BLOCKED`, `CANCELLED`, `ERROR`, and settlement outcomes, with checkpoints and handoff notes rather than a generic “agent stopped.”
- The same plain artifact can select Claude, Codex, Kimi, or a generic adapter; CLI JSON/tokens are designed for another harness to consume.
- Pass 4 re-hashes the reviewed inputs and refuses unresolved objections or missing cross-family evidence. This is stronger than a decorative “reviewer agent.”
- The project documents uncomfortable limitations more honestly than most early agent tooling, notably HMAC's non-boundary status and Cockpit's open proving grounds.

Market table stakes or weaker than alternatives:

- Worktrees, sandboxes, plan approval, hooks, test execution, task logs, PR creation, and multi-session UI are already common.
- A Markdown workflow or spec pipeline is not ownable by itself; Spec Kit is a much larger and broader substitute.
- Converge has no durable fleet scheduler, protected merge authority, current public effectiveness corpus, production identity/RBAC, or server-side verifier.
- Cockpit is a polished observation prototype but is private, excluded from the root npm package (`package.json:21-26`), requires Node 22 plus dependencies (`apps/cockpit/package.json:18-49`), and explicitly lacks current live proving-ground sign-off.

Strongest reason to adopt: a team can make its acceptance logic and task authority explicit once, run different agent CLIs behind the same local protocol, and get deterministic failure/recovery semantics.

Strongest reason not to adopt: the ceremony and trust vocabulary imply more end-to-end safety than the runtime actually supplies, while established platforms already deliver the scheduling, sandbox, PR, and operational UX that Converge lacks.

“Autonomous Fabric” could become accurate and ownable only if Converge owns a durable cross-harness protocol plus an enforcement plane: grader inputs hidden from workers, independent identity, verifiable sandbox attestation, server-side acceptance/merge, multi-task scheduling, and portable evidence bundles demonstrated on real repositories. Without those, the phrase is a vision label rather than a product category.

## 8. Scorecard

The weighted formula is `dimension score × dimension weight / 10`; weighted points sum to 56.8.

| Dimension | Weight | Score / 10 | Weighted points | Rationale |
|---|---:|---:|---:|---|
| Problem and product thesis | 10% | 6.4 | 6.4 | The need for bounded, auditable agent delivery is real; the nine-pass/dark-factory scope is too broad for the shipped product. |
| Differentiation and market position | 15% | 5.8 | 8.7 | Task-Spec plus deterministic referee is distinctive, but spec-driven and multi-agent workflows are crowded and the independence wedge is incomplete. |
| Method and architecture coherence | 15% | 6.8 | 10.2 | Clear artifacts, gates, tokens, negative states, and separation of UI truth; too many claims rely on declarative controls or manual sequencing. |
| Trust, verification, and security model | 20% | 4.5 | 9.0 | Strong path/HMAC mechanics and honest caveats; unseen holdouts, independent judge, signer authority, host enforcement, and receipt completeness do not survive adversarial inspection. |
| Implementation quality and reliability | 15% | 7.2 | 10.8 | Substantial code, 319 representative checks, fail-closed parsers, and thoughtful regressions; settlement/token/attestation defects remain load-bearing. |
| Autonomous end-to-end completeness | 10% | 3.8 | 3.8 | One prepared task can loop and settle locally/at a PR attempt; selection, acceptance, transition, merge, and fleet operation are external. |
| Developer experience and adoption readiness | 10% | 5.2 | 5.2 | Good CLI tokens, dry runs, recovery, and clean-room install; high authoring ceremony, scattered installs, partial validation, portability exception, and no packaged Cockpit. |
| Evidence, credibility, and project maturity | 5% | 5.4 | 2.7 | Strong hermetic tests and candid changelog; current distributed proof is mostly stubs, while real proving-ground artifacts require Git archaeology. |
| **Overall** | **100%** |  | **56.8 / 100** | **Credible alpha with a strong method kernel and foundational trust/completeness gaps.** |

- Vision potential: **High**
- Current readiness: **Alpha**
- Market position: **Interesting**
- Evidence confidence: **High**
- Adopt today: **Conditional**

## 9. Prioritized Findings

### F-codex-gpt5-01 — The shipped loop is not end-to-end autonomous delivery

- Type: claim gap
- Surface: runtime
- Severity: high
- Confidence: high
- Evidence: `README.md:32-39` promises merged work; `README.md:396-398` admits the Manager and CI gate are absent; `skills/task-loop/scripts/open-issue-pr.sh:525-531` stops at PR; `tests/test-clean-room-install-e2e.sh:195-221` separately runs loop, acceptance, and transition.
- Claim: Converge implements bounded single-task repair and settlement, not idea-to-merge delivery. Work selection, post-execution acceptance, lifecycle transition, merge, and fleet scheduling remain external.
- Why it matters: “Autonomous Fabric” and “dark factory” imply continuous delivery authority. A prospective adopter must build the most operationally important layer themselves.
- Falsifier: a clean, ordinary repository can use only released Converge commands to select ready tasks, execute them, reverify in protected CI, accept, merge, transition state, and recover across multiple concurrent tasks.
- Recommended move: ship a durable Manager and protected CI settlement service, with loop as its worker primitive.
- Acceptance evidence: a credential-scoped test repository completes three dependent tasks through protected PRs and merge, with no manual command between approved intent and final acceptance.

### F-codex-gpt5-02 — “Unseen” holdouts are visible to the worker

- Type: claim gap
- Surface: security
- Severity: critical
- Confidence: high
- Evidence: `skills/task-spec/SKILL.md:564-579` says the worker never sees `## Holdout`; `verify-work.py:75-77` reads it from the Task-Spec; `loop-kernel.sh:850-859` tells the worker that the Task-Spec is its instruction source and to read it; the default template contains no separate holdout reference/store.
- Claim: the claimed train/test separation is not implemented. Any worker that reads the Task-Spec can inspect the holdout before writing code.
- Why it matters: hidden acceptance criteria are a central anti-reward-hacking differentiator. Their visibility invalidates the strongest verification narrative and the historical “never saw” wording.
- Falsifier: holdout bytes are demonstrably absent from the worker filesystem, prompt, logs, environment, and accessible services, yet become available to an independently authorized verifier after the worker epoch closes.
- Recommended move: move holdouts to a verifier-side encrypted/secret artifact store keyed by task/revision; Task-Spec should contain only a commitment/hash and disclosure policy.
- Acceptance evidence: a malicious worker test exhaustively searches its namespace and cannot retrieve holdout content, while the verifier resolves it, validates its commitment, runs it, and binds the result into the receipt.

### F-codex-gpt5-03 — Cross-family and read-only Tier-2 are preferences, not invariants

- Type: design risk
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `verify-work.py:85-98` accepts a requested same-family judge and falls back to same-family; `:300-314` permits low-radius `UNAVAILABLE`; `:355-360` allows same-family `UPHELD`; `:188-209` launches vendor CLIs without explicit read-only/sandbox flags. The loop accepts `CHECK_VERIFY=UNAVAILABLE` (`loop-kernel.sh:993-994`).
- Claim: Tier-2 can settle without a different-family verdict, and the supposed read-only judge is not bounded by an explicit OS/tool policy in its dispatch command.
- Why it matters: a second model is useful only if its independence and authority are measurable. Otherwise “different-family judge” becomes an optimistic routing hint.
- Falsifier: the verifier fails closed whenever family identity is unknown/equal or read-only attestation is absent, and a negative test proves the judge cannot mutate the repository or external state.
- Recommended move: require attested family identity for designated lanes, launch each judge through a read-only adapter, and make waivers explicit signed artifacts rather than implicit low-risk success.
- Acceptance evidence: same-family, unknown-family, mutation-attempt, and no-judge tests all land `BLOCKED`; a different-family read-only run produces a signed verifier artifact.

### F-codex-gpt5-04 — The token budget axis is disconnected from shipped engines

- Type: verified defect
- Surface: runtime
- Severity: high
- Confidence: high
- Evidence: `loop-kernel.sh:838-840` brakes on accumulated tokens and `:917` parses `ENGINE_TOKENS`; `_engine_lib.sh:12-14` only asks adapters to emit it; `codex.sh:42-45`, `claude.sh:38-44`, and `kimi.sh:27-30` never parse or emit usage. Only the test stub emits `ENGINE_TOKENS` (`tests/test-loop-kernel.sh:134`).
- Claim: iteration and wall-clock budgets work, but `budget_tokens` cannot constrain any shipped provider adapter.
- Why it matters: the README markets a three-axis bounded loop. Cost/runaway control is a primary adoption and safety concern, not a cosmetic metric.
- Falsifier: each shipped adapter reports authenticated/parsed token usage or an enforceable provider-side ceiling, and an over-budget real/stub response stops before another attempt.
- Recommended move: implement adapter-specific usage extraction and fail closed—or visibly degrade to a two-axis contract—when a spec requires tokens but usage cannot be measured.
- Acceptance evidence: golden transcripts for all adapters, malformed/missing usage tests, resume accounting, and an integration smoke test showing exact token debit.

### F-codex-gpt5-05 — Binding validates a declaration, not this host's enforcement

- Type: claim gap
- Surface: runtime
- Severity: high
- Confidence: high
- Evidence: README Pass 7 says bind proves “this host can actually enforce it” (`README.md:284`). The default required control is only `fs.write`, with detection accepted (`_runtime_contract.py:471-491`); all adapters admit Task-Spec subpaths are postflight-detected (`bind-runtime-contract.py:94-113`). `attest-runtime.py:34-65` performs a separate presence/kernel probe, and search shows it is reached through `cvg doctor runtime-contract` (`bin/cvg:2427`), not bind/check/loop.
- Claim: `CHECK_RUNTIME_CONTRACT=PASS` proves hashes, declarations, adapter manifests, and at least postflight detection; it does not prove the selected provider is installed with a usable sandbox or that the host enforces the declared denied capabilities.
- Why it matters: a machine-readable “ready” verdict is likely to be consumed by future automation. Overstating it turns policy metadata into a false security boundary.
- Falsifier: bind/dispatch consumes a fresh host attestation, runs a capability probe, requires all denied capabilities relevant to the task, and refuses stale/degraded enforcement.
- Recommended move: merge host attestation into the contract readiness gate, version the attestation, and distinguish `READY_DETECT_ONLY` from `READY_PREVENT` in stable tokens.
- Acceptance evidence: remove/break the sandbox primitive or provider binary and show bind/loop fails before worker execution; probe network and path escape attempts per adapter.

### F-codex-gpt5-06 — HMAC is strong drift evidence but not a worker-external signer

- Type: design risk
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `_lib.sh:584-638` resolves a symmetric key from environment or Git common state; `tests/test-loop-kernel.sh:545-563` explicitly proves the linked worker worktree can resolve it. V2 correctly seals authorization fields (`_lib.sh:759-773`). The deeper skill docs accurately call it tamper-evident, not tamper-proof (`SKILL.md:559-562`).
- Claim: HMAC proves continuity against actors without the key and catches accidental/stale edits; under the normal same-OS-user worker model it does not authenticate “human/CI approved” versus “worker can compute a MAC.”
- Why it matters: the README FAQ describes the seal as the moment a human approved delegation (`README.md:425-429`). Automation must not treat Tier 1 as an independent identity assertion.
- Falsifier: the worker execution identity cannot read/use signing authority, sign operations occur in a separate principal/service, and verification records signer identity and revocation.
- Recommended move: use asymmetric signatures or a narrow signing service/CI identity outside the worker namespace; keep HMAC only as an explicitly local drift tier.
- Acceptance evidence: a malicious worker with full allowed task capability cannot mint a valid approval for a changed authorization envelope; rotation/revocation and signer identity tests pass.

### F-codex-gpt5-07 — Settlement tokens can overstate the artifact that exists

- Type: verified defect
- Surface: runtime
- Severity: high
- Confidence: high
- Evidence: local and remote paths ignore `write_receipt pass` failure with `|| true` (`open-issue-pr.sh:460-467`, `:518-523`). If `gh` is missing, the script says a PR must be opened manually (`:500-514`) but still prints “PR opened” and `TASK_LOOP=SETTLED` (`:525-531`).
- Claim: `TASK_LOOP=LOCAL_SETTLED|SETTLED` does not guarantee a success receipt, and `SETTLED` does not guarantee a PR exists.
- Why it matters: stable terminal tokens are intended for machines. A false positive at settlement can cause downstream acceptance or scheduling to advance without its evidence or handoff object.
- Falsifier: receipt write and PR creation/lookup are mandatory atomic preconditions, or separate tokens precisely encode `COMMITTED`, `PUSHED`, and `PR_OPENED`.
- Recommended move: make receipt failure blocking, verify PR URL/ID, and split settlement phases with idempotent recovery.
- Acceptance evidence: simulated disk failure and absent/failing `gh` never emit `SETTLED`; retry resumes without duplicate commit/PR and ends with receipt plus verified PR identifier.

### F-codex-gpt5-08 — Receipts omit the independent-verification evidence

- Type: claim gap
- Surface: security
- Severity: high
- Confidence: high
- Evidence: `write-execution-receipt.py:105-129` records spec/profile hashes, eval-output hash, path policy, agent, and branch, but no Tier-2 output, judge identity/family, holdout commitment, waiver, or host attestation. Historical `T-20260729-obs-rowcounts.json` at commit `46601b2` likewise has no Tier-2 field despite the changelog claiming Kimi UPHELD it (`CHANGELOG.md:591-600`).
- Claim: the canonical receipt cannot independently prove the project's strongest “green plus adversarial verification” claim.
- Why it matters: logs and changelog prose are not a portable audit chain. Evidence that is not bound into settlement can be lost, substituted, or become impossible to correlate.
- Falsifier: a versioned receipt includes content-addressed verifier input/output, family identity, holdout commitment, enforcement attestation, waivers, and settlement identifiers, all validated by `cvg doctor evidence`.
- Recommended move: design a receipt v2 as an append-only signed evidence manifest and make every required gate contribute an artifact hash before settlement.
- Acceptance evidence: offline verification from a release evidence bundle reconstructs every gate and detects any changed judge result, holdout, host attestation, or PR identity.

### F-codex-gpt5-09 — The deterministic method kernel is substantive

- Type: strength
- Surface: method
- Severity: positive
- Confidence: high
- Evidence: HMAC, runtime, loop, clean-room, and install commands passed 181 checks collectively; the implementation has explicit negative states, checkpoint/handoff files, whole-repo path checks, trusted-base gate parsing, and stale-profile detection. `loop-kernel.sh:489-702` owns state, receipts synchronization, verification, and stagnation fingerprinting.
- Claim: Converge is more than prompt templates. Its one-task contract/state machine is implemented, testable, and operationally thoughtful.
- Why it matters: this kernel is the credible foundation for a broader product and the primary reason the project deserves iteration rather than repositioning as documentation only.
- Falsifier: tests are tautological/stub-only in paths claimed deterministic, or an ordinary local task can emit success while its eval/path gate is red without exploiting Findings 07/08.
- Recommended move: preserve the stable token/state semantics while extracting them into a durable Manager protocol.
- Acceptance evidence: conformance tests run unchanged against local CLI, CI worker, and a second independent implementation.

### F-codex-gpt5-10 — Pass 4 and Cockpit show unusually good safety discipline

- Type: strength
- Surface: Cockpit
- Severity: positive
- Confidence: high
- Evidence: Pass-4 suite passed 23/23 including same-family, missing-decider, unresolved-risk, tampered-plan, and timeout failures. Cockpit check passed 102 tests. Its bridge exposes only fixed read-only commands (`server/cvg.mjs:5-8`, `:31-75`), filters environment (`server/security.mjs:1-32`), hash/snapshot-binds previews, denies permission requests, and blocks Codex Ask when tool isolation is insufficient (`apps/cockpit/README.md:83-113`).
- Claim: where Converge draws a narrow boundary, it often implements and tests it carefully instead of hiding limitations.
- Why it matters: safety credibility comes from refusing unsafe functionality and distinguishing replay/fixture evidence from live proof; Cockpit does both.
- Falsifier: an artifact traversal, stale snapshot, forged POST, ACP permission, environment secret, or same-family plan review crosses the documented boundary.
- Recommended move: make this “narrow claim, enforced boundary, adversarial test” discipline mandatory for runtime/settlement claims.
- Acceptance evidence: one shared threat-model/conformance suite covers Pass 4, Pass 8, Manager, and Cockpit boundaries.

### F-codex-gpt5-11 — Real proving evidence is historical, not release-consumable

- Type: claim gap
- Surface: distribution
- Severity: high
- Confidence: high
- Evidence: the changelog says the `uc-analytics` proving ground was removed and preserved only in Git history (`CHANGELOG.md:521-531`); CI asserts the removed case is not referenced (`ci.yml:286-301`). Cockpit states all four release proving cases are open/not run and requires a dated real-workspace/provider run (`apps/cockpit/PROVING-GROUNDS.md:3-19`, `:32-37`).
- Claim: the repository has credible historical dogfood evidence, but the current source/release does not ship a self-contained, reproducible real-agent proof bundle for its strongest claims.
- Why it matters: adopters cannot distinguish current capability from a historical success affected by later code/provider drift. “Every claim has a receipt” is not true for the distributed artifact.
- Falsifier: each release publishes content-addressed real-workspace evidence, full commands/config, provider/version metadata, receipts, verifier results, and expected reproduction limits.
- Recommended move: publish sanitized proving grounds in a separate versioned evidence repository or release artifact rather than deleting them from the consumable proof surface.
- Acceptance evidence: an independent reviewer downloads a release bundle—without private services or repository archaeology—and verifies at least one UPHELD and one REFUTED end-to-end case.

### F-codex-gpt5-12 — First success has avoidable ceremony and a misleading install check

- Type: market gap
- Surface: distribution
- Severity: medium
- Confidence: high
- Evidence: installer copies every skill into three harness trees (`install.sh:123-157`), then validates only `.agents/skills/task-spec`; validation failure is a warning and `INSTALL=OK` still prints (`install.sh:193-217`). README says installed skills parse (`README.md:154`). `cvg lint` still needs Bash 4 despite a Bash 3.2 floor (`CHANGELOG.md:43-49`). Cockpit is excluded from npm packaging and needs Node 22.
- Claim: installation is mechanically tested but organizational onboarding remains high-friction, and its success token overstates validation breadth.
- Why it matters: Spec Kit and vendor agents reach first useful output much faster. Teams will not adopt nine passes, signing, binding, and multiple install trees before experiencing value.
- Falsifier: a fresh user gets one safe real task to a verified PR with one install/doctor command, no ambiguous warnings, and measured median time-to-first-success.
- Recommended move: ship a minimal pilot lane, fail install on validation error, validate every installed copy, resolve the Bash floor, and package Cockpit only after its proving gates close.
- Acceptance evidence: clean macOS/Linux/Windows-or-WSL onboarding telemetry and scripted acceptance complete without manual path repair or hidden prerequisites.

### F-codex-gpt5-13 — “Autonomous Fabric” obscures the strongest current wedge

- Type: market gap
- Surface: market
- Severity: high
- Confidence: medium
- Evidence: GitHub, OpenHands, Codex, Claude, and Jules already market operational agent runtimes/sandboxes; Spec Kit offers a much broader harness-independent spec/workflow ecosystem (Market Landscape, sources retrieved 2026-08-05). Converge itself admits no Manager/CI gate and an observation-only Cockpit.
- Claim: the category phrase is not yet clear, defensible, or ownable. It invites comparison on fleet autonomy and control-plane maturity, where Converge is weakest, instead of delivery-contract verification, where it is strongest.
- Why it matters: unclear positioning raises adoption expectations the product cannot meet and hides the buyer/job that could form a real community.
- Falsifier: independent users consistently understand “Autonomous Fabric,” choose Converge for that category, and demonstrate multi-agent delivery outcomes competitors cannot reproduce.
- Recommended move: lead with “open, agent-neutral delivery verification protocol/runtime”; reserve “Autonomous Fabric” for the roadmap and define objective category conformance requirements.
- Acceptance evidence: user research shows target adopters can explain the product/job after one paragraph, and three external integrations implement the Task-Spec/receipt protocol without copying the full methodology.

## 10. The Top Three Moves

### 1. Externalize and enforce the trust boundary

- Problem it solves: hidden grader data is visible, signer authority shares the worker principal, judge independence/read-only mode can degrade, host enforcement is not bound to readiness, token metering is absent, and receipts omit the evidence.
- Why top three: independent verification is the project's most differentiated and most fragile claim. Fixing it raises safety, credibility, and category defensibility simultaneously.
- Users affected: security-conscious teams, regulated adopters, platform engineers, and every unattended-loop user.
- Scope/surfaces: secret/committed holdout store; asymmetric or service-backed signer; signer/reviewer identity; `task-spec`, `task-to-runtime-contract`, engine adapters, `verify-work.py`, receipt v2, `doctor evidence`, CI; mandatory host capability attestation; explicit read-only judge sandboxes; token accounting and signed waivers.
- Dependencies/sequencing: publish threat model and assurance tiers first; implement holdout/signer identity; then adapter enforcement/attestation; finally receipt v2 and migration.
- Estimated effort: **XL**
- Expected impact: **10/10**
- Principal risk: portability may regress if the secure tier requires a service/container; preserve a clearly named local cooperative tier rather than pretending equivalence.
- 30-day outcome: threat model, assurance taxonomy, receipt-v2 schema, malicious-worker tests, and a prototype verifier-side holdout commitment.
- 90-day outcome: two provider families complete an end-to-end run where worker cannot read/sign holdouts, host enforcement is attested, token/waiver state is explicit, and an offline verifier checks the full receipt.
- Acceptance: tests described in Findings 02–08; public evidence bundle includes both UPHELD and REFUTED outcomes.
- Estimated overall-score effect: **+12.0 points**.

### 2. Ship the Manager and protected CI settlement plane

- Problem it solves: Converge cannot select/schedule a ready frontier, reverify under an independent principal, merge, accept, transition, or manage concurrent dependencies.
- Why top three: without this layer, “fabric” remains a method wrapped around one task. It is also where worker-external authority can practically live.
- Users affected: teams operating backlogs, maintainers wanting unattended dependency work, and enterprise platform owners.
- Scope/surfaces: durable ready queue, worker leases/epochs, concurrency and dependency scheduling, remote workspaces, CI-side contract/host/receipt verification, PR lookup and protected merge, acceptance/transition, idempotent recovery, cancellation, audit API, and Cockpit read model. Likely surfaces include `bin/cvg`, new manager service/CLI, `.github` reference workflow, Task-Spec state ledger, loop settlement, and snapshot contract.
- Dependencies/sequencing: depends on Move 1's assurance/receipt contracts; build with stub workers first, then real adapters; merge authority last.
- Estimated effort: **XL**
- Expected impact: **10/10**
- Principal risk: becoming a fragile bespoke CI/CD system. Keep GitHub/GitLab adapters thin and make the manager protocol portable.
- 30-day outcome: Manager RFC and a hermetic three-task DAG that leases, retries, blocks, resumes, and settles without manual transitions.
- 90-day outcome: a real repository completes three dependent protected PRs through two agent families, server-side re-verification, acceptance, merge, and state transition; Cockpit observes but cannot mutate it.
- Acceptance: crash/restart, duplicate webhook, stale lease, conflicting path ownership, failed CI, rejected merge, and rollback/retry tests; every terminal outcome has a receipt.
- Estimated overall-score effect: **+9.5 points**.

### 3. Publish a reproducible proving program and one-command pilot

- Problem it solves: real evidence is historical/removed, CI uses stubs, current Cockpit proving gates are open, and first success demands too much method ceremony.
- Why top three: a new category requires repeatable proof and a low-cost wedge more than another skill. It converts implementation into adoption and falsifies product claims continuously.
- Users affected: skeptical maintainers, evaluators, open-source contributors, platform teams, and prospective design partners.
- Scope/surfaces: separate public proving-ground/evidence repository or signed release assets; three varied real repositories; sanitized configs/transcripts/receipts; provider/CLI version matrix; comparative task corpus; `cvg pilot`/doctor; strict install validation; minimal lane; packaging/versioning policy for Cockpit after its gates close; positioning rewrite.
- Dependencies/sequencing: define evidence bundle against Move 1 receipt v2; exercise Move 2 manager; pilot UX can start in parallel but must not claim secure/full autonomy prematurely.
- Estimated effort: **L**
- Expected impact: **9/10**
- Principal risk: cherry-picked demos. Pre-register tasks/failure criteria and publish failures, cost/time envelopes, and provider limitations.
- 30-day outcome: one downloadable current evidence bundle, one-command local stub pilot, installation failures made fatal, and public conformance checklist for “Autonomous Fabric.”
- 90-day outcome: three dated real-agent proving grounds across at least two languages and three model families, one independent reproduction, and measured time-to-first-verified-PR.
- Acceptance: release consumer verifies evidence without full Git history; every headline claim links to a current artifact; both success and deliberate refutation/recovery are present.
- Estimated overall-score effect: **+7.0 points**.

## 11. Suggested 30/60/90-Day Sequence

**Days 0–30 — make claims and contracts exact**

- Freeze new passes and Cockpit features.
- Publish threat model, assurance tiers, Manager protocol, receipt-v2 schema, and category conformance checklist.
- Correct current wording: hidden holdouts, host enforcement, merged outcome, three-axis budgets, and receipt guarantees.
- Fix immediate correctness issues: blocking receipt writes, phase-specific settlement tokens, adapter token/degradation behavior, strict all-copy install validation.
- Deliver verifier-side holdout commitment and malicious-worker test harness.
- Publish one current downloadable evidence bundle.

**Days 31–60 — establish an external authority plane**

- Land signer/reviewer identity and read-only judge adapters.
- Make runtime attestation a dispatch precondition with prevent/detect tokens.
- Implement receipt v2 and offline evidence verification.
- Build Manager alpha over a hermetic task DAG: leases, dependency frontier, retry/resume/cancel, idempotent settlement.
- Add a reference protected-CI workflow; do not grant merge authority yet.

**Days 61–90 — prove real delivery, then simplify adoption**

- Run the Manager on three pre-registered real repositories and at least two provider families.
- Enable protected merge only after server-side re-verification and acceptance are proven.
- Publish successes, refutations, failures, versions, elapsed time, token/cost availability, and recovery evidence.
- Ship one-command pilot and measure time-to-first-verified-PR.
- Close Cockpit's proving gates, then decide whether to package it; keep it observation-only until the Manager API is independently authorized.

## 12. What Should Not Be Built Yet

- More methodology passes, skills, templates, or document types. The current twelve already exceed what most adopters will learn before first value.
- More tracker adapters or board views. GitHub/Linear/Jira breadth does not fix settlement authority or proof.
- Multi-agent topology features beyond the minimum Manager DAG. Parallel-agent novelty will amplify ambiguous ownership and trust boundaries.
- A writable Cockpit, chat-triggered approvals, or browser-based control actions. Its read-only design is currently a strength.
- Enterprise RBAC, billing, marketplace, SaaS hosting, or a generalized agent observability product. Validate the delivery-protocol wedge first.
- New cryptographic branding without principal separation. Changing HMAC to another algorithm does not create an external signer.
- Benchmarks optimized for leaderboard scores before real release evidence. Publish representative delivery outcomes and failures first.

## 13. Open Questions and Falsifiers

1. Who owns eval/holdout authoring in a real organization, and how is grader quality reviewed? A corpus showing inter-reviewer agreement and escaped defects would materially change the trust score.
2. Is the threat model a cooperative but fallible worker, a prompt-injected worker, or a hostile process with the user's OS identity? The present implementation is defensible mainly for the first.
3. Can Converge support a secure tier without requiring every harness to implement identical sandbox semantics? A portable attestation/conformance protocol would falsify the portability-versus-enforcement tradeoff.
4. What exact event is `SETTLED`: committed, pushed, PR opened, CI green, accepted, or merged? A versioned lifecycle ontology must make this unambiguous.
5. How will HMAC/asymmetric signer rotation, revocation, repository forks, and CI identities work without exposing approval authority to workers?
6. How often do authored evals pass on baseline, reward hacks, or miss production regressions? Current optional gold-sanity is not enough evidence.
7. Does cross-family review improve defect detection after controlling for an additional sample/model call? A preregistered comparison against same-family and deterministic review would test the thesis.
8. Can a normal team maintain the nine-pass artifacts as code evolves, or do they become stale ceremony? Measure artifact maintenance time and abandonment in three external pilots.
9. Is provider-neutrality valuable enough to outweigh lowest-common-denominator controls? External integrations adopting only the Task-Spec/receipt protocol would be strong evidence.
10. What is the category boundary? A falsifiable “Autonomous Fabric conformance” definition should require durable scheduling, external authority, enforced capability boundaries, complete receipts, and protected settlement—not merely agent-compatible skills.

## 14. Sources

Repository evidence is cited inline as `path:line`; command outcomes are recorded in Section 4. External sources below were all retrieved on **2026-08-05**:

1. OpenAI, [Codex repository and current install/surface](https://github.com/openai/codex).
2. OpenAI, [GPT-5.2-Codex system card addendum — sandbox architecture](https://cdn.openai.com/pdf/ac7c37ae-7f4c-4442-b741-2eabdeaf77e0/oai_5_2_Codex.pdf).
3. GitHub, [Concepts for GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent).
4. GitHub, [Cloud and local sandboxes for GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/about-cloud-and-local-sandboxes).
5. GitHub, [About GitHub Agentic Workflows](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows).
6. GitHub, [About third-party coding agents](https://docs.github.com/en/copilot/concepts/agents/about-third-party-coding-agents).
7. Anthropic, [Claude Code sandboxing](https://code.claude.com/docs/en/sandboxing).
8. Anthropic, [Claude Code permissions and hooks](https://code.claude.com/docs/en/permissions).
9. Google, [Jules getting started and task VM/plan flow](https://jules.google/docs/).
10. Google, [Jules changelog](https://jules.google/docs/changelog).
11. OpenHands, [OpenHands repository / Agent Canvas](https://github.com/OpenHands/OpenHands).
12. OpenHands, [Sandbox providers](https://docs.openhands.dev/openhands/usage/sandboxes/overview).
13. Wang et al., [OpenHands: An Open Platform for AI Software Developers as Generalist Agents](https://arxiv.org/abs/2407.16741).
14. GitHub, [Spec Kit overview](https://github.github.com/spec-kit/index.html).
15. GitHub, [Spec Kit CLI/workflow reference](https://github.com/github/spec-kit/blob/main/docs/reference/overview.md).
16. Princeton NLP, [SWE-agent repository](https://github.com/swe-agent/swe-agent).
17. Yang et al., [SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering, NeurIPS 2024](https://proceedings.neurips.cc/paper_files/paper/2024/hash/5a7c947568c1b1328ccc5230172e1e7c-Abstract-Conference.html).
18. LangChain, [LangSmith Evaluation](https://docs.langchain.com/langsmith/evaluation).
19. LangChain, [Self-hosted LangSmith control/data plane](https://docs.langchain.com/langsmith/self-hosted).

## 15. Machine-Readable Summary

{
  "reviewer_id": "codex-gpt5",
  "commit": "9c966884e37919c0f7e4c3e027b4b237670eb2ad",
  "review_complete": true,
  "market_research": "complete",
  "overall_score": 56.8,
  "vision_potential": "High",
  "current_readiness": "Alpha",
  "market_position": "Interesting",
  "evidence_confidence": "High",
  "adopt_today": "conditional",
  "top_strength": "Provider-neutral executable Task-Specs with a real bounded state machine and unusually strong negative-path tests",
  "top_risk": "The claimed independent trust boundary is not external to the worker: holdouts are visible and signer, judge, host, and receipt guarantees are incomplete",
  "top_3": [
    {
      "rank": 1,
      "name": "Externalize and enforce the trust boundary",
      "effort": "XL",
      "impact": 10,
      "score_delta": 12.0
    },
    {
      "rank": 2,
      "name": "Ship the Manager and protected CI settlement plane",
      "effort": "XL",
      "impact": 10,
      "score_delta": 9.5
    },
    {
      "rank": 3,
      "name": "Publish a reproducible proving program and one-command pilot",
      "effort": "L",
      "impact": 9,
      "score_delta": 7.0
    }
  ],
  "critical_finding_ids": [
    "F-codex-gpt5-02"
  ],
  "tests_run": {
    "passed": 319,
    "failed": 0,
    "blocked": 0
  },
  "external_sources": 19
}
