# Converge backlog

Distilled from the eight independent model reviews in [`reviews/`](reviews/).
All eight reviewed the same commit `9c966884e37919c0f7e4c3e027b4b237670eb2ad`
against an identical 15-section template. Mean overall score: **68.25/100**
(range 56.8–74.8; DeepSeek 6.8/10 and MiniMax 7.3/10 scaled to /100).
Seven reviewers landed on `current_readiness: Alpha`. MiniMax landed on
`Beta`. All eight returned `adopt_today: conditional`.

Counts below were recounted from the source files. A finding ID is credited
only when it states the same claim as the bullet. Adjacent-but-different
findings are listed separately.

Each item carries the number of reviewers who raised it and a **Status** line
verified against `main`, not against the reviewed commit.

---

## P0 — Distribution is blocked

Two reviewers made “go public with a portable proof bundle” their single
highest-impact move (Fable, Qwen). MiniMax’s rank-1 is “publish the package
and verify the install doors.” No amount of internal rigor is visible while
the front door is shut.

- [ ] **Make the repository public** — 3 of 8 (`F-fable-01`, `F-qwen3.8-max-01`, `F-openrouter-minimax-m3-01`)
      **Status: OPEN.** `gh repo view` reports private. Every install path in
      `README.md` 404s for anyone who is not the owner.

- [ ] **Publish the npm package** — implied by all install-door findings
      **Status: OPEN.** `npm view @luanmorenommaciel/converge` returns E404.

- [ ] **Restore CI** — 1 of 8 (`F-KCC-04`)
      **Status: OPEN.** Hosted jobs since 2026-08-17T17:26Z die in seconds with
      a billing error. That is not a test result.

- [ ] **Ship the missing live UPHELD/REFUTED pair in the tree** — 6 of 8
      (`F-fable-07`, `F-glm-02`, `F-grok-05`, `F-KCC-05`, `F-openrouter-minimax-m3-03`, `F-codex-gpt5-11`)
      **Status: PARTIAL.** `evidence/releases/v0.2.0/live-codex/` is in-tree
      composed-flow evidence. The reviewers’ artifact — bidirectional
      cross-family `obs-rowcounts` / `obs-fence` receipts — is still only in
      git history.

---

## P1 — The trust boundary is weaker than the language

- [ ] **The holdout is readable by the worker** — 4 of 8
      (`F-codex-gpt5-02`, `F-fable-02`, `F-KCC-02`, `F-qwen3.8-max-02`)
      “A holdout the builder never saw” is a prompt convention: the worker is
      pointed at the file that contains it.
      Adjacent, not counted here: `F-grok-02` (holdout is optional to sign) and
      `F-DSV4-11` (independence is author discipline).

- [ ] **The signing key is worker-readable; HMAC is not a worker-external signer** — 4 of 8
      (`F-codex-gpt5-06`, `F-fable-03`, `F-DSV4-04`, `F-KCC-03`)

- [ ] **Lock the tier-2 judge read-only** — 2 of 8
      (`F-qwen3.8-max-03`, `F-codex-gpt5-03`)
      Adjacent, not counted here: `F-fable-04` is prompt-injection through the
      graded artifact, not a missing read-only lock.

- [ ] **The tier-2 judge is prompt-injectable through what it grades** — 1 of 8
      (`F-fable-04`)

- [ ] **Make tier-2 verification default for high-blast-radius work** — 2 of 8
      (`F-grok-01`, `F-openrouter-minimax-m3-04`)

- [ ] **Record tier-2 verdicts in the durable receipt** — 2 of 8
      (`F-codex-gpt5-08`, `F-qwen3.8-max-04`)
      Adjacent, not counted here: `F-DSV4-01` is a missing public REFUTED
      artifact, not a receipt-schema gap.

- [ ] **Close the prevention gap: portable path control is detect-only** — 3 of 8
      (`F-glm-03`, `F-qwen3.8-max-10`, `F-grok-03`)

---

## P2 — The autonomy ceiling

- [ ] **Build the Manager (fleet dispatch)** — 6 of 8 named findings, 7 of 8 top-3s
      (`F-DSV4-03`, `F-fable-08`, `F-glm-04`, `F-grok-04`, `F-KCC-07`, `F-openrouter-minimax-m3-05`)
      **Status: OPEN.** No `manager` verb in `cvg --help`. Fable’s top-3 #3 is
      the CI eval-gate, not the Manager; Fable said build the gate *before*
      the Manager.

- [ ] **Ship the CI eval-gate (server-side re-verification)** — 3 named findings, 6 of 8 top-3s
      (`F-fable-08`, `F-glm-04`, `F-KCC-07`; also top-3 for Qwen, Codex, Grok)
      Settlement trust is local-only today.

---

## P3 — Adoption and developer experience

- [ ] **Cut first-success cost** — 6 of 8
      (`F-fable-11`, `F-glm-13`, `F-grok-06`, `F-KCC-12`, `F-DSV4-05`, `F-codex-gpt5-12`)

- [ ] **Decide the Cockpit's position** — 7 of 8
      (`F-DSV4-06`, `F-fable-12`, `F-KCC-10`, `F-qwen3.8-max-09`, `F-openrouter-minimax-m3-07`, `F-glm-05`, `F-grok-11`)
      **Status: confirmed** — `apps/` is absent from the `files` list in
      `package.json`. Its package version now matches `VERSION` (0.2.0); the
      proving grounds remain open.

- [ ] **Address bus factor 1 on a large bash kernel** — 2 of 8 exact
      (`F-fable-09`, `F-KCC-13`)
      Adjacent: `F-glm-10` is single-author adoption, not kernel fragility.

- [ ] **Close the macOS bash 3.2 gap** — 2 of 8
      (`F-openrouter-minimax-m3-06`, `F-grok-13`)

---

## Known defects

- [ ] **`CVG_TASKSPEC_BIN` is ignored when a cvg subcommand re-enters the CLI.**
      `cvg snapshot` shells out to `cvg next`, which resolves `taskspec` through
      PATH instead of the override. Since the 3.8.x pin landed in `56a6478`, a
      3.9.x on PATH is rejected inside that nested call and surfaces as
      `cvg snapshot: \`cvg next --lane FULL --json\` returned no NEXT_PASS verdict` —
      failing 11 of 13 rows in `tests/test-cvg-snapshot.sh` for a reason that names
      neither the engine nor the version. Bisected: `db8c368` passes 13/13,
      `56a6478` fails. CI does not catch it because it puts the pinned engine on
      `$GITHUB_PATH`; the Makefile now does the same locally, which masks the
      symptom but not the cause. The documented workflow in README ("First composed
      journey") exports only `CVG_TASKSPEC_BIN`, so it is broken for anyone whose
      PATH carries a different Task-Spec.

- [ ] **The D1 "anchored to git root instead of workspace" defect class** — `F-glm-07`
- [ ] **`--resume` under worktree isolation restarts at attempt 1** — `F-glm-11`, `F-openrouter-minimax-m3-08`
- [ ] **Tier-2 judge timeout is hardcoded at 300s** — `F-glm-11`
- [ ] **Token budget axis is disconnected from the shipped engines** — `F-codex-gpt5-04`, `F-DSV4-07`
- [ ] **No Gemini adapter despite appearing in the family map** — `F-DSV4-09`
- [ ] **"Grok Build" support is skills-install only** — `F-qwen3.8-max-08`
- [ ] **Holdout criteria are optional to sign or delegate** — `F-grok-02`
- [ ] **Settlement tokens can overstate the artifact that exists** — `F-codex-gpt5-07`
- [ ] **Bind validates a declaration, not this host's enforcement** — `F-codex-gpt5-05`
- [ ] **"Autonomous Fabric" is an unearned category name** — `F-openrouter-minimax-m3-02`, `F-codex-gpt5-13`, `F-glm-09`
- [ ] **The public `task-spec` sibling splits the evidence** — `F-qwen3.8-max-12`

## Found this session, not in the reviews

- [x] **Task-Spec 3.9.0 breaks `_state.yaml` reproducibility.** Confirmed: in a
      git workspace, 3.9.0 `rebuild-state` writes an absolute `path:` while
      `tests/test-clean-room-install-e2e.sh:286` requires the 3.8.0 relative
      form. **Addressed** by narrowing the supported engine to `3.8.x` in
      `bin/cvg`, `install.sh`, `tests/test-version-unity.sh`, and compose.
      Upstream `rebuild-state` still has no flag; do not advertise 3.9.x until
      it does.

---

## Do not build yet (reviewer consensus, section 12)

- Multi-tenant or hosted SaaS control plane; enterprise RBAC, billing, marketplace.
- More engine adapters (Grok/Gemini workers) **before** the proof exists.
- More tracker adapters or board views — breadth does not fix settlement authority.
- More passes, skills, templates or document types; the descent is already steep.
- Multi-repo / monorepo orchestration.
- Additional eval frameworks inside the package.
- Vendor lock-in adapters or a Converge-branded model — harness-agnosticism is the moat.
- More Cockpit views until the isolation blocker is resolved.

---

## Already fixed since the reviewed commit

- **`v0.1.0` existed at review time** (Kimi and Qwen recorded the local tag).
  **`v0.2.0` did not.** Both tags are now published as GitHub releases. The
  `v0.2.0` release body is the migration note; it is not a verbatim copy of
  the deleted `docs/releases/v0.2.0.md` (Bash/Python/Node rows were dropped).
  Visible only to the owner while the repository stays private.
- **Task-Spec and Seamwise are independently installed engines** pinned to
  exact commits. Reviewers at `9c96688` still saw an in-tree `skills/task-spec/`.
- **`make check` resolves engine binaries to absolute paths**, fixing 9
  spurious `doctor host` failures when the engine lives in `~/.local/bin`.
- **Cockpit `package.json` version matches `VERSION`.**
