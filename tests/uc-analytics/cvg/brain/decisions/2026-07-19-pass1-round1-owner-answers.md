# Pass 1 · Interrogation Round 1 — owner answers (locked 2026-07-19)

> Owner: VP of Engineering (Luan Moreno, persona). Voice reply, one round,
> five questions. Recorded here immediately so the answers survive session
> boundaries; the tech-spec's Confirmed-decisions section will restate these
> as locked decisions. Q&A verbatim-faithful, lightly condensed.

## D1 — Freshness number (confirms the recommended default)

**Data queryable in the backbone within 5 minutes of the operational
write.** Owner: "let's not get less than that" — 5 minutes is the floor,
and it becomes **a default standard for this process** going forward.

## D2 — "Answered in under 1 hour," measured how (redirects the default)

A single bar is wrong: the SLA **depends on the complexity of the
question**. Classify questions as **small / medium / hard**, each class
with its own SLA. **Round 2 (2026-07-19) locked the numbers:** small = a
known metric looked up, **≤ 5 minutes**; medium = analysis across domains
with existing data, **≤ 30 minutes**; hard = a brand-new question needing
new modeling, **≤ 1 hour** (the BRD's KPI-1 ceiling holds as the worst
case). The timed question-to-answer drill as the measurement mechanism was
not contested — it runs per class.

## D3 — Production lockdown definition (confirms the recommended default)

Phase one ends with all current partner analytical consumers migrated,
then the flip: analytical read paths to production revoked and **provably
fail**, plus a **7-day observation window showing zero analytical
queries** on the operational database. The flip happens **after the last
partner is migrated, not before** (answers the BRD's open question on
lockdown timing).

## D4 — Late / missing / wrong data (confirms, with owner emphasis)

**Never silently wrong.** Show consumers what the data actually gives us —
"if the source gives us the truth, hand over the truth" — with freshness
always visible; deal with staleness openly and use it to drive strategies
for fresher data. Staleness beyond ~3× the freshness target becomes an
alerted incident (recommended default, uncontested).

## D5 — Load (corrects the placeholder)

**100 analytical queries per day** — per **day**, not per week; size for
it. **Round 2 (2026-07-19) confirmed the placeholders:** ≤ 10 partner
organizations in phase one and modest data growth — both stay tagged
`(estimated)` as planning numbers, re-validated when partner migration
planning starts.

## Process note (owner, same reply)

Locked answers ride inside every pass from here down — the human shapes
the passes so that machine execution matches what the owner and customer
actually want.
