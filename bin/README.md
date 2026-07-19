# bin/ — the cvg CLI

> **This file is the CLI's status card: what exists, what it wraps, what
> proved it.** It records the present only. The backlog — what comes next
> and in what order — lives in ONE place: [`cvg-todo.md`](../cvg-todo.md)
> (the working contract; see its R0/R1 beats and Milestones 1–7). A second
> todo here would fork the truth — deliberately not done, matching the
> 2026-07-16 housekeeping call that folded all contracts into one file.

**cvg v0.1.0** · born 2026-07-19 at R0.I (Milestone 1.1 executed early per
the owner's pivot) · Task-Spec `tasks/done/T-20260719-cvg-router.md` —
stamped Tier-1, 3/3 evals, accepted with `--gold-sanity`.

## The two files

| File | Role |
|---|---|
| `cvg` | The router. One name over the proven task-spec scripts. Referee, never a player: no model credentials, no LLM calls, wrapped commands are byte-exact pass-throughs (`exec`). Bash 3.2-safe, zero dependencies. |
| `_ui.sh` | Shared presentation layer (sourced). Color only on an interactive TTY; `NO_COLOR` non-empty disables; `CVG_COLOR=0|1` overrides; 8 basic ANSI colors only; color never carries meaning alone. Never touches wrapped-command output. Grows the stage strip at `cvg capture`. |

## Command surface (v0.1.0)

| Command | Wraps | Proven by |
|---|---|---|
| `cvg tasks validate <spec>` | `validate-task-spec.sh` | routed pass-through (same mechanism as `gate`, byte-parity eval'd there) |
| `cvg tasks gate <spec>` | `safe-to-delegate.sh` | eval_1: byte + exit-code parity vs direct call |
| `cvg tasks accept <spec>` | `accept-task.sh` | accepted its own birth task (`--stamp --gold-sanity` → ACCEPT) |
| `cvg eval <spec>` | `run-task-spec.sh` | ran its own birth task's evals, 3/3 + Exit Check |
| `cvg lint` | `lint-backlog.sh` | routed pass-through |
| `cvg transition <id> <state>` | `transition-status.sh` | moved `T-20260719-cvg-router` ready → done |
| `cvg ready` | `list-ready.sh` | listed the fixture backlog |
| `cvg help` / `cvg version` | native | eval_2 (completeness), eval_3 (no ANSI when piped / `NO_COLOR`) |

Resolution: `CVG_HOME` wins when set; otherwise walk up from the working
directory to the first repo carrying `skills/task-spec/scripts/`.

## Contracts every future subcommand inherits

1. **Wrap, don't rewrite** (rule 3) — route to the proven scripts; a
   rewrite needs a written reason in `cvg-todo.md`.
2. **Byte-parity pass-through** — no decoration of wrapped output, ever;
   beauty lives in `help`/`version`/error surfaces only.
3. **Degradation floor** — no ANSI on non-TTY, `NO_COLOR`, or
   `CVG_COLOR=0`; every state readable as words (field research:
   `temp/cli-ux-research-2026-07-19.md`).
4. **Bash 3.2 + ShellCheck clean** (`shellcheck -x bin/cvg bin/_ui.sh`),
   zero pip/npm dependencies in the core path (rule 5).
5. **Dogfood ceremony** — S+ subcommands are cut as Task-Specs, gated
   before build, gold-sanity accepted after (rule 6).

## Not yet built (see cvg-todo.md for order and detail)

`capture` (R0.I, after P-8) · `intent` (R1.I) · `status` (1.2) ·
`next` (1.3) · `ci` (2.2) · `doctor`/`work` (M3) · `run`/`route` (M4) ·
`board` (M5) · `verify` (M6) · `deliver`/`metrics` (M7).
