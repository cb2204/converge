# receipts/ — evidence (write-once)

Gate verdicts and pass receipts: what was produced, where, the gate
output, the lesson link. One file per pass close (P-5 SHOW). Never edited
after the fact.

## One receipt is post-hoc, and here is why

`T-20260721-cap-freshness.json` carries `post_hoc: true`. The loop never
settled that task: its only landing was **BLOCKED** (2026-07-28T20:42Z —
the eval went green but the guard refused settlement), and completion was
operator-driven — the two live-only defects were fixed (ec3d4c4, cd5fbbf),
PR #2 merged, and the POST-gate accepted by hand at 20:50Z. No settled run
ever wrote a `result: pass` receipt, so none existed to lose.

The receipt now in place is a **re-verification, not a reconstruction**: on
2026-07-29 the full accept gate was re-run dry against the settled tree
(evals green, blast radius clean, sign-off HMAC intact) and the receipt was
written by `write-execution-receipt.py --post-hoc`, which refuses unless
the sign-off envelope still verifies. It records the spec's current hash
AND the bind-time hash, and names its own provenance in `generated_by`.
An evidence gap documented beats an evidence gap papered over.

The three `T-20260721-cap-steelthread.attempt-*.json` files are stub-engine
kernel-test artifacts, kept knowingly as the record of the runs that proved
the brakes before any real engine was dispatched.
