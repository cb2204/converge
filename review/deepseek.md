# deepseek

RUN: 2026-08-04 · files read: 47 · external sources cited: 14

## FINDINGS

### F-deepseek-01 — The Converge repository cannot run its own method

- SURFACE: method
- SEVERITY: critical
- CONFIDENCE: high
- EVIDENCE: `cvg next` → `no Converge workspace found walking up from '/Users/luanmorenomaciel/GitHub/converge' — run cvg init first` → `NEXT_PASS=USAGE_ERROR` (exit 2) · `glob cvg/` → no matches (the `cvg/` workspace directory does not exist in the repo) · `bin/cvg:466-596` (cvg_init creates the workspace) · `bin/cvg:88-125` (resolve_project_root requires `.cvg/` or `cvg/tasks/` or `cvg/INDEX.md`)
- CLAIM: The tool that promises nine-gate verified delivery has never been delivered through its own pipeline. The repo contains no `cvg/` workspace, no BRD, no task-specs for its own features, and the descent conductor (`cvg next`) refuses to operate because `cvg init` was never run.
- WHY IT MATTERS: A compiler whose own source doesn't compile is suspect. Converge's strongest claim — autonomous, verified, gate-enforced delivery — has never been demonstrated on Converge itself. A potential adopter who clones the repo and runs `cvg next` gets `USAGE_ERROR`, not a proof of the method. The nine gates are applied to external "proving ground" use cases that have been removed from CI (CHANGELOG documents removing uc-01-analytics-engineering), so there is no live, inspectable demonstration of the full descent.
- FALSIFIER: `cvg init && cvg setup signing && cvg next` exits 0 and reports NEXT_PASS=0 (or a higher pass if artifacts exist). Also, at least one Task-Spec in `cvg/tasks/` documents a feature of Converge itself.
- MOVE: Run `cvg init` in the Converge repo root. Write the BRD for the next feature (the Manager, say) as a real Converge run, with task-specs in `cvg/tasks/` that the loop can attempt. This is self-hosting: eat your own dogfood, as a verifiable artifact rather than a README claim.
- EVAL: `cvg next 2>&1 | grep -q 'NEXT_PASS='` — exits 0 only after `cvg init` creates the workspace, proving the tool can run on itself.

### F-deepseek-02 — `cvg lint` requires bash 4+ but the CLI floor is bash 3.2

- SURFACE: cli
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `skills/task-spec/scripts/lint-backlog.sh:19` — "*cannot run here (needs bash 4+ for associative arrays; see LINT=UNSUPPORTED)*" · `skills/task-spec/scripts/lint-backlog.sh:65-73` — `declare -A` (requires bash 4+) · `bin/README.md:48` — "*`cvg lint` requires bash 4+ and cannot run on stock macOS. Converge declares bash 3.2 as its portability floor and runs a macos-latest CI leg to prove it.*" · `CHANGELOG.md:46-49` — "*The gap itself is open: the real fix is a bash-3.2 rewrite or dropping the floor.*"
- CLAIM: One of the twelve CLI verbs is silently unusable on the platform the CLI claims as its portability floor (stock macOS, bash 3.2). The CI runs on macos-latest which ships bash 3.2, so the lint suite row is skipped there — meaning CI cannot detect if the lint script regresses on bash 4+ either.
- WHY IT MATTERS: A user on stock macOS who follows the README and runs `cvg lint` gets `LINT=UNSUPPORTED` (exit 3) with no warning during `cvg doctor host` or `cvg setup` that this verb is unavailable. The CHANGELOG has flagged this gap for months with no resolution. Every other verb works on bash 3.2 — this one is an anomaly that undermines the "one CLI" claim.
- FALSIFIER: `bash --version | head -1` reports 3.2, and `bash skills/task-spec/scripts/lint-backlog.sh` exits 0 (not 3). Or the `bin/README.md` statement is deleted because the floor was dropped.
- MOVE: Either rewrite `lint-backlog.sh` in bash 3.2 (replace associative arrays with sorted flat files or indexed arrays with paired keys) or formally drop the bash 3.2 floor and require bash 4+. The former is a day of work; the latter breaks the macOS stock shell promise.
- EVAL: `bash --version | head -1 | grep -q 'version 3' && bash skills/task-spec/scripts/lint-backlog.sh --help >/dev/null 2>&1` — exits 0 only after the rewrite works on bash 3.2.

### F-deepseek-03 — Cross-family verification literature partially undermines Converge's strongest selling point

- SURFACE: method
- SEVERITY: high
- CONFIDENCE: medium
- EVIDENCE: `README.md:54-57` — "*Cross-family verification. Tier-2 acceptance sends the diff, the intent, and holdout criteria the builder never saw to a different vendor's model, prompted to refute. Proven live in both directions.*" · External: [Digital Applied, 2026] — "*When two models are both wrong, they converge on the same wrong answer ~60% of the time; larger/more accurate models show higher error correlation, even across providers/architectures.*" (https://www.digitalapplied.com/blog/cross-model-review-consensus-verification-2026, retrieved 2026-08-04) · External: [Panickssery et al., arXiv:2404.13076, April 2024] — self-preference bias documented across GPT-4, GPT-3.5, Llama 2. · External: [Li et al., arXiv:2502.01534, Feb 2025, ICLR 2026] — "*Preference Leakage: systematic bias of judges toward related student models.*"
- CLAIM: The README frames cross-family verification as a radical innovation that catches what same-model review cannot. The literature supports the claim that same-model review is biased, but also finds that cross-family models share ~60% error correlation — the independence Converge relies on is weaker than the README implies. The one REFUTED verdict the README cites is a single data point, not a systematic evaluation.
- WHY IT MATTERS: A user who adopts Converge because of the cross-family claim may over-trust the tier-2 verdict. The README says "fails closed" but doesn't quantify the false-negative rate (a correct implementation that gets REFUTED). The absence of any measurement of cross-family adjudication accuracy on the proving ground makes the claim unfalsifiable.
- FALSIFIER: A test suite that measures cross-family adjudication accuracy on a benchmark of known-bug and known-correct diffs, reporting precision, recall, and the false-refutation rate. Or a README statement that quantifies the uncertainty.
- MOVE: Add a "limitations" paragraph to the cross-family verification section acknowledging the error correlation literature and stating that cross-family review reduces but does not eliminate shared blind spots. This isn't weakening the claim — it's making it honest, which is the entire thesis of the tool.
- EVAL: `grep -q 'error correlation\|shared blind\|not eliminate' README.md` — exits 0 when the limitation is documented.

### F-deepseek-04 — loop-kernel.sh hardcodes `python3` without a preflight

- SURFACE: cli
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `skills/task-loop/scripts/loop-kernel.sh:215` — `PROFILE_RUNTIME="$(python3 -c '…` · `skills/task-loop/scripts/loop-kernel.sh:289` — `COST_OUT="$(python3 "$COST_RESOLVER" …` · `skills/task-loop/scripts/loop-kernel.sh:358` — `python3 -c 'import os,sys; …` · `skills/task-loop/scripts/loop-kernel.sh:430` — `_tw="$(python3 -c '…` · `skills/task-loop/scripts/loop-kernel.sh:988` — `python3 "$VERIFIER" …`
- CLAIM: The loop kernel calls `python3` in five separate code paths without checking whether `python3` is available on the host before starting the loop. `cvg doctor host` checks for python3, but the loop itself does not gate on it — so a run authorized at `cvg setup` time on a host that later loses python3 (PATH change, venv deactivation) will crash mid-loop after spending tokens.
- WHY IT MATTERS: This is the same defect class as the shellcheck incident documented in `CHANGELOG.md:179-187` — a missing prerequisite reported correctly but three verbs too late. Here the cost is worse: the loop spends engine tokens on an attempt, then crashes during verification, settlement, or cost profiling with a bare Python traceback instead of a named terminal state.
- FALSIFIER: On a host without python3 on PATH, `cvg loop --issue T-fake --dry-run` exits 2 or 4 with a clear "python3 required" message before any engine is called.
- MOVE: Add a `command -v python3 >/dev/null` check to the loop kernel's preflight section (around line 707), before the dry-run/estimate branches. Emit `TASK_LOOP=ERROR` if missing. `cvg doctor host` already reports MISSING for python3 — the loop just needs to read that verdict or replicate the check.
- EVAL: `PATH=/usr/bin cvg loop --issue T-...md --dry-run 2>&1 | grep -q 'TASK_LOOP=ERROR'` — exits 0 when python3 is absent and the loop refuses rather than crashing.

### F-deepseek-05 — The "zero runtime dependencies" claim is both true and misleading

- SURFACE: docs
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `README.md:15` — "*zero runtime dependencies*" · `README.md:98` — "*Cockpit is not included in the published zero-runtime-dependency Converge package*" · `package.json:21-27` — the npm `files` array includes only `bin/`, `skills/`, `install.sh`, `VERSION`, `.claude-plugin/` — Cockpit is excluded · `apps/cockpit/package.json:18-46` — Cockpit has 13 dependencies + 11 devDependencies including React, Vite, TypeScript, pdfjs-dist, @xyflow/react
- CLAIM: The core CLI (bash + stdlib Python) genuinely has zero runtime dependencies. But the README prominently features the Cockpit as a key part of the product ("The repository-first Cockpit makes a workspace observable") and the claim "zero runtime dependencies" appears in the hero section before any carve-out. A reader who scrolls past the Cockpit section without reading the fine print will believe the entire project, including the observation surface, has no dependencies.
- WHY IT MATTERS: This is a credibility tax. The Cockpit is not ancillary — it's one of the first things the README introduces (section 2, before Install). The carve-out is technically correct but rhetorically dishonest: the thing you're proudest of showing is the thing that doesn't meet your headline claim.
- FALSIFIER: The Cockpit could run with only Node.js stdlib and a bundled snapshot — no npm install required. Or the README could separate the claims clearly in the hero.
- MOVE: Change the hero line to "*zero runtime dependencies (core CLI)*" and move the Cockpit carve-out from a footnote to a visible note in the Cockpit section itself. Or, more honestly: ship the Cockpit as a separate repository so the claim is unqualified.
- EVAL: `head -20 README.md | grep -q 'zero runtime' && head -20 README.md | grep -q 'core CLI\|referee'` — exits 0 when the hero line self-qualifies.

### F-deepseek-06 — Task-Spec is an invented format when standards are crystallizing

- SURFACE: method
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `skills/README.md:191-203` — Task-Spec v3.x with "YAML frontmatter + six zones + ≥3 runnable bash evals + an Exit Check" · External: [agents.md, retrieved 2026-08-04] — "*AGENTS.md is a simple, open Markdown format … donated to the Agentic AI Foundation (AAIF) under the Linux Foundation in December 2025*" (https://agents.md/) · External: [MCP SEP-2640, retrieved 2026-08-04] — "*A Skill is a directory (at least SKILL.md) that provides structured workflow instructions … skill:// URI scheme*" (https://github.com/modelcontextprotocol/modelcontextprotocol/blob/93d7a9ddb20d4b3594f4a1be7508ee47f0718f17/seps/2640-skills-extension.md) · External: [Leon Breukelman, retrieved 2026-08-04] — "*A TaskSpec consists of five fields: Intent, Deliverable, Quality bar, Constraints, and Context*" (https://leonbreukelman.engineer/human/writing/the-delegation-pattern/) — another independent TaskSpec format.
- CLAIM: Converge invents its own Task-Spec format (YAML frontmatter, six zones, HMAC seal, bash evals) while the ecosystem is converging on AGENTS.md (Linux Foundation) and MCP Skills (Anthropic-donated, MCP SEP-2640). The SKILL.md format Converge uses is similar to but incompatible with the MCP skill format. Converge's `skill://` URI scheme collides with the MCP standard's `skill://` scheme.
- WHY IT MATTERS: Interoperability. A task written as a Converge Task-Spec cannot be consumed by an MCP-native agent, and an MCP skill cannot be gated by Converge. If Converge's format wins, it fragments the ecosystem. If AGENTS.md/MCP skills win, Converge's entire skill chain needs a migration path. The skill format conflict (`skill://`) is particularly bad — two standards claiming the same URI scheme means an agent serving both will route incorrectly.
- FALSIFIER: The Converge SKILL.md format is documented as a deliberate extension of the MCP/AGENTS.md formats with a migration path. Or the `skill://` URI collisions are resolved by adopting a different scheme or documenting why MCP's `skill://` and Converge's `skill://` can coexist.
- MOVE: Document the relationship between Converge's formats and the emerging standards. If Converge's Task-Spec predates and differs deliberately, state the design rationale. If the MCP skill format is Converge's future target, declare the migration path. At minimum, rename the internal `skill://` scheme to avoid collision with MCP SEP-2640.
- EVAL: Not mechanically checkable — requires design decision followed by documentation.

### F-deepseek-07 — The pass numbering is confusing and the README's "nine passes" claim is ambiguous

- SURFACE: docs
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `README.md:30-38` — "*a raw idea enters a nine-gate production line*" · `README.md:245-269` — mermaid diagram shows 0-8 (nine boxes) · `README.md:272-286` — nine-row table with passes 0-8 · `README.md:268` — "*Not every change earns all nine passes. `cvg lane` routes work … FAST (5, 7, 8), NORMAL (1, 2, 5, 7, 8), or FULL (0–8)*" · `skills/README.md:7-9` — "*nine spine skills (the passes, including the optional Capture ⓪ and the opt-in Register)*"
- CLAIM: The README says "nine passes" in multiple places and the diagram shows nine boxes. But two passes are optional (0 and 6), and the FAST lane runs only three passes (5, 7, 8). The user who reads the hero section comes away believing every change goes through nine gates, when the most common path (NORMAL) is actually five passes (1, 2, 5, 7, 8) plus an optional 6.
- WHY IT MATTERS: A new user evaluating Converge against a simpler workflow tool sees "nine gates" and assumes heavy process overhead. The lane router means most changes skip four of the nine. The marketing undersells the product: the actual ceremony is lighter than the number implies, but the number is what the reader remembers.
- FALSIFIER: Every path through the README that mentions "nine" also states the lane-routing carve-out in the same paragraph. The hero section says "nine-gate production line" — it does not.
- MOVE: Change the hero line from "nine-gate production line" to "gated production line" and move the count to the passes table where it's qualified by the lane routing explanation on the same page. The number nine is a property of the full descent for greenfield work, not of every change.
- EVAL: Not mechanically checkable — requires copy change and judgment.

### F-deepseek-08 — `cvg tasks gate` is read-only but `cvg tasks gate --stamp` mutates

- SURFACE: cli
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `bin/README.md:95` — "*A plain verdict is read-only; only explicit --stamp mutates the sign-off envelope.*" · `cvg agent-context --json` shows `tasks gate --stamp` has `mutating: true` while bare `tasks gate` has `mutating: false` · `bin/cvg` — the gate-without-stamp path: the CLI routes to `safe-to-delegate.sh` without `--stamp`
- CLAIM: The verb "gate" means "read-only check" everywhere else in the CLI (`cvg gate`, `cvg capture`, `cvg intent`, `cvg structure`, `cvg decompose`, `cvg review --check`). But `cvg tasks gate --stamp` is a mutation that HMAC-seals the spec — the naming convention "gate = read-only" breaks on the most common verb in the task authoring path.
- WHY IT MATTERS: A user who internalizes "gate commands are read-only" may run `cvg tasks gate --stamp` expecting a dry-run and unintentionally seal a spec before its evals are written. The `--stamp` flag is documented but the pattern of "same verb, flag toggles mutability" is unique to `tasks gate` and violates the contract `cvg agent-context` publishes.
- FALSIFIER: `cvg tasks gate --stamp` is renamed to `cvg tasks seal` or `cvg tasks sign`, making the mutation explicit in the verb.
- MOVE: Rename `cvg tasks gate --stamp` to `cvg tasks seal <spec>`. Keep `cvg tasks gate` as the read-only check. This is a CLI breaking change but the method is pre-1.0.
- EVAL: `cvg help 2>&1 | grep -c 'tasks seal'` — exits 0 when the verb exists. Or `cvg tasks gate --stamp` emits a deprecation warning pointing to the new verb.

### F-deepseek-09 — The Cockpit shows a consensus verdict that may be stale against live plan files

- SURFACE: cockpit
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: `apps/cockpit/README.md:28` — "*Its observation path invokes exactly one read-only CLI command: cvg snapshot --json*" · `apps/cockpit/README.md:103-106` — "*Artifact previews require the snapshot ID and captured SHA-256. The bridge returns 409 if the snapshot or source bytes changed before the preview opened.*" · `CHANGELOG.md:56-74` — documents the barrier-walking bug where plans changed after adversarial review and the conductor didn't detect it
- CLAIM: The Cockpit renders the adversarial review verdict from the snapshot, but the snapshot captures the objection log's state as a JSON artifact — not whether the plans the verdict was based on are still current. A user viewing CHECK_CONSENSUS=OK in the Cockpit may not realize the plans have been edited post-review. The artifact preview mechanism catches changed bytes only when the user opens a preview, not proactively.
- WHY IT MATTERS: The same defect class as the barrier-walking bug (CHANGELOG 2026-08-03): consent given to one text is not consent to another. The Cockpit is the observation surface an owner uses to decide "is this ready?" — showing a stale green without a staleness indicator is worse than showing nothing, because it reads as verified.
- FALSIFIER: The Cockpit Health view shows a "stale consensus" warning when the objection log's recorded input hashes don't match the current plan files. Or the snapshot contract includes a `consensus_stale: true|false` field computed by `cvg snapshot`.
- MOVE: Extend the snapshot to include a per-artifact freshness check: for the objection log's `inputs[]` hashes, compare against live file hashes and surface `consensus_stale` in the snapshot contract. The Cockpit can then render a warning banner when stale.
- EVAL: `cvg snapshot --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('snapshot',{}).get('consensus_stale','NOT_PRESENT'))"` — exits 0 when the field exists and reports `true` after plans are edited.

### F-deepseek-10 — `cvg doctor plugin` diagnoses staleness but cannot resolve it

- SURFACE: cli
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `CHANGELOG.md:246-247` — "*Read-only and offline by design — it never fetches, because a network-dependent doctor lies when offline.*" · `bin/cvg:1399-1500` (cvg_doctor_plugin) — fingerprint comparison, sha comparison, but no `--fix` or `--update` flag
- CLAIM: `cvg doctor plugin` tells you your skills are stale but gives you no path to fix them. The user must manually re-install. The CHANGELOG says "a network-dependent doctor lies when offline" — true, but a doctor that diagnoses without treating is half a doctor.
- WHY IT MATTERS: Minor but real: the finding "your skills are eight commits stale" was hard-won (the CHANGELOG describes the debugging scar). Once found, the tool should offer to resolve it, accepting that resolution may fail offline — that's what exit codes are for.
- FALSIFIER: `cvg doctor plugin --update` exists and attempts to update the plugin cache, failing gracefully when offline.
- MOVE: Add `cvg doctor plugin --update` that re-runs install.sh to the latest pinned ref. Fail with a clear offline message if the network is unavailable.
- EVAL: Not mechanically checkable without network — but `cvg help | grep 'doctor plugin'` should list `--update`.

### F-deepseek-11 — The "Not yet built" section in bin/README.md contradicts its own policy

- SURFACE: docs
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `bin/README.md:3-6` — "*This file is the CLI's status card: what exists, what it wraps, what proved it. It records the present only. The backlog — what comes next and in what order — lives in ONE place: the project's issue tracker. A second todo here would fork the truth — deliberately not done.*" · `bin/README.md:174-178` — "*`status` · `ci` · `work` · `run`/`route` · `board`/`graph` · `deliver`/`metrics` — tracked on the project board.*" directly below this policy.
- CLAIM: The file explicitly says it won't keep a todo list because the tracker is the single source of truth — then keeps a todo list. The list is prefixed with "tracked on the board" but its presence in this file IS the fork the policy warns against.
- WHY IT MATTERS: Low-severity but revealing: the repository that enforces single-source-of-truth for every consumer can't maintain it for its own CLI surface card. It's the same class as F-deepseek-01 — the tool's own documentation can't follow the rule it enforces.
- FALSIFIER: The "Not yet built" section is either removed (the tracker is the only list) or relabeled as "the current backlog as of `<date>`, read from the tracker" with a script that generates it.
- MOVE: Delete the "Not yet built" section. Add a `cvg board` command that reads from the tracker and prints the live backlog. The status card then points to `cvg board`, not a static list.
- EVAL: `grep -c 'Not yet built' bin/README.md` — exits 0 when the count is 0.

## KILL LIST

### K-01 — Delete `apps/cockpit/src/data/fallback.ts`

- EVIDENCE: `apps/cockpit/README.md:44` — "*If the first bridge request is unavailable, the client clearly labels and renders the deterministic replay fixture in src/data/fallback.ts.*" · The file exists in the Cockpit source tree.
- WHY: A fixture baked into source code for a removed proving ground (uc-01-analytics-engineering, per CI gate `test-ci-covers-every-suite.sh` and the CHANGELOG's removal documentation) is dead code that looks alive. A new user spinning up the Cockpit hits this fallback and sees data from a project that no longer exists. The fallback should be generated on-the-fly from the live snapshot or replaced with an empty-state component. Committing fixture data for a removed proving ground is an archaeology trap.
- MOVE: Replace `fallback.ts` with a generated empty-state that says "no snapshot available — point the Cockpit at a Converge workspace" and remove the uc-01 references.

### K-02 — Drop the bash 3.2 portability floor or fix `cvg lint`

- EVIDENCE: `CHANGELOG.md:48-49` — "*The gap itself is open: the real fix is a bash-3.2 rewrite or dropping the floor.*" · `skills/task-spec/scripts/lint-backlog.sh:19` — "*cannot run here (needs bash 4+ for associative arrays)*"
- WHY: The floor has been a documented open gap for months. Every day it stays open, the README's "bash 3.2+" badge is closer to a lie. Pick a side: rewrite the lint script in bash 3.2 (indexed arrays + linear search, it's a backlog linter, not a database) or drop the floor to bash 4+ and update the CI matrix. The middle ground — shipped with a known gap — is the worst of both.
- MOVE: See F-deepseek-02 MOVE.

### K-03 — Delete the `control-room:*` npm script aliases after one release

- EVIDENCE: `package.json:15-19` — six `control-room:*` scripts aliased to `cockpit:*` · `apps/cockpit/README.md:150-151` — "*The previous control-room:* root scripts remain compatibility aliases for one release.*"
- WHY: The promise was one release. v0.1.0 has shipped. These aliases are dead weight in the root package.json and a confusion vector for new users who see two sets of identical scripts and don't know which to use.
- MOVE: Delete lines 15-19 of `package.json`.

## BLIND SPOT

The author assumes that a **repository organized around the Converge method would naturally use it** — but the Converge repo itself has no `cvg/` workspace, no BRD for any feature, no Task-Specs for its own development, and `cvg next` returns USAGE_ERROR from the repo root. The method has been applied to external "proving ground" use cases that have since been removed from CI, leaving zero live, inspectable demonstrations of the full descent inside the repo.

This is not hypocrisy — the author is building the tool, not using it to build a product. But it IS a blind spot: the tool's strongest claim (autonomous, verified, gate-enforced delivery) has never been demonstrated on the tool itself. Every claim about the loop, the gates, and the barrier is backed by hermetic test suites — but a hermetic test is not a live run. A potential adopter clones the repo, runs `cvg next`, and hits a wall. The first interaction with Converge is a gate failure on Converge itself.

The specific unexamined assumption: **"the tool and the thing built with the tool are different projects."** They are, but they don't have to be. A compiler that can compile itself is stronger than one that cannot. Converge that can deliver Converge is the proof the README already claims to have.

## STRONGEST OBJECTION

**Target: The cross-family adversary as THE BARRIER's load-bearing mechanism.**

The README says: "*A model won't refute itself hard enough, so this pass binds a different-family engine as a skeptic.*" This is presented as the mechanism that makes Pass 4 the last human sign-off — the adversary attacks, objections are resolved, the human signs.

Here is the argument that this is WRONG:

1. **The real barrier is the human, not the adversary.** The CHANGELOG documents this vividly: the adversary's own proposal was read as consent, and Pass 4 went GREEN with seven criticals open (CHANGELOG 2026-08-03). The fix was not a better adversary — it was a **field change** in the objection log schema (proposal vs. resolution) and a **human decision verb** (`cvg review --resolve`). The adversary files objections; the human decides. The cross-family property is window dressing on a human gate.

2. **Error correlation across model families is high.** The ICML 2025 study found ~60% overlap in wrong answers. The adversarial review asks a different model to refute plans — but if both models share the same blind spots 60% of the time, the adversary misses 60% of what a truly independent reviewer would catch. The README cites ONE refuted verdict as proof. One.

3. **The adversary is read-only and fires exactly once.** It doesn't iterate. It doesn't see the implementation. It attacks the plan, not the code. The tier-2 verifier at Pass 8 is the one that sees the diff — but that's a separate mechanism. The BARRIER adversary is a design reviewer, not a code reviewer, and the most expensive bugs in software are in the gap between design and implementation.

4. **The cross-family rule is a bet on literature that partly undermines it.** Panickssery et al. (2024) and Wataoka et al. (2024) document self-preference bias — models favor their own outputs. Li et al. (2025) extend this to same-family preference leakage. Cross-family reduces this. But the literature also documents that agreement between models is a weak predictor of correctness (Spearman ρ ~0.20–0.59). The adversary can disagree AND be wrong. The adversary can agree AND be wrong. Neither outcome is reliably diagnostic.

**Do I believe my own argument?** Partially. The cross-family adversary IS better than same-model review — the literature is unambiguous on that. And Converge's design of making the adversary a separate process with fresh context, adversarial framing, and a provenance-stamped log is genuinely well-executed. My objection is that the README presents cross-family as a **sufficient** mechanism when it's only a **helpful** one. The human is the actual barrier. The adversary is a sophisticated linter that catches some fraction of issues. The README should say so.

## GAPS

1. **Proving-ground cases removed from CI.** `CHANGELOG.md` documents the removal of uc-01-analytics-engineering references. The CI gate `test-ci-covers-every-suite.sh` verifies no live references remain. This means the live demonstrations of the full descent — the "proven live" claims — are no longer inspectable. The hermetic test suites prove component behavior, not end-to-end method efficacy. I could not verify a single full-descent run.

2. **Multi-engine dispatch not tested.** `cvg review --adversary codex,kimi` requires installed engine CLIs with valid credentials. My host has the engines installed (`cvg doctor` reports DOCTOR=OK) but I did not dispatch them — doing so would spend tokens, and the prompt forbids mutations. The adversarial review path has hermetic test coverage in `skills/sketch-plans-adversarial-review/tests/run-tests.sh`, but I could not verify it against live engines.

3. **Linear integration not tested.** `cvg register --tracker linear` requires `LINEAR_API_KEY`. The `fake` adapter provides offline test coverage (145 checks per `bin/README.md:101-102`), but the real Linear adapter's behavior against the live API is unverified in this review.

4. **Cockpit browser tests not run.** `npm run test:browser` requires Playwright and a running dev server. CI runs these — I could not. The axe accessibility checks and multi-viewport tests are verified by CI but not by this review.

5. **Large artifacts not exhaustively reviewed.** `docs/converge.pdf` (generated from `docs/converge-deck.html`) — the deck appears to have been modified in the working tree (16 unstaged changes in `apps/cockpit/` and `docs/`). The PDF and HTML are present but I did not audit their claims against the code.

6. **Knowledge-graph bash source edges.** The graphify-out graph's bash `source` resolution only resolves plain same-dir variables — ~19 of 21 real importers of `_lib.sh` are unrepresented. I verified blast-radius claims against source directly rather than through graphify for this reason.

7. **Tavily/Firecrawl not available.** My harness does not expose Tavily or Firecrawl MCP tools (they are listed in the tool inventory but attempts to use them would likely fail). Web research was conducted via `web_search` only. Some competitor analysis that would benefit from deep crawling (e.g., PR-AF's full feature set vs. Converge) was limited to surface-level results.

8. **Git working tree is dirty.** 16 unstaged modifications and 4 untracked files exist in the repo at review time. These are Cockpit and docs changes the author is working on. I did not review these changes — they may address some findings or introduce new ones.

REVIEW=deepseek:DONE