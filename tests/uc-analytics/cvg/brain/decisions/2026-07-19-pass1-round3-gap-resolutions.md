# Pass 1 · Round 3 — gap resolutions (owner answers, locked on arrival)

> Date: 2026-07-19 · Owner: VP of Engineering (Luan Moreno, persona) —
> decider. Round 3 of the Pass 1 interrogation: the three minor gaps left
> open at crystallization (GAP-001/002/003), answered at R1.C. Recorded
> verbatim-first per the standing rule (answers land on disk the moment
> they arrive); normalized readings follow each quote.

## D6 — Capture overhead bound (resolves GAP-001)

**Owner, verbatim:** "around 15% to 20% since the need to get the data on
the analytical backbone will become critical"

**Locked reading:** Acceptable capture overhead on production is **up to
20% added p95 latency** (hard ceiling for R-2's eval), **15% the working
target**, feed-on vs feed-off under like-for-like load. This is a
DELIBERATE loosening of the interrogator's proposed 5% default: the owner
judges the backbone feed business-critical enough to spend real production
headroom on it. Recorded tension (interrogator's note, owner aware):
production fragility is the founding pain of this project — a bound this
generous must be re-examined at Pass 3 when the capture mechanism is
chosen, and the measured number published per R-2 regardless.

## D7 — Local-loop target (resolves GAP-002)

**Owner, verbatim:** "15 minutes should be fine for the v1 interaction"

**Locked reading:** R-7's loop target is **≤ 15 minutes** from fresh
checkout to a verified change — the proposed default, confirmed for
phase one (v1).

## D8 — Partner migration sequencing (resolves GAP-003)

**Owner, verbatim:** "partners will be elected and will be in waves TBD"

**Locked reading:** Migration proceeds in **elected waves**: partners are
selected (elected) into migration waves; wave composition and order are
decided at migration-planning time, not in this spec. The gap closes as a
PROCESS RULE — sequencing = waves, election = at planning — which is all
R-5's execution planning needed; R-5's acceptance criteria (all partners
migrated → revocation provably fails → 7 clean days) are unchanged and
never depended on the order.
