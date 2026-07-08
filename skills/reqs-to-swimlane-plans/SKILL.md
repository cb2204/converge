---

name: reqs-to-swimlane-plans
description: Implements Converge Pass 3 (DECOMPOSE). Reads the Pass 2 ADRs under docs/adrs/ plus the in-session understanding and splits the system into one sketch plan per swimlane (sketch/*.plan) along its natural seams — by feature or component, plan altitude only, no tasks and no implementation code. Use when the user says "decompose", "decompose this", "swimlane plans", "split it into plans", "break it into plans", "find the seams", or "one plan per lane". Each plan lists features, dependencies, build order, and inherits the relevant ADR decisions; the downstream lane names the exact upstream interface it consumes. Engine- and tracker-agnostic; runs in the same session as Pass 2, after structure is confirmed and before the plans are attacked in adversarial review. Do not use for atomic tasks or implementation code — that is Pass 5 (task-spec), not this pass.
metadata:
  version: "0.2.0"
compatibility: Claude Code on the repo; same session as Pass 2 (tech-req-to-adrs). No engine/tracker flags.
---

# reqs-to-swimlane-plans — Converge Pass 3 (DECOMPOSE)

> **Identity:** The decomposition pass that cuts a confirmed system into one sketch plan per swimlane, along its real seams.
> **Domain:** Plan-altitude decomposition, swimlane partitioning, ADR inheritance, seam/interface naming.
> **Converge Pass:** 3 of 8 — DECOMPOSE. Lowers altitude from Pass 2's "what is true about the terrain" (ADRs) to "what to build in each lane, and in what order" (plans) — but never as far as Pass 5's tasks or code.
> **Engine/flags:** Claude Code, SAME session as Pass 2. No flags — single transformation.

## Important — read first

- **Plan altitude only. This is the one guardrail that defines the pass.** A plan describes *what* each lane contains and *in what order* it is built. The moment a plan holds a query body, a handler body, or an atomic task with an eval, it has left Pass 3 and skipped the adversarial review meant to harden the plan first. When you feel the urge to write implementation code, stop — that is Pass 5.
- **Inherit the ADRs; never re-decide them.** Decisions were bound in Pass 2 under `docs/adrs/`. Plans stand on those facts. A plan that contradicts an ADR, or silently re-settles something an ADR already settled, fails the gate.
- **Same-session handoff.** The Pass 2 understanding lives only in this session — no file reloads it. That is why Pass 3 shares Pass 2's session and takes no engine flag. Cross a session boundary and the input is gone; re-run Pass 2.
- **The number of lanes is the number of real seams — not a quota.** Two lanes (for example, a transform lane vs. a serve lane) is one common shape, not a rule; a system may reveal one lane or five. An unnamed seam is a hidden coupling; a forced extra lane is a fake one.

## Inputs / Outputs / Gate

| Slot | Contract |
|------|----------|
| **IN** | The Pass 2 understanding (held in-session) **+** the ADRs at `docs/adrs/*.md` (each a numbered decision file — e.g. a join-key decision, a date-grain decision, a metric-definition decision). |
| **OUT** | One sketch plan per swimlane under `sketch/`, named for the lane's technology or feature — e.g. `sketch/<lane-a>.plan` (Component A) + `sketch/<lane-b>.plan` (Component B). |
| **GATE** | One plan per genuine seam, each listing **features / dependencies / build-order / proving-tests** and inheriting the relevant ADR decisions; the downstream lane names the exact upstream interface it consumes; **plan altitude held** (no tasks, no implementation code). See the full checklist under [Gate](#gate--confirm-before-leaving-this-pass). |

## Flags

No engine/tracker flags — this is a single transformation. It runs in the SAME session as Pass 2 because the understanding is the handoff and cannot survive a session boundary. There is no adversary and no tracker at this pass: the adversary binds in Pass 4 (`--adversary`), the tracker in the Pass 5B/register fork (`--tracker`). The lane count is not a flag either — it is the number of genuine seams the architecture reveals (see Step 1).

## Instructions

### Step 1 — DECOMPOSE: find the natural seams

From the loaded Pass 2 understanding and the ADRs, split what is being built into its top-level pieces and justify where each boundary falls.

- Cut along **natural seams — by feature OR by component**, never arbitrary slices.
- Name each seam and the **dependency direction** between the resulting groups. Do not plan the contents yet.
- The seam itself is an **interface**, and it must be nameable. *Example — a data pipeline whose upstream inputs are already fixed:* the seam falls cleanly above those inputs — a **transform** lane that shapes the data (Component A) and a **serve** lane that exposes it (Component B), with the **published-output contract** (the tables/columns A produces and B consumes) as the interface between them. Your seams will follow your own system's real boundaries.
- If a boundary is fuzzy, that is signal: either it is a real seam (name the interface) or a false one (fold the lanes back together).

### Step 2 — SWIMLANE: one plan per seam

Write one sketch plan per seam under `sketch/`. **One lane, one plan, one focus.** Each plan should carry:

1. **Identity line** — which component this is (e.g. A · Transform / B · Serve) and its input/output contract.
2. **Features / components** — the pieces inside the lane and what each does (for example, in a transform lane, the staged transformation layers; in a serve lane, a shared query core plus each transport/interface it exposes). Component-level, never implementation bodies (no query bodies, no handler bodies).
3. **The consumed interface (downstream lanes only)** — the exact upstream tables/columns/fields this lane reads, so the seam is explicit. A downstream lane names precisely which published outputs each endpoint/tool/consumer reads and **never reaches below the seam** into an upstream lane's internals.
4. **Dependencies** — a small DAG showing the build order between the lane's own pieces and its inbound seam.
5. **Build order** — a sane sequence, with the gating input called out (for example, a frozen acceptance-question set may gate the output layer and the final serving surface).
6. **Tests that prove each piece** — at plan altitude: *what* each test asserts, not the test code.
7. **Open questions** — anything the ADRs do not cover, with an owner and whether it blocks the build. Surface it here; do not invent the answer inside the plan.

Keep each plan tight and skimmable. Plan altitude only.

### Step 3 — GROUNDED: each lane inherits the ADRs

Tie every lane back to the bound decisions in `docs/adrs/`.

- Each lane honors the decisions the ADRs bound for it — for example, a transform lane honors any ADR-fixed join path and grain; a serve lane honors any ADR-fixed read boundary (reading only the published contract, read-only, never reaching into an upstream store or below-contract internals).
- Trace each component back to the tech requirement or ADR it satisfies (a short "spec traceability" note per plan makes this checkable).
- A plan that contradicts an ADR, or that re-decides something an ADR already settled, fails this step — fix the plan, do not edit the ADR here.

### Step 4 — Gate and hand off

Run the [Gate checklist](#gate--confirm-before-leaving-this-pass). When every box holds, the `sketch/*.plan` files are the input to Pass 4 (`sketch-plans-adversarial-review`), where a **different** model attacks them one at a time and names the fork.

## Gate — confirm before leaving this pass

- [ ] One sketch plan exists per genuine seam (e.g. `sketch/<lane-a>.plan` + `sketch/<lane-b>.plan`).
- [ ] The split follows a natural seam — by feature or component — and each boundary is **justified**, not a guess and not a quota.
- [ ] Each plan lists features/components, the dependencies between them, a sane build order, and the tests that prove each piece (at plan altitude).
- [ ] Each plan inherits the relevant `docs/adrs/*` decisions and **contradicts none** of them.
- [ ] The downstream lane names the **exact upstream interface** it consumes (the published tables/columns/fields) and never reaches below it.
- [ ] Open questions the ADRs do not cover are surfaced with an owner and a blocks-build flag — not answered inside the plan.
- [ ] **Plan altitude held** — no atomic tasks, no implementation code anywhere.

When these hold, hand off to Pass 4.

## Examples

**Example 1 — a common two-lane cut (illustrative, for a data pipeline with a serving layer).**
User says *"decompose this — the ADRs are written."* → From the in-session understanding + `docs/adrs/`, you identify the seam above the fixed upstream inputs and cut two lanes: Component A · Transform and Component B · Serve, with the published-output contract as the interface between them. → You write `sketch/<transform-lane>.plan` (the staged transformation layers, each layer's responsibility, a test strategy, build order gated on the frozen acceptance questions) and `sketch/<serve-lane>.plan` (a shared query core plus each transport/interface, the exact published columns each endpoint/tool consumes, read-only/contract-only isolation). → Result: two skimmable plans, each tracing to its ADRs, seam named, no implementation code — ready for adversarial review.

**Example 2 — resisting altitude drift.**
User says *"split it into plans and write the dedup query while you're at it."* → You produce the plans, and in the relevant lane you write that step's *responsibility* ("dedup duplicate records by business signature, quarantine the rest") but **not** the query body. → You tell the user the query is Pass 5 (`task-spec`) work and the plan stays at altitude so Pass 4 can attack the plan before any code exists.

**Example 3 — a false seam.**
User proposes three lanes where two of them are just two transports (say, an HTTP API and a tool interface) over the same logic. → You note they share one query core and differ only in protocol framing — that is one lane (serve) with two transports, not two lanes. → You fold them into a single serve plan as components B2/B3 over a shared B1, and record the split-later condition (only if one transport needs logic the other doesn't). Two lanes, not three.

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| A plan contains a query body or a handler body | Altitude leak into Pass 5 territory | Delete the code; replace with the component's *responsibility* in prose. Push the code to `task-spec` (Pass 5). |
| A plan asserts a join/grain/metric/rule the ADRs don't back | Re-deciding instead of inheriting | Remove the assertion; cite the ADR instead. If no ADR covers it, log it as an open question (owner + blocks flag), don't invent it. |
| The understanding "feels gone" / plans read like guesses | Session boundary crossed since Pass 2 | Stop. Re-run Pass 2 (`tech-req-to-adrs`) in this session to reload the understanding and confirm the ADRs; then decompose. |
| Three-plus lanes and the extra one feels thin | Forced quota, not a real seam | Test each seam by naming its interface. If you can't name a hard interface, fold the lane back in. |
| Downstream plan reaches below the seam (into an upstream lane's internals) | The interface wasn't pinned | Make the plan name the exact published tables/columns/fields it consumes; any missing field becomes a "new output request" upstream, never a deeper read. |
| ADRs missing under `docs/adrs/` | Pass 2 didn't record, or ran in another session | Do not proceed on memory. Ensure Pass 2 wrote the ADRs; plans inherit files, not recollection. |

## Notes

- **Why this order.** Seams first (Step 1), then plan the contents (Step 2), then ground against the ADRs (Step 3). Planning contents before naming the seam enshrines a boundary you haven't justified; grounding before planning has nothing to check.
- **The seam is a contract, not a suggestion.** The published-output interface is owned by the upstream lane and consumed by the downstream lane. Naming it here is what lets Pass 4 attack it and Pass 5 build both lanes against a frozen shape.
- **Plans are attacked, not shipped.** Pass 3 output is deliberately un-hardened. It is *supposed* to have soft spots that Pass 4's adversary finds. Do not over-polish or pre-empt objections into the plan; that hides the seams the review needs to test.

## Handoff

→ **`sketch-plans-adversarial-review`** (Pass 4, CONSENSUS). It consumes the `sketch/*.plan` files produced here and attacks them **one at a time** — hunting unjustified seams, missing dependencies, plans that contradict an ADR, and any altitude leak into task or code detail — sharpens them in place (the diff is the record), and names **THE FORK**: whole-system plan-driven (Pass 5A, `plans-to-coherent-spec`) or per-unit task-driven (Pass 5B, `task-spec`).
