# uc-analytics — the Converge greenfield proving ground

E-commerce operational Postgres (customers, products, orders, payments;
deterministic seed 42, container `uc-analytics-postgres`, port 5433). The
analytical lane does NOT exist yet — Converge builds it, pass by pass.

## The single home: `converge/`

Everything Converge touches lives under **`converge/`** — the workspace
root. Skill-conventional paths (`docs/brd-*`, `sketch/*.plan`, `brain/`)
are relative to it. [`converge/INDEX.md`](converge/INDEX.md) is the front
door — the full folder map, lifecycles, and current pass state. The one-
breath version:

**brain feeds → docs agree → sketch explores → tasks execute → receipts prove.**

- `brain/` — user-generated inputs (second brain). **Read
  `brain/INDEX.md` before grilling the owner**; index anything you add —
  anything indexed is a question the grill never asks.
- `docs/` · `sketch/` · `tasks/` · `receipts/` — cvg-generated; gate-
  contract paths, never mix inputs in. (`tasks/` is git-root anchored
  today — see its README.)

Everything OUTSIDE `converge/` is the product itself: `src/` (schema, seed,
chaos generator), `Makefile` (`make help`), `docker-compose.yml`.

## Standing rules for sessions in this project

- The chain's working contract is the repo-root [`cvg-todo.md`](../../cvg-todo.md)
  — find the current beat there before doing anything.
- Technology choices are made at Pass 3 against ADRs, never earlier; the
  owner's preferences ride in the BRD's open questions.
- The `_control` schema is the chaos ledger — fenced ground truth, never
  read by business/analytical consumers.
