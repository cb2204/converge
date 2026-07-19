# CLI UX research — field-verified patterns for `cvg` (2026-07-19)

> Deep-research run from the R1.R session (workflow `wf_ccea6bb8-394`,
> 20 sources, 99 claims extracted, 25 adversarially verified → 18 confirmed,
> 2 refuted, 5 unverified-by-fetch-error). Synthesis stage failed in-run;
> this file is the manual distillation of the 18 confirmed claims, ranked by
> fit to the R1.I UX contract (dep-free ANSI core + optional rich shell).
> Consumed at R1.I when the `_ui` layer is born.

## 1. The degradation contract (highest fit — becomes `_ui`'s acceptance checks)

- **Disable color when:** stdout/stderr is not a TTY, or `NO_COLOR` is set
  non-empty, or `--no-color` passed. (clig.dev, 3-0)
- **`NO_COLOR` semantics:** presence + non-empty, value ignored — a single
  env check, trivially bash-3.2. Flags/config **override** the env var
  (`--color` wins over `NO_COLOR`). (no-color.org, 3-0)
- **Non-TTY = no animations**, ever — "stops progress bars turning into
  Christmas trees in CI log output." (clig.dev, 3-0)
- **gh's machine-output mode** when piped: no color/styling, state written
  as words (never implied by color), tab-delimited columns (`cut` uses
  tabs), no truncation, exact dates, no header. This is the spec for
  `cvg`'s non-TTY gate output. (primer/cli, 3-0)

## 2. Color discipline

- Only the **8 basic ANSI colors** are reliably supported; 256-color is
  not reliable everywhere; color may **enhance** meaning, never carry it
  alone. (primer/cli, 3-0)
- Lipgloss pattern worth reimplementing dep-free: define one truecolor
  palette, **downsample** by detected capability (truecolor → 256 → 16 →
  plain), strip everything on non-TTY. (charmbracelet/lipgloss, 3-0)
- Errors: catch and rewrite for humans; red sparingly; the most important
  information goes **last** (the eye lands at the end). (clig.dev, 3-0)

## 3. Stage/pipeline visualization precedents

- **docker buildx `--progress=auto`**: TTY → interactive in-place redraw,
  non-TTY → `plain` text log; `auto` detection is the canonical pattern
  for a multi-stage pipeline CLI. (docker docs, 3-0)
- **Dagger 0.6 TUI**: parallel pipelines as box-drawing vertical columns
  (`┃` active, `│` inactive), ops as block chars; DAG rendered
  `git log --graph`-style, with a **full plain snapshot printed at the
  end** so the interactive run still leaves a complete log. (dagger.io,
  3-0 / 2-0)
- Progress indication is mandatory for long work — "if your program
  displays no output for a while, it will look broken." (clig.dev, 3-0)

## 4. Interaction patterns (gh design system, 3-0)

Confirm steps for risky commands; headers to set context for output;
consistent command language; similar commands visually/behaviorally
parallel; **anticipate the next action** (e.g., gh offers branch deletion
after merge — cvg should offer the next beat/gate after a green one).

## 5. Framework verdict (confirms the R1.I call)

- Typer **vendors a full copy of Click** (8.3.1) — real footprint for a
  thin router. (typer docs, 3-0)
- Even Typer's own docs bless **argparse as the stdlib baseline**. (3-0)
- → R1.I's decision stands: bash router + stdlib-Python where needed;
  Rich/Textual only as optional presentation shell, never in the gate path.

## Refuted / unverified (kept honest)

- Refuted (0-3): "cli-py is line-oriented/minimal by design" — do not cite.
- Refuted (1-2): "Typer is a layer over external Click" — it *vendors*
  Click; the dependency-cost point survives in different form (see §5).
- Unverified (fetch errors, not disproven): Dagger live-tree details,
  clig.dev authors' human-vs-machine framing, one duplicate NO_COLOR claim.
