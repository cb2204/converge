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
- **Pass 1 (Intent): CLOSED END-TO-END** (2026-07-19, all five beats) —
  `docs/tech-spec-analytical-backbone.md` signed by the owner after an
  agentic-execution review (SUFFICIENT-WITH-FIXES; all blocker and
  should-fix edits applied: analytical-query defined by principal,
  Q-SET-1 answer-key oracle, p99 normative for R-1, D1–D8 traceability).
  Gap register fully resolved (D6 ≤20% capture overhead / D7 15-min local
  loop / D8 elected waves). Lesson:
  [`docs/lessons/lesson-pass-1-analytical-backbone.md`](docs/lessons/lesson-pass-1-analytical-backbone.md).
- **Pass 1 machine proof:** `cvg intent` born (cvg 0.3.0) over the
  check-tech-spec v0.4.0 exit contract (`CHECK_TECH_SPEC=…` tokens,
  sign-off enforced); R1.P golden diff EMPTY.
- **Pass 2 (Structure): CLOSED END-TO-END** (2026-07-21, all five beats) —
  seven accepted ADRs (`0000`–`0006`) and the 10-term `docs/CONTEXT.md`
  ground the canonical technical specification in the live Postgres terrain;
  adversarial second-eyes review fixes were applied before acceptance. The
  final ADR gate returns `CHECK_ADR=OK`. `cvg structure` was born in cvg 0.4.0,
  and R2.P reproduced the direct gate byte-identically (golden diff EMPTY).
  Lesson:
  [`docs/lessons/lesson-pass-2-analytical-backbone.md`](docs/lessons/lesson-pass-2-analytical-backbone.md).
- **Pass 3 (Decompose): CLOSED END-TO-END** (2026-07-21, all five beats) —
  `reqs-to-swimlane-plans` v0.7.0 produced the three backbone swimlanes
  (`sketch/swimlane-{capture,transform,serve}/` — a lean PRD + one file per leg).
  `cvg decompose` reproduces the direct gate byte-identically (R3.P, EMPTY diff);
  `CHECK_PLAN=OK`.
- **Pass 4 (Consensus): CLOSED END-TO-END** (2026-07-21, all five beats) — a real
  cross-family adversary (kimi/moonshot) attacked the swimlanes; it raised 1 blocker
  + 3 high + 1 medium cross-lane seam gaps, all **sharpened into the PRDs** and
  re-attacked to a PASS verdict. `cvg review --check` → **`CHECK_CONSENSUS=OK`**
  (cross-family provenance over all 12 plan files). **The fork is collapsed** — Pass 4
  always hands off to task-driven decomposition (`FORK: B`); plan-driven (A) is retired.
- **Engine upgrade:** `task-spec` is now the universal **six-tier sizing engine** (v3.4)
  — XS/S/M/L runnable leaf atoms, XL/XXL decomposition nodes; the delegation gate
  refuses to run a node. Tasks all the way down.
- **Next beat:** R5.R — **Pass 5B tasking**: decompose the backbone into task-specs,
  steel thread first (`swimlane-capture-leg-01`, an L leaf).
- The authoritative beat log lives in the repo-root
  [`PLAN.md`](../../../PLAN.md).
