---
id: T-20260719-pass0-exit-contract
title: Harden the Pass 0 exit contract — no noncanonical brief reaches Pass 1
status: done
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: S  # XS | S | M → Kimi ; L → GLM (requires execution_backend: glm) ; XL → route to SDD (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: claude
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
touches_paths:
  - skills/idea-to-brd/scripts/check-brd.sh
  - skills/idea-to-brd/SKILL.md
  - skills/idea-to-brd/tests
  - skills/pass-to-lesson/SKILL.md
creates_paths:
  - skills/idea-to-brd/tests
source_note: cvg-todo.md P-8 — Pass 0 exit contract before cvg capture
created: 2026-07-19T14:19:59Z
tags: ["cvg", "pass-0", "gate", "P-8"]
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
signed_off_at: 2026-07-19T14:23:56Z
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-19T14:31:00Z
signed_off_sig: hmac-sha256-v1:1f197c76:cdb54c0c30a6177e7296f6c53abd68463a1b9795a80c6bc7498ab97e6d7c6395
---

# Harden the Pass 0 exit contract — no noncanonical brief reaches Pass 1

> **Why:** Today `check-brd.sh` prints `GATE: PASS — hand off to Pass 1` even
> when the owner's sign-off is pending — a draft can impersonate a canonical
> brief. Before `cvg capture` automates this pass, the exit contract must be
> mechanical: draft validation and handoff authorization are different verdicts.

---

## Goal

`check-brd.sh` gains two modes and a validator. **Canonical (default):**
pending sign-off, missing sign-off date, empty Scope In/Out entries, blank
question owners, untagged numbers, and `(guessed)` numbers with no open
question each hard-FAIL, and only a fully canonical brief may print the
Pass 1 handoff verdict. **`--draft`:** the same structural checks run, the
ownership/provenance items downgrade to warnings, and the verdict NEVER
authorizes handoff. **`--no-go`:** validates a no-go record (date + why +
what-would-reopen). Every verdict ends in a stable greppable machine token
(`CHECK_BRD=PASS|FAIL|DRAFT_OK|DRAFT_INCOMPLETE|NOGO_OK|NOGO_INVALID`) —
the agent-experience contract. A table-driven regression suite under
`skills/idea-to-brd/tests/` proves every negative fixture fails for its
intended reason; semantic owner-voice/altitude judgment stays WARN-only
(explicitly human). Packaging: both `idea-to-brd` and `pass-to-lesson`
frontmatter lose the unsupported top-level `compatibility:` key (folded
into `metadata:`) so the official skill validator passes alongside the
vendored one.

---

## Context

`cvg-todo.md` P-8 (found during the guided Pass 0 audit 2026-07-19) — the
full requirement list, including the packaging gate. Prerequisite for R0.I
`cvg capture`. Rule 9 applies: SKILL.md version bumps, `quick_validate.py`
green, gate proven discriminating on passing AND failing fixtures including
a NON-data domain. PDF policy follows check-tech-spec.sh precedent: the
verifier reads .md and refuses .pdf with conversion guidance. P-5 owns the
future write-once pass receipt — do not build receipts here.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN a brief whose Sign-off is pending WHEN `check-brd.sh` runs
  in default (canonical) mode THEN it exits non-zero, does NOT print the
  Pass 1 handoff verdict, and prints `CHECK_BRD=FAIL`; the same file with
  `--draft` exits 0 with `CHECK_BRD=DRAFT_OK` and still no handoff line.
- **B-2** — GIVEN the table of negative fixtures (pending sign-off, empty
  scope entries, blank owner, missing provenance, guessed-without-question,
  invalid no-go) WHEN the regression suite runs THEN every fixture fails
  for its INTENDED reason (asserted by grep, not just exit code), the
  canonical fixtures (data AND non-data domain) pass, the altitude fixture
  passes WITH its warning, and the valid no-go record passes `--no-go`.
- **B-3** — GIVEN the two Pass 0 skills WHEN validated THEN
  `quick_validate.py` reports valid for both and neither SKILL.md carries a
  top-level `compatibility:` key; `check-brd.sh` is ShellCheck-clean and
  parses on bash 3.2.

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: a pending-sign-off brief cannot emit the Pass 1 handoff verdict
eval_1() {
  F=skills/idea-to-brd/tests/fixtures/brd-pending-signoff.md
  [ -f "$F" ] || return 1
  out=$(bash skills/idea-to-brd/scripts/check-brd.sh "$F" 2>&1)
  rc=$?
  [ "$rc" -ne 0 ] || return 1
  printf '%s\n' "$out" | grep -q 'hand off to Pass 1' && return 1
  printf '%s\n' "$out" | grep -q '^CHECK_BRD=FAIL$' || return 1
  out=$(bash skills/idea-to-brd/scripts/check-brd.sh --draft "$F" 2>&1) || return 1
  printf '%s\n' "$out" | grep -q 'hand off to Pass 1' && return 1
  printf '%s\n' "$out" | grep -q '^CHECK_BRD=DRAFT_OK$'
}

# eval-2: the table-driven regression suite is green (every fixture fails for its intended reason)
eval_2() {
  bash skills/idea-to-brd/tests/run-tests.sh
}

# eval-3: packaging + portability — vendored validator green for both skills, no top-level compatibility key, shellcheck clean
eval_3() {
  python3 skills/skill-creator/scripts/quick_validate.py skills/idea-to-brd    | grep -qi 'valid' || return 1
  python3 skills/skill-creator/scripts/quick_validate.py skills/pass-to-lesson | grep -qi 'valid' || return 1
  grep -q '^compatibility:' skills/idea-to-brd/SKILL.md    && return 1
  grep -q '^compatibility:' skills/pass-to-lesson/SKILL.md && return 1
  shellcheck -x skills/idea-to-brd/scripts/check-brd.sh || return 1
  /bin/bash -n skills/idea-to-brd/scripts/check-brd.sh
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
    description: pending-sign-off brief cannot emit the Pass 1 handoff verdict (canonical FAIL, draft OK, never handoff)
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 3
  - id: eval_2
    description: table-driven regression suite green — every fixture fails for its intended reason
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 15
  - id: eval_3
    description: both skills validator-green, no top-level compatibility key, shellcheck + bash -n clean
    runnable: bash
    check_type: deterministic
    verifies: [B-3]
    terminal: true
    expected_duration_sec: 10

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

(Concrete: `git checkout -- skills/idea-to-brd skills/pass-to-lesson` plus
`rm -rf skills/idea-to-brd/tests` restores the previous gate exactly; the
canonical BRD on the proving ground is untouched by this task.)

---

## Observability Hooks

What to watch during execution and after deployment:

- **Expected duration:** under 45 minutes of build time; evals < 30 s total
- **Key metric:** regression rows passed / total (run-tests.sh prints one row per fixture)
- **Alert condition:** the signed proving-ground BRD failing the NEW canonical mode — the hardening broke a true positive (stop and surface, never patch)
- **Log tail:** run-tests.sh prints expected vs got per fixture on failure

---

## Anti-Patterns

- **Don't gate the semantic judgments** — owner-voice and altitude leaks stay
  WARN in every mode; the human judges voice. Mechanize only what is
  mechanically provable.
- **Don't let `--draft` become a backdoor** — draft mode must never print the
  handoff verdict, no matter how complete the brief; only canonical mode
  authorizes descent to Pass 1.
- **Don't break the true positive** — the signed proving-ground BRD must pass
  the new canonical mode unmodified; if it fails, the check is wrong (or the
  BRD genuinely regressed) — stop and surface it, never patch the subject.

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- tests/uc-analytics/cvg/docs/brd-analytical-backbone.md (the signed canonical BRD — a validation subject, never a fixture to edit)
- skills/task-spec/scripts/* (different skill, different task)
- bin/* (the router is accepted; capture is a later task)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

1. **Official validator invocation** — the installed `skills` CLI (npx,
   v1.5.19) is the "official validator" P-8 names; discover its validate
   subcommand during build and record the exact command + result in the
   progress log. If it needs network or proves nondeterministic, it stays a
   documented proof step rather than a sealed eval line (eval_3's
   frontmatter grep already pins the mechanical part).
2. **Sign-off date detection** — recommendation: require an ISO date
   (`YYYY-MM-DD`) in the Sign-off section alongside the word `canonical`;
   looser date formats stay a WARN, not a FAIL.
