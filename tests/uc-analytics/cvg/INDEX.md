# cvg/ — the Converge workspace (single home)

One kind of knowledge per folder, one lifecycle each:

**brain feeds → docs agree → sketch explores → tasks execute → receipts prove.**

| Folder | Kind | Lifecycle | Born at |
|---|---|---|---|
| [`brain/`](brain/INDEX.md) | user-generated inputs | raw, append-only, never gated | any time — feed it constantly |
| [`docs/`](docs/) | consensus artifacts | gated, permanent, never deleted | Pass 0 ✓ (BRD) · 1 (tech-spec) · 2 (adrs/, CONTEXT.md) · lessons/ any pass |
| [`sketch/`](sketch/) | drafts (swimlane plans) | transient by design — sharpened at Pass 4, superseded at 5A/5B | Pass 3 |
| [`tasks/`](tasks/) | sealed execution units | HMAC-stamped, tracked | Pass 5B *(see exception in tasks/README)* |
| [`receipts/`](receipts/) | evidence — gate verdicts, pass receipts | write-once | every pass close (P-5 SHOW) |

## Current state

- **Pass 0 (Capture): CANONICAL** — `docs/brd-analytical-backbone.md`
  signed by the owner 2026-07-19 (gate green since 2026-07-17). Lesson:
  [`docs/lessons/lesson-pass-0-analytical-backbone.md`](docs/lessons/lesson-pass-0-analytical-backbone.md).
- **Next beat: R1.R** — Pass 1 (`brd-docs-to-tech-req`) runs on the
  canonical BRD; the tech-spec gets born in `docs/`.
- Everything else: not yet born. The current beat lives in the repo-root
  [`cvg-todo.md`](../../../cvg-todo.md).
