# grok

RUN: 2026-08-04 · files read: 48 · external sources cited: 11

## FINDINGS

### F-grok-01 — Sensitive work is labeled "tier-2 REQUIRED" then settled without it

- SURFACE: method
- SEVERITY: critical
- CONFIDENCE: high
- EVIDENCE: `skills/task-spec/scripts/classify-lane.py:91-96` · `skills/task-spec/scripts/classify-lane.py:128` · `skills/task-to-runtime-contract/scripts/cost-profile.py:61-67` · `skills/task-loop/scripts/loop-kernel.sh:300-302` · `skills/task-loop/scripts/loop-kernel.sh:977-978` · `README.md:190-192` · reproduction: `python3 skills/task-spec/scripts/classify-lane.py "fix auth login token leak" --paths "auth/login.py"` prints `verify    tier-2 independent verification is REQUIRED` and `LANE=NORMAL`; `python3 skills/task-to-runtime-contract/scripts/cost-profile.py --effort M --lane NORMAL` prints `COST_VERIFY=false`
- CLAIM: Auth/money/secret work is forced off FAST into NORMAL with `verification_required=true`, but the loop only enables tier-2 from `COST_VERIFY` (FULL-only) or an explicit `--verify`/`--judge`, so the default settlement path for sensitive work is sealed-eval alone.
- WHY IT MATTERS: The user is told the risky surface requires independent refutation; the unattended command the README quickstart prints (`cvg loop --issue … --agent claude`) does not run it. The product's load-bearing trust claim fails on the work that most needs it.
- FALSIFIER: A NORMAL-lane loop with a sensitive hard floor enables tier-2 without `--verify`, or `verification_required` from `classify-lane` is read by `loop-kernel.sh` and fails closed when false.
- MOVE: Wire `verification_required` (or hard floors) into `loop-kernel.sh` the same way `COST_VERIFY` is applied; flip `NORMAL` cost-profile verify for floors, or refuse settlement when floors say required and VERIFY is off. Files: `skills/task-loop/scripts/loop-kernel.sh`, `skills/task-to-runtime-contract/scripts/cost-profile.py`, `skills/task-spec/scripts/classify-lane.py`, `README.md` quickstart.
- EVAL: ```bash
set -euo pipefail
out="$(python3 skills/task-spec/scripts/classify-lane.py 'fix auth login token' --paths 'auth/x.py')"
echo "$out" | grep -q 'verification is REQUIRED'
lane="$(echo "$out" | sed -n 's/^LANE=//p')"
cost="$(python3 skills/task-to-runtime-contract/scripts/cost-profile.py --effort M --lane "$lane")"
echo "$cost" | grep -q 'COST_VERIFY=true'
```

### F-grok-02 — Holdout lives in the same file the worker is ordered to open

- SURFACE: method
- SEVERITY: critical
- CONFIDENCE: high
- EVIDENCE: `skills/task-to-runtime-contract/references/verification.md:35-38` · `skills/task-spec/SKILL.md:564-569` · `skills/task-to-runtime-contract/scripts/verify-work.py:75-77` · `skills/task-loop/scripts/loop-kernel.sh:854-855` · `skills/task-loop/scripts/engines/claude.sh:9-11` · https://arxiv.org/html/2605.21384v1 (retrieved 2026-08-04) — "The held-out suite, hidden from the agent, composes those same features"
- CLAIM: Marketing and docs say holdout criteria are criteria "the implementer never saw," but holdouts are an optional `## Holdout` section inside the sealed Task-Spec, and the loop brief tells the worker that file is "the only instruction source" and to open it.
- WHY IT MATTERS: Train/test separation only works if the agent cannot read the holdout. Co-location turns "held out" into a polite section heading. SpecBench's whole measurement of coding-agent reward hacking depends on suites the agent cannot see; Converge does not enforce that boundary.
- FALSIFIER: Holdouts are stored outside the worker-readable path (separate sealed artifact, env-injected at verify only) and engine adapters refuse to feed the Task-Spec body containing them.
- MOVE: Extract holdouts to `cvg/execution/<id>/holdout.md` (mode 0600, not in fs.write, not pointed at by the brief); strip `## Holdout` from any worker-visible copy; make `verify-work.py` the only reader. Files: `verify-work.py`, `render_task_brief` in `_runtime_contract.py`, `loop-kernel.sh` brief, `task-spec` template + SKILL.md.
- EVAL: ```bash
# fails today if any shipped doc claims holdouts are invisible while the loop points at the full Task-Spec
grep -n 'only instruction source' skills/task-loop/scripts/loop-kernel.sh
grep -n 'never saw' skills/task-to-runtime-contract/references/verification.md
# and no separate holdout path exists:
! test -f skills/task-to-runtime-contract/scripts/write-holdout.py
```

### F-grok-03 — Cross-family is the headline defense; default lanes leave it off

- SURFACE: method
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `README.md:54-57` · `skills/task-to-runtime-contract/scripts/cost-profile.py:53-75` · `skills/task-loop/scripts/loop-kernel.sh:92-94` · `skills/task-loop/scripts/loop-kernel.sh:977-978` · `tests/test-loop-kernel.sh:296` · comment contradiction at `loop-kernel.sh:92-94` ("Tier-2 is ON by default") vs `VERIFY=false`
- CLAIM: The README's differentiation bullet is cross-family verification; FAST and NORMAL cost profiles set `verify: False`, the kernel initializes `VERIFY=false`, and the kernel's own hermetic suite greps for `tier 2 ── not requested`.
- WHY IT MATTERS: Users adopt Converge for the adversarial check. They get sealed bash evals unless they remember a flag or draw FULL. An opt-in load-bearing control is a brochure feature.
- FALSIFIER: Default `cvg loop --issue X --agent claude` (no lane, no flags) runs tier-2 when a second family is installed, or README demotes the claim to "available behind `--verify` / FULL."
- MOVE: Either default VERIFY on whenever `cvg doctor` sees ≥1 cross-family engine, or rewrite README "Why it's different" and the Status bullet to match the opt-in reality. Smallest code fix: NORMAL→`verify: True` when a second engine exists. Files: `cost-profile.py`, `loop-kernel.sh`, `README.md`.
- EVAL: ```bash
# README claims cross-family as differentiation while NORMAL defaults off
grep -q 'Cross-family verification' README.md
python3 skills/task-to-runtime-contract/scripts/cost-profile.py --effort M --lane NORMAL | grep -q 'COST_VERIFY=false'
```

### F-grok-04 — Literature does not support "different family ⇒ independent judge"

- SURFACE: method
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `skills/task-to-runtime-contract/references/verification.md:28-33` · https://arxiv.org/html/2410.21819v1 (retrieved 2026-08-04) — "LLMs assign significantly higher evaluations to outputs with lower perplexity … regardless of whether the outputs were self-generated" · https://ar5iv.labs.arxiv.org/html/2604.06996 (retrieved 2026-08-04) — "judges can be up to 50% more likely to incorrectly mark them as satisfied when the output is their own" · https://arxiv.org/html/2607.28636v1 (retrieved 2026-08-04) — "standalone bias resistance does not predict audit effectiveness" / best auditor is bias-specific
- CLAIM: Converge treats different-vendor family as the independence invariant; the LLM-as-judge literature shows self-preference is largely familiarity/perplexity (and persists on objective rubrics), and cross-family auditor quality is bias-specific—not a binary family check.
- WHY IT MATTERS: A REFUTED or UPHELD token is treated as settlement evidence. If the independence model is wrong, the receipt manufactures confidence the way an optimistic verifier does—the failure mode `verification.md` itself names.
- FALSIFIER: Converge measures judge agreement against programmatically verifiable holdouts (SpecBench-style) and shows family-mismatch reduces false UPHELD relative to same-family by a reported margin; or docs demote family to one of several weak signals.
- MOVE: Keep family as a minimum bar; add (a) require mechanical holdout suite when present, (b) optional multi-judge / jury, (c) record judge model id + independence strength on the receipt, (d) stop equating `independent` with "full strength" in docs. Files: `verification.md`, `verify-work.py`, settlement receipt writer.
- EVAL: not mechanically checkable — requires a graded corpus of known-gamed diffs; the defect is a method claim vs literature, not a missing assert.

### F-grok-05 — "Zero runtime dependencies" is false on the signing path

- SURFACE: install
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `README.md:15` · `README.md:149-150` · `bin/cvg:1247-1252` · `skills/task-spec/scripts/safe-to-delegate.sh:157` · `package.json:2-4` ("zero runtime dependencies") · `CHANGELOG.md:44-49` (lint needs bash 4+ on stock macOS)
- CLAIM: The badge and package description say zero runtime dependencies / bash 3.2+; signing always invokes shellcheck, bind/verify need python3, lint needs bash 4+, and `doctor host` exists because CI-installed shellcheck made green CI lie about a bare macOS host.
- WHY IT MATTERS: A new macOS user follows the install doors, hits `DOCTOR_HOST=MISSING` / cannot stamp Tier-1, and distrusts every other claim that was oversold the same way.
- FALSIFIER: A clean macOS image with only stock bash 3.2 + git can `cvg setup signing` → `tasks gate --stamp` → `bind` without brew packages; or README requirements list shellcheck + python3 + bash 4 for lint as first-class deps.
- MOVE: Replace "zero runtime dependencies" with an honest matrix (core / sign / bind / lint / cockpit). Make shellcheck optional with a clear DEGRADED tier rather than an unconditional gate hard-block, or ship it as a documented required tool next to git. Files: `README.md`, `package.json`, `.claude-plugin/plugin.json`, `safe-to-delegate.sh` if soft-fail path is chosen.
- EVAL: ```bash
grep -E 'zero runtime dependencies' README.md package.json .claude-plugin/plugin.json
# still claims zero deps while doctor host documents shellcheck as load-bearing:
grep -q 'shellcheck' bin/cvg
```

### F-grok-06 — HMAC is marketed as autonomy seal; skill admits it is not a security boundary

- SURFACE: foundation
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `README.md:427-429` · `skills/task-spec/SKILL.md:559-562` · `skills/task-spec/scripts/_lib.sh:585-627` · `skills/task-spec/configs/setup-taskspec-signing-key.sh:13-18` · `skills/task-loop/scripts/engines/claude.sh:39-40` (`--permission-mode acceptEdits`) · `.cvg/gate.yaml:19` protects `**/.git/**` for writes, not key confidentiality from a shelling agent
- CLAIM: README FAQ says editing an eval breaks the seal so autonomy requires the gate; SKILL.md states the envelope is "tamper-evident, not tamper-proof" with a repo-shared key under `.git/info/`. A worker with shell can `cat $(git rev-parse --git-common-dir)/info/taskspec-signing-key` and re-stamp.
- WHY IT MATTERS: Users who believe HMAC stops a misaligned agent from rewriting its own grade are wrong. They have a drift detector against accidental edits, not a referee the player cannot forge.
- FALSIFIER: Signing key is unavailable inside the worker sandbox (OS keychain / remote HSM / separate host CI re-sign only), and engines cannot invoke `tasks gate --stamp`.
- MOVE: Align README with SKILL.md language; move Tier-1 stamp to a human/CI identity outside the worker; treat in-loop re-stamp as `CHECK_GATE=FORBIDDEN`. Files: `README.md`, signing setup, path policy / capability envelope for stamp verbs.
- EVAL: ```bash
grep -q 'tamper-evident, not tamper-proof' skills/task-spec/SKILL.md
# README FAQ still sells seal-as-autonomy without the admission:
grep -A3 'Why signed specs' README.md | grep -vq 'tamper-evident'
```

### F-grok-07 — Gold-sanity (the Goodhart guard) is opt-in while reward-hacking is the stated threat model

- SURFACE: tests
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `skills/task-spec/scripts/accept-task.sh:41-57` · `skills/task-spec/scripts/accept-task.sh:314` · https://arxiv.org/html/2605.21384v1 (retrieved 2026-08-04) — "high validation scores can substantially overestimate true specification compliance" · `skills/task-to-runtime-contract/references/verification.md:5-14`
- CLAIM: POST-accept's GATE E (evals must fail on unpatched baseline) is off by default "so existing callers are unchanged," while the method docs and external SpecBench results treat non-discriminating evals as the central failure mode.
- WHY IT MATTERS: A task can accept with evals that were always green. Settlement then certifies a thermometer that never moves.
- FALSIFIER: `accept-task.sh` without flags runs gold-sanity when git is available, or `tasks gate --stamp` refuses evals that pass on empty worktree fixtures.
- MOVE: Default `--gold-sanity` on when git works; keep `--no-gold-sanity` as the explicit escape. File: `accept-task.sh`, wire through `cvg tasks accept`.
- EVAL: ```bash
grep -q 'OFF by default' skills/task-spec/scripts/accept-task.sh
grep -q 'gold-sanity' skills/task-spec/scripts/accept-task.sh
# default path does not pass the flag:
grep -n 'accept-task' bin/cvg | head -5
```

### F-grok-08 — agent-context says "8-pass"; product says nine gates

- SURFACE: cli
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `bin/cvg:2594` ("8-pass method") · `README.md:32` ("nine-gate") · `README.md:270` ("The nine passes") · `skills/README.md:3-4` (nine spine skills including Capture ⓪)
- CLAIM: The machine-readable self-description agents are told to trust disagrees with the human surface on the number of passes.
- WHY IT MATTERS: Agents steering from `cvg agent-context --json` plan the wrong chain; humans reading README plan another. The referee's own manifest is the wrong map.
- FALSIFIER: `cvg agent-context --json | jq -r .description` matches the README pass count and names pass 0 as optional rather than dropping it.
- MOVE: One sentence in the embedded Python manifest in `bin/cvg` plus a version-unity-style string check. Files: `bin/cvg`, optionally `tests/test-version-unity.sh` or a tiny agent-context contract test.
- EVAL: ```bash
cvg agent-context --json | python3 -c 'import json,sys; d=json.load(sys.stdin)["description"]; assert "9-pass" in d or "nine" in d.lower(), d'
```

### F-grok-09 — "21 hermetic suites" undercounts what CI actually wires

- SURFACE: docs
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `README.md:382` · suite inventory via `find tests skills … test-|run-tests` → 30 candidates · `.github/workflows/ci.yml:152-275` (many more named steps) · `tests/test-ci-covers-every-suite.sh` (coverage gate exists; README number is free-floating)
- CLAIM: Status section freezes "21 hermetic suites" while the coverage gate and workflow already run a larger, different set (≈30 shell suites plus Python gate policy, cockpit job, shellcheck, skill validation).
- WHY IT MATTERS: A stale pride number trains readers to stop checking. The project already invented the fix (`test-ci-covers-every-suite.sh`) and then left the human claim unhooked from it.
- FALSIFIER: README prints the same TOTAL the coverage script prints, or links "see CI_COVERAGE" with no integer.
- MOVE: Delete the integer; replace with "every suite under tests/ and skills/*/tests is wired (enforced by test-ci-covers-every-suite.sh)". File: `README.md`.
- EVAL: ```bash
n=$(find tests skills -type f -name '*.sh' | grep -E '/(test-[^/]+|run-tests)\.sh$' | grep -vc 'test-ci-covers-every-suite\|/conformance/')
grep -E '21 hermetic' README.md && test "$n" -ne 21
```

### F-grok-10 — skill-creator is method-adjacent bloat shipped to every consumer

- SURFACE: skills
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `skills/README.md:310-316` · `wc -l` ≈2059 lines under `skills/skill-creator/scripts` · `install.sh:195` copies validator from skill-creator into every target · CI step `companions` runs its suite · not on the pass chain in `skills/README.md` mermaid
- CLAIM: Anthropic's skill-authoring toolkit is vendored as a full skill package and installed into consumer repos so `quick_validate.py` can run; consumers of the *delivery* method get a second product (skill authoring/eval loops) they did not ask for.
- WHY IT MATTERS: Install surface, CI time, and agent skill discovery noise grow for a capability orthogonal to "compile intent into shipped software." Reviews that only add are how tools get fat—this is already fat.
- FALSIFIER: skill-creator is not installed by default, or only `quick_validate.py` is shipped as a 50-line dependency without the eval-loop Python agents.
- MOVE: Extract `quick_validate.py` (and its minimal deps) to `bin/` or `skills/_validate/`; drop skill-creator from default `install.sh` copy set; keep it as a devExtra in this monorepo only. Files: `install.sh`, `skills/README.md`, CI companions step.
- EVAL: ```bash
# default install surface still includes the authoring toolkit
grep -q 'skill-creator' install.sh
test -d skills/skill-creator
```

### F-grok-11 — pass-to-lesson adds a parallel gate vocabulary for an optional companion

- SURFACE: skills
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: `skills/README.md:295-308` · `skills/pass-to-lesson/` (220-line SKILL + gate) · `bin/cvg` / `cvg lesson` surface · CHANGELOG pattern of "missing door" fixes for lesson
- CLAIM: An optional teaching companion owns `CHECK_LESSON`, seven exact section names, discovery rules, and CI—while the method text insists it never blocks the descent.
- WHY IT MATTERS: Optional-but-gated creates maintenance tax and agent confusion ("is lesson part of done?"). The same energy could document decisions inside ADRs/Task-Specs the chain already requires.
- FALSIFIER: Lesson is pure markdown guidance with no machine token, or it is required after each pass and appears on the descent diagram as a real pass.
- MOVE: Demote to a reference doc + prompt under `docs/`; remove `cvg lesson` from the primary command map or mark clearly `OPTIONAL / non-blocking` in agent-context. Files: `bin/cvg`, `skills/pass-to-lesson/`, `skills/README.md`.
- EVAL: ```bash
cvg agent-context --json | python3 -c 'import json,sys; cmds=json.load(sys.stdin)["commands"]; print(any(c["name"].startswith("lesson") for c in cmds))'
# true today — optional companion still first-class in the manifest
```

### F-grok-12 — Public install doors and badges assume a public GitHub repo

- SURFACE: install
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: `README.md:10-11` (Actions badge) · `README.md:109-126` (marketplace / `npm i -g github:…` / `curl … raw.githubusercontent.com/…/main/install.sh`) · `package.json:28-32` · review brief: repository is private and not indexed (operator statement this session)
- CLAIM: Every non-clone install path and the CI badge point at `github.com/luanmorenommaciel/converge` as if it were a public distribution channel.
- WHY IT MATTERS: Outside collaborators and "curl | bash" users hit 404/auth walls; the README still reads as a shipped open product. That is a trust break before any gate runs.
- FALSIFIER: Repo is public and anonymous `curl -fsI https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh` returns 200, or README install section documents private-only clone + path install first.
- MOVE: Lead with `git clone` / path install / private-package registry; badge the private Actions URL correctly or drop public badges until publish. Files: `README.md`, `package.json` repository fields.
- EVAL: ```bash
code=$(curl -s -o /dev/null -w '%{http_code}' https://raw.githubusercontent.com/luanmorenommaciel/converge/main/install.sh || true)
# non-200 while README still advertises the curl door:
grep -q 'raw.githubusercontent.com/luanmorenommaciel/converge' README.md && test "$code" != 200
```

### F-grok-13 — Practitioners want falsifiable done; Converge answers that and ignores the other top complaints

- SURFACE: docs
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: https://x.com/loganthorneloe/status/2084686819795574890 (retrieved 2026-08-04) — "making agents provide proof of their assumptions and output" · https://x.com/_kvnloo/status/2082738101777285445 (retrieved 2026-08-04) — "agents don't hallucinate the work. they hallucinate the *report* of the work" · https://x.com/hkarthik/status/2039538965162889658 (retrieved 2026-08-04) — overnight agents produced "a weeks worth of slop" · competitor landscape via https://moclaw.ai/blog/devin-ai-alternative-2026-guide (retrieved 2026-08-04) — Devin, Cursor, OpenHands, SWE-agent, Aider as daily tools · `README.md:396-397` Manager / CI eval-gate still missing
- CLAIM: The live complaint Converge uniquely addresses is false "done"; the complaints it does not address—slop volume, overnight cost, multi-task fleet control, IDE-native flow—are exactly where Devin/Cursor/OpenHands compete, and Converge's nine-pass ceremony amplifies time-to-first-green without the Manager.
- WHY IT MATTERS: Positioning as "the dark factory" without fleet dispatch or low-ceremony defaults cedes the actual adoption funnel to tools that ship a worse proof model but a better day-1 experience.
- FALSIFIER: A documented path from zero to settled PR for a one-file fix under 15 minutes with FAST defaults, tier-2 when available, and a scheduled multi-task runner—or explicit non-goals that refuse the dark-factory metaphor.
- MOVE: Make FAST the documented default story in README (not FULL narrative); ship a thin `cvg ready | head -1 | xargs cvg loop` recipe as interim Manager; measure time-to-first-SETTLED in clean-room e2e. Files: `README.md`, optional `scripts/run-frontier.sh`.
- EVAL: not mechanically checkable — positioning vs market complaints; clean-room wall-clock could become a metric later.

### F-grok-14 — bin/cvg is a 2,677-line single router that re-encodes the whole product

- SURFACE: cli
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `wc -l bin/cvg` → 2677 · `bin/README.md:72-73` · agent-context embedded as a large Python string near `bin/cvg:2590+` · repeated discovery/root-resolution lessons documented in `bin/README.md:136-145`
- CLAIM: The "wrap, don't rewrite" rule is right, but the router has become a second encyclopedia (help text, doctor narratives, full manifest) that will drift from skill scripts the same way README integers drift.
- WHY IT MATTERS: Every future subcommand pays merge-conflict tax in one file; agent-context already drifted to "8-pass." Simplification, not another doctor.
- FALSIFIER: Commands are thin `exec` stubs; manifest is generated from a schema file both help and agent-context read; line count of `bin/cvg` < 800.
- MOVE: Generate `agent-context` from a `contracts/cli/commands.yaml`; move doctor prose into `bin/doctor/*.sh`. Files: `bin/cvg`, new contract file, CI check that manifest matches yaml.
- EVAL: ```bash
test "$(wc -l < bin/cvg)" -lt 1200
```

## KILL LIST

1. **Default-install skill-creator package** — keep `quick_validate.py` only; stop shipping Anthropic's skill eval harness to every consumer (`install.sh`, `skills/skill-creator/`). Evidence: F-grok-10.
2. **Integer pride stats in README** ("21 hermetic suites", and any future suite counts) — replace with the coverage gate's live total or no number. Evidence: F-grok-09 · `README.md:382` · `tests/test-ci-covers-every-suite.sh`.
3. **Dual "Tier-2 is ON by default" comment** next to `VERIFY=false` — delete the lie or flip the default. Evidence: `skills/task-loop/scripts/loop-kernel.sh:92-94`.
4. **control-room:\* npm script aliases** once the one-release window ends — already marked legacy in `README.md:97-98`; kill on schedule so package.json stops carrying two names for one app.

## BLIND SPOT

**He cannot see that the worker is trusted with the entire trust root.** The system was built by a careful human who stamps seals, keeps the signing key in `.git/info/`, puts holdouts in the Task-Spec, and runs agents with `acceptEdits` on the same machine. Every control assumes the agent will not read the key, will not open the Holdout section, will not re-invoke the gate, and will not edit evals outside path policy—assumptions that have been true for *him* since day one because *he* is the adversary model. The dark-factory pitch requires the opposite assumption: the agent is the untrusted player. The HMAC admission in `skills/task-spec/SKILL.md:559-562` is the crack of daylight; the README and default loop still operate as if the crack is not there.

## STRONGEST OBJECTION

**Target: "the referee is never a player" (`README.md:52-53`, `bin/cvg` role: referee).**

Argument it is wrong: A referee that does not hold API keys still *chooses* when the game ends by defining sealed evals, path fences, budget axes, and optional judges. More sharply: the same human/org that authors Task-Specs also owns the HMAC key, the gate.yaml, and the CI that re-runs suites. That is not separation of powers; it is one party writing the rules, signing them, and employing the athletes. Real adjudication (sports, certifiers, SLSA builders vs. signers) splits those roles across organizations. Converge's referee is a local scoring library with strong rhetoric. When tier-2 is off (the common path), the "referee" is a bash exit code on tests the player helped design—functionally closer to a coach's stopwatch than to an independent official. Cross-family verify, when it runs, reintroduces a second model as a player-judge, which the architecture both depends on and disclaims.

Do I believe this? **Partially.** The no-credentials split is real and valuable against secret exfiltration and silent vendor lock-in. The stronger claim—that completion is therefore non-self-graded—is only true when evals are discriminating *and* holdouts are invisible *and* tier-2 runs. Those three are each optional or unenforced today, so the proud separation collapses to a style guide unless the defaults in F-01–F-03 land.

## GAPS

- Did not run live engine tier-2 or a full `cvg loop` (would call models / mutate worktrees).
- Did not mutate with `cvg init` / `setup signing` in this checkout (`cvg next` → `NEXT_PASS=USAGE_ERROR` with no workspace).
- Did not open PDFs (`docs/converge-v0.1.pdf`, `docs/task-spec-v0.1.pdf`) beyond listing them; trust order said PDFs rank below code.
- Did not re-verify private-repo HTTP status beyond the operator's private-repo constraint + public URL claims (F-12 CONFIDENCE medium).
- graphify was on PATH; one query on HMAC resolution returned noisy/truncated nodes—blast-radius claims confirmed against source instead.
- MCP: Linear/Notion/magic/ref unavailable; used Tavily, Exa, X search, and local reads.
- Cockpit Ask/ACP path (modified on branch) not deeply re-audited; observation-only claim taken from `apps/cockpit/README.md` only.
- Did not measure real SpecBench-style gaming rates on Converge evals—literature cited, product not re-benchmarked.

REVIEW=grok:DONE
