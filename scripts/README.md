# Scripts

Build, release, and validation tooling. Nothing here ships to consumers; the npm
package allowlist in `package.json` excludes this directory deliberately.

| Script | Purpose |
|---|---|
| `check-docs.py` | the documentation gate — links, anchors, fences, release truth, archive inventory, tracked debris |
| `render-cli-reference.py` | regenerates `docs/cli-reference.md` from the canonical command matrix; `--check` fails on drift |
| `render-mermaid.py` | renders diagrams for the generated guide |
| `build-release-guide.py` | builds `docs/converge-v0.2.0.pdf` from README, architecture, and composed-flow |
| `release-assets.py` | assembles checksummed release assets |
| `validate-live-evidence.py` | asserts retained executor traces under `evidence/` still agree with their receipts |
| `demo-composed.sh` | deterministic composed settlement demo |
| `demo-composed-live-codex.sh` | the same path against a live Codex engine |

Run them through the Makefile rather than directly — it resolves the pinned
engine binaries these scripts assume.
