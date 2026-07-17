# uc-analytics — the Converge greenfield proving ground

E-commerce operational Postgres (customers, products, orders, payments;
deterministic seed 42, container `uc-analytics-postgres`, port 5433). The
analytical lane does NOT exist yet — Converge builds it, pass by pass.

## Where things live (keep this split sacred)

- **User-generated inputs → [`brain/`](brain/INDEX.md).** Transcripts, notes,
  definitions, refs, decisions. `brain/INDEX.md` is the front door — read it
  before grilling the owner; index anything you add.
- **cvg-generated artifacts → `docs/` and `sketch/`** (and task-specs in the
  repo-root `tasks/`). These paths are gate contracts — the check scripts
  glob them. Never mix inputs into them.
  - `docs/brd-analytical-backbone.md` — the brief (Pass 0, gate green
    2026-07-17). Stack preferences live in its open questions, NOT as
    decisions.
  - `docs/lessons/` — pass-to-lesson debriefs land here.
- **The terrain** — `src/` (schema, seed, chaos generator), `Makefile`
  (`make help` lists everything), `docker-compose.yml`.

## Standing rules for sessions in this project

- The chain's working contract is the repo-root [`cvg-todo.md`](../../cvg-todo.md)
  — find the current beat there before doing anything.
- Technology choices are made at Pass 3 against ADRs, never earlier; the
  owner's preferences ride in the BRD's open questions.
- The `_control` schema is the chaos ledger — fenced ground truth, never
  read by business/analytical consumers.
