# uc-analytics — the Converge greenfield proving ground

E-commerce operational Postgres (customers, products, orders, payments;
deterministic seed 42, container `uc-analytics-postgres`, port 5433). The
analytical lane does NOT exist yet — Converge builds it, pass by pass.

## The single home: `converge/`

Everything Converge touches in this project lives under **`converge/`** —
the Converge workspace root. Skill-conventional paths (`docs/brd-*`,
`sketch/*.plan`, `brain/`) are relative to it. The split inside:

- **`converge/brain/`** — user-generated inputs: transcripts, notes,
  definitions, refs, decisions. [`brain/INDEX.md`](converge/brain/INDEX.md)
  is the tidy front door — read it before grilling the owner; index
  anything you add. Anything indexed is a question the grill never asks.
- **`converge/docs/`** — cvg-generated consensus artifacts (gate-contract
  paths; never mix inputs in):
  - `docs/brd-analytical-backbone.md` — the brief (Pass 0, gate green
    2026-07-17, re-proven after the move). Stack preferences live in its
    open questions, NOT as decisions.
  - `docs/adrs/`, `docs/lessons/`, `docs/CONTEXT.md` — born in later passes.
- **`converge/sketch/`** — swimlane plans (born at Pass 3).
- Task-specs are the one exception: the tooling anchors `tasks/` at git
  root (currently the converge repo root; moves here if this project ever
  becomes its own repo).

Everything OUTSIDE `converge/` is the product itself: `src/` (schema, seed,
chaos generator), `Makefile` (`make help`), `docker-compose.yml`.

## Standing rules for sessions in this project

- The chain's working contract is the repo-root [`cvg-todo.md`](../../cvg-todo.md)
  — find the current beat there before doing anything.
- Technology choices are made at Pass 3 against ADRs, never earlier; the
  owner's preferences ride in the BRD's open questions.
- The `_control` schema is the chaos ledger — fenced ground truth, never
  read by business/analytical consumers.
