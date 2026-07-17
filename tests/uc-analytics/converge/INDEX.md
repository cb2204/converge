# converge/ — the Converge workspace (single home)

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

- **Pass 0 (Capture): gate green** — `docs/brd-analytical-backbone.md`
  (2026-07-17). Awaiting owner canonization (R0.C).
- Everything else: not yet born. The current beat lives in the repo-root
  [`cvg-todo.md`](../../../cvg-todo.md).
