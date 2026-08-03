# Converge Cockpit visual system

Cockpit is a read-only operational projection of canonical Converge state. It
is built for understanding the full journey from intent to settlement without
turning the browser into a second execution authority.

## Product posture

- The repository and `cvg` CLI remain canonical.
- The browser fetches WorkspaceSnapshot 2.0 and renders only what the snapshot
  can prove.
- The persistent command dock can copy an authorized command. It cannot execute
  or mutate anything.
- Empty, unavailable, loading, stale, blocked, and error states are visually and
  textually distinct.
- Panel preferences are the only client state persisted in localStorage.

## Shell

The interface fills `100dvh` with no floating outer frame:

- A 56 px command bar identifies the workspace, Git state, transport freshness,
  and panel controls.
- A left navigation rail is 56 px collapsed and 256 px expanded. It links to
  Journey, Work, Runs, Proof, and Health.
- The center is a full-bleed operational surface.
- A right inspector is 48 px collapsed and 376 px expanded. Its Details, Proof,
  and History tabs keep typed entity context in one place.
- A 56 px command dock exposes authorization, mutation class, dry-run support,
  rationale, and exact copy-only CLI text.

## Responsive behavior

- At 1600 px and wider, both side panels start expanded.
- From 1280 px through 1599 px, navigation starts collapsed and the inspector
  starts docked open.
- From 1024 px through 1279 px, both panels start closed and the inspector opens
  as an overlay.
- At 1023 px and narrower, navigation and inspector are mutually exclusive
  drawers.
- Below 768 px, Journey and Work use semantic lists instead of React Flow, the
  inspector becomes a full-width sheet, and the five primary views move to a
  bottom navigation bar.
- Saved desktop panel preferences are restored where docked panels fit. Smaller
  viewports always start unobstructed.

## Direction

- Dense, cinematic operational software rather than a generic card dashboard.
- Outfit Variable for product typography and system monospace for commands,
  identifiers, hashes, and paths.
- Factory Black and Carbon surfaces with Forge Gold as the single brand accent.
- Mint communicates canonical proof, coral communicates failure or unresolved
  risk, and Steel communicates optional, future, empty, or unavailable state.
- Semantic color is always paired with a written status and icon.
- Borders and restrained depth organize the workspace. Decorative glass and
  gradients never replace hierarchy.

## Surfaces

### Journey

Journey renders the nine Converge passes and their required, optional, and
bypass lineage. Nodes can be dragged for local exploration. Pan, zoom, Fit, and
Arrange never alter repository state. Center Selected preserves the current
zoom and does not reset the viewport.

### Work

Work offers dependency graph and semantic list projections of the same
Task-Spec inventory. Frontier, backlog, and completed groups remain explicit.
Dispatchability, blockers, dependencies, sign-off, agent, and iteration budget
come only from the snapshot.

### Runs

Runs groups durable attempts by task. RED, retry, resumed, and settled records
remain separate. Null attempts and missing checkpoints are shown as unavailable,
not inferred.

### Proof

Proof shows hash-bound artifacts and settlement receipts. Receipt integrity and
freshness are separate fields. Artifact content is fetched by relative path,
snapshot ID, and SHA-256 through a GET-only endpoint. The viewer rejects any
response that does not match the requested proof tuple.

### Health

Health presents required and optional checks plus typed issues. A healthy
component does not erase a blocking issue in another domain.

## Selection and truth

Selection is always `{kind, id}`. The inspector resolves typed pass, task, run,
receipt, health, signal, issue, and artifact entities. History includes only
signals with an explicit matching entity reference. Labels and prose are never
parsed to invent lineage or association.

Transport state remains outside the semantic snapshot:

- `loading` means the previous projection remains visible during refresh.
- `stale` means a last-good snapshot is visible after a refresh failure.
- `fixture` is labeled as replay data and never claimed as a live workspace.
- malformed v2 snapshots are rejected at the client boundary.

## Motion and accessibility

- The shell uses one restrained arrival transition.
- Proven edges may carry a quiet traveling highlight. Waiting edges remain
  still.
- The viewport auto-fits only on first load or explicit user request.
- Reduced-motion preference removes traveling highlights and nonessential
  transitions.
- Keyboard focus uses a visible Forge Gold outline.
- Status never depends on color alone.
- Artifact dialogs trap focus, close on Escape, and restore focus to the
  launcher.
- Small screens receive textual alternatives for graph exploration.
