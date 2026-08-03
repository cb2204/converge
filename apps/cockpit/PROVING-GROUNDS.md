# Cockpit v1 proving grounds

Cockpit is named and versioned v1 on `feat/front-end-cockpit-v1`. That product
version does not imply that the release gates below have passed.

| Case | Lane | Current evidence | Release gate |
|---|---|---|---|
| `uc-01-analytics-engineering` | FULL | The live snapshot holds at blocked Pass 4 with three unresolved owner decisions; work, runs, and receipts are empty | Open |
| `uc-02` Data Engineering | NORMAL (planned) | No proving-ground workspace is present | Not run |
| `uc-03` Software Engineering | NORMAL (planned) | No proving-ground workspace is present | Not run |
| `uc-04` AI Engineering | FAST and failure paths (planned) | No proving-ground workspace is present | Not run |

The application is release-ready only when all four cases have exercised the
same WorkspaceSnapshot 2.0 contract without frontend-derived truth.

For `uc-01`, owner decisions must close the current consensus barrier before
tasking can begin. Cockpit must continue to show the barrier; it must not create
tasks, advance the pass, or synthesize later lifecycle data. The gate remains
open until the workspace proceeds through tasks, attempts, and settlement
receipts.

Hermetic fixtures in this repository verify rendering and interaction
semantics. They are explicitly replay data and are not evidence that a
proving-ground case completed.
