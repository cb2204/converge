# Converge backlog

Distilled from the eight independent model reviews in [`docs/reviews/`](docs/reviews/).
All eight reviewed the same commit `9c966884e37919c0f7e4c3e027b4b237670eb2ad` against
an identical 15-section template, which makes their agreement meaningful rather than
coincidental. Mean overall score: **~68/100** (range 56.8–74.8). Every reviewer
independently landed on `current_readiness: Alpha` and `adopt_today: conditional`.

Each item below carries the number of reviewers who raised it and a **Status** line
verified against `main` today, not against the reviewed commit. Findings the reviewers
raised that are already fixed are recorded at the bottom so they are not re-litigated.

---

## P0 — Distribution is blocked

These gate everything else. Four reviewers made "go public with reproducible proof"
their single highest-impact move; no amount of internal rigor is visible while the
front door is shut.

- [ ] **Make the repository public** — 3 of 8 (`F-fable-01`, `F-qwen3.8-max-01`, `F-openrouter-minimax-m3-01`)
      **Status: OPEN, verified today.** `gh repo view` reports `visibility=PRIVATE`.
      Every install path in `README.md` — the `git clone`, the `npm install -g github:…`,
      and the `curl` one-liner — 404s for anyone who is not the owner. This is the
      `top_risk` field for three separate reviewers.

- [ ] **Publish the npm package** — implied by all install-door findings
      **Status: OPEN, verified today.** `npm view @luanmorenommaciel/converge` returns
      E404. `package.json` declares the `bin` and a complete `files` list, so the
      package is ready; it has simply never been published.

- [ ] **Restore CI** — 1 of 8 (`F-KCC-04`), and it invalidates the proof channel
      **Status: OPEN, verified today.** Every run since 2026-08-17T17:26Z fails in
      3–5s with `The job was not started because recent account payments have failed`.
      Jobs never start. This is a billing problem, not a test problem — the last real
      run (`32048296517`) passed all eight jobs on both Ubuntu and macOS. Kimi's
      framing is the sharp one: the proof channel currently contradicts the pitch.

- [ ] **Ship reproducible proving-ground evidence in the tree** — 6 of 8
      (`F-fable-07`, `F-glm-02`, `F-grok-05`, `F-KCC-05`, `F-openrouter-minimax-m3-03`, `F-codex-gpt5-11`)
      The strongest trust evidence — including a live cross-family REFUTED verdict —
      exists only in git history. Reviewers had to do "git archaeology" to find it.

---

## P1 — The trust boundary is weaker than the language

The most-converged technical theme. The mechanism is real and tamper-evident; the
claim of independence is what overreaches.

- [ ] **The holdout is readable by the worker** — 5 of 8, the single most-agreed finding
      (`F-codex-gpt5-02`, `F-fable-02`, `F-KCC-02`, `F-qwen3.8-max-02`, `F-grok-02`)
      "A holdout the builder never saw" is a prompt convention, not a mechanical
      boundary: the worker is pointed at the file that contains it. Fix is to separate
      holdout storage from the worker-visible spec.

- [ ] **The signing key is worker-readable; HMAC is not a worker-external signer** — 3 of 8
      (`F-codex-gpt5-06`, `F-fable-03`, `F-DSV4-04`)
      Symmetric HMAC gives strong drift evidence and no per-author non-repudiation.
      Reviewers judged the fine print honest and the front-door claim oversold.

- [ ] **Lock the tier-2 judge read-only; it is prompt-injectable through what it grades** — 3 of 8
      (`F-fable-04`, `F-qwen3.8-max-03`, `F-codex-gpt5-03`)
      Pass 4 already demonstrates the correct pattern, so this is a consistency fix.

- [ ] **Make tier-2 verification default for high-blast-radius work** — 3 of 8
      (`F-grok-01`, `F-openrouter-minimax-m3-04`, `F-codex-gpt5-03`)
      Currently opt-in and lane-driven, so the default settle path can skip independent
      holdout verification while the marketing implies proven-done autonomy.

- [ ] **Record tier-2 verdicts in the durable receipt** — 3 of 8
      (`F-codex-gpt5-08`, `F-qwen3.8-max-04`, `F-DSV4-01`)
      A REFUTED verdict currently leaves no inspectable evidence in the receipt.

- [ ] **Close the prevention gap: `fs.write` is detect-only outside Codex** — 2 of 8
      (`F-glm-03`, `F-qwen3.8-max-10`)
      Only the Codex adapter prevents at the OS level; Claude, Kimi and generic are
      postflight detection at settlement.

---

## P2 — The autonomy ceiling

- [ ] **Build the Manager (fleet dispatch)** — 6 of 8 named it a finding, and it appears
      in the top-three moves of all 8
      (`F-DSV4-03`, `F-fable-08`, `F-glm-04`, `F-grok-04`, `F-KCC-07`, `F-openrouter-minimax-m3-05`)
      **Status: OPEN, verified today.** No `manager` verb in `cvg --help`. A single-task
      loop is one cell, not a factory — this is what caps the "fabric" claim.
      Note the tension flagged in section 12: build the *minimum* DAG, not a scheduler.

- [ ] **Ship the CI eval-gate (server-side re-verification)** — 5 of 8
      (`F-fable`, `F-glm-04`, `F-KCC-07`, plus top-three moves from qwen and codex-gpt5)
      Settlement trust is local-only today. Moving the gate into the PR is what makes
      it credible to a second party.

---

## P3 — Adoption and developer experience

- [ ] **Cut first-success cost** — 6 of 8
      (`F-fable-11`, `F-glm-13`, `F-grok-06`, `F-KCC-12`, `F-DSV4-05`, `F-codex-gpt5-12`)
      Ceremony, multi-engine prerequisites and macOS sharp edges block the first win.
      Three reviewers proposed the same remedy: a one-command quickstart with a
      ~15-minute path from idea to settled task.

- [ ] **Decide the Cockpit's position** — 7 of 8
      (`F-DSV4-06`, `F-fable-12`, `F-KCC-10`, `F-qwen3.8-max-09`, `F-openrouter-minimax-m3-07`, `F-glm-05`, `F-grok-11`)
      **Status: confirmed** — `apps/` is absent from the `files` list in `package.json`,
      so it is not in the published package, and its own proving grounds are open.
      Reviewers called it well-engineered but premature relative to the core wedge;
      Kimi went further and called it a liability while unreleased.

- [ ] **Address bus factor 1 on a large bash kernel** — 3 of 8
      (`F-fable-09`, `F-KCC-13`, `F-glm-10`)

- [ ] **Close the macOS bash 3.2 gap** — 2 of 8
      (`F-openrouter-minimax-m3-06`, `F-grok-13`) — `cvg lint` requires bash 4+, declared
      honestly but still an install-time break on stock macOS.

---

## Known defects

- [ ] **The D1 "anchored to git root instead of workspace" defect class** — `F-glm-07`,
      7 separate sightings. A recurring, load-bearing sharp edge rather than one bug.
- [ ] **`--resume` under worktree isolation restarts at attempt 1** in a fresh tree —
      `F-glm-11`, `F-openrouter-minimax-m3-08`.
- [ ] **Tier-2 judge timeout is hardcoded at 300s** — `F-glm-11`.
- [ ] **Token budget axis is disconnected from the shipped engines** — `F-codex-gpt5-04`,
      `F-DSV4-07`.
- [ ] **No Gemini adapter despite appearing in the family map** — `F-DSV4-09`.
- [ ] **"Grok Build" support is skills-install only**; execution claims overstate it —
      `F-qwen3.8-max-08`.

## Found this session, not in the reviews

- [ ] **Task-Spec 3.9.0 breaks `_state.yaml` reproducibility.** The engine writes an
      absolute path where `tests/test-clean-room-install-e2e.sh:286` requires a relative
      one, so the committed derived state would embed each developer's home directory.
      `tests/test-version-unity.sh` declares 3.9.0 compatible while the clean-room test
      proves it is not. CI does not catch this because it pins Task-Spec to `0e6180c`.
      Upstream fix: `taskspec rebuild-state` accepts no flags, so Converge has no lever.
- [ ] **`apps/cockpit/package.json` is versioned `1.0.0`** while the whole stack is
      `0.2.0`, despite a CI job named "one package, one version".

---

## Do not build yet (reviewer consensus, section 12)

Recorded so these are actively declined rather than quietly revisited:

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

- **v0.1.0 and v0.2.0 are tagged and published as GitHub releases**, with the full
  0.2.0 release notes in the release body. Reviewers saw neither. Note this is only
  visible to the owner while the repository stays private.
- **Task-Spec and Seamwise are now independently installed engines** pinned to exact
  commits, which removes the embedded-engine concern.
- **`make check` now resolves engine binaries to absolute paths**, fixing 9 spurious
  `doctor host` failures on any machine with the engine in `~/.local/bin`.
