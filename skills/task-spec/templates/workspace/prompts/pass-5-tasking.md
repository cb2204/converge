# Pass 5 · Tasking — legs → signed Task-Specs (the cornerstone)

**Mission:** cut one self-verifying Task-Spec per leg. **Evals come first**:
write the checks that define done before describing the work — a task without
a runnable eval is not a task yet.

**Inputs:** the signed swimlane tree. If the project holds judge-only
criteria (an answer key the human designated), you still do not open it —
the human decides what enters evals vs what stays held out.

**Procedure, per leg:**
1. `cvg tasks new <slug> <effort>` — effort honestly sized (XS/S/M/L are
   leaf budgets; XL/XXL must declare `children:` and decompose — a node is
   never dispatched).
2. Author the evals as runnable bash that asserts *outcomes* (state, files,
   query results) — not "the script ran". Then the description, budgets
   (`budget_iterations`, wall-clock, tokens), and blast radius.
3. If holdout criteria exist: the human places them under `## Holdout` —
   the section is excluded from the worker's brief and reserved for the
   tier-2 judge. Never echo holdout content anywhere else in the spec.
4. `cvg tasks validate <spec>` — structure + six-tier sizing.
5. The human stamps: `cvg tasks gate --stamp <spec>` → `VERDICT: DELEGATE`,
   `TIER=1`. The HMAC seal now covers the eval bodies: editing them after
   this point breaks every downstream gate.
6. `cvg lint` across the backlog: no cycles, no write-surface overlaps.

**Exit:** every leg has a sealed spec in `cvg/tasks/`, `TIER=1`, backlog
lint clean.

**Hands off to:** Pass 6 (Register, opt-in) or straight to Pass 7 (Bind).
