---
id: T-20260719-cvg-capture
title: Add cvg capture — the Pass 0 subcommand that gates a brief
status: done
format_version: 3
profile: standard  # lite | standard | full — scales required zones to effort/blast-radius (see references/concepts/profiles.md)
effort: S  # XS | S | M → Kimi ; L → GLM (requires execution_backend: glm) ; XL → route to SDD (see references/concepts/effort-gate.md)
budget_iterations: 15
agent: claude
parent: (none)  # FEATURE-altitude PRD/SDD this task decomposes from (path or url); the task DISTILLS it, never embeds it
depends_on: []
touches_paths:
  - bin/cvg
  - bin/README.md
source_note: cvg-todo.md R0.I — cvg capture wraps the hardened Pass 0 gate
created: 2026-07-19T14:35:31Z
tags: ["cvg", "cli", "pass-0", "capture", "R0.I"]
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
signed_off_at: 2026-07-19T14:40:34Z
accepted: true
accepted_by: luanmorenomaciel
accepted_at: 2026-07-19T14:41:02Z
signed_off_sig: hmac-sha256-v1:1f197c76:8f714bbe1e0f251b26e2bd99fefe4fda1280a202051618ea2b4d891e77268e14
---

# Add cvg capture — the Pass 0 subcommand that gates a brief

> **Why:** Pass 0's I-beat. The interview is human-in-the-loop by design (the
> session IS the engine at Pass 0), so the CLI's referee job is the rest:
> find the brief in the workspace, run the hardened exit contract, hand back
> the verdict — byte-identical to calling the gate script directly.

---

## Goal

`cvg capture [--draft|--no-go] [file]` in `bin/cvg`. With an explicit file,
it is an exact pass-through (`exec`) to
`skills/idea-to-brd/scripts/check-brd.sh` — same bytes, same exit code, so
R0.P's prove-by-diff holds. With no file, it discovers the brief from the
working directory: `cvg/docs/brd-*.md` then `docs/brd-*.md` (for `--no-go`,
the `no-go-*.md` pattern instead); exactly one match proceeds, zero or many
is a usage error (exit 2) that names what it found — an agent never has to
guess. `cvg help` gains a passes section listing capture; CVG_VERSION bumps
to 0.2.0 (surface change).

---

## Context

`cvg-todo.md` R0 beat state (owner pivot 2026-07-19): router born (1.1) and
P-8 closed — this is step 3 of 4; R0.P (prove against the manual golden
run: GATE PASS exit 0 on the signed proving-ground BRD) closes Pass 0
end-to-end right after. Wrap-don't-rewrite (rule 3): check-brd.sh is the
implementation; capture only locates and routes. The agents-are-users
directive applies: no decoration on the gate path, stable tokens come from
the gate script itself.

For the feature-level PRD/design this task decomposes from, see the `parent:`
frontmatter field — that document is REFERENCED, never copied here. Zone 1 carries
only the one-paragraph distillation needed to execute this atomic unit.

---

## Behavior

Given/When/Then scenarios the implementation must satisfy. Each scenario has a
stable `B-N` id; every eval in the Validation Card declares which behavior(s) it
`verifies:`, and the validator enforces the chain both ways (no orphan behavior,
no orphan eval).

- **B-1** — GIVEN the proving-ground workspace WHEN `cvg capture` runs from
  `tests/uc-analytics/` with no file argument THEN it discovers
  `cvg/docs/brd-analytical-backbone.md` and its output and exit code are
  byte-identical to invoking `check-brd.sh` on that file directly (the
  R0.P golden-diff contract).
- **B-2** — GIVEN gate-mode flags WHEN `cvg capture --draft <brief>` or
  `cvg capture --no-go <record>` runs THEN the flags pass through to the
  gate script unchanged (draft never prints the handoff verdict; tokens
  intact), and `cvg help` lists `capture`.
- **B-3** — GIVEN a directory with zero or multiple briefs WHEN
  `cvg capture` runs with no file THEN it exits 2 with a message naming
  what it found (each candidate path when ambiguous), and a directory with
  exactly one brief proceeds to the gate.

---

## Success Criteria

Each criterion is a runnable bash function returning 0 (pass) or non-zero (fail).
Each MUST be terminal (deterministic, idempotent, non-flaky).

```bash
# eval-1: golden parity — discovery + gate === direct check-brd.sh (bytes + exit)
eval_1() {
  BRD=tests/uc-analytics/cvg/docs/brd-analytical-backbone.md
  bash skills/idea-to-brd/scripts/check-brd.sh "$BRD" > /tmp/cap_direct.txt 2>&1
  d=$?
  (cd tests/uc-analytics && ../../bin/cvg capture) > /tmp/cap_routed.txt 2>&1
  r=$?
  [ "$d" -eq 0 ] && [ "$r" -eq 0 ] && diff -q /tmp/cap_direct.txt /tmp/cap_routed.txt >/dev/null
}

# eval-2: mode pass-through (draft never authorizes; no-go token intact) + help lists capture
eval_2() {
  out=$(./bin/cvg capture --draft skills/idea-to-brd/tests/fixtures/brd-pending-signoff.md 2>&1) || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_BRD=DRAFT_OK$' || return 1
  printf '%s\n' "$out" | grep -q 'hand off to Pass 1' && return 1
  out=$(./bin/cvg capture --no-go skills/idea-to-brd/tests/fixtures/nogo-valid.md 2>&1) || return 1
  printf '%s\n' "$out" | grep -q '^CHECK_BRD=NOGO_OK$' || return 1
  hlp=$(./bin/cvg help)
  grep -qw capture <<<"$hlp"
}

# eval-3: discovery contract — zero briefs exit 2, two briefs exit 2 naming both, one brief gates
eval_3() {
  ROOT="$PWD"
  T=$(mktemp -d) || return 1
  mkdir -p "$T/docs"
  RC=0
  (cd "$T" && CVG_HOME="$ROOT" "$ROOT/bin/cvg" capture) >/tmp/cap_zero.txt 2>&1 || RC=$?
  [ "$RC" -eq 2 ] || { rm -rf "$T"; return 1; }
  cp "$ROOT/skills/idea-to-brd/tests/fixtures/brd-canonical.md" "$T/docs/brd-one.md"
  cp "$ROOT/skills/idea-to-brd/tests/fixtures/brd-canonical-devops.md" "$T/docs/brd-two.md"
  RC=0
  (cd "$T" && CVG_HOME="$ROOT" "$ROOT/bin/cvg" capture) >/tmp/cap_two.txt 2>&1 || RC=$?
  [ "$RC" -eq 2 ] || { rm -rf "$T"; return 1; }
  grep -q 'brd-one.md' /tmp/cap_two.txt || { rm -rf "$T"; return 1; }
  grep -q 'brd-two.md' /tmp/cap_two.txt || { rm -rf "$T"; return 1; }
  rm "$T/docs/brd-two.md"
  RC=0
  (cd "$T" && CVG_HOME="$ROOT" "$ROOT/bin/cvg" capture) >/tmp/cap_one.txt 2>&1 || RC=$?
  rm -rf "$T"
  [ "$RC" -eq 0 ] && grep -q '^CHECK_BRD=PASS$' /tmp/cap_one.txt
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
    description: golden parity — workspace discovery + gate byte-identical to direct check-brd.sh
    runnable: bash
    check_type: deterministic
    verifies: [B-1]
    terminal: true
    expected_duration_sec: 4
  - id: eval_2
    description: draft/no-go flags pass through unchanged; help lists capture
    runnable: bash
    check_type: deterministic
    verifies: [B-2]
    terminal: true
    expected_duration_sec: 4
  - id: eval_3
    description: discovery contract — 0 briefs exit 2, 2 briefs exit 2 naming both, 1 brief gates green
    runnable: bash
    check_type: deterministic
    verifies: [B-3]
    terminal: true
    expected_duration_sec: 6

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

(Concrete: `git checkout -- bin/cvg bin/README.md` restores the accepted
router exactly; capture adds a case branch and a discovery helper, nothing
else.)

---

## Observability Hooks

What to watch during execution and after deployment:

- **Expected duration:** under 20 minutes of build time; evals < 15 s total
- **Key metric:** eval_1 golden diff — any byte of drift between discovered-and-routed and direct gate output
- **Alert condition:** the proving-ground BRD gating differently through capture than directly
- **Log tail:** /tmp/cap_*.txt on eval failure

---

## Anti-Patterns

- **Don't decorate the gate path** — no banner, no discovery chatter on
  stdout/stderr when routing to the gate; R0.P proves by byte-diff and
  agents parse the gate's own token. Discovery messages appear ONLY on the
  exit-2 error path.
- **Don't reimplement any check** — capture locates and routes;
  check-brd.sh decides. A verdict difference is a bug in capture.
- **Don't guess when ambiguous** — two briefs found means exit 2 naming
  both, never "picked the first one".

---

## Do-Not-Touch

Files the executor MUST NOT modify:

- skills/idea-to-brd/** (the gate and its suite are accepted — P-8's work)
- tests/uc-analytics/** (the proving ground is the golden subject)
- bin/_ui.sh (no presentation change in this step)

---

## Open Questions

Things the executor should resolve DURING build, not assume:

1. **Discovery scope** — recommendation: check `cvg/docs/` first (the P-2
   workspace convention), fall back to `docs/` (skill-conventional path);
   never recurse further — predictability beats magic.
2. **`--where` helper** — an agent may want the resolved path without
   gating. Defer unless free: predictability first, surface area later.
