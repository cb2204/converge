# Partner onboarding — MCP access to the analytical backbone

Goal (R-11): a new partner gets from zero to a first successful query in
**<=1 business day**. This runbook is the checklist that makes that true —
follow it top to bottom; nothing here requires a source-schema change or a
transform re-run.

## Before you start

- Confirm the partner has signed the standard data-access agreement
  (business process, outside this repo — the runbook assumes it's done).
- Confirm `make up` is running (`uc-analytics-postgres` container healthy).
  Partner access rides over the same live Postgres the FastAPI surface uses.

## Step 1 — Provision the read-only principal (~15 min)

The serve layer never grants partners anything beyond the published
`gold.*` seam (ADR-0001). This is enforced by the database, not discipline:

```bash
python3 -c "
import sys; sys.path.insert(0, 'cvg/serve/core')
import reader
reader.ensure_serve_role()
"
```

This is idempotent — safe to re-run. It creates `serve_reader` if missing
and grants exactly `USAGE` on schema `gold` + `SELECT` on the published
gold tables (`revenue`, `revenue_by_product`). Nothing on `silver`,
`raw.*`, `public`, or `_control` is ever granted to this role.

## Step 2 — List the exposed MCP tools (~5 min)

```bash
python3 cvg/serve/mcp/server.py
```

Each line names a tool, its SLA class, and its budget in seconds. Share
this list with the partner — it is the entire surface they can call.

## Step 3 — Walk the partner through their SLA class (~10 min)

| Class  | Budget | Example tool          |
|--------|--------|-----------------------|
| small  | <=5m   | `total_revenue`       |
| medium | <=30m  | `revenue_by_product`  |
| hard   | <=60m  | multi-table / 3x drill|

SLA classes are defined once in `cvg/serve/mcp/sla_classes.py` — point the
partner at that file if they ask "how fast should this respond?" rather
than restating the numbers by hand, so the runbook never drifts from code.

## Step 4 — First successful query (~15 min)

Have the partner run one small-class tool end to end:

```bash
python3 -c "
import sys; sys.path.insert(0, 'cvg/serve/mcp')
import server
print(server.call_tool('total_revenue'))
"
```

A successful first query returns a dict with `metric`, `value`, and
`as_of` — the freshness watermark (R-4) this answer agrees with. If
`as_of` is missing or clearly stale, stop and escalate (Step 6) instead of
handing off a partner integration against a broken freshness signal.

## Step 5 — Confirm the answer is honest, not just present

- `as_of` must be a real timestamp, not null and not far in the past.
- If `staleness = now - as_of` exceeds the R-4 SLA (15 min), the partner
  should expect (and your integration should surface) the staleness alert
  — that's expected behavior under load, not a bug to route around.
- The partner never sees anything below the seam: no `silver`, no
  `raw.*`, no `_control`. If a query needs that, it is an upstream gap,
  not something to grant around.

## Step 6 — Escalation

If Step 4 fails, or `as_of` looks wrong:

1. Re-run Step 1 (`ensure_serve_role` is safe to repeat).
2. Confirm `make up` and the container are actually healthy.
3. If the gold tables themselves look stale or missing, this is a
   transform-layer gap (outside serve's write scope) — report it upstream
   rather than patching around it here.

## Definition of done for this onboarding

- [ ] Partner has a working `serve_reader`-scoped query path.
- [ ] Partner has run one small-class tool and gotten a real `as_of`.
- [ ] Partner knows their SLA class and where the budgets live in code.
- [ ] Elapsed time from Step 1 to a successful Step 4: <=1 business day.
