# Loop state

Append-only. Written by `cvg loop` on every landing.
An error or an exhausted budget is never recorded as success.

| when (UTC) | task | engine | state | iterations | note |
|---|---|---|---|---|---|
| 2026-07-27T19:56:51Z | `T-20260721-cap-steelthread` | claude | **ERROR** | 0/1 | the task could not be resolved or its contract is missing |
| 2026-07-27T20:11:29Z | `T-20260721-cap-steelthread` | claude | **EXHAUSTED** | 1/1 | iteration budget exhausted — work-in-progress and a handoff note are on disk |
| 2026-07-27T21:17:43Z | `T-20260721-cap-steelthread` | claude | **BLOCKED** | 1/2 | the eval went green but settlement refused — read the guard verdict above |
| 2026-07-28T13:51:16Z | `T-20260721-cap-steelthread` | claude | **BLOCKED** | 1/15 | tier-2 returned no usable verdict (rc=1) — a verdict that cannot be obtained is never a pa |
| 2026-07-28T16:09:12Z | `T-20260721-cap-steelthread` | claude | **LOCAL_SETTLED** | 1/5 | — |
| 2026-07-28T19:11:28Z | `T-20260721-cap-alldomains` | claude | **ERROR** | 1/5 | the verification step itself could not run |
| 2026-07-28T19:35:14Z | `T-20260721-cap-alldomains` | claude | **LOCAL_SETTLED** | 1/5 | — |
| 2026-07-28T20:42:01Z | `T-20260721-cap-freshness` | claude | **BLOCKED** | 1/5 | the eval went green but settlement refused — read the guard verdict above |
| 2026-07-28T21:01:05Z | `T-20260721-tf-silver` | claude | **SETTLED** | 1/5 | — |
| 2026-07-28T21:40:32Z | `T-20260721-tf-gold` | claude | **EXHAUSTED** | 3/5 | wall-clock budget exhausted |
| 2026-07-28T21:49:44Z | `T-20260721-tf-gold` | claude | **ERROR** | 0/5 | the task could not be resolved or its contract is missing |
| 2026-07-28T21:58:17Z | `T-20260721-tf-gold` | claude | **ERROR** | 0/5 | the task could not be resolved or its contract is missing |
