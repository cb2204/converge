# Chat guide

The descent conductor ([`evidence-to-next-pass`](../../skills/evidence-to-next-pass/))
owns the canonical pass prompts and the sequence itself. This guide explains how
a chat session navigates the Converge method.

## The four-step chat path

1. **Session opens** (or resumes) → run `cvg next`

   It says where the descent stands — no scroll-back, no re-explaining, no
   tokens spent reconstructing state. Position is derived from workspace
   evidence, not from memory.

2. **Before steering a pass** → `pre N`

   The fail-closed door: every lane pass before N must have left its artifact.
   If it refuses, **the missing step IS the instruction**.

   - `PASS_PRE=OK` — pass N may start
   - `PASS_PRE=MISSING` (exit 1) — names exactly what's absent

3. **Steer with the pass prompt**

   Each pass skill carries its own steering prompt at
   `skills/<pass-skill>/references/pass-prompt.md`. Prompts ship with the
   package and are **never copied into a consuming project**.

4. **After the pass** → `post N`, then the pass's `cvg` gate

   Both must be green before `next` will move on.

   - `PASS_POST=OK` — artifact landed in its folder
   - `PASS_POST=INCOMPLETE` (exit 1) — artifact missing

## The one rule

**Evidence presence is not a verdict.** The conductor reads that a BRD file
exists; only `cvg capture` says it PASSES. The conductor sequences; the gates
decide.

## CLI entry points

```bash
cvg next                  # where are we, what's next
cvg next pre 3            # may pass 3 start?
cvg next post 3           # did pass 3 leave its artifact?
```

Lane-aware (`--lane FULL|NORMAL|FAST`), read-only, instant.

## Harness destinations

The installer projects exactly eleven Converge skills:

| Harness | dest |
|---|---|
| Codex / Kimi | `.agents/skills/` |
| Claude Code | `.claude/skills/` |
| Grok | `.grok/skills/` |

No Cursor dest exists in `install.sh`.

## Claude Code plugin

Claude Code can also load `.claude-plugin/` (`plugin.json` + `marketplace.json`):

- Eleven owned Converge skills
- The `cvg` CLI
- Task-Spec independently installed at 3.8

## Setup harness

`cvg setup harness` scaffolds `AGENTS.md` (~50 lines, routing only, non-clobbering).

Pass 7 Bind emits `AGENTS.task.md` — the task brief the model reads:

- Spec path, contract path, **epoch** (`<task-id>@<spec-sha12>`)
- Exact paths it may write, fences it must not cross
- Exit Check — *done is this command exiting zero, not your judgment*
- A pointer to the project router — **never a copy of it**

The brief carries **identifiers, not content**.

## Cockpit

[Cockpit](../../apps/cockpit/) is a read-only observation and interpretation
surface over `cvg snapshot`. It cannot authorize work.

```bash
npm run cockpit:install
npm run cockpit:dev --   --cvg-home "$PWD"   --project-root /absolute/path/to/project
```

## Related

- [Descent guide](descent.md) — two phases, one barrier
- [Skills reference](../concepts/skills.md) — one section per owned skill
- [`evidence-to-next-pass` skill](../../skills/evidence-to-next-pass/) — full sequence layer
