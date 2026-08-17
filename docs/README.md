# Documentation map

The current truth hierarchy is intentionally small:

1. [`README.md`](../README.md): installation and first successful journey.
2. [`architecture.md`](architecture.md): authority and cross-repository data flow.
3. [`composed-flow.md`](composed-flow.md): prepare through settlement.
4. [`cli-reference.md`](cli-reference.md): generated from the canonical command matrix.
5. [`releases/v0.2.0.md`](releases/v0.2.0.md): migration and release scope.
6. [`release-readiness.md`](release-readiness.md): evidence ledger and publication policy.

## Historical evidence

The following are retained as historical v0.1 evidence. They are not the
current composed behavior and must not be used as 0.2 implementation proof.

Large binaries are published as assets on the immutable
[`v0.1.0` release](https://github.com/luanmorenommaciel/converge/releases/tag/v0.1.0)
rather than carried in the working tree, so a clone does not pay for them:

- [`converge-v0.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-v0.1.pdf)
- [`task-spec-v0.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/task-spec-v0.1.pdf)
- [`converge.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge.pdf)
- [`converge-deck.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-deck.pdf)
- [`converge-brand-concepts-round-01.zip`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-brand-concepts-round-01.zip)

These stay in the tree because they are small and browsable:

- `converge-deck.html`
- decks under `decks/`

The current generated release guide is `converge-v0.2.0.pdf`. Its
canonical sources are the root README, `architecture.md`, and
`composed-flow.md`.

[`converge-v0.2.0-alpha.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-v0.2.0-alpha.1.pdf)
is retained only as superseded candidate evidence and is not the current
operating guide.

`authority-model.md` remains only as a compatibility pointer to
`architecture.md`.
