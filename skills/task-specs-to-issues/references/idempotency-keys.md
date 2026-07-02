# Idempotency keys — how each tracker carries the spec `id`

Re-running `register.sh` **must not create duplicate issues**. Every adapter
carries the spec `id` on the issue as a durable, greppable key, looks the issue
up by that key first, and **updates in place** if found. This is the single
mechanism that makes the projection idempotent — "look up by id, update else
create." If the key is ever stripped, the next run creates a second issue
instead of updating; restoring the key repairs it (see the SKILL.md
Troubleshooting row on duplicate issues).

The key is always the spec `id` (e.g. `T-20260625-bronze-views`) verbatim — the
same string that appears in `depends_on`, so link resolution and upsert lookup
share one key space.

## GitHub — HTML marker + label

- **Carrier:** an HTML comment embedded in the issue body:
  ```
  <!-- task-spec: T-20260625-bronze-views -->
  ```
  It renders invisibly in Markdown, survives edits, and is trivially greppable.
  Plus a `task-spec` label so the whole registered set is one filter.
- **Lookup:** `gh issue list --label task-spec --state all --search "<marker> in:body" --json number,body`,
  then `jq` filters bodies that `contains` the exact marker and takes the first
  number. `--state all` means a **closed (done)** issue is still updated in
  place, never re-created.
- **Failure mode:** someone deletes the HTML comment from the body → the next
  lookup misses → a duplicate is created. Fix: paste the marker back into the
  original issue's body.

## Linear — native `externalId`

- **Carrier:** Linear's first-class `externalId` field, set to the spec id at
  `issueCreate`. This field exists precisely for "this issue mirrors an external
  record" and is not shown in the title, so it never clutters the board.
- **Lookup:** a GraphQL `issues(filter: { externalId: { eq: "<id>" }, team: {
  id: { eq: $team } } })` query returns the node id; upsert updates it via
  `issueUpdate`, else `issueCreate`.
- **Failure mode:** creating the issue by hand (no `externalId`) → lookup misses.
  Fix: set the `externalId` on the manually-created issue to the spec id.

## Jira — label + summary tag

- **Carrier:** a `task-spec:<id>` **label** (the machine key) plus a
  `[task-spec:<id>]` prefix on the **summary** (a human-visible echo). The label
  is what lookup keys on; the summary tag is redundancy for eyeballs.
- **Lookup:** JQL `project = KEY AND labels = "task-spec:<id>"` → the first
  issue key; upsert `PUT`s if found, else `POST`s a new issue carrying the label.
- **Status:** the Jira adapter is **partial** — the shapes are correct and the
  lookup is real, but write verbs are gated behind `TSI_JIRA_ENABLE=1` until a
  maintainer validates the create/transition payloads against a live project.

## Invariants every adapter upholds

1. **One key per spec, one spec per key.** The id is unique in `tasks/`, so the
   key is unique on the board. Never fan-out (1 spec → 2 issues) and never merge
   (2 specs → 1 issue).
2. **Lookup before write.** Upsert always resolves the key first; create is the
   fallback, not the default.
3. **The key is stable across re-runs.** Editing a spec's title changes the
   issue title on the next run but **not** the key — so the same issue is
   patched, not duplicated. (SKILL.md Example 3.)
4. **Links resolve through the same key.** `link --from X --to Y` resolves both
   ids via the identical lookup, so the dependency graph and the issue set can
   never drift apart.
