# Documentation map

The current truth hierarchy is intentionally small:

1. [`README.md`](../README.md): installation and first successful journey.
2. [`architecture.md`](architecture.md): authority and cross-repository data flow.
3. [`composed-flow.md`](composed-flow.md): prepare through settlement.
4. [`cli-reference.md`](cli-reference.md): generated from the canonical command matrix.
5. [0.2.0 release notes](https://github.com/luanmorenommaciel/converge/releases/tag/v0.2.0): migration and release scope, published with the tag.
6. [`release-readiness.md`](release-readiness.md): evidence ledger and publication policy.
7. [`backlog.md`](backlog.md): reviewer-derived backlog. Not a substitute for `cvg register`.

## Historical evidence

The following are retained as historical v0.1 evidence. They are not the
current composed behavior and must not be used as 0.2 implementation proof.

Large binaries are published as assets on the
[`v0.1.0` GitHub release](https://github.com/luanmorenommaciel/converge/releases/tag/v0.1.0)
rather than carried in the working tree. That release is **not** marked
immutable on GitHub (`isImmutable: false`); anyone with write access can
replace an asset. A full clone still carries the blobs in `.git`. A shallow
clone of current `main` does not pay the working-tree cost.

- [`converge-v0.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-v0.1.pdf)
- [`task-spec-v0.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/task-spec-v0.1.pdf)
- [`converge.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge.pdf)
- [`converge-deck.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-deck.pdf)
- [`converge-brand-concepts-round-01.zip`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-brand-concepts-round-01.zip)
- [`converge-v0.2.0-alpha.1.pdf`](https://github.com/luanmorenommaciel/converge/releases/download/v0.1.0/converge-v0.2.0-alpha.1.pdf)
  (superseded candidate evidence; not the current operating guide)

These stay in the tree because they are small and browsable:

- decks under `decks/`, including `converge-deck.html`

The current generated release guide is `converge-v0.2.0.pdf`. Its
canonical sources are the root README, `architecture.md`, and
`composed-flow.md`.

The v1 brand kit is not on the `v0.1.0` release. Recover it from git
history (`git checkout db8c368~1 -- assets/brand-kit`) if needed.
The `converge-brand-concepts-round-01.zip` asset is the concept-round
images, not the kit.
