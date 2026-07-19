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

- **Pass 0 (Capture): CLOSED END-TO-END** (2026-07-19, all five beats) —
  `docs/brd-analytical-backbone.md` signed canonical by the owner; gate
  hardened (check-brd.sh v0.3.0 exit contract); `cvg capture` reproduces
  the manual golden run byte-identically (R0.P). Lesson:
  [`docs/lessons/lesson-pass-0-analytical-backbone.md`](docs/lessons/lesson-pass-0-analytical-backbone.md).
- **Pass 1 (Intent): tech-spec gate-green, owner-approved** —
  `docs/tech-spec-analytical-backbone.md` (R1.R closed 2026-07-19; locked
  decisions in `brain/decisions/`). Canonization (R1.C, Gate H1) deferred
  by the owner's Pass-0-first call.
- **Next beat:** R1.C when the owner reopens Track R's descent.
- Everything else: not yet born. The current beat lives in the repo-root
  [`cvg-todo.md`](../../../cvg-todo.md).
