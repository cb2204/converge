# Converge Control Room visual system

The interface is a product canvas, not a dashboard made from generic cards.
Lineage is the primary surface. Chrome stays quiet so state changes carry the
visual weight.

## Direction

- Artistic asymmetry with a wide lineage field and a pinned evidence chamber.
- Outfit Variable for product typography; system monospace for tokens and paths.
- Settlement Fold vector lockup and icon on dark surfaces; the wordmark is never
  reconstructed with a font.
- Factory Black and Carbon surfaces with Forge Gold as the single brand accent.
- Mint communicates canonical proof, coral communicates failure or unresolved
  risk, and Steel communicates optional, future, or unavailable state.
- Every semantic color is paired with a written status and an icon.

## Motion

- The shell arrives through opacity and a very small scale change.
- Selecting a node expands its internal hierarchy without moving unrelated
  nodes.
- Proven edges carry a restrained traveling highlight. Waiting edges remain
  still.
- The viewport only auto-fits on first load or when the user requests it.
- Nodes can be rearranged locally for exploration; the Arrange control restores
  the deliberate top-line, return-lane, and optional-branch composition.
- Reduced motion removes traveling highlights, scale changes, and ambient drift.

## Shape and depth

- Outer shell: 30 px radius.
- Nodes and panels: 18 px radius.
- Controls: 12 px radius or fully round when icon-only.
- Shadows are tinted toward the green-black background.
- Glass is an edge treatment, not a substitute for hierarchy.
- At desktop widths the shell, canvas, inspector, evidence stream, and footer
  share one viewport budget. Tablet and mobile layouts return to document flow.

## Observation interactions

- Clicking or keyboard-selecting a pass updates only the evidence inspector.
- Dragging a node changes only the local visual arrangement; it never changes
  the method graph or repository state.
- Evidence-stream items link to passes through explicit snapshot `passId`
  values. Labels are never parsed to infer lineage.
- Artifact previews stay bound to snapshot ID and SHA-256 evidence.

## Accessibility

- Body copy targets a 4.5:1 contrast ratio.
- Interactive targets are at least 44 px.
- Keyboard users can traverse pass nodes and inspector controls.
- Focus rings use gold plus an outer dark offset.
- The canvas has a parallel textual pass navigator for small screens and
  assistive technology.
