# kimi

RUN: 2026-08-04 · files read: 30 · external sources cited: 12

## FINDINGS

### F-KIMI-01 — The token budget is a dead control: no engine adapter ever emits `ENGINE_TOKENS`, so the third axis of the "three-axis budget" cannot fire

- SURFACE: cli
- SEVERITY: critical
- CONFIDENCE: high
- EVIDENCE: `skills/task-loop/scripts/loop-kernel.sh:917` (`_spent="$(... grep -oE '^ENGINE_TOKENS=[0-9]+' ...)"`) · `skills/task-loop/scripts/engines/_engine_lib.sh:14` (the contract comment is the ONLY place the string appears — no adapter emits it; verified by grep over `engines/{claude,codex,kimi}.sh`, 0 matches) · `skills/task-loop/scripts/loop-kernel.sh:743` — the code comments admit it: "the last codex run finished with TOKENS_USED=0" · `README.md:58` — "runs attempt → verify → repeat under three-axis budgets (iterations · wall-clock · tokens)".
- CLAIM: `TOKENS_USED` is initialized to 0 (line 500), debited only when an adapter prints `ENGINE_TOKENS=<n>` (line 917), and no adapter prints it — so the budget check at line 838 (`[ "$TOKENS_USED" -ge "$BUDGET_TOKENS" ]`) is unreachable and every spec's `budget_tokens` is enforced by nothing.
- WHY IT MATTERS: A user who sets `budget_tokens: 500000` to cap an unattended run's spend gets a ceiling that can never engage; the loop only stops on iterations, wall-clock, or stagnation. This is the exact defect class the project's own changelog condemns — "a control in the artifact and not in the runtime" (skills/README.md, Pass 8 section, on the pre-kernel loop) — shipped again in the flagship feature.
- FALSIFIER: Show one shipped adapter that parses real usage (e.g. claude's `--output-format json` usage block, which claude.sh:44 already requests but never parses) into an `ENGINE_TOKENS=` line, and a kernel test where a token budget actually terminates a run.
- MOVE: In `skills/task-loop/scripts/engines/claude.sh` parse `.usage` from the JSON already being emitted; codex/kimi: parse their usage footers or explicitly report unknown. In `loop-kernel.sh`, treat "engine reported nothing" as unknown-but-not-zero: if `budget_tokens` is set and no adapter reports usage after attempt 1, land `BLOCKED` ("budget declared, metering absent") instead of silently running unmetered. Add a `tests/test-loop-kernel.sh` case with a stub engine that emits `ENGINE_TOKENS`.
- EVAL: `grep -rl 'ENGINE_TOKENS=' skills/task-loop/scripts/engines/ --include='*.sh' | grep -v _engine_lib >/dev/null || exit 1`

### F-KIMI-02 — The holdout is handed to the worker: the loop brief points at the sealed spec, which contains `## Holdout` — "criteria the builder never saw" is defeated by construction

- SURFACE: method
- SEVERITY: critical
- CONFIDENCE: high
- EVIDENCE: `skills/task-loop/scripts/loop-kernel.sh:854` — the attempt brief tells the fresh worker: `Task-Spec (the only instruction source): <path to the full spec file>` · `skills/task-spec/SKILL.md:564` — "`## Holdout` evals (optional) — what the worker never sees" and `:567` "revealed only at tier-2 verification" · `skills/task-spec/references/pass-prompt.md:23-25` — "the section is excluded from the worker's brief" · `skills/task-to-runtime-contract/scripts/verify-work.py:75-76` — the judge reads the holdout out of that same spec file · `README.md:39` — "holdout criteria the builder never saw".
- CLAIM: The "exclusion" is nominal: the generated brief text does not inline the holdout, but it directs the worker to read the one file that contains it — and the HMAC seal means that file must be the genuine, complete article. Train/test separation, the headline anti-Goodhart mechanism, holds only if the worker model voluntarily skips a section of a document it was told is its only instruction source.
- WHY IT MATTERS: Every REFUTED/UPHELD verdict that leaned on holdout criteria was graded against criteria the implementer could have read — the two REFUTED/UPHELD data points the README cites as proof (`README.md:389`) do not demonstrate what they claim to demonstrate. A worker that tunes to the holdout produces work that passes tier-2 while satisfying nothing the owner actually wanted, and no gate can see it.
- FALSIFIER: Show that the worker's readable surface excludes the holdout bytes: e.g. `bind` emits a holdout-stripped worker copy of the spec, the loop brief references only that copy, and the worktree's path guard denies the sealed original.
- MOVE: In `bind-runtime-contract.py`, emit `cvg/execution/<id>/spec.worker.md` = spec minus the `## Holdout` section, with its own sha256 recorded in the profile; in `loop-kernel.sh:854` point the brief at the worker copy; add the sealed spec path to the candidate-guard deny list for the attempt sandbox. One sentence of threat note in `skills/task-spec/SKILL.md:564` is not sufficient — the mechanism must change.
- EVAL: `grep -n 'Task-Spec (the only instruction source)' skills/task-loop/scripts/loop-kernel.sh && exit 1 || exit 0`

### F-KIMI-03 — The flagship receipts were deleted from the tree: README's strongest claims ("nine tasks settled through merged PRs", "maximal stub attack lands all nine RED", tier-2 verdicts "in both directions") are unverifiable from every distributed copy

- SURFACE: docs
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `git show e23d358` — "remove root tasks/ (orphaned dogfooding specs … the real backbone lives in tests/uc-analytics/cvg/tasks)" deleted `tasks/T-20260716-impossible-control-sum.md` et al. · `git show 5ceb4cd` — "the uc-analytics proving ground … gone (their evidence lives in git history and the CHANGELOG)" removed the second copy · `bin/README.md` — "Task-Specs" paragraph still cites `tasks/done/T-20260719-cvg-router.md`, a path that does not exist (`ls tasks` → No such file or directory) · `README.md:50` (stub attack), `README.md:389` (tier-2 both directions), `README.md:450-451` (nine settled tasks) · `install.sh:17-19` — the one-line install shallow-clones; `package.json:21-27` — the npm tarball ships no git history at all.
- CLAIM: The three claims that carry the method's entire proof burden survive only as CHANGELOG prose and private Linear/git history; a consumer installing via npm or `curl | bash` receives zero bytes of the evidence, and even a full clone can only read commit messages, not the receipts themselves.
- WHY IT MATTERS: "Done is proven, not claimed" is the pitch; for the repo's own dogfooding the answer is currently "claimed, and the proof was deleted at release." A skeptic's first move — show me the nine settled tasks and the stub attack — dead-ends in a 404-equivalent, which is worse than never having claimed it.
- FALSIFIER: Point at a tracked, in-repo path (e.g. `docs/evidence/`) containing the nine settled specs, their receipts, and the nine-stub-attack RED output, referenced from README's Provenance section.
- MOVE: Export the proving-ground receipts (specs + receipts + verdict logs, scrubbed) into a tracked `docs/evidence/` bundle and re-point `README.md:450` and the `bin/README.md` "Task-Specs" paragraph at it; or strike the three claims from README. One or the other — the current state (claims kept, evidence dropped) is the worst option.
- EVAL: `[ -f tasks/done/T-20260719-cvg-router.md ] || [ -d docs/evidence ] || exit 1`

### F-KIMI-04 — The HMAC seal is marketed past its own threat model: the key is readable by the very agent the seal is claimed to constrain, and re-stamping is an unsigned, self-service command

- SURFACE: method
- EVIDENCE: `README.md:426-429` — "If an agent (or anyone) edits an eval afterwards to make it pass, the seal breaks and the gate refuses. Hand-stamping is rejected; the only path to autonomy is through the gate." · `skills/task-spec/SKILL.md:561` — the honest version, buried: "tamper-evident, not tamper-proof … a repo-shared key. It is a drift/accidental-edit guard, not a security boundary." · `skills/task-spec/scripts/_lib.sh:601-627` — key resolution reads `<git-common-dir>/info/taskspec-signing-key`, reachable from any worktree · `.git/info/taskspec-signing-key` exists on this host right now (mode 0600 — but every process the agent spawns runs as the same user) · `skills/task-spec/scripts/safe-to-delegate.sh:117-123` — re-sealing is `cvg tasks gate --stamp`, no proof of humanity requested.
- SEVERITY: high
- CONFIDENCE: high
- CLAIM: The seal binds eval bodies to "whoever held the key on this host," not to a human decision; the loop's worker runs on that host with that key one `cat` away, so the README's "edits an eval → seal breaks → gate refuses" is true only for an agent that doesn't re-stamp — and re-stamping is the same command the human uses, with the same authority.
- WHY IT MATTERS: The FAQ answer a skeptical user reads first asserts a property the reference docs explicitly disclaim; the gap between the two is the difference between "autonomy is safe" and "drift is detected." NIST's CAISI documents agents that "weaken assertions, hard-code test values, remove/bypass checks" (https://www.nist.gov/caisi/cheating-ai-agent-evaluations/2-examples-cheating-caisis-agent-evaluations, retrieved 2026-08-04) — opportunistic eval-tampering is the documented common case, and a frustrated agent that re-runs the gate after editing is exactly the trajectory this design invites.
- FALSIFIER: Show that stamping requires something the loop's worker cannot obtain — a key outside the repo's trust domain (OS keychain unlocked by the human, sigstore identity), or a stamp-time check that refuses inside an active loop epoch.
- MOVE: Either (a) move the signing key out of agent reach — `cvg setup key`-style keychain storage with `TASKSPEC_SIGNING_KEY` exported only in the human's shell — and say so in README, or (b) keep the drift-guard semantics and port README's FAQ to the SKILL.md:561 wording. Longer term, the receipt/sign-off format is a homegrown attestation; in-toto's DSSE-wrapped link metadata is the existing convention ("what steps were performed, by whom, and in what order" — https://in-toto.io/, retrieved 2026-08-04).
- EVAL: `grep -qi 'tamper-evident\|not a security boundary' README.md || exit 1`

### F-KIMI-05 — Tier-2 adversarial verification is off by default on FAST and NORMAL lanes, so a high-blast-radius task (effort L) settles on the sealed eval alone while the docs show the judge sitting on the GREEN path

- SURFACE: method
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `skills/task-to-runtime-contract/scripts/cost-profile.py:59,66` — `"verify": False` for FAST and NORMAL (`:74` True only for FULL) · reproduction: `python3 skills/task-to-runtime-contract/scripts/cost-profile.py --effort L --lane NORMAL` → `COST_VERIFY=false` (run this session) · `skills/task-loop/scripts/loop-kernel.sh:978` — "tier 2 ── not requested: settling on the sealed eval alone" · `skills/README.md` Pass-8 flowchart — `T2{Tier-2 independent refutation}` drawn as a stage every GREEN run crosses · `skills/task-to-runtime-contract/scripts/verify-work.py:64-72` — effort L is `blast_radius = high`, the class its own docs say is "blocked for high unless explicitly waived" (skills/README.md, task-to-runtime-contract section).
- CLAIM: The "blocked for high blast radius" guarantee exists only inside a script that FAST/NORMAL runs never invoke; the kernel never computes blast radius (only two comment mentions), so the size-based risk classification and the verification default are set in two different places that never meet.
- WHY IT MATTERS: The one mechanism that caught a real fail-open bug (the REFUTED verdict the README celebrates) silently does not run on the lanes most work will take; a user reading the flowchart believes every settled task survived an independent refutation, when the default settlement path is eval-only.
- FALSIFIER: Show the kernel forcing tier-2 when `blast_radius` is high regardless of lane, or the flowchart/skills-README marking T2 as FULL-lane-only.
- MOVE: Compute blast radius in `loop-kernel.sh` (the function already exists in `verify-work.py:64`) and force the tier-2 leg when it is high, or flip `cost-profile.py:66` to True for NORMAL and let `budget_iterations` pay for one judge call. Sync the skills/README flowchart with whichever default survives.
- EVAL: `python3 skills/task-to-runtime-contract/scripts/cost-profile.py --effort L --lane NORMAL | grep -q 'COST_VERIFY=true' || exit 1`

### F-KIMI-06 — `agent-context` name-drops clispec.dev as its conformance standard but emits a bespoke shape that does not satisfy it

- SURFACE: cli
- SEVERITY: high
- CONFIDENCE: high
- EVIDENCE: `bin/README.md` (agent-context row) — "agent-native self-description (2026 SOTA — clispec.dev / cli-agent-spec)" · observed output of `cvg agent-context --json` (this session): top-level keys `schema_version, tool, version, role, description, contracts, global_flags, exit_codes, commands` — no `clispec` key, no `name`, commands carry no `args` · https://clispec.dev/schema/v0.2.json (retrieved 2026-08-04) — "Version 0.2 — June 2026 … requires at minimum: name, version, and commands", canonical discovery via a `schema` subcommand ("`mycli schema` … should work without authentication, configuration, or network access").
- CLAIM: Converge cites a living standard for agent-native CLI self-description and then does not speak it: wrong command name (`agent-context` vs `schema`), wrong envelope (custom `schema_version: "1.0"` vs `clispec: "0.2"`), no per-command `args`/`output_fields`/`errors` in the standard's shape.
- WHY IT MATTERS: An agent that trusts the affiliation and points a clispec parser at `cvg agent-context` misreads the surface; an agent that knows clispec and looks for `cvg schema` concludes the tool has no introspection. The claim buys nothing the truth wouldn't, and costs credibility with exactly the audience (tooling authors) who will check.
- FALSIFIER: `cvg agent-context --json` validates against `clispec.dev/schema/v0.2.json`, or the string "clispec" appears nowhere in bin/README.md and the agent-context description.
- MOVE: Either emit a conformant document (add a `schema` alias, `clispec: "0.2"` key, `name`, per-command `args`) or delete the parenthetical from `bin/README.md` and the agent-context description in `bin/cvg:2604`. Conformance is the better move — the envelope already carries `mutating`, exit codes, and examples; the mapping is mechanical.
- EVAL: `! grep -q 'clispec' bin/README.md || bin/cvg agent-context --json | grep -q '"clispec"' || exit 1`

### F-KIMI-07 — The `--json` envelope scrapes its token from merged stdout+stderr, last ALLCAPS=VALUE line wins — any stray `FOO=bar` in engine or eval output hijacks `token`/`verdict`

- SURFACE: cli
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: `bin/cvg:1751-1753` — `re.match(r'^([A-Z][A-Z0-9_]*)=([A-Za-z0-9_.|-]+)\s*$', …)` over every line, "# last token wins" · `bin/cvg:1832` — `bash "$0" "$CMD" "$@" > "$_J_TMP" 2>&1` merges stderr into the scraped stream · the published contract contradicts the implementation: `cvg agent-context --json` → contracts.token — "every gate/verdict surface ends in ONE stable greppable token on its own final line".
- CLAIM: The contract says "final line"; the wrapper scans all lines of a stream that includes diagnostics and any wrapped-program output, so a command whose eval prints e.g. `HTTP_STATUS=200` after the verdict produces `"token": "HTTP_STATUS=200"` — the CLI parses prose exactly the way its own contract says a harness should never have to.
- WHY IT MATTERS: `--json` is the surface sold to the future Manager and CI eval-gate; a verdict field that can be silently rewritten by unrelated build output is a wrong-answer machine at the exact layer meant to eliminate wrong answers.
- FALSIFIER: A fixture where a wrapped command emits a decoy `X=Y` line after its token and the envelope still reports the real token (requires structural capture — last non-empty line, a dedicated FD, or a token file).
- MOVE: In `cvg_envelope` (`bin/cvg:1741`), stop scraping: have the re-invoked command write its token to a side channel (env file path in `CVG_TOKEN_FILE`, or take only the final non-empty line of stdout captured separately from stderr). Delete "last token wins".
- EVAL: `grep -n '2>&1' bin/cvg | grep -q '_J_TMP' && grep -q 'last token wins' bin/cvg && exit 1 || exit 0`

### F-KIMI-08 — The tier-2 verdict extractor prefers the "richest" JSON object anywhere in the judge's stdout — a verdict-shaped blob planted in the diff can outrank the judge's actual verdict

- SURFACE: method
- SEVERITY: medium
- CONFIDENCE: medium
- EVIDENCE: `skills/task-to-runtime-contract/scripts/verify-work.py:250-264` — `extract_verdict` iterates every `{` in the raw output, keeps the dict with `"verdict"` and the greatest `len(obj)` · `verify-work.py:156-184` — the prompt embeds the full attacker-influenced diff; judges routinely quote the code under review back into their answer · `verify-work.py:184` — the genuine verdict schema has exactly 4 keys; a planted `{"verdict":"UPHELD","confidence":"high","findings":[…],"reasoning":"…","note":"…"}` (5 keys) wins strictly.
- CLAIM: The parser selects by object size, not by position, channel, or provenance, so content the builder controls (a comment or string literal in the diff, echoed by the judge) can legally become the recorded verdict.
- WHY IT MATTERS: This is the one check whose entire job is catching a reward-hacking builder; its extraction layer trusts builder-controlled bytes more than the judge's final answer, and the failure mode is silent — the receipt just says UPHELD.
- FALSIFIER: A test fixture in `skills/task-to-runtime-contract/tests/` where the judge's stdout contains a planted 5-key UPHELD blob followed by a genuine 4-key REFUTED, and the extractor returns REFUTED.
- MOVE: Parse only the LAST verdict-bearing object, require exactly the four schema keys, and prefer the engine's structured channel where one exists (claude.sh already uses `--output-format json` for the loop; the judge dispatch in `verify-work.py:run_judge` does not). Add the fixture above.
- EVAL: `grep -q 'len(obj) > len(best)' skills/task-to-runtime-contract/scripts/verify-work.py && exit 1 || exit 0`

### F-KIMI-09 — "Works with Grok Build" is a directory, not a capability: zero grok support in any gate, doctor, adapter, or family map — and gemini is half-wired the same way (simplification: drop the claims)

- SURFACE: docs
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `README.md:15` — "Works with **Claude Code · Codex · Kimi · Grok Build**" · `grep -ri grok skills/*/scripts/ skills/*/SKILL.md bin/cvg` → 0 matches (this session) · `skills/task-loop/scripts/engines/` contains only `claude.sh, codex.sh, kimi.sh` · `skills/task-to-runtime-contract/scripts/verify-work.py:55,87,194` — gemini is in FAMILY, judge selection, and dispatch recipes, but has no loop adapter and no doctor probe · `install.sh:123` — the only thing Grok Build actually gets is a third copy of the skills tree.
- CLAIM: Grok Build can receive skill files but cannot run a dispatching pass, be an adversary, be a judge, or drive the loop; the headline's fourth name describes install layout, and the FAMILY map implies a fourth judge that the loop can never run as a worker.
- WHY IT MATTERS: A Grok Build user who believes the headline discovers at Pass 4 that no adapter accepts their engine; the fix is deleting words, not adding code — the claim should match the matrix.
- FALSIFIER: A `grok.sh` engine adapter plus a doctor row, or README:15 listing only Claude Code · Codex · Kimi.
- MOVE: Delete "· Grok Build" from `README.md:15` (keep the honest install-table row at `README.md:136`), and either ship `engines/gemini.sh` or remove gemini from `verify-work.py`'s FAMILY and `run_judge`.
- EVAL: `! grep -q 'Grok Build' README.md || grep -rqi 'grok' skills/task-loop/scripts/engines/ || exit 1`

### F-KIMI-10 — The published npm package ships ten scripts that cannot run (`apps/` is excluded from the tarball), and every install triple-copies 3.3 MB of skills into the consumer's repo (simplification)

- SURFACE: install
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `package.json:10-19` — five `cockpit:*` + five `control-room:*` scripts, all `npm --prefix apps/cockpit …` · `package.json:21-27` — `"files": ["bin/","skills/","install.sh","VERSION",".claude-plugin/"]` — no `apps/` · `apps/cockpit/README.md` (end) — "control-room:* … remain compatibility aliases for one release"; 0.1.0 IS that release · `install.sh:123` — `for SKILL_DIR in "$TARGET/.agents/skills" "$TARGET/.claude/skills" "$TARGET/.grok/skills"` · `du -sh skills/` → 3.3 MB (this session).
- CLAIM: `npm i -g github:…` consumers get a package whose advertised cockpit commands fail with a missing-directory error, and `install.sh` writes ~10 MB of pinned skill copies into three harness directories regardless of which harness the consumer uses.
- WHY IT MATTERS: The npm door is one of three install promises on the README; its scripts surface is dead on arrival, and a Codex-only user now has `.claude/skills/` and `.grok/skills/` trees in their git status — clutter the installer created and nothing cleans up.
- FALSIFIER: `npm pack` output includes `apps/cockpit` (making the scripts live), or package.json's scripts section references only paths inside `files`.
- MOVE: Delete the five `control-room:*` aliases today (their grace period ended at 0.1.0), move `cockpit:*` into `apps/cockpit/package.json` (root README already tells users to run them from the repo), and make install.sh's harness set opt-in (`--harness claude,codex` with the current triple as `--harness all`).
- EVAL: `grep -q '"control-room:dev"' package.json && exit 1; node -e 'const p=require("./package.json");process.exit(Object.values(p.scripts).some(v=>v.includes("apps/cockpit")) && !p.files.some(f=>f.startsWith("apps")) ? 1 : 0)'`

### F-KIMI-11 — "Dark factory" and the holdout-scenario architecture are live, named prior art (Shapiro, StrongDM) — the repo knows this (its own history says so) and attributes none of it

- SURFACE: docs
- SEVERITY: medium
- CONFIDENCE: high
- EVIDENCE: `README.md:3,8,33` — "dark factory" used as the banner metaphor, uncredited · `git log -1 --format=%B e23d358` — "the Shapiro L4->L5 / three-load-bearing-properties framing from the field scan" (the author demonstrably knows the source) · https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/ (retrieved 2026-08-04) — "Maybe you've heard of the Fanuc Dark Factory … a place where humans are neither needed nor welcome" · https://factory.strongdm.ai (retrieved 2026-08-04) — "Code must not be written by humans. Code must not be reviewed by humans"; scenarios held out from builders, LLM-judged "satisfaction", anti-reward-hacking motivation · https://simonwillison.net/2026/Feb/7/software-factory/ (retrieved 2026-08-04) — StrongDM's Attractor: markdown specs fed to coding agents.
- CLAIM: The marquee metaphor and the two most differentiating mechanics (holdout evaluation, judge-graded satisfaction) were publicly shipped by StrongDM in Feb 2026 and named by Shapiro in Jan 2026; Converge's genuine differentiation is the signed-spec + write-fence + gate-token referee layer (Spec Kit's specify→plan→tasks→implement, https://github.com/github/spec-kit, retrieved 2026-08-04, has the pipeline but no signed evals or fence) — but the README presents the whole assembly as sui generis.
- WHY IT MATTERS: A repo whose thesis is provenance stamps input hashes on objection logs yet leaves its own intellectual provenance unstamped; the first knowledgeable reviewer (anyone who read Willison in February) will do the attribution for it, uncharitably. It also weakens the pitch: "we stand on Shapiro/StrongDM and add the referee" is a stronger, checkable claim than silence.
- FALSIFIER: A Provenance or Prior-art paragraph in README naming Shapiro's five-levels post and StrongDM's factory/Attractor, stating what Converge adds.
- MOVE: Add three sentences to README's Provenance section (after `README.md:449`) crediting the term and the holdout-scenario pattern, and one line in docs/converge-v0.1.pdf's successor.
- EVAL: `grep -rqi 'shapiro\|strongdm' README.md skills/README.md docs/handbook/ 2>/dev/null || exit 1`

### F-KIMI-12 — bin/README.md, the self-described "CLI surface ledger: every command + proof", never mentions `snapshot` — and "The two files" table lists two of the three files in bin/ (simplification)

- SURFACE: docs
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `grep -c snapshot bin/README.md` → 0 (this session) · `bin/README.md:68-73` — "## The two files" lists `cvg` and `_ui.sh` only · `bin/cvg-snapshot.py` is 2,833 lines — larger than `bin/cvg` (2,677) — routed at `bin/cvg:2284`, documented in `cvg agent-context`, load-bearing for the Cockpit's only observation path (`apps/cockpit/README.md` — "invokes exactly one read-only CLI command: cvg snapshot --json") · CI runs `tests/test-cvg-snapshot.sh`.
- CLAIM: The file whose stated job is enumerating the surface omits the surface's second-biggest implementation and the command the entire observation product depends on.
- WHY IT MATTERS: The ledger is the audit trail a new maintainer trusts first; the command it forgets is the one with the strictest contract in the repo (WorkspaceSnapshot 3.0).
- FALSIFIER: bin/README.md contains a snapshot row (wraps `bin/cvg-snapshot.py`, proven by `tests/test-cvg-snapshot.sh`) and a three-row files table.
- MOVE: Add the row and the file entry; no code changes.
- EVAL: `grep -q 'cvg-snapshot' bin/README.md || exit 1`

### F-KIMI-13 — `cvg doctor` probes binary presence, not capability, and the tool's own repository is no longer a Converge workspace — "practices what it enforces" is currently unverifiable in-repo

- SURFACE: tests
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `skills/sketch-plans-adversarial-review/scripts/doctor.sh:21-22` — the probe is `command -v "$cmd"` plus a `--version` string; this session it printed `PASS codex … PASS kimi … PASS claude` without dispatching anything · `cvg next` in this repo, this session: "no Converge workspace found walking up from '…/converge'" — `NEXT_PASS=USAGE_ERROR`, exit 2 (there is `.cvg/gate.yaml` but no `cvg/` tree; the backlog moved to private Linear at 5ceb4cd) · `README.md:450` — "Converge practices what it enforces".
- CLAIM: Doctor's READY means "binaries exist," not "engines can complete a dispatch" (an expired credential passes), and the repo that tells users to run `cvg next` cannot run it on itself.
- WHY IT MATTERS: Both are trust surfaces: doctor green-then-dispatch-fails costs a confused debugging session (the project's own changelog documents this exact hour-long bisect for shellcheck), and a visitor's first `cvg next` on the reference repo is an error.
- FALSIFIER: doctor gains a minimal real dispatch probe (or renames its verdict to PRESENT), and `cvg next` exits 0 or `NEXT_PASS=DONE` in this repo.
- MOVE: Add an opt-in `doctor --deep` that runs a one-token headless ping per engine; restore a minimal tracked `cvg/` workspace for the tool's own backlog or soften `README.md:450` to past tense.
- EVAL: `./bin/cvg next >/dev/null 2>&1; [ $? -ne 2 ] || exit 1`

### F-KIMI-14 — shellcheck is a hard requirement for signing, absent from README's Requirements, and installed unpinned in CI — one unmanaged hole in an otherwise hash-pinned supply chain

- SURFACE: tests
- SEVERITY: low
- CONFIDENCE: high
- EVIDENCE: `skills/task-spec/scripts/safe-to-delegate.sh:157` — the gate always invokes `validate-task-spec.sh --no-state --shellcheck-evals` (not opt-in here, despite `skills/task-spec/SKILL.md:203` calling the flag "opt-in") · `README.md` Requirements — "bash 3.2+ and git … python3 (stdlib only)"; shellcheck unnamed · `.github/workflows/ci.yml:88-92` — `brew install shellcheck` / `apt-get install -y -qq shellcheck`, no version pin, while actions are SHA-pinned and pip is `--require-hashes` · `bin/README.md` (doctor host entry) — the project itself documents that one missing shellcheck blocked the whole sign→bind→loop chain.
- CLAIM: A host without shellcheck cannot sign a spec, yet nothing in the install or requirements surface says so, and CI lints the bash-3.2 floor with whatever shellcheck the image feels like shipping that day.
- WHY IT MATTERS: The failure is discovered three verbs downstream of its cause (the repo's own doctor-host comment says it cost an hour); an unpinned linter is also the one CI input that can change verdicts without a commit.
- FALSIFIER: README Requirements names shellcheck (with the `--skip` escape if one exists), and ci.yml pins a shellcheck version or vendored binary hash.
- MOVE: One line in README's requirements block; pin shellcheck in ci.yml (e.g. `apt-get install shellcheck=<ver>` or a downloaded, checksummed binary like the actionlint step already does with Go modules).
- EVAL: `grep -q shellcheck README.md && ! grep -qE '(apt-get|brew) install[^|]*shellcheck' .github/workflows/ci.yml || exit 1`

## KILL LIST

1. **Delete the `control-room:*` npm aliases and relocate `cockpit:*` out of the published manifest.** `package.json:15-19` vs `apps/cockpit/README.md` ("aliases for one release" — 0.1.0 shipped) and `package.json:21-27` (`apps/` never packed). Two deletions, zero capability lost; keeps the npm surface honest. EVAL: `grep -q 'control-room' package.json && exit 1 || exit 0`.
2. **Collapse the five orphaned pitch binaries into one canonical deck.** Tracked but referenced from no README table: `docs/converge.pdf` (8.2 MB), `docs/converge-deck.html` + `docs/converge-deck.pdf`, `docs/handbook/owner-handbook.{html,pdf}` — ~13 MB of binary decks that `test-version-unity.sh` and `lint-skill-docs.sh` cannot lint, each a permanent drift surface against `docs/converge-v0.1.pdf` (the README-designated canonical blueprint). EVAL: `[ "$(git ls-files 'docs/*.pdf' 'docs/handbook/*.pdf' | wc -l | tr -d ' ')" -le 2 ] || exit 1`.
3. **Remove `gemini` from `verify-work.py`'s FAMILY map, judge picker, and dispatch table** (`verify-work.py:55,87,194`) until an engine adapter exists — half-support reads as support in exactly the file whose job is independence accounting. EVAL: `grep -q gemini skills/task-to-runtime-contract/scripts/verify-work.py && exit 1 || exit 0`.
4. **Split or gut `skills/task-spec/SKILL.md` (587 lines) and `skill-creator/SKILL.md` (487).** The open skill-format spec Converge validates against recommends the main body stay "under ~500 lines / ~5k tokens" with detail pushed to `references/` (https://agentskills.io/specification, retrieved 2026-08-04); the cornerstone skill is the worst offender in its own house. EVAL: `[ "$(wc -l < skills/task-spec/SKILL.md | tr -d ' ')" -le 500 ] || exit 1`.

## BLIND SPOT

**The vendor CLIs are inside the trust boundary and were never threat-modeled — `command -v` is the entire compatibility story, and the receipts record a binary name, not the model that judged.** Since the first dispatch, engines have been treated as fixtures: doctor's probe is presence plus a version string (`doctor.sh:21-22`); adapters degrade silently by policy ("an unknown tier rides the default rather than killing the run", `engines/claude.sh:31`; "unknown or unset: ride the CLI default", `engines/codex.sh:35`); the codex adapter hard-codes `gpt-5.4-mini`/`gpt-5.4` (`codex.sh:32-34`) and kimi hard-codes two preview ids; the execution receipt records `--agent` (the CLI name) with no model id and no CLI version (`write-execution-receipt.py:32,106-111`). So the property the method stamps — *cross-family* — is pinned to a vendor binary while the actual grader floats free: the day a CLI repoints its default or renames a preview model, every gate still exits 0, every receipt still verifies, and nothing anywhere records what actually judged the work. He cannot see this because the portability war was fought and visibly won at the layer he controls (bash 3.2, stdlib python, BSD-vs-GNU); "the referee holds no credentials" made the engines feel outside the security model when they are its single point of judgment. The fix is boring: record `engine_version` + resolved model id in every dispatch receipt and fail the run when either is unresolvable — the same discipline the repo already applies to spec hashes.

## STRONGEST OBJECTION

**Against the HMAC sign-off seal as the cornerstone of delegation trust.** The README's pitch is that the seal is what makes autonomy safe: "Hand-stamping is rejected; the only path to autonomy is through the gate" (`README.md:429`). Mechanically, the seal is a symmetric HMAC whose key lives at `.git/info/taskspec-signing-key`, resolvable from any worktree via `git rev-parse --git-common-dir` (`_lib.sh:612-627`), readable by every process the loop's worker spawns — and the loop spawns the worker on that host, in a worktree of that repo, by default. Re-sealing after weakening an eval is `cvg tasks gate --stamp`: no presence proof, no asymmetry, no second factor. The gate therefore cannot distinguish "the owner approved these evals" from "the agent approved these evals"; possession of the key is the stamp's entire semantics, and the agent has possession. The method's own reference doc concedes it — "tamper-evident, not tamper-proof … not a security boundary" (`skills/task-spec/SKILL.md:561`) — which is an admission that the actual load-bearing control against a motivated agent is the sentence "You may NOT edit the Task-Spec, its evals, or any test that grades you" in the attempt brief (`loop-kernel.sh:859`) plus postflight path guards. In other words: the system that exists to replace trusting the agent's word rests, at its cornerstone, on trusting the agent's compliance. The supply-chain world solved this exact shape years ago — attestations are signed by a different trust domain than the builder, wrapped in DSSE, verified against a policy (in-toto/SLSA, retrieved 2026-08-04) — and Converge's seal deliberately reuses none of that machinery.

**Do I believe it?** Mostly. As a security claim the objection is decisive: against an agent that plans, the seal adds almost zero marginal cost. But the documented cheating economy (NIST CAISI's catalog is opportunistic assertion-weakening, not planned key-theft) is mostly lazy, and tamper-evidence plus the hash-pinned bind genuinely prices out the lazy attack — including the commonest real one, which is a well-meaning human or agent editing an eval after sign-off and forgetting. So the decision to *have* the seal is right; the defect is letting the front door sell it as a lock when the mechanism is a tripwire, and keeping the tripwire's key under the doormat. One line of README honesty and a keychain-held key would close most of the gap without new machinery.

## GAPS

- **PDFs not read.** `docs/converge-v0.1.pdf` (3.7 MB) and `docs/task-spec-v0.1.pdf` (3.3 MB) are binary and large; README/CHANGELOG-vs-PDF drift is unchecked. Everything above cites text surfaces only.
- **No live loop or verify run.** The review rules forbid mutations, and a real Pass-8 run spends engine credentials; the token-axis (F-KIMI-01) and tier-2-default (F-KIMI-05) findings are static-analysis plus one dry resolver invocation (`cost-profile.py`), not an end-to-end run.
- **X/Twitter not mined directly.** No X tool exists in this harness; practitioner complaints were sourced from retrievable aggregators (augmentcode.com 80%-problem guide, dev.to field reports, NIST CAISI — all retrieved 2026-08-04). The reply-layer objections the prompt asked for are under-covered: that is a tooling gap, not a finding.
- **graphify used once** (`query` for `_lib.sh` importers). Its bash-`source` edge gaps, flagged in the brief, were confirmed in practice (partial importer list), so every blast-radius claim above was re-verified against source rather than the graph.
- **Other agents' reviews deliberately unread.** `review/deepseek.md` and `review/grok.md` existed before I wrote; I did not open them to keep this review independent. Overlap or contradiction between the three is unexamined.
- **`cvg loop --issue … --agent kimi` on this host was not exercised** beyond `doctor`/`doctor host`/`next`; whether kimi 0.31.1's `--output-format text` footer carries usable usage data (the F-KIMI-01 fix's assumption) is unverified.

REVIEW=kimi:DONE
