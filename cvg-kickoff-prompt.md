# Kickoff: build `cvg` — the CLI that automates Converge (one step at a time)

You are starting the build of **cvg**, a multi-harness CLI that automates the
Converge method. This session (and every future build session) works from one
contract file: **`cvg-todo.md`** at the repo root. This prompt is your complete
context — assume no prior conversation.

## What Converge is (30 seconds)

Converge compiles a fuzzy brief into an autonomous, eval-gated system through
eight passes (Intent → ADRs → Swimlane plans → Adversarial consensus → Task-Specs
→ Register → Harness → Loop), shipped today as 11 Claude Code skills in this
repo. Its atomic unit is the **Task-Spec v3** (`skills/task-spec/`): a markdown
file whose frontmatter + six zones carry runnable bash evals, an HMAC-sealed
sign-off, blast-radius boundaries (`touches_paths` / do-not-touch), a retry
budget, and dual gates (`safe-to-delegate.sh` PRE, `accept-task.sh` POST with
`--gold-sanity`). "Done" means the eval passes — never that an agent claims it.

## What cvg is

One CLI that wraps the method so any engine (Claude Code, Codex, Kimi, Gemini,
Copilot) can run it. **The CLI is the referee, never a player**: it frames
prompts (pass cards), dispatches engines headlessly, and gates their outputs
with the existing check scripts. It holds zero model credentials and never
calls an LLM API itself. State is always derived from `tasks/*.md` frontmatter +
tracker + git — no database, no daemon, no stored graph.

## Read these first, in order (before writing any code)

1. `cvg-todo.md` — the build plan. **It is the law for this work.** Rules of
   engagement at the top; milestones with per-step proof gates below.
2. `readme.md` — the method, the fork, the two moats.
3. `skills/task-spec/SKILL.md` + `skills/task-spec/scripts/` — the scripts you
   will WRAP (never rewrite): `safe-to-delegate.sh`, `accept-task.sh`,
   `run-task-spec.sh --ci`, `validate-task-spec.sh`, `lint-backlog.sh`,
   `transition-status.sh`, `conformance-check.sh`, `ref-executor.sh` (the
   60-line worked example your Milestone-3 worker generalizes).
4. `presentation/cvg-automation-plan-v1.0.html` — the full design: command
   surface (§06), developer flow (§07), worked use-case (§08), trust ladder
   (§09), board (§10), phases (§11), risks (§12).
5. `todo.md` — the method backlog (B-1…B-14) that cvg implements. Context only;
   do not edit it in this work.

## How to work (non-negotiable)

- **One step at a time.** Open `cvg-todo.md`, find the first unchecked step,
  do ONLY that step, prove its gate with the runnable check written in the
  step, paste the proof into the Progress log, check the box, commit. Then
  stop and report — do not start the next step in the same breath unless I say
  "continue".
- **Dogfood:** steps of effort S+ get cut as a Task-Spec first (use the
  task-spec skill), gated with `safe-to-delegate.sh --stamp`, accepted with
  `accept-task.sh --stamp --gold-sanity`. XS steps may skip ceremony — note it.
- **Wrap, don't rewrite.** Bash 3.2-safe core, python stdlib only, zero
  npm/pip dependencies in the core path.
- **Evals must discriminate** — a check that passes before the step is built is
  a broken check.
- Commit style: small commits per step, message `cvg: <milestone.step> <what>`.

## Start now

Begin with the first unchecked step in `cvg-todo.md`. Report back with: what
you built, the proof command + its output, and what step comes next. Do not
proceed past one step without my go.
