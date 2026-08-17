# Converge Brand Kit v1

Approved identity: **Settlement Fold**

Settlement Fold turns the Converge promise into one compact symbol: a governed boundary
folds back through itself and closes as proof. The dark body represents the controlled
execution loop; the Forge Gold fold marks the moment where an attempted result becomes a
settled one.

This package is built from controlled SVG geometry. The approved AI-assisted concept sheet
was used as visual direction only; it is not a production logo file.

## Quick selection

- Light background: use `converge-icon-color-dark` or `converge-lockup-color-dark`.
- Dark background: use `converge-icon-color-light` or `converge-lockup-color-light`.
- One-color production: use the black, white, gold, or graphite assets in `02-monochrome/`.
- Browser/PWA: use the prepared files in `04-digital/favicon/` and `04-digital/app-icons/`.
- Social sharing: use the ready-sized artwork in `04-digital/social/`.
- Responsive web: use the SVG masters or the PNG/WebP files in `05-web/`.

## Package structure

- `00-source/` — reproducible SVG geometry and the asset build script.
- `01-primary/color/` — transparent full-color icon and horizontal lockups.
- `02-monochrome/` — one-color black, white, gold, and graphite assets.
- `03-backgrounds/` — approved icon and lockup applications on five surfaces.
- `04-digital/` — favicons, app/PWA icons, avatars, Open Graph, GitHub, and social covers.
- `05-web/` — responsive PNG, lossless WebP, CSS variables, and web manifest.
- `06-guidelines/` — overview board and logo-usage guidance.
- `brand-tokens.json` — machine-readable identity tokens.
- `MANIFEST.sha256` — hashes for every packaged asset.

## Canonical colors

- Factory Black: `#070A0F`
- Carbon: `#111720`
- Graphite: `#29313A`
- Proof Ivory: `#F5F2EA`
- Forge Gold: `#F3B64C`
- Settlement Mint: `#73E2C3`
- Verdict Coral: `#FF6B64`
- Steel: `#8D99A6`

Forge Gold is the master-brand accent. Mint and Coral are semantic state colors, not
decorative alternatives.

## Rebuild

Requires Node.js and ImageMagick:

```bash
node 00-source/build-brand-kit.mjs
```

The script regenerates the SVG masters, raster exports, digital formats, overview artwork,
and SHA-256 manifest.
