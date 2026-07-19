---
id: T-20260719-cvg-intent
title: R1 machine contract — check-tech-spec exit contract (v0.4.0) + cvg intent
status: done
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: S  # XS | S | M → Kimi ; L → GLM (requires execution_backend: glm) ; XL → route to SDD (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: claude
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
touches_paths:
  - skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh
  - skills/brd-docs-to-tech-req/SKILL.md
  - skills/brd-docs-to-tech-req/tests
  - bin/cvg
  - bin/README.md
  - cvg-todo.md
creates_paths:
  - skills/brd-docs-to-tech-req/tests
source_note: R1.I (cvg-todo) + agentic-execution review blocker B-1 (2026-07-19) — the gate passes an unsigned spec and emits no machine token
created: 2026-07-19T19:30:00Z
tags: ["cvg", "pass-1", "gate", "intent", "R1.I"]
owner: (none)
priority: P1
severity: feature
due_date: (none)
precondition: (none)
blocked_reason: (none)
security_class: (none)
source_action_item: (none)
linear_ref: (none)  # off-repo Intent crossing — Linear issue id/url this task traces to
execution_backend: any  # OPEN STRING — names the canonical executor (any|claude|codex|kimi|glm|gemini|<your-harness>). Adapters live in runbooks/dispatch-recipes/ (non-normative). Required to be 'glm' for effort: L.
signed_off: true
signed_off_by: luanmorenomaciel
signed_off_at: 2026-07-19T16:17:11Z
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-19T16:21:35Z
signed_off_sig: hmac-sha256-v1:1f197c76:576f52e92a5c1a932b8876c80204fae4257b29d7c8e1544b5710ab28fdfe0721
---

# R1 machine contract — check-tech-spec exit contract (v0.4.0) + cvg intent

> **Why:** The agentic-execution review that conditioned Gate H1 proved its
> blocker B-1 live: `check-tech-spec.sh` v0.3.0 PASSes an UNSIGNED spec
> (Sign-off section deleted → exit 0) and its last line is prose, not a
> machine token — so the judge beat exists only as words, and a Pass 2 agent
> would consume a draft. `cvg intent` must not wrap a gate that means
> nothing to a machine: the exit contract and the subcommand are one unit
> (the Pass 1 analog of Pass 0's P-8 → capture sequence).

---

## Goal

**(a) check-tech-spec.sh v0.3.0 → v0.4.0 — the exit contract.** Two modes,
mirroring check-brd v0.3.1: **canonical (default)** adds Check 9 — the
Sign-off section must exist (fence-stripped extraction, so a fenced example
proves nothing), the FIRST verdict line must say `canonical` and not
`pending`/`draft`, and a valid ISO date (month 01–12, day 01–31) must sit
on a Date/Signed line — and remains the ONLY mode whose verdict says "hand
to Pass 2". **--draft** runs the same structural checks but downgrades
sign-off to advisory and NEVER authorizes descent. Every run ends in a
stable machine token — `CHECK_TECH_SPEC=PASS|FAIL|DRAFT_OK|
DRAFT_INCOMPLETE|USAGE_ERROR` — including every exit-2 path (help, missing
file, unknown flag, extra positional, PDF refusal). A table-driven 15-row
regression suite is born at `skills/brd-docs-to-tech-req/tests/` (canonical
fixture in a NON-data domain per rule 9), every new negative proven
discriminating against v0.3.0. **(b) `cvg intent` — the R1.I subcommand.**
Mirrors `capture`: explicit file = exact `exec` pass-through; no file =
workspace discovery (`cvg/docs/tech-spec-*.md` then `docs/tech-spec-*.md`;
0 found → exit 2 + token, >1 → exit 2 naming each + token, never guesses);
`--draft` passes through; unknown flags refused with token. `cvg` bumps to
0.3.0; help + bin/README gain the intent row. **(c) R1.P rides on
acceptance:** `cvg intent` on the proving ground is byte-identical to the
direct manual gate run on the canonical spec (golden diff EMPTY).

---

## Context

R1.I in cvg-todo.md (Track R) + blocker B-1 from the 2026-07-19
agentic-execution review recorded in the R1.C progress-log entry. Sequence
precedent: P-8 (exit contract) → cvg capture; here both land in one atomic
task because the subcommand without the contract is meaningless to the
machine stage. Rule 8 with teeth: every new negative fixture must wrongly
PASS (or lack the token) on v0.3.0 via `git show HEAD:`. Rule 9: SKILL.md
0.3.0 → 0.4.0, quick_validate green, canonical fixture from a NON-data
domain (DevOps). The UX contract from R1.I's cvg-todo entry (stage-visible
CLI, `_ui` layer) applies only to cvg's own surfaces — the gate path stays
an undecorated exec (byte-parity is the proof). The signed proving-ground
spec is a validation subject, never edited.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN a tech-spec whose Sign-off is pending, absent, fenced-
  example-only, or dated with an impossible ISO date WHEN the canonical
  gate runs THEN it exits 1 with `CHECK_TECH_SPEC=FAIL` and never prints
  the Pass 2 handoff verdict; the same pending spec under `--draft` exits 0
  with `CHECK_TECH_SPEC=DRAFT_OK` and still no handoff verdict.
- **B-2** — GIVEN the 15-row regression suite WHEN it runs THEN every row
  holds: the canonical DevOps fixture and the signed proving-ground spec
  pass with `CHECK_TECH_SPEC=PASS`; every negative fails for its INTENDED
  reason; every exit-2 usage path (unknown flag, missing file, two
  positionals, PDF) ends in `CHECK_TECH_SPEC=USAGE_ERROR`.
- **B-3** — GIVEN the proving-ground workspace WHEN `cvg intent` runs with
  no arguments THEN it discovers the single tech-spec and its output is
  byte-identical (same exit code) to the direct check-tech-spec.sh run;
  GIVEN an empty directory THEN it exits 2 ending in
  `CHECK_TECH_SPEC=USAGE_ERROR`; `cvg help` lists intent.
- **B-4** — GIVEN the changed scripts WHEN linted THEN `shellcheck -x` and
  `/bin/bash -n` (bash 3.2) are clean and the vendored `quick_validate.py`
  reports the skill valid at version 0.4.0.

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: the exit contract — draft/canonical are different verdicts, unsigned specs are blocked
eval_1() {
  F=skills/brd-docs-to-tech-req/tests/fixtures/spec-pending-signoff.md
  U=skills/brd-docs-to-tech-req/tests/fixtures/spec-unsigned.md
  [ -f "$F" ] || return 1
  [ -f "$U" ] || return 1
  RC=0; out=$(bash skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh "$F" 2>&1) || RC=$?
  [ "$RC" -eq 1 ] || return 1
  printf '%s\n' "$out" | grep -q 'hand to Pass 2' && return 1
  printf '%s\n' "$out" | grep -q '^CHECK_TECH_SPEC=FAIL$' || return 1
  RC=0; out=$(bash skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh --draft "$F" 2>&1) || RC=$?
  [ "$RC" -eq 0 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_TECH_SPEC=DRAFT_OK$' || return 1
  printf '%s\n' "$out" | grep -q 'hand to Pass 2' && return 1
  RC=0; out=$(bash skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh "$U" 2>&1) || RC=$?
  [ "$RC" -eq 1 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_TECH_SPEC=FAIL$'
}

# eval-2: the 15-row regression suite is green
eval_2() {
  RC=0; out=$(bash skills/brd-docs-to-tech-req/tests/run-tests.sh 2>&1) || RC=$?
  [ "$RC" -eq 0 ] || return 1
  printf '%s\n' "$out" | grep -q 'rows: 15  failed: 0'
}

# eval-3: cvg intent — golden byte-parity on the proving ground, discovery contract, hygiene
eval_3() {
  RCA=0; A=$(cd tests/uc-analytics && ../../bin/cvg intent 2>&1) || RCA=$?
  RCB=0; B=$(cd tests/uc-analytics && bash ../../skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh cvg/docs/tech-spec-analytical-backbone.md 2>&1) || RCB=$?
  [ "$RCA" -eq 0 ] || return 1
  [ "$RCA" -eq "$RCB" ] || return 1
  [ "$A" = "$B" ] || return 1
  ROOT=$(pwd)
  TMPD=$(mktemp -d)
  RC=0; out=$(cd "$TMPD" && CVG_HOME="$ROOT" bash "$ROOT/bin/cvg" intent 2>&1) || RC=$?
  rm -rf "$TMPD"
  [ "$RC" -eq 2 ] || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_TECH_SPEC=USAGE_ERROR$' || return 1
  out=$(bash bin/cvg help 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'intent' || return 1
  shellcheck -x bin/cvg bin/_ui.sh skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh || return 1
  /bin/bash -n skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh || return 1
  out=$(python3 skills/skill-creator/scripts/quick_validate.py skills/brd-docs-to-tech-req 2>&1) || return 1
  printf '%s\n' "$out" | grep -qi 'valid'
}
```

---

## Validation Card

```yaml
success_criteria:
  # check_type: deterministic (default, bash-checked, preferred) | llm_judge
  # (subjective criteria graded by a fast LLM via judge_prompt — deterministic-first).
  # verifies: the behavior id(s) this eval proves. Standard/full profiles require
  # every B-N to be covered by >=1 eval and every eval to map to a behavior.
  - id: eval_1
    description: exit contract discriminates — pending/unsigned specs blocked in canonical, draft validates but never authorizes
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 5
  - id: eval_2
    description: 15-row table-driven regression suite green, every negative failing for its intended reason
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 20
  - id: eval_3
    description: cvg intent byte-parity with the direct gate run (R1.P golden diff), discovery token contract, shellcheck/bash3.2/validator green
    runnable: bash
    check_type: deterministic
    verifies: [B-3, B-4]
    terminal: true
    expected_duration_sec: 15

retry_policy:
  max_iterations: 15
  circuit_breaker_no_progress: 3
  on_terminal_failure: park_with_context

agent_contract:
  version: 2
  read: [intent, behavior, contract, guardrails, operations]
  produce:
    - code
    - docs
    - config
    - tests
  required_tools: [git, bash]
  timeout_minutes: 30
  sandbox_type: host  # host | isolated | ephemeral
  output_artifacts: []
  mcp_dependencies: []
  emit:
    - pass
    - fail
    - retry_with_reason
    - parked_with_context
  backend_metadata: {}  # optional executor-specific key/value map (the backend names itself); replaces the old codex_metadata/kimi_metadata
```

---

## Exit Check

```bash
# Final proof-of-done. Returns 0 only when ALL evals pass.
eval_1 && eval_2 && eval_3
```

---

## Rollback Plan

If execution fails mid-task, revert to the pre-task state:

1. **Git revert** — `git revert --no-commit HEAD` (if commits were made)
2. **File restore** — `git checkout -- <paths>` for any modified files not yet committed
3. **State reset** — update task status to `parked` and record `blocked_reason`

(Concrete: `git checkout -- skills/brd-docs-to-tech-req bin cvg-todo.md`
plus removing `skills/brd-docs-to-tech-req/tests/` restores the v0.3.0 gate
and cvg 0.2.1 exactly; the canonical tech-spec is untouched by this task.)

---

## Observability Hooks

What to watch during execution and after deployment:

- **Expected duration:** under 45 minutes of build time; evals < 45 s total
- **Key metric:** regression rows passed / total; the golden diff line count (must be zero)
- **Alert condition:** the signed proving-ground tech-spec failing the NEW canonical mode, or the golden diff going non-empty — the hardening broke a true positive (stop and surface, never patch the spec)
- **Log tail:** run-tests.sh prints expected vs got per fixture on failure

---

## Anti-Patterns

- **Don't decorate the gate path** — `cvg intent`'s pass-through is an
  exact `exec`; tokens on cvg's own exit-2 surfaces only. Byte-parity is
  the R1.P proof and it must survive.
- **Don't let `--draft` become a backdoor** — the draft verdict never
  contains the Pass 2 handoff line, no matter how complete the spec.
- **Don't trust a new fixture that wasn't proven discriminating** — each
  negative must demonstrably fool v0.3.0 (`git show HEAD:`) before it
  counts as a regression guard (rule 8).
- **Don't rewrite the proven checks 1–8** — they were validated at R1.U;
  v0.4.0 ADDS the sign-off contract and the token surface (rule 3: wrap,
  don't rewrite — a rewrite needs a written reason in cvg-todo.md).

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- tests/uc-analytics/cvg/docs/tech-spec-analytical-backbone.md (the signed canonical spec — a validation subject, never a fixture to edit)
- tests/uc-analytics/cvg/docs/brd-analytical-backbone.md (Pass 0's signed artifact)
- skills/idea-to-brd/* (Pass 0's gate is closed; different task)
- skills/task-spec/scripts/* (different skill, different task)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

1. **Draft-mode structural strictness** — recommendation: checks 1–8 stay
   hard in BOTH modes (a draft with no Requirements section is not a
   validatable draft); only the sign-off items downgrade. If a fixture
   proves this wrong, record the adjustment in the progress log.
2. **`--out-format` mention** — check-tech-spec's PDF refusal message
   references `--out-format md`; keep the wording aligned with the
   skill's actual flag surface when editing the die() path.
