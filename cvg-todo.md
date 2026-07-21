# cvg — Build Plan (one step at a time)

> The build backlog for `cvg`, the multi-harness CLI that automates Converge.
> **This file is the working contract for every build session.** The root
> [`todo.md`](todo.md) stays the *method* backlog (B-1…B-14); this file is the
> *build* backlog that implements B-1/B-2/B-3/B-4/B-9/B-12/B-13 as one CLI,
> ordered so every step is small, testable, and proven before the next begins.
>
> Context artifacts (read before building):
> [`readme.md`](readme.md) · [`presentation/cvg-automation-plan-v1.0.html`](presentation/cvg-automation-plan-v1.0.html)
> (the full design: command surface §06, flow §07, use-case §08, phases §11, risks §12)
> · [`skills/task-spec/`](skills/task-spec/) (the atomic unit — its scripts are the CLI's core).

---

## Fresh session? Start here

This file is the complete contract — assume no prior conversation. **cvg** is a
multi-harness CLI that automates the Converge method (eight passes, fuzzy brief
→ eval-gated system; see `readme.md`). The CLI is the **referee, never a
player**: it frames prompts, dispatches engine CLIs headlessly, and gates their
outputs with the existing check scripts — zero model credentials, no LLM calls
of its own. Before writing code, read: this file top to bottom →
`skills/task-spec/SKILL.md` + its `scripts/` (you WRAP these, never rewrite:
`safe-to-delegate.sh`, `accept-task.sh`, `run-task-spec.sh --ci`,
`validate-task-spec.sh`, `lint-backlog.sh`, `transition-status.sh`,
`conformance-check.sh`, `ref-executor.sh`) → the presentation deck. Then find
the first unchecked step below, do ONLY that step, prove its gate, log it,
commit (`cvg: <milestone.step> <what>`), and stop for the user's go.

---

## Rules of engagement (read every session)

0. **Go slow and teach.** This CLI is the user's de-facto engine for building
   anything from scratch — their understanding of every piece is a deliverable
   equal to working code. Every step: (a) BEFORE building, explain in plain
   terms what the step is, why it exists, and how it fits the machine;
   (b) AFTER proving, walk through what was built and hand the user runnable
   commands to verify and explore it themselves; (c) never bundle steps, never
   rush past a concept the user hasn't confirmed they own.
1. **One step at a time.** Never start step N+1 before step N's gate is proven
   green in this file. Check the box, paste the proof command + output summary
   under the step, commit, then move on.
2. **The CLI is the referee, never a player.** `cvg` frames prompts, dispatches
   engines, and gates outputs. It holds **zero model credentials** and never
   calls an LLM API itself — it shells out to engine CLIs (`claude -p`,
   `codex exec`, `kimi`, …).
3. **Wrap, don't rewrite.** The 53 shell scripts in `skills/*/scripts/` are the
   subcommand implementations. `bin/cvg` routes to them. A rewrite of a working
   script needs a written reason in this file.
4. **State is derived, never stored.** Truth = `tasks/*.md` frontmatter +
   tracker + git. No database, no daemon state, no canonical graph file.
5. **Bash 3.2-safe core** (macOS system bash), matching task-spec's discipline.
   Python is stdlib-only. No npm/pip dependencies anywhere in the core path.
6. **Dogfood from Milestone 1 onward:** any step of effort S or larger is cut
   as a Task-Spec first (`skills/task-spec`), gated with
   `safe-to-delegate.sh --stamp`, and accepted with `accept-task.sh --stamp
   --gold-sanity` when done. Trivial steps (XS) may skip the ceremony — note it.
7. **Fixture-first testing.** Every piece is proven on
   `tests/e2e-test-engine/` (Milestone 0), never only on the converge repo
   itself. The fixture tests the *machine*; the real proving ground
   (`uc-postgres-duckdb-dbt-analytics`) validates the *method*.
8. **Gold-sanity always. Evals must discriminate** — an eval that passes on the
   unbuilt baseline is a bug in the step, not a pass.
9. **Skill changes ship through skill-creator discipline.** Every edit to a
   `skills/*/SKILL.md`: `quick_validate.py` green before commit, version bump
   in frontmatter, gate-script changes proven against BOTH a passing and a
   failing synthetic spec (discriminating, per rule 8) — including at least
   one from a NON-data domain (the universality check).

---

## The operating model — five beats per pass (agreed 2026-07-16)

Track R validates the method **one pass at a time**, and each pass is a
complete vertical slice. The five beats, in order, never bundled:

1. **UNDERSTAND** — read the pass's skill + references + check script end to
   end; compare against the field (DGE etc.); deliver a hardening list for
   the user's approval. Analysis only, no edits.
2. **RUN** — execute the pass **for real** on the proving ground:
   **`tests/uc-analytics/`** (greenfield-from-Pass-0: e-commerce Postgres
   terrain, deterministic seed, no BRD — the brief gets born here). The user
   judges every output; hardening list gets applied along the way. The
   external `uc-postgres-duckdb-dbt-analytics` repo is the future
   *brownfield* receipt (enters at Pass 1; its BRD exists). Cross-discipline
   universality receipts (frontend/DevOps runs) deferred to runs #2/#3.
3. **CANONIZE** — iterate skill + artifact until the user calls it canonical.
   Deliverable: the updated SKILL.md (the blueprint) + the pass's artifact
   approved at its gate. Blueprints are **canonical v0** — a later pass may
   send a retro-edit back (compound loop; logged, expected).
   **Closing the C-beat includes the TEACH beat (agreed 2026-07-19):** run
   `pass-to-lesson` on the just-canonized artifacts, `check-lesson.sh` green,
   lesson committed under the workspace `docs/lessons/` — a pass is not
   closed until its lesson exists.
4. **IMPLEMENT** — the `cvg` subcommand for this pass: frame → dispatch →
   collect → gate, thin by design. Shared plumbing (bin/cvg entrypoint,
   engine adapter) is born once in R1's beat 4 and only reused after.
5. **PROVE** — re-run the pass through the CLI on the same input; artifacts
   and gate verdicts must match the canonical manual run (the golden
   reference). Nothing to trust, only to diff.

---

## Track R — validate the method, pass by pass ⟵ CURRENT

> Detailed beats are written only for the CURRENT pass (understand deeply,
> then move); later passes get their detail when they become current.

- [x] **R0 · Pass 0 Capture** — `idea-to-brd` ✅ **CLOSED END-TO-END
  2026-07-19, all five beats** *(absorbed 2026-07-17; optional on-ramp when
  no BRD exists)*. **Beat state: U ✅ · R ✅ · C ✅ (BRD signed canonical +
  lesson taught) · I ✅ (`cvg capture`, T-20260719-cvg-capture, gold-sanity
  accepted) · P ✅ (golden diff EMPTY: `cvg capture` on the proving ground
  byte-identical to the manual gate run, exit 0, `CHECK_BRD=PASS`).**
  Sequence executed per the owner's pivot: 1.1 router → P-8 exit-contract
  hardening → R0.I capture → R0.P prove. Signed off by the owner's
  wrap-and-sign-off call, 2026-07-19. **Second-eyes hardening same day
  (owner's "complete the sign-off" call): check-brd.sh v0.3.1 closed the
  template-copy bypass + 3 seams (T-20260719-pass0-gate-v031, gold-sanity
  ACCEPT, suite 17→27 rows, golden diff re-proven EMPTY) — Pass 0 sign-off
  is now 100%.**
- [x] **R1 · Pass 1 Intent** — `brd-docs-to-tech-req` ✅ **CLOSED END-TO-END
  2026-07-19, all five beats.** Beat state: U ✅ · R ✅ · C ✅ (tech-spec
  signed canonical at Gate H1 + lesson taught) · I ✅ (`cvg intent` +
  check-tech-spec v0.4.0 exit contract, T-20260719-cvg-intent, gold-sanity
  accepted) · P ✅ (golden diff EMPTY: `cvg intent` byte-identical to the
  direct gate run, exit 0, `CHECK_TECH_SPEC=PASS`).
  - [x] R1.U understand + harden ✅ 2026-07-16 — audited skill vs DGE's
    `dge-design`; applied H1–H7 to SKILL.md (v0.3.0) + H1/H4/H6 to
    check-tech-spec.sh (v0.3.0). Gate proven discriminating on two synthetic
    specs (passing DevOps spec exit 0 / same spec with one open blocker gap
    exit 1) — H6 universality confirmed (a non-data domain passes the
    de-biased "data named" check). `quick_validate.py` green.
  - [x] R1.R run ✅ 2026-07-19 — interrogation answered in two frontier
    rounds (D1–D5 locked, recorded in the workspace
    `brain/decisions/2026-07-19-pass1-round1-owner-answers.md`); tech-spec
    crystallized at `tests/uc-analytics/cvg/docs/tech-spec-analytical-backbone.md`;
    `check-tech-spec.sh` GATE PASS exit 0, zero warnings; owner judged the
    spec: "looks great, nice structure".
  - [x] R1.C canonize ✅ 2026-07-19 — **Gate H1 taken**: owner verdict
    "approved — canonical" signed into the spec's new Sign-off block
    (added at this beat — the three-engine structure review found the
    field's approved-by practice missing). Gaps resolved as D6/D7/D8
    (Round 3, locked in `brain/decisions/`). Agentic-execution second-eyes
    review: SUFFICIENT-WITH-FIXES → all fixes applied (B-2 analytical
    query defined by database principal; B-3 Q-SET-1 + answer-key oracle,
    `_control` readable by verifiers only; B-4 p99 normative with sample
    size + probe interval; S-1..S-7 decidability edits). Gate re-proven
    PASS exit 0. TEACH beat: `lesson-pass-1-analytical-backbone.md`,
    check-lesson exit 0 (12 components, 12 decisions w/ alternatives).
  - [x] R1.I implement ✅ 2026-07-19 — `cvg intent` born (cvg 0.3.0) +
    check-tech-spec v0.4.0 exit contract, one atomic ceremony
    (T-20260719-cvg-intent, Tier-1, gold-sanity ACCEPT); see progress log.
    *(original beat notes preserved below)* — `cvg intent` subcommand (the `bin/cvg` entrypoint
    birth moved to R0.I, owner's call 2026-07-19). **UX contract (owner's wish,
    2026-07-19 — resolution proposed, canonize at this beat):** the CLI must
    be beautiful and show the stages. Proposed: core stays bash/stdlib per
    rule 5 (gates run dep-free in CI); beauty ships as a shared pure-ANSI
    `_ui` layer (blueprint aesthetic — stage strip, truecolor, box-drawing)
    used by every subcommand; Rich/Textual allowed only as an OPTIONAL
    presentation shell with graceful plain fallback, never in the gate path;
    Typer evaluated and declined for core (thin routing surface, hard pip
    dep). Full stage visualization lands at Milestone 5's board.
    Field research done 2026-07-19 (deep-research, 18 verified claims):
    `temp/cli-ux-research-2026-07-19.md` — degradation contract
    (TTY/NO_COLOR/machine-mode), color discipline, buildx/Dagger stage
    precedents; confirms the argparse-over-Typer call. Consume at this beat.
    **Owner directive (2026-07-19): the CLI serves AGENTS as first-class
    users too — feed them what they need.** Standing rule from P-8 onward:
    every gate/verdict surface ends in a stable greppable machine token
    (`CHECK_BRD=…` pattern), exit codes are contracts, piped output is
    plain and parse-stable; `--json`/`--ci` modes deepen this at
    Milestone 2.1.
  - [x] R1.P prove ✅ 2026-07-19 — `cvg intent` on the proving ground
    byte-identical to the direct check-tech-spec run (golden diff EMPTY,
    exit 0, `CHECK_TECH_SPEC=PASS`), proven in eval_3 AND re-proven by
    hand post-acceptance.
- [x] **R2 · Pass 2 Structure** — `tech-req-to-adrs` ✅ **CLOSED END-TO-END
  2026-07-21, all five beats.** Beat state: U ✅ · R ✅ (6 grounding ADRs on
  live terrain) · C ✅ (7 ADRs CANONICAL + second-eyes fixes + lesson) · I ✅
  (`cvg structure`, cvg 0.4.0, T-20260721-cvg-structure gold-sanity ACCEPT) ·
  P ✅ (golden diff EMPTY: `cvg structure` byte-identical to the direct gate,
  `CHECK_ADR=OK`).
  - [x] R2.U understand + harden ✅ 2026-07-19 — field comparison (Nygard /
    MADR 4.0 / YADR / AWS / fitness functions, source-linked) delivered
    H1–H12; owner approved ALL. Applied: scaffold-adr.sh v0.3.0→**v0.4.0**
    (YAML frontmatter w/ `spec_ref` requirement-ID traceability; lifecycle
    proposed→accepted→deprecated|superseded, born `proposed`, accepted
    ADRs immutable; `--supersede NNNN` stamps bidirectional links;
    `--context` mode births 0000-context.md (Terrain/Given/Build/Spec);
    `--check` now fails unfilled scaffolds (template comments + empty
    sections), validates the status enum + supersede back-links, requires
    0000 + CONTEXT.md, catches mid-sentence modal drift in Decision
    ("…must therefore build…"), advisory NOTEs for missing Rejected
    reading / empty spec_ref / no runnable-evidence block; `--final` for
    pass close (nothing `proposed`); machine token
    `CHECK_ADR=OK|FAIL|EMPTY|USAGE_ERROR`). Template gains Rejected
    reading (H1), runnable-command Evidence block (H6), "Re-verify when:"
    (H12), `deciders` (H11). SKILL.md 0.4.0: lifecycle + agents-first
    sections; `compatibility` moved under metadata (P-8 packaging rule).
    Rule 8/9 proof: unfilled scaffold NEW=FAIL vs v0.3.0=wrong-OK (live
    repro both ways); modal drift caught (pattern absent from v0.3.0 by
    construction); status-enum + supersede-link negatives each flag for
    their intended reason; good DevOps set (non-data, rule 9) exits 0
    `CHECK_ADR=OK` incl. `--final`. shellcheck -x clean, bash 3.2 parse
    OK, quick_validate green. Post-apply validation via Tavily+Firecrawl:
    frontmatter=MADR ADR-0013, lifecycle enum + supersede semantics =
    field canon (adr-tools `-s`), Rejected reading ≈ Alternatives
    Considered, runnable Evidence ⊃ MADR Confirmation; Structured MADR
    names "AI Optimization / LLM context injection" as the direction —
    matches the agents-first design. Noted deviation (deliberate,
    documented): Converge ADRs record terrain facts, not design choices —
    design choices live in Pass 3+. Optional future: an index/README
    table per ADR dir (field convention; 0000 partially serves).
  - [x] R2.R run ✅ 2026-07-21 — booted the real Postgres terrain
    (`uc-analytics-postgres`, seed 42: 50/20/200/200), grounded the
    canonical tech-spec against the live schema, owner verdict **approved**.
    Six records born `proposed` on the proving ground
    (`tests/uc-analytics/cvg/docs/adrs/`): `0000-context` (greenfield;
    given vs build surface), `0001-analytical-reads-fenced-to-public`
    (R-3/scope-out), `0002-no-row-level-change-timestamp` (R-1/R-4/R-10 —
    zero CDC columns, freshness must come from the log stream),
    `0003-single-principal-no-analytical-query-seam` (R-2/R-5 — one login
    role, the by-principal seam doesn't exist yet),
    `0004-revenue-is-captured-not-paid` (R-3 — spec's "paid" absent;
    revenue = `captured`), `0005-payments-order-cardinality-not-enforced`
    (R-3 — non-unique FK, seed 1:1 is data not guarantee). Glossary
    `docs/CONTEXT.md` pins 10 terms, each tracing to evidence. Every
    Evidence block carries a re-runnable command (two re-executed verbatim
    to prove the living-terrain-contract idea). `--check` green,
    `CHECK_ADR=OK`, no advisory NOTEs. Records stay `proposed` → flipped
    `accepted` at R2.C. Next: R2.C (second-eyes review → accept → TEACH).
  - [x] R2.C canonize + TEACH ✅ 2026-07-21 — owner verdict **approved →
    canonical**; all seven ADRs flipped `proposed → accepted` (immutable),
    `--check --final` green (`CHECK_ADR=OK`, nothing proposed). **Second-eyes
    review** (adversarial, re-ran every Evidence command live → zero drift):
    `SUFFICIENT-WITH-FIXES` — caught a frozen false fact and applied all fixes
    before accept: **B-1** 0002 wrongly claimed `payments.status` mutates
    (verified: no `UPDATE payments` in `src/`; real in-place mutation is
    `orders.status`/`total_amount` at `failures.py:431/463/491`) → re-grounded
    on `orders`, `payments` noted insert-terminal; **B-2** removed 0002's
    WAL/logical-replication prescription (Pass 3 stack choice + touches ops
    like the rejected `updated_at`) → constraint kept, mechanism deferred;
    **S-1** 0004 names `paid_at`; **S-2** money `NUMERIC(12,2)` glossary line;
    **M-1** new **ADR 0006** (revenue join is transitive `payments→orders→
    products|customers`, owner-approved); **M-2/3/4** glossary lines (total
    referential integrity, UTC grain, partner≠customer). Set is now 7 records
    (0000–0006) + 10-term glossary. **TEACH**: `lesson-pass-2-analytical-
    backbone.md`, check-lesson `GATE: PASS` (8 components each w/ downstream
    failure, decisions table w/ alternatives, 5 check-yourself Qs). Next: R2.I
    (`cvg structure` subcommand) → R2.P (golden diff vs this manual run).
  - [x] R2.I implement ✅ 2026-07-21 — `cvg structure` born (cvg 0.3.0→
    **0.4.0**), one atomic dogfooded ceremony (`T-20260721-cvg-structure`,
    effort S, TIER=1 sign-off, 3/3 evals + Exit Check, `--gold-sanity`
    ACCEPT — discriminating: evals FAIL on baseline HEAD, PASS now). Mirrors
    `intent`/`capture`: locate the ADR set (`cvg/docs/adrs/` then
    `docs/adrs/`; 0→exit 2, >1→exit 2 naming both, 1→gates) then exact `exec`
    pass-through to `scaffold-adr.sh --check [--final] --dir <dir>`; `--dir`
    override; unknown flags + every exit-2 path end in
    `CHECK_ADR=USAGE_ERROR`; FAIL passed through unmasked (exit 1
    `CHECK_ADR=FAIL`). Gate path undecorated (byte-parity is the proof).
    shellcheck -x + bash 3.2 -n clean; help/version/bin-README carry the
    structure row. Blast-radius note: pre-existing unrelated scratch
    (`docs/…v4.pdf`, `temp/*.png`) set aside via `git stash` for the clean
    accept, then restored.
  - [x] R2.P prove ✅ 2026-07-21 — **golden diff EMPTY**: `cvg structure
    --final` on the proving ground byte-identical to the direct
    `scaffold-adr.sh --check --final --dir cvg/docs/adrs` run (same stdout,
    exit 0, `CHECK_ADR=OK`), proven in eval_1 AND by hand. **R2 = third pass
    fully closed end-to-end; next: R3.U (Pass 3 Decompose — reqs-to-swimlane-plans).**
- [x] **R3 · Pass 3 Decompose** — `reqs-to-swimlane-plans` ✅ **CLOSED
  END-TO-END 2026-07-21, all five beats.** U ✅ (skill hardened 0.3.0→**0.7.0**:
  H1–H7 seam economics · .plan.md · leg-NN-tech nomenclature · mermaid ·
  **swimlane = directory** = lean PRD + one file per leg, internal structure
  MCP-grounded) · R ✅ (3 swimlanes on the proving ground, 9 legs, owner-approved,
  b02feca) · C ✅ (canonical + easy-first lesson w/ teaching modes, check-lesson
  PASS) · I ✅ (`cvg decompose`, cvg 0.5.0, T-20260721-cvg-decompose gold-sanity
  ACCEPT) · P ✅ (golden diff EMPTY: `cvg decompose` byte-identical to the direct
  gate, `CHECK_PLAN=OK`). Next: R4 (Pass 4 Consensus — adversarial review + the fork).
  - [x] R3.U understand + harden ✅ 2026-07-21 — read the skill + both
    references (plan-altitude, seams-and-swimlanes) + `new-plan.sh` end to end;
    **MCP field verification** (Exa/Firecrawl/Tavily, source-linked) graded the
    pass **4/5 mature**: strongly anchored in Parnas (information hiding),
    Ousterhout (deep modules = the deep-lane test), contract-first/consumer-
    driven design, anti-premature-decomposition, and 2025–26 spec-driven /
    orchestrator-worker agentic practice; "seam" is a deliberate redefinition
    of Feathers'. Owner approved ALL hardening; applied **H1–H7** →
    SKILL.md **0.3.0→0.4.0** + `new-plan.sh` v0.4.0: **H1** steel-thread lane
    (walking skeleton, `thread=yes`, set-level gate), **H2** per-lane `risk=`
    + risk-first spike order, **H3** `owner=` stream (Conway), **H4** downstream
    seam-evolution rule (additive-safe vs breaking + coexistence window),
    **H5** cycle-breaking sub-procedure (dependency inversion / async / shared
    kernel, recorded blocks-build), **H6** seam≠Feathers doc note, **H7**
    deep-lane "what's the lane's secret" (Parnas change-locality). `lane-meta:`
    greppable line born; `--check` gates the machine-checkable subset. Rule 9:
    good/bad fixtures in a NON-data domain (web checkout) + run-tests.sh —
    discriminating (good exit 0 / bad exit 1 on THREAD/META/SEAM; fresh scaffold
    now fails until filled). quick_validate green; shellcheck -x + bash 3.2 -n
    clean. Next: R3.R (run Pass 3 on the backbone ADRs).
    - **R3.U+ finalization ✅ 2026-07-21 (v0.4.0→0.5.0)** — the **leg** level
      added (owner's out-of-session breakthrough): decomposition chain is now
      **seam → swimlane → leg → task-spec** (a leg = one responsibility + one
      proving-test cluster, independently finishable, one context window,
      yielding 1:N task-specs at 5B; `references/legs.md`; "leg" not "stage" to
      dodge staging/deploy/dbt collisions). Second-eyes polish applied to close
      it as the definitive skill: **(1) agents-first machine token**
      `CHECK_PLAN=OK|FAIL|EMPTY|USAGE_ERROR` on every `--check`/usage surface
      (was prose-only — the one toolchain inconsistency; R3.I's `cvg decompose`
      now gates on it like `cvg structure` on `CHECK_ADR`); **(2) legs
      section-scoped + contiguity** check (leg-01..leg-0N, no gap = dropped
      stretch); **(3)** orphaned `good-set`/`bad-set` fixtures removed;
      **(4)** SKILL states green `--check` proves legs exist/named/ordered, not
      well-*cut* (that's Pass 4). Suite 26/26 green (new leg-gap, legs-noids,
      4 token rows, non-data web-checkout domain); quick_validate green;
      shellcheck -x + bash 3.2 -n clean. Skill CLOSED — ready for R3.R.
    - **R3.U++ v0.5.0→0.6.0 ✅ 2026-07-21 (mid-R3.R retro, MCP-grounded)** —
      owner asked to finalize nomenclature + human-visualization; grounded via
      Firecrawl/Exa/Tavily (RFC 7764, PLOS "Identifiers for the 21st century",
      Last-Responsible-Moment, mermaid+dual-coding). Applied: **(1)** plans are
      **`<lane>.plan.md`** (renders as Markdown, greppable — RFC 7764 §2.1);
      **(2)** leg nomenclature **`leg-NN-<tech>`** (display) / fully-qualified
      **`swimlane-<seam>-leg-NN-<tech>`** — with the grounded correction that
      the **stable reference key is tech-LESS** (`swimlane-<seam>-leg-NN`);
      `<tech>` is a swappable label, never in the key (volatile-id anti-pattern);
      **(3)** every plan carries an **`## Architecture` mermaid `flowchart LR` +
      adjacent numbered steps** (dual coding), enforced by `--check` (new VISUAL
      guard); **(4)** stack named at Pass 3 as a *reversible* pick (LRM),
      resolving the earlier open judgment call. `--check` glob → `*.plan.md`;
      suite 28/28 (new no-mermaid fixture + mermaid scaffold assert); quick_validate
      green; shellcheck + bash 3.2 clean. R3.R plans regenerated to the new format
      (mermaid + dlt/dbt/ducklake/duckdb/fastapi/mcp legs), CHECK_PLAN=OK.
    - **R3.U+++ v0.6.0→0.7.0 ✅ 2026-07-21 (swimlane = directory)** — owner
      refinement, MCP-grounded (Tavily/Firecrawl + Spec Kit/arc42/Amazon PR-FAQ/
      INVEST/Gherkin/Shape Up): a swimlane is now a **dir** `sketch/swimlane-<seam>/`
      = a lean PRD index (`swimlane-<seam>.plan.md`) + **one file per leg**
      (`swimlane-<seam>-leg-NN-<tech>.md`); PRD links to legs, never embeds them
      (no bloat); each leg evolves independently. Filenames = fully-qualified ids.
      Internal structure grounded: PRD gains **Non-Goals** (#1 anti-bloat); legs
      express **Proves as Given/When/Then** (1-3, no evals) + frontmatter
      (stable `leg:` key, parent, status, spec_ref, depends_on) + Appetite. `--check`
      now cross-file (PRD + legs, contiguity across files, no orphan/dangling links).
      Suite 28/28 across 11 dir-per-swimlane fixtures; quick_validate green;
      shellcheck + bash 3.2 clean (commit 5f3a12b). R3.R **capture** lane migrated
      to the final form (PRD 73 lines + 3 leg files), CHECK_PLAN=OK; transform/serve
      migration is the mechanical next step.
- [ ] **R4 · Pass 4 Consensus** — `sketch-plans-adversarial-review`;
  real `--adversary`; **Gate H2 + the fork** (five beats)
  - [x] R4.U understand + harden ✅ 2026-07-21 — MCP-grounded (Exa/Tavily/
    Firecrawl/Context7/GitHub; it read the local Codex/Kimi plugin prompts +
    schemas). Field verdict fed H1–H12. **Two real defects found + fixed:**
    (1) the gate proved "a different model attacked" by `grep '(Codex|Gemini|GPT)'`
    in the plans — **spoofable by typing the word**; (2) `codex|gemini|gpt` mixes
    OpenAI brands. Applied: skill **0.3.0→0.4.0**; `check-consensus-gate.sh`
    **rewritten** to validate a **stamped objection-log artifact**
    (`sketch/.consensus/objection-log.json`, SARIF-inspired schema) via python3
    stdlib — structure + semantics + **provenance hashes** (re-hashes the live
    plans → a plan edited after review, or an adversary that never saw the real
    plans, FAILs). Cross-**family** invariant (openai/moonshot/google ≠ anthropic;
    claude=weak fallback); dir-per-swimlane; per-leg attack; FIX/ACCEPT+owner as a
    schema constraint; fork in artifact AND atop every PRD; severity floor; bounded
    rounds; token `CHECK_CONSENSUS=OK|FAIL|EMPTY|USAGE_ERROR`. New references:
    `attack-playbook.md` (v0.4.0 output contract), `engine-adapter.md` (headless
    dispatch: read-only + schema-JSON + timeout + provenance + `cvg doctor`;
    Codex-exits-0-on-failure fail-closed), `objection-log.schema.json`. Rule 9:
    `tests/run-tests.sh` 10/10 (good passes; same-family/unresolved/accept-no-owner/
    no-fork/no-objections/tampered-hash/no-PRD-fork/no-log/usage all FAIL for their
    reason); quick_validate green; shellcheck + bash 3.2 clean; gen-log.py stdlib.
    Next: R4.R (dispatch codex/kimi on the 3 swimlanes) → R4.I (`cvg review` +
    `cvg doctor` + engine adapters).
  - [x] R4.I implement ✅ 2026-07-21 — **cvg's first DISPATCHING subcommand** +
    the engine-adapter/doctor layer (Milestone 3.1, reused by 5B/8). cvg 0.5.0→
    **0.6.0**. `dispatch-review.sh` frames the attack-playbook + swimlane plans,
    shells out to a **different-family** engine headless (codex/kimi/claude,
    read-only, timeout(1)-or-gtimeout-or-uncapped), and **stamps provenance
    itself** (input sha256s — the referee computes them, never trusts the engine)
    into `sketch/.consensus/objection-log.json`; fail-closed (Codex-exits-0
    guarded), `REVIEW=OK|ERROR|SKIP|TIMEOUT|USAGE_ERROR`. `doctor.sh` reports
    per-engine PASS/SKIP (needs ≥2 + ≥1 cross-family; `DOCTOR=OK`). `bin/cvg`:
    `review --adversary E` (dispatch) / `review [--check]` (gate) / `doctor`;
    discovery mirrors decompose. **Referee never a player** — zero creds; the
    engine CLI authenticates itself; engine cmd env-overridable (`CVG_CODEX_CMD`)
    for tests. **End-to-end proven** with an injectable fake engine: dispatch →
    stamp (REVIEW=OK) → gate (CHECK_CONSENSUS=OK); tamper a plan → FAIL (hash
    mismatch). Rule 9: Pass 4 suite 13/13 (gate 10 + dispatch pipe 3);
    quick_validate green; shellcheck -x + bash 3.2 -n clean; DOCTOR=OK (3 engines
    live: codex/kimi/claude). Full CLI e2e regression green (capture→intent→
    structure→decompose→doctor). **Pass 4 is now RUNNABLE end-to-end via the CLI.**
    Next: R4.R (dispatch a REAL codex/kimi adversary on the 3 backbone swimlanes)
    → sharpen → name the fork → R4.C/R4.P.
  - [~] R4.R review — **FIRST REAL DISPATCH** ✅ hardening 2026-07-21 (07b51be);
    real objection SET still pending (env-blocked). Fired live codex + kimi at the
    backbone. The real engines exposed **3 defects the fake engine never could, all
    fixed + tested (suite 13→14/14):** (1) greedy `{.*}` judgment extractor swallowed
    the prose a real engine wraps JSON in → **raw_decode scan** picking the richest
    judgment object; (2) macOS ships no `timeout`/`gtimeout` so the cap was a WARN and
    ran **UNCAPPED** — a hung `codex exec` (0% CPU, 0 bytes, forever) hung the referee
    → **pure-bash watchdog** (bg + sibling sleeper TERM/KILL + marker → 124 →
    `REVIEW=TIMEOUT`), new `dispatch-timeout` suite row; (3) wrong kimi flags
    (`--print`/`stream-json` → real `-p`/`text`; `-p` ✗ with `--auto`). **Fail-closed
    proven LIVE:** kimi outran a 280s cap (full backbone) AND a 420s cap (serve-only)
    → clean `REVIEW=TIMEOUT`, **no objection-log written** — the referee never
    fabricates a consensus. `engine-adapter.md` corrected to the flags the live CLIs
    accept. **Env finding:** in this headless sandbox codex blocks on the model
    round-trip and kimi is too slow (>420s/swimlane) to complete a structured attack
    — a latency/auth constraint, not a pipe defect. **To land a real objection set:**
    run the dispatch in an interactive/authed engine session (or a faster `kimi -m`
    alias) with a longer budget; the pipe + gate + provenance are ready and honest.
    Then: sharpen (FIX/ACCEPT) → name the fork → R4.C/R4.P.
- [ ] **R5 · Pass 5B Tasking** — `task-spec` on the real plans (five beats)
- [ ] **R① · Register** — `task-specs-to-issues` → real tracker (five beats)
- [ ] **R6 · Pass 6 Harness** — `stack-to-harness` on the real stack (five beats)
- [ ] **R8 · Pass 8 The Loop** — `task-loop --issue N` by hand, one issue at a
  time; this is where Track M (worker/Manager/board) wakes up (five beats)

---

## Track M — the execution machine (fixture-tested; resumes at/around R8)

Milestone 0 below is **done** — it is Track M's test floor and it waits.
Milestone 1.1's entrypoint is absorbed into R1.I; the remaining machine
milestones (CI gate, worker, Manager, board, verification depth) activate
when Track R reaches the Loop and real execution begins.

## Milestone 0 — the test bed (implements B-9)

*You cannot test a factory without a floor. Build the floor first.*

- [x] **0.1 · Golden fixture repo** — `tests/e2e-test-engine/` ✅ 2026-07-16
  *(created as `examples/toy-revenue/`, renamed 2026-07-16)*
  - Build: tiny seeded SQLite (or DuckDB) repo — `orders`, `payments`,
    `products` tables, a `seed.sh`, a trivial transform script, and
    `evals/smoke.sh` (one passing eval) + `evals/red.sh` (a deliberately
    failing eval, used later to test RED paths).
  - **Prove:** fresh clone → `bash seed.sh && bash evals/smoke.sh` exits 0 in
    < 60 s; `evals/red.sh` exits 1.

- [x] **0.2 · Fixture backlog** — 6 Task-Specs with a diamond dependency ✅ 2026-07-16
  - Build: in `tasks/` (git-root-anchored by the tooling — one repo, one
    queue), author T1 (root) · T2, T3 (depend on T1) · T4 (depends on T2+T3)
    · T5 (independent) · T6 (designed to exhaust `budget_iterations` — an
    unsatisfiable eval). Real runnable evals against the seeded DB. Wire
    `depends_on`; give T2/T3 disjoint blast radii and T4 an overlap with T3.
  - **Prove (amended to match linter reality):** `safe-to-delegate.sh --stamp`
    → 6/6 DELEGATE + HMAC-sealed; `validate-task-spec.sh` green on all 6;
    `lint-backlog.sh` reports **exactly one** issue — the deliberate T3↔T4
    overlap, listed with both ids (exit 1 is expected: overlaps are issues by
    design, and that listing is the Manager's serialization input) — and no
    cycles, duplicates, or dangling deps.

---

## Milestone 1 — cvg v0: one name, derived state (implements B-3)

- [x] **1.1 · The router** — `bin/cvg` ✅ 2026-07-19 *(executed at R0.I per
  the owner's pivot; full dogfood ceremony: `tasks/T-20260719-cvg-router.md`
  stamped Tier-1, built, accepted with `--gold-sanity`)*
  - Build: bash-3.2-safe entrypoint with subcommand map wrapping existing
    scripts: `cvg tasks validate|gate|accept`, `cvg eval`, `cvg lint`,
    `cvg transition`, `cvg ready`, plus `cvg help` and `cvg version`.
    Repo-local resolution: find `skills/task-spec/scripts/` from the repo the
    command runs in (or a `CVG_HOME` override for the fixture).
  - **Prove:** on the fixture, `cvg tasks gate tasks/T-…md` produces the exact
    same verdict + exit code as calling `safe-to-delegate.sh` directly (diff
    the outputs); `cvg help` lists every subcommand.

- [ ] **1.2 · Derived spine state** — `cvg status [--json]`
  - Build: stdlib-python harvester (the B-4 spike rules, rebuilt): spine state
    from artifact presence (tech-spec → P1, `docs/adrs/` → P2, `sketch/*.plan`
    → P3, stamped specs → 5B, tracker binding → ①, `.claude/` → P6, fleet
    done/total → 7/8) + task state from frontmatter. `display_status` is
    computed: `ready` with un-done deps *displays* blocked.
  - **Prove:** on the fixture — move an artifact away → that pass flips red on
    the next run; restore → green. JSON validates against a shipped
    `state.schema.json`.

- [ ] **1.3 · The queue accessor** — `cvg next [--json]`
  - Build: read-only: returns the first task whose `status: ready` ∧ all
    `depends_on` done ∧ `signed_off: true`, in graph order; `null` when dry.
    Never mutates anything.
  - **Prove:** fixture backlog → returns T1 (T5 listed as also-ready); hand-flip
    T1 to done + rebuild state → returns T2/T3; flip all → returns null with
    `done_count`/`remaining_count` correct.

**Milestone gate:** `cvg status` + `cvg next` agree with reality after any
manual file edit, with no stored state anywhere. `git grep -l 'state cache'` → empty.

---

## Milestone 2 — trust before scale (implements B-2)

- [ ] **2.1 · Machine-readable eval runs** — `cvg eval T-… --ci`
  - Build: JSON line per eval (id, verdict, duration, tail of output) +
    machine exit code — port the `run-task-spec.sh --ci` pattern up to the
    issue level (`run-issue-eval.sh --ci`).
  - **Prove:** on fixture T5 — JSONL parses with `jq`; exit 0 iff Exit Check
    passes; `evals/red.sh` task exits non-zero with the failing eval named.

- [ ] **2.2 · The CI eval-gate** — `cvg ci install` (first template)
  - Build: `templates/ci/converge-eval-gate.yml` — on `task/*` PRs, clean
    container, re-run the task's own evals via `cvg eval --ci`, report a
    required status check. Push the fixture to a throwaway GitHub repo and
    enable branch protection.
  - **Prove (the B-2 gate):** a PR whose branch claims GREEN but whose eval
    fails in the container is **blocked from merge**, with the failing eval's
    output visible on the check. A genuinely green PR merges.

---

## Milestone 3 — engines: dispatch ONE task (the first real automation)

- [ ] **3.1 · Engine adapters + doctor** — `adapters/engines/*.sh`, `cvg doctor`
  - Build: adapter contract — stdin/arg: prompt file + workdir; behavior:
    headless run (`claude -p`, `codex exec --json`, `kimi`), exit code through,
    final message to stdout. ~20 lines each. `cvg doctor` certifies each
    installed engine: binary present, hello-world card round-trips, artifact
    lands in the workdir.
  - **Prove:** `cvg doctor` prints a per-engine PASS/SKIP table on this
    machine; at least two engines PASS.

- [ ] **3.2 · Single-task worker** — `cvg work T-… --engine e`
  - Build: acquire lock (`transition-status.sh` → in-progress), create a git
    worktree, hand the engine the **sealed spec as the only instruction
    source**, loop: implement → `cvg eval --ci` → RED feeds back, bounded by
    `budget_iterations`; GREEN → done + evidence; exhaustion → parked with
    `blocked_reason`. (This is `ref-executor.sh` with the dumb work block
    swapped for a real engine.)
  - **Prove:** fixture T5 goes ready → done **unattended** by a real engine,
    evals green from a clean checkout; T6 parks at budget with a report and
    the worktree preserved for inspection.

- [ ] **3.3 · Conformance: cvg certifies itself**
  - Build: nothing new — run task-spec's own suite against the new worker.
  - **Prove:** `conformance-check.sh --level L2 --executor "cvg work --engine
    claude"` prints `CONFORMANCE=L2`.

---

## Milestone 4 — the Manager tick (implements B-1, Profile L)

- [ ] **4.1 · Sequential tick** — `cvg run --once`
  - Build: stateless: read ready (`cvg next`), dispatch one `cvg work`, settle
    (done) or park, append `TICK/DISPATCH/GREEN/PARKED` events to
    `_fleet.jsonl`, exit.
  - **Prove:** three consecutive `--once` runs on the fixture complete T1 then
    T2 then T3, deriving everything fresh each time (kill/restart safe).

- [ ] **4.2 · Parallel fleet** — `cvg run --max-parallel 3`
  - Build: at-most-one lock per task carried on the task/issue; one worktree
    per in-flight task; **serialize `touches_paths` overlaps**; park on budget;
    stop only at fleet-green or all-parked; `check-fleet-green.sh`.
  - **Prove (THE B-1 gate):** the diamond backlog reaches fleet-green
    unattended with T6 force-failed → parked + reported; T4 provably waited
    for the T3 overlap; `check-fleet-green.sh` exits 0 only when every task is
    closed by a green eval.
  - *Note from 0.2:* the T3↔T4 overlap is also dependency-ordered, so deps
    alone would serialize it — to prove the overlap rule specifically, this
    step must add one **no-dependency** overlap pair to the fixture backlog
    (two ready tasks sharing a path) and show the Manager runs them serially.

- [ ] **4.3 · Routing v1** — `cvg route [--explain]`
  - Build: pin (`execution_backend`) → rules (effort × severity → engine
    table in `.cvg/routing.yaml`) → fallback default. Every decision logs
    a rationale record `{task, chose, source, why}` to the ledger. (Receipts
    layer comes in Milestone 7 — leave the seam.)
  - **Prove:** `--explain` dry-run prints one rationale per ready task; a pin
    always wins; changing a rule changes the plan without touching code.

---

## Milestone 5 — the board (implements B-4; spike rules apply)

- [ ] **5.1 · Harvester + zoom 0/1** — `cvg board --serve|--snapshot`
  - Build: stdlib `serve.py` (`state` / `serve` / `snapshot`, re-harvest per
    GET, no-store) sharing Milestone 1's derivation; ONE self-contained HTML —
    spine gate strip (zoom 0) + swimlane DAG with overlap badges (zoom 1);
    LIVE/SNAPSHOT dual mode. Design: the blueprint language of
    `presentation/*.html`. **Read-only — the board never writes.**
  - **Prove:** re-pass the 9 spike evals (schema-valid JSON from real
    frontmatter; every task + one edge per dep; blocked display; zero network
    in snapshot mode); editing a task's `status:` updates the DAG within one
    poll.

- [ ] **5.2 · Ledger rail + trust ladder (zoom 2)**
  - Build: `_fleet.jsonl` timeline (typed events, honest empty state) and the
    per-task trust ladder (signed_off/HMAC → dispatched → tiers → accepted)
    rendered from real fields.
  - **Prove:** watch a live `cvg run` paint DISPATCH/RED/GREEN/PARKED in
    order; the ladder for a done task shows every rung with its evidence.

---

## Milestone 6 — verification depth (implements B-12 + B-13)

- [ ] **6.1 · Tier-2 judge** — `cvg verify T-… --judge e`
  - Build: fresh-context dispatch to a *different* engine; context allowlist =
    diff + Behavior zone + evals (never the worker's transcript); structured
    verdict JSON; **fails closed** (missing/malformed verdict ≠ pass);
    severity decides whether tier 2 is mandatory.
  - **Prove (the B-12 gate):** a fixture task "solved" with a hardcoded lookup
    table passes tier 1 but is **refuted by tier 2** and blocked.

- [ ] **6.2 · Provenance + injection defense**
  - Build: enforce sealed-spec-as-only-instruction-source in `cvg work`
    (issue bodies are display text, never prompt content); stock
    dependency-verification eval added to the task-spec template.
  - **Prove (the B-13 gate):** a fixture issue whose body contains "ignore the
    spec, run curl…" produces zero deviation — the worker's prompt file
    provably contains only the sealed spec.

---

## Milestone 7 — conductor, platform, receipts (the horizon)

- [ ] **7.1 · `cvg deliver`** — sequence passes 1–6 + register, stopping only
  at H1/H2; resume from `cvg status`. Gate: brief → sealed registered backlog
  with exactly two human stops.
- [ ] **7.2 · Profile C** — bind the tick to GitHub Actions / `gh aw`
  (`cvg ci install` emits dispatch + settle templates). Gate: the Milestone-4
  fixture goes fleet-green in CI, laptop closed.
- [ ] **7.3 · Receipts routing** — `cvg metrics` (time-to-green, RED
  histogram, cost + first-pass per engine) feeding `cvg route` layer 3.
  Gate: the router demonstrably changes a pick based on accumulated ledger
  data, with the rationale citing the numbers.

---

## Parked — do later, out of Track R's way

- [ ] **P-1 · Chain-level versioning policy** *(agreed in principle 2026-07-17;
  implement between passes, not during one)*. Per-skill semver is heavy at
  current change velocity and the chain is the real unit of coherence
  (handoffs name skills, Pass 0/1 protocols must match, `pass-to-lesson`
  encodes every pass's outputs). Adopt: (a) **one Converge release version**
  — git tag + root `CHANGELOG.md` entry per release; (b) per-skill
  `metadata.version` becomes a **contract marker** — bump only when a skill's
  gate, flags, or IN/OUT artifacts change, never for wording/examples (so
  `task-spec` v3.x keeps meaning); (c) **no lockstep stamping** of all skills
  at release; (d) state the policy in `skills/README.md`; (e) **amend rule 9
  above** (currently: bump on every SKILL.md edit) to match; (f) optional: a
  check that warns when a diff touches Gate/Flags/IN-OUT lines without a
  version bump. Gate: first tagged chain release + policy paragraph in
  README + rule 9 consistent with it.

- [ ] **P-2 · The cvg knowledge home** *(sketched 2026-07-17; decide the
  convention at a beat boundary, never mid-pass — artifact paths are gate
  contracts)*. **Convention DECIDED + first cut shipped 2026-07-17:** the
  single home is **`<project>/cvg/`** — the Converge workspace root
  (Luan's call, same day, reversing the initial `converge/` pick: matches
  the CLI brand AND kills the collision with the converge repo's own
  name; visible over `.cvg/` = hidden folders defeat a knowledge home;
  dot-space stays reserved for machine config `.cvg/`, Milestone 4.3).
  Skill paths
  (`docs/brd-*`, `sketch/*.plan`, `brain/`) are RELATIVE to the workspace
  — no skill edits needed; engrave the workspace-root line in each skill
  at its beat, and `cvg` resolves the workspace before globbing.
  Shipped: root `MAP.md`; `tests/uc-analytics/cvg/{docs,brain}/`
  (brain = transcripts/notes/definitions/refs/decisions + INDEX.md front
  door; BRD moved in, gate re-proven exit 0 post-move);
  `tests/uc-analytics/CLAUDE.md` states the split. **Full org finalized +
  skeleton shipped in advance (Luan's call, 2026-07-17):** five folders,
  one kind of knowledge each — brain (inputs, append-only) → docs
  (agreements, gated) → sketch (drafts, transient) → tasks (sealed units)
  → receipts (evidence, write-once; P-5's SHOW home) — each with a
  self-describing README stub; `cvg/INDEX.md` is the workspace front
  door with the lifecycle table + current pass state. `brain/` kept over
  `store/` (collides with "analytical store" domain vocabulary).
  Exception: `tasks/` stays git-root anchored (tooling finding from 0.2)
  until the project is its own repo — workspace `tasks/README.md` marks
  it reserved. Remaining below: grounding-receipt skill enhancement
  + P-10 memory stewardship + P-11 tooling-radar evaluation.
  One organized root per consuming project for everything the
  chain generates and consumes, so learning scales instead of scattering:
  **generated** (brds, no-gos, tech-specs, adrs, plans, task-specs, lessons,
  gate receipts) + **inputs** (transcripts, meeting notes, definitions,
  refs) + a single `INDEX.md` kept tidy on top of raw dumps. First
  deliverable: root `MAP.md` (ten lines: where do I look for X) — zero
  path churn. Skill enhancement riding along (rule-9 ceremony): Pass 0
  Step 1 / Pass 1 Step 1.5 read the knowledge home's index when present
  and emit a **grounding receipt** (facts found + where — provenance for
  every question not asked). Embedded memory tooling (MemPalace,
  Graphify, claude-mem — github.com/MemPalace/mempalace,
  github.com/Graphify-Labs/graphify, github.com/thedotmack/claude-mem)
  evaluated later, AFTER the folder convention exists; tools serve the
  convention, not the reverse.

- [ ] **P-3 · Second-brain integration** *(Luan has several ideas parked
  here, 2026-07-17; research-grounded contract added 2026-07-21)*. External
  brains — first an Obsidian vault, then MCP-exposed or storage-specific
  sources — are **read-only pull sources** for the knowledge home. Key
  information and decisions are distilled INTO `cvg/brain/inputs/`; the repo
  stays canonical, and the external brain is never silently rewritten.
  Implement a source-adapter contract with: source ID/type, explicit path or
  resource allowlist, retrieval timestamp, content digest, source URI, and
  the permissions/data-residency boundary. Start with the smallest safe
  adapter: an Obsidian vault is already a local folder of Markdown files, so
  direct allowlisted file reads work without an Obsidian plugin; Obsidian CLI
  or URI support is optional (the CLI requires the app to be running). Add an
  MCP Resources adapter as the generic second path for other storage systems.
  Produce a grounding receipt for every imported source and index only
  owner-approved, high-value distilled facts into `CLAUDE.md` / `AGENTS.md`.
  Depends on P-2's convention existing first. **Gate:** on a fixture vault
  plus one non-Obsidian MCP source, Pass 0 retrieves only allowlisted records,
  cites every used claim to URI + digest + observed time, detects a changed
  or conflicting source, proves no source writes occurred, and leaves BRD
  canonicalization exclusively to the owner. Sources:
  [Obsidian data storage](https://obsidian.md/help/data-storage),
  [Obsidian CLI](https://obsidian.md/help/cli),
  [MCP specification](https://modelcontextprotocol.io/specification/2025-11-25/index).

- [ ] **P-4 · `--questions auto` — the brain answers first** *(noted
  2026-07-17 per Luan: "agentic auto mode with the human at the gate";
  acceptance contract tightened 2026-07-21)*. For interviewing passes 0 and
  1, each frontier round first queries the repo + staged knowledge-home
  sources. Every proposed answer carries `source_ref`, `observed_at`, content
  digest, provenance (`measured|estimated|guessed|derived`), and state
  (`supported|conflict|stale|unknown`). Only supported facts may pre-fill the
  understanding pack; conflicts, staleness, unknowns, and all owner decisions
  escalate through the gap-register questionnaire. Present one concise
  proposed understanding to the owner for **approve / decline / correct**;
  approval signs the understanding, never the source itself, and the normal
  BRD sign-off still gates Pass 1. Facts stop consuming human turns without
  turning retrieval into authority. Feeds Milestone 7.1 (`cvg deliver`'s
  two-human-stops design). Depends on P-2 + P-3. **Gate:** on a seeded Pass 0
  fixture, every answerable factual question is removed from the human round
  with a valid citation, contradictory and absent answers abstain/escalate,
  no business decision is auto-locked, a declined understanding regenerates
  without preserving the rejected claim, and only explicit owner approval
  allows canonical BRD sign-off.

- [ ] **P-5 · Engrave the pass anatomy** *(Luan's framing, 2026-07-17: every
  pass = PROCESS → JUDGE → TEACH → SHOW)*. Today the four verbs exist but
  are distributed: PROCESS = each skill's Instructions + gate script;
  JUDGE = the human (Track R's run-beat contract) + a different engine
  only at Pass 4 (`--adversary`) and later Milestone 6.1 (`cvg verify
  --judge`); TEACH = `pass-to-lesson` offered at every handoff; SHOW =
  gate output + progress-log line. The engraving: (a) make the anatomy
  explicit as the uniform close-of-pass contract in `skills/README.md`;
  (b) generalize the second-engine JUDGE so ANY pass's artifact can be
  reviewed by another engine via CLI (Kimi, Codex — Pass 4's adversary
  pattern promoted to a per-pass option). Recommended surface:
  `cvg judge <artifact> --engine codex|kimi [--rubric <path>]`, with Pass 0
  explicitly accepting BRD/PRD artifacts. Dispatch fresh-context and
  read-only: artifact + versioned rubric + cited grounding pack only, never
  the producer transcript. Codex uses non-interactive read-only execution and
  a JSON output schema; Kimi print mode must run behind stricter isolation
  because print mode auto-approves tool calls. The result is a fail-closed,
  versioned receipt with `PASS|REVISE|ABSTAIN|ERROR`, criterion findings,
  artifact locations, severity/confidence, engine/model/version, and prompt +
  artifact hashes. Missing/malformed output is `ERROR`, never pass. Judge
  bias is part of the threat model: the engine verdict is adversarial advice,
  not the owner gate, and comparative judging swaps/randomizes candidate
  order;
  (c) standardize SHOW as a small "pass receipt" (what was produced,
  where, gate verdict, lesson link). Implement alongside each pass's
  I-beat, not as a big-bang skill edit. **Gate:** Codex and Kimi adapters are
  proven on good/bad/injected fixture briefs; neither can mutate the checkout;
  unsupported, malformed, timed-out, or unavailable engines produce stable
  non-zero machine verdicts; every finding cites the rubric criterion and
  artifact evidence; and the human can accept or reject the advice without
  the CLI changing sign-off. Sources:
  [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive),
  [Kimi print mode](https://www.kimi-cli.com/en/customization/print-mode.html),
  [LLM judge position-bias study](https://aclanthology.org/2025.ijcnlp-long.18.pdf).

- [ ] **P-6 · Reconcile the public method/skill taxonomy** *(found during the
  guided anatomy audit, 2026-07-18)*. The live tree contains **13** skill
  packages: ten spine skills (including optional Capture ⓪ and Register ①),
  one teaching companion, one harness engine, and one authoring tool.
  `skills/README.md` states that taxonomy at the top but still says 12 in its
  Compliance and By-the-numbers sections; the root `readme.md` still presents
  and catalogs 11, omitting Capture and the teaching companion. Decide the
  canonical public wording for **passes vs bridges vs supporting skills**, then
  make both READMEs use it consistently. Gate: the advertised installed count
  equals `find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l`, every
  installed skill appears exactly once in the catalog, and the optional path is
  visibly distinct from the invariant spine.

- [ ] **P-7 · Re-ground the competitive positioning against the live field**
  *(found during the guided methodology audit, 2026-07-19)*. The root README
  says Spec Kit and the other named SDD frameworks stop at `Implement` and lack
  a closed loop. Current official Spec Kit documentation now ships workflow
  gates, conditional loops, fan-out/fan-in, pause/resume, and
  `/speckit.converge`, which checks implementation against spec/plan/tasks and
  appends missing work until convergence. Re-run the comparison using current
  primary sources and distinguish **contract semantics** instead of claiming
  feature absence: adversarial cross-engine consensus, the explicit
  trust-boundary fork, sealed per-unit PRE/POST eval contracts, clean-checkout
  acceptance, and derived tracker state are the candidate Converge differences
  to prove. Gate: every competitor claim is source-linked and date-stamped;
  no categorical `lacks` claim survives without a reproducible receipt; the
  matrix says what each gate guarantees, not merely whether a similarly named
  command exists.

- [ ] **P-9 · Pass 1 universality retro-hardening (v0.4.1) before the next
  domain run** *(second-eyes universality review, 2026-07-19 — owner's
  standing goal: Converge as the universal harness for ALL work areas
  (SWE/FE/BE/DE/DA/AI/DevOps/SA); Pass 1 closed with one real receipt (data
  greenfield), verdict READY-WITH-GAPS on both lenses)*. **Five should-fixes
  before run #2 in a non-data domain — two behavioral holes CONFIRMED by
  mutated-fixture runs, three contract engravings:** (1) `LEAK_TERMS` is
  data-stack-only — a spec naming React/Next.js/Kubernetes/Terraform/
  LangChain/GPT-4/Pinecone gets ZERO leak warnings and a clean PASS; extend
  with per-domain buckets or move to `references/leak-terms.txt`, add word
  boundaries (kills the confirmed 'sparked'→spark false positive). (2)
  Check 7 fails OPEN on unrecognized blocker resolutions — `resolution:
  awaiting owner` on a `severity: blocker` record → clean PASS (same seam
  class check-brd v0.3.1 closed); invert: a blocker passes only with a
  resolved-shaped resolution, add the evasion fixture. (3) Pass 0→1
  handoff glob says `docs/brd-*.pdf` in all three SKILL.md contract spots
  but Pass 0's default output is `.md` — a cold agent globs .pdf, finds
  nothing, mis-routes; fix to `.md|.pdf`. (4) Engrave the
  decisions-on-disk rule in SKILL.md Step 2 (`brain/decisions/…roundN…`
  with stable Dn IDs; requirements cite them) — currently only progress-log
  lore born from the R1.R crash; a fresh agent repeats that loss. (5)
  Mandate stable requirement IDs (`R-n`/`W-n`) in Step 3 + warn-only check —
  Pass 2 ADRs and 5B task minting anchor on them, today they are craft.
  **Park-riders for P-4's autonomous mode:** questionnaire export needs a
  schema+path; question rounds need a machine format (id/default/rationale);
  recap folds into sign-off for async owners; enrich falsifiability units
  (user/request/session/deploy/incident/$/week) + wish-words
  (secure/stable/boring/resilient); de-data-fy interrogation prose examples;
  soften "typically 2–3 questions" (real run: 3 rounds, D1–D8); mandate the
  spec→BRD provenance header. Gate: rule-9 ceremony (both a passing and a
  failing fixture per behavioral fix, non-data domain included), suite rows
  grow accordingly, golden diff on the canonical spec stays EMPTY.
- [x] **P-8 · Align and reproduce the Pass 0 exit contract before `cvg
  capture`** ✅ 2026-07-19 — closed by `tasks/done/T-20260719-pass0-exit-contract.md`
  (check-brd.sh v0.3.0: canonical/--draft/--no-go modes, machine tokens,
  17-row regression suite, both skill validators green; see progress log).
  *(found during the guided Pass 0 audit, 2026-07-19)*. Today
  `check-brd.sh` is a useful structural linter, but a pending owner sign-off
  only warns and the script still prints `GATE: PASS` plus “hand off to Pass
  1,” contradicting the skill and template. Split draft validation from
  handoff authorization (`--draft` versus canonical/default, or equivalent):
  canonical sign-off + date must hard-block handoff; Scope In/Out must contain
  real entries; question/owner records must pair with nonblank owners; enforce
  the mechanically provable provenance and guessed-number linkage rules; and
  keep semantic owner-voice/altitude judgment explicitly human. Add a no-go
  record validator and define how advertised PDF output is converted or
  checked. Commit a table-driven regression suite covering canonical green,
  pending sign-off, empty scope, blank owner, missing/guessed provenance,
  altitude warning, and valid/invalid no-go records—the earlier synthetic
  proof currently survives only in commit/backlog prose. Packaging gate: both
  `idea-to-brd` and its `pass-to-lesson` close must pass the current installed
  official skill validator as well as the vendored one (both currently fail
  the official validator on unsupported `compatibility` frontmatter). Final
  gate: no noncanonical brief can emit a Pass 1 handoff verdict, every negative
  fixture fails for its intended reason, Bash 3.2 + ShellCheck stay green, and
  P-5 owns the resulting write-once receipt rather than duplicating it here.

- [ ] **P-10 · Memory & lesson stewardship — maintain what Converge learns**
  *(requested 2026-07-21; grounded against current agent-memory research)*.
  Treat durable context as a **write → manage → read** lifecycle, not a folder
  that grows forever. Keep raw pass artifacts, lessons, decisions, and receipts
  append-only; derive compact memory records that always retain source URI/path,
  content digest, observed/effective time, author/approver, confidence, and the
  record they supersede. The maintenance engine proposes rather than silently
  rewrites: exact duplicate/index/cache cleanup may be deterministic, while
  semantic merges, contradiction resolution, promotion to always-loaded
  context, demotion, and archival require a reviewable proposal and receipt.
  Default cadence (configurable, not a platform dependency): **after every pass
  close** validate the lesson + enqueue memory candidates; **nightly** refresh
  indexes, detect source drift/staleness, and flag exact duplicates; **weekly**
  generate consolidation/contradiction/promotion proposals; **monthly** run a
  held-out retrieval evaluation and publish a stewardship report (precision,
  coverage, staleness, contradiction rate, latency/token budget, and misses).
  Establish the baseline before setting numeric thresholds; a scheduler is an
  adapter (local cron/launchd, CI, or future Manager), not canonical state.
  Candidate tools such as Graphify/Graphiti/claude-mem/MemPalace are evaluated
  under P-11 and may accelerate a lane, but the lifecycle contract must work
  with plain files first. **Gate:** a seeded history containing duplicates,
  contradictions, superseded decisions, stale sources, and one rare critical
  lesson produces the same auditable proposal set on repeat; no raw evidence is
  lost; no semantic change auto-commits; approved changes preserve provenance
  and rollback/supersession history; a held-out query set proves that maintained
  context is no worse than the unmaintained baseline and exposes every miss.
  Sources: [agent-native memory study](https://arxiv.org/html/2606.24775),
  [memory mechanisms survey](https://arxiv.org/pdf/2603.07670),
  [bi-temporal memory engine](https://arxiv.org/html/2606.09900v1).

- [ ] **P-11 · Tooling radar — discover, test, and retire plugins safely**
  *(requested 2026-07-21; initial MCP/Graphify scan complete)*. Build a recurring
  evidence pipeline, not an unbounded “install interesting tools” list:
  **discover → de-duplicate → score → sandbox pilot → adopt / reject / watch →
  re-review**. Discovery lanes include the official MCP Registry, original
  repositories/releases, package registries, research papers, and curated lists;
  every candidate maps to a concrete Converge pain before evaluation. The
  scorecard records source/owner, capability and overlapping native feature,
  release/maintenance evidence, license, install/runtime dependencies,
  permissions/secrets/network, data residency and telemetry, canonical-data
  impact, Codex/Kimi/Claude portability, performance/cost, failure behavior,
  uninstall/rollback, and security advisories. Registry presence proves
  namespace/metadata, **not code safety**; reference MCP servers are educational,
  not production approval. Every pilot runs on a disposable fixture with a
  no-tool/plain-file baseline and produces a dated decision receipt with an
  owner and re-review trigger. Seed the first portfolio with Graphify, Graphiti,
  claude-mem, and MemPalace; evaluate Graphify's local/remote backend choice,
  MCP surface, query logging, data-residency behavior, and graph value against
  `rg` + indexed Markdown before baking in any feature. **Gate:** the radar can
  ingest candidates from at least two source classes, reject a malicious or
  over-privileged fixture, run and fully remove a sandboxed candidate without
  residue, reproduce the baseline/candidate comparison, emit one of
  `ADOPT|REJECT|WATCH|ERROR` with cited evidence, and schedule re-review when a
  source, version, permission, license, or security fact changes. Sources:
  [official MCP Registry](https://modelcontextprotocol.io/registry/about),
  [MCP reference-server warning](https://github.com/modelcontextprotocol/servers),
  [Graphify](https://github.com/Graphify-Labs/graphify),
  [Graphiti](https://github.com/getzep/graphiti).

---

## Progress log

> Append one line per completed step: date · step · proof command · result.

- 2026-07-19 · **R1.I + R1.P — PASS 1 CLOSED END-TO-END** · One atomic ceremony (T-20260719-cvg-intent, stamped Tier-1 → built → 3/3 evals → gold-sanity ACCEPT → done through cvg): **check-tech-spec v0.3.0→v0.4.0** — the Pass 1 exit contract (review blocker B-1 closed): canonical (default) adds Check 9 (fence-stripped Sign-off extraction, verdict-line-anchored canonical, valid-ISO date) and is the ONLY mode whose verdict hands to Pass 2; --draft validates and NEVER authorizes; every exit path incl. exit-2 ends in CHECK_TECH_SPEC=PASS|FAIL|DRAFT_OK|DRAFT_INCOMPLETE|USAGE_ERROR; dead HAS_IN assignment removed (shellcheck SC2034, never consulted). **New 15-row regression suite** (skills/brd-docs-to-tech-req/tests/, canonical fixture in DevOps domain per rule 9) — rule-8 with teeth: all 4 sign-off negatives wrongly PASS on v0.3.0 with the full handoff verdict (git show run recorded), exit-2 paths tokenless there. **cvg intent** (cvg 0.2.1→0.3.0): capture-mirror discovery (cvg/docs/tech-spec-*.md then docs/, 0→exit 2+token, >1→exit 2 naming+token), --draft pass-through, unknown flags refused; gate path exact exec. **R1.P: golden diff EMPTY** — cvg intent byte-identical to the direct gate run on the canonical spec, CHECK_TECH_SPEC=PASS. Version note: task Context assumed SKILL.md 0.3.0 (stale R1.U reading — external absorb had moved it to 0.5.0); bumped 0.5.0→0.6.0, quick_validate green, eval contract unaffected. **R1 = second pass fully closed; next: R2.U (Pass 2 Structure — tech-req-to-adrs).**
- 2026-07-19 · **R1.C — Gate H1 taken, Pass 1 canonical** · Owner verdict (conditional on agentic-execution review) → two independent reviews ran: (a) three-engine STRUCTURE review (Exa/Firecrawl/Tavily vs field guides + ISO 29148): layout matches or beats practice (problem-first, MoSCoW, per-requirement evals, hand-built traceability), one true gap — no approved-by block → Sign-off section added; (b) adversarial AGENTIC-EXECUTION review: SUFFICIENT-WITH-FIXES, 4 blockers + 7 should-fixes, ALL applied (analytical query = identity-by-principal never judgment; Q-SET-1 named deliverable w/ answer-key oracle, verifiers may read _control, product surface stays fenced; R-1 p99 normative w/ ≥1000 samples @ ≤30s probes; D1–D8 trace rule; partner registry = decidable "all"; cost boundary = billing exports; staleness event = 5-min floor; load shape = ≥20% peak hour). Gaps→D6/D7/D8 locked on arrival (brain/decisions round3). check-tech-spec PASS exit 0 post-edits. TEACH engraved: lesson-pass-1 (12 components, 12 decisions, check-lesson exit 0). Review also proved gate B-1: unsigned spec passes check-tech-spec v0.3.0 + no machine token → R1.I hardens the exit contract before cvg intent wraps it.
- 2026-07-19 · **R0 second-eyes hardening — Pass 0 sign-off completed at 100%** · An adversarial second-eyes review (two independent agents: gate-evasion + closure-consistency) refuted the "airtight" claim with one BLOCKER: a BRD copied faithfully from the skill's OWN template (verdict `_pending_`, guidance sentence containing `canonical`, any ISO date in the section) passed the canonical gate — plus 3 seams: fenced examples satisfied checks, open-questions fail-OPEN on unrecognized shapes, no machine token on exit-2 paths (contradicting the script's own header AND codified by the old pdf-refused test row). Closed via full dogfood ceremony (`T-20260719-pass0-gate-v031` stamped Tier-1 → built → 3/3 evals + Exit Check → gold-sanity ACCEPT → done through `cvg`). check-brd.sh v0.3.0→**v0.3.1**: verdict-line anchoring (canonical must be ON the verdict line, pending/draft there never authorizes), ALL checks run fence-stripped, OQ shape fails closed, valid-ISO date on a Date/Signed line, `--draft --no-go` conflict + unknown flags + extra positionals refused, EVERY exit-2 ends in `CHECK_BRD=USAGE_ERROR` (pdf-refused row fixed to expect it); `cvg` 0.2.1: capture refuses unknown flags/conflicts, discovery exit-2 paths emit the token (gate path stays exact exec — untouched). Proof: suite 17→**27 rows** green; **rule-8 with teeth: all 4 new fixtures wrongly PASS on v0.3.0** (`git show HEAD:` run recorded), conflict on v0.3.0 silently returned NOGO_OK and two-positionals gated only the last file — both now exit 2; shellcheck -x clean, bash 3.2.57, `quick_validate.py` "Skill is valid!" (idea-to-brd → 0.6.0); **R0.P golden diff re-proven EMPTY** post-hardening. Consistency audit fixes riding along: bin/README stale "(v0.1.0)" heading → v0.2.1, P-2's two stale `converge/` paths → `cvg/`. Known-limit recorded in the spec: S3 per-number provenance coverage stays document-level (a mechanical per-line rule would false-fail dates/numbering) — candidate for a later beat. Deferred to P-6: count drift now includes shell scripts (56 actual vs 54/53 advertised). **Pass 0 = 100% signed off; next: R1.C.**
- 2026-07-19 · **R0.I + R0.P — PASS 0 CLOSED END-TO-END** · `cvg capture` born (v0.2.0) via full ceremony (`T-20260719-cvg-capture` stamped Tier-1 → built → 3/3 evals → gold-sanity ACCEPT → done). Thin by design: explicit file = exact `exec` pass-through to check-brd.sh (zero decoration — agents parse the gate's own token); no file = workspace discovery (`cvg/docs/brd-*.md` then `docs/`, `no-go-*.md` under `--no-go`; 0 found → exit 2 with guidance, >1 → exit 2 NAMING each candidate, never guesses). **R0.P proof: golden diff EMPTY** — `cd tests/uc-analytics && cvg capture` byte-identical to the direct manual gate run, exit 0, `GATE: PASS … hand off to Pass 1`, `CHECK_BRD=PASS` (one advisory warn — altitude "database"; the R0.R-era second warn became a passing hard check under v0.3.0's guessed→OQ linkage, expected delta). **Task-spec learnings paid for (2 new eval-authoring footguns, both caught by the gate/harness before acceptance):** (1) `cmd | grep -q` on a LIVE pipe under the harness's pipefail dies SIGPIPE 141 when grep exits early — capture output to a var first (herestring); (2) the eval harness runs bodies under `set -e`, so an expected-to-fail command aborts the eval before its check — use `RC=0; cmd || RC=$?`. Candidates for the generator's guidance block (rule-9 ceremony, own XS step). **R0 = the first pass fully closed: skill hardened, artifact canonical, lesson taught, CLI subcommand accepted, CLI run provably equal to the human run.**
- 2026-07-19 · **P-8** · Pass 0 exit contract hardened — `check-brd.sh` v0.2→v0.3.0 via full dogfood ceremony (`T-20260719-pass0-exit-contract`, stamped Tier-1, accepted `--gold-sanity`, transitioned done through `cvg`). The gate now has an exit contract: **canonical (default)** hard-FAILs pending sign-off, missing ISO sign-off date, empty Scope In/Out entries, blank owners, untagged numbers, and (guessed)-without-open-question — and is the ONLY mode that prints the Pass 1 handoff verdict; **--draft** validates structure and NEVER authorizes; **--no-go** validates the other honest exit (marker/date/why/reopen); PDF input refused with convert guidance; every verdict ends in a machine token `CHECK_BRD=…` (first brick of the owner's agents-are-users directive). Proof: 17-row table-driven regression suite green (`skills/idea-to-brd/tests/run-tests.sh` — canonical passes in data AND DevOps domains (rule-9 universality), every negative fails for its INTENDED reason via grep, altitude stays warn-only, the signed proving-ground BRD stays a true positive); shellcheck -x + bash 3.2 clean; packaging gate met — vendored AND installed-official `quick_validate.py` both "Skill is valid!" after moving `compatibility` under `metadata:` (idea-to-brd → 0.5.0, pass-to-lesson → 0.1.1). Finding for later: `claude plugin validate` expects `.claude-plugin/` manifests — the repo's plugin packaging (incl. task-spec's root plugin.json) predates that layout; belongs to P-1/P-6 packaging work, out of this task's blast radius. Next: R0.I `cvg capture`.
- 2026-07-19 · **1.1 (at R0.I)** · `bin/cvg` router born — the CLI's first breath, full dogfood ceremony. Task-Spec `T-20260719-cvg-router` generated → filled → `validate-task-spec.sh` OK → `safe-to-delegate.sh --stamp` DELEGATE Tier-1 (one re-stamp: eval_3 initially passed on the unbuilt baseline — a rule-8 bug in the eval, fixed to require command success before the no-ANSI check; resealing after edit proved the envelope's tamper-detection works). Built: `bin/cvg` (router: tasks validate|gate|accept, eval, lint, transition, ready, help, version — exact pass-throughs via exec; CVG_HOME override + walk-up home resolution) + `bin/_ui.sh` (degradation-correct color: TTY + NO_COLOR + CVG_COLOR, 8-color palette, per the field research). Proof: `./bin/cvg eval tasks/T-20260719-cvg-router.md` → 3/3 evals pass + Exit Check pass (eval_1 byte-parity with direct script, eval_2 help completeness, eval_3 zero ANSI when piped); `shellcheck -x` clean; bash 3.2.57 verified; `cvg tasks accept --stamp --gold-sanity` → **ACCEPT** (blast radius clean after git-ignoring pre-existing temp/spine-* scratch; gold-sanity: evals FAIL on baseline HEAD, PASS on the work). The acceptance itself ran THROUGH cvg — the machine gated its own birth. Next: P-8 (Pass 0 exit contract) → `cvg capture` → R0.P.
- 2026-07-19 · **R1.R** · Pass 1 executed for real on the canonical greenfield BRD. Note: the first R1.R session crashed mid-round — the owner's five answers were recovered from the session transcript, verified verbatim against the question round, and locked into the workspace `brain/decisions/` (new standing rule: interrogation answers land on disk the moment they arrive). Two frontier rounds: D1 5-min freshness floor (process default), D2 SLA classes small ≤5m / medium ≤30m / hard ≤1h (timed drills per class), D3 lockdown = migrate-all → revoke-provably-fails → 7-day-zero window, D4 never-silently-wrong + 15-min staleness alert, D5 100 queries/day (≤10 orgs + modest growth stay estimated). Deliverable: `tests/uc-analytics/cvg/docs/tech-spec-analytical-backbone.md` — `check-tech-spec.sh` GATE PASS exit 0, ZERO warnings (14 quantified lines, 17 comparators, no stack leak); 3 minor gaps open (capture-overhead bound, local-loop time, partner sequencing), no blockers. Owner verdict on the spec: "looks great, nice structure". CLI-UX deep-research recovered from the crashed session's workflow state → `temp/cli-ux-research-2026-07-19.md` (18 verified claims). **Owner re-ordered the plan:** Pass 0 closes 100% end-to-end NOW (router → P-8 → capture → prove); R1.C/I/P and R2 wait.
- 2026-07-19 · **R0.C** · Pass 0 canonized. Owner verdict **approved — canonical** signed into the BRD's Sign-off block (the v0.4.0 field-audit sections Executive summary + Sign-off were already applied); `check-brd.sh` → GATE PASS exit 0, sign-off check green, same 2 advisory warns as the R0.R run. TEACH beat taken — first real outing of `pass-to-lesson`: `tests/uc-analytics/cvg/docs/lessons/lesson-pass-0-analytical-backbone.md`, `check-lesson.sh` exit 0 (11 components four-part treated, 7 decisions with rejected alternatives, 5 check-yourself questions). R1.R's input path corrected in this file (greenfield `.md`, not the UC repo PDF — stale pre-pivot line). R0.I/R0.P deferred by design: the `bin/cvg` entrypoint is born at R1.I; `cvg capture` circles back immediately after. Next: R1.R.
- 2026-07-17 · **R0.R** · Pass 0 executed for real on `tests/uc-analytics/` — first live outing of the frontier-rounds grill (3 rounds, voice, Luan as owner/VP-of-Eng persona). Terrain read first (schema + counts verified in container; no BRD → precondition held). Captured: partners' analytical queries crashing operational Postgres (several outages (estimated), one major w/ 3-4h rescue), no analytical backbone = business flying blind; KPI under-1-hour answers; near-real-time freshness; partners in scope; pre-mortem yielded prod-lockdown hard requirement + accepted $1k/mo phase-one ceiling; full stack preference (DuckDB/MotherDuck/dbt/CDC-WAL) quarantined to open-questions ledger for Pass 3. Deliverable: `tests/uc-analytics/docs/brd-analytical-backbone.md` — `check-brd.sh` GATE PASS exit 0 (2 expected warns: guessed→owned-OQ, advisory "database" = terrain description). Owner judgment → R0.C next.
- 2026-07-17 · **R0.U** · Pass 0 understand+harden closed. Two hardening rounds on `idea-to-brd` since absorption: v0.2.0 (no-go exit + `docs/no-go-*.md` record, provenance tags (measured)/(estimated)/(guessed) with guessed→owned-verification rule, do-nothing test, pre-mortem→Risks section, named decider) and v0.3.0 (frontier-rounds batch grill default — adapts Matt Pocock's batch-grill-me; `--questions batch|one`; voice-first). Companion skill `pass-to-lesson` v0.1.0 born (teach-after-any-pass; 13/13 validator green). Rule 9 proof: `check-brd.sh` discriminating on a NON-data (DevOps runbook) synthetic pair — full BRD exit 0, Risks-section-stripped exit 1; numbers-stripped exit 1 proven at absorption. Next: R0.R — run the grill for real on `tests/uc-analytics/` (raw idea → BRD born there).

- 2026-07-16 · **0.1** · `/bin/bash seed.sh && /bin/bash evals/smoke.sh` → exit 0 in 0.064s (bash 3.2.57); `evals/red.sh` → exit 1 ("gold_daily_revenue does not exist yet"). Effort XS — Task-Spec ceremony skipped per rule 6. Note: red.sh doubles as backlog T1's Success Criteria (discriminating by construction).
- 2026-07-16 · **housekeeping** · fixture renamed `examples/toy-revenue/` → `tests/e2e-test-engine/` (proof re-run green from new path); `cvg-kickoff-prompt.md` deleted — its bootstrap content folded into this file ("Fresh session? Start here"). One contract file from here on.
- 2026-07-17 · **R0 terrain** · Proving ground pivoted to `tests/uc-analytics/` (Luan's call: first run in the home domain — method friction, not domain confusion; universality receipts deferred to runs #2/#3). Postgres terrain transplanted from the UC repo (compose + schema + gen/seed, container `uc-analytics-postgres`, port 5433, own volume). **Smoke test caught real contamination:** the compose project name `ecommerce` mounted the stale `ecommerce_pgdata` volume from earlier experiments (5000 leftover orders, schema has zero INSERTs — data had to be foreign). Fixed: project renamed `uc-analytics`, fresh volume, `.env` port agreement, deterministic seed 42 → customers=50 / products=20 / orders=200 / payments=200 verified. Clean terrain, known numbers.
- 2026-07-17 · **absorb (external session)** · Reviewed + integrated Luan's out-of-session skill upgrades: NEW `idea-to-brd` (Pass 0 Capture — 12th skill) + refinements across all 9 spine skills (Pass 1 facts-vs-decisions rule + gap-questionnaire export + self-review; Pass 2 ADR-worthiness 3-condition test + `docs/CONTEXT.md` glossary; Pass 3 highest-seam/fewest-seams + deep-lane test; Pass 4 throwaway-prototype settlement; Pass 5A staple-check self-review; **task-spec v3.3.0**: vertical-slice rule, context-window sizing, breakdown quiz, expand–contract for wide refactors; Pass 6 glossary wiring + wizard-ize manual steps; Pass 8 stop-patching-start-diagnosing after 2× same RED). Review actions: 12/12 `quick_validate` green; `check-brd.sh` proven discriminating (rule 8/9); fixed version skew their lint caught (_lib.sh + plugin.json + marketplace.json → 3.3.0) + wrote the missing CHANGELOG 3.3.0 entry; restored `docs/demos/*` (staged for deletion but referenced by the committed ASD deck §04/§07/§12). Process note: external changes skipped rule 9's proof runs — remediated here, all green.
- 2026-07-16 · **R1.U** · Pass 1 skill `brd-docs-to-tech-req` hardened v0.2.0→v0.3.0. SKILL.md gained: Step 1.5 prior-art (problem-level only), one-question-at-a-time interrogation protocol with typed gap register (blocker gaps fail the gate), Confirmed-decisions recap before Crystallize, prioritized requirements (must/should/could/wont), TL;DR discipline. check-tech-spec.sh gained: Check 7 (unresolved blocker gaps → FAIL, awk-paired severity/resolution), Check 8 (priority differentiation warn), and de-biased "data named" (dropped hardcoded order/payment/customer nouns → domain-universal). Proof: passing DevOps fixture exit 0 (10/10 checks), same fixture w/ one open blocker gap exit 1 (fails only Check 7). Rule 9 satisfied incl. non-data domain. Rule 0/8/9 all honored.
- 2026-07-16 · **restructure** · Operating model agreed: five beats per pass (UNDERSTAND → RUN → CANONIZE → IMPLEMENT → PROVE), Track R (method, pass-by-pass vertical slices on the UC repo) now CURRENT; Track M (machine) parked at Milestone 0-done, resumes ~R8. CLI subcommands are built per pass, thin, against the manual golden run.
- 2026-07-16 · **0.2** · 6 specs authored via `generate-task-spec.sh` + filled; `validate-task-spec.sh` 6/6 OK; `safe-to-delegate.sh --stamp` 6/6 DELEGATE (Tier-1 HMAC, key 1f197c76); `lint-backlog.sh` → exactly 1 issue: overlap on `build_daily_totals.sh` between T-…-build-daily-totals and T-…-build-revenue-report, exit 1 (deliberate). **Findings paid for:** (1) overlap detection is touches_paths-only — a file created by task A and modified by task B must be redundantly declared in B's *and A's* touches+creates to be machine-visible (convention adopted); (2) editing sealed frontmatter invalidates the envelope → re-stamp is the only path (proved on T3, new sig minted); (3) the tooling anchors `tasks/` at git root — fixture backlog lives in the repo's single queue, which is what the Manager wants anyway. Dogfood note: the step's deliverable IS task-specs, so the ceremony (generate→validate→gate) was intrinsic.
