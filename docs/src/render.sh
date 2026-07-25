#!/usr/bin/env bash
# Render a Converge HTML document to PDF via headless Chrome (Skia/PDF).
# Mermaid diagrams render client-side, so Chrome gets a virtual-time budget
# large enough for the CDN fetch + layout before printing.
#
#   usage: bash docs/src/render.sh <name-without-extension>
#   e.g.   bash docs/src/render.sh converge-method-v6
#
# Chrome is backgrounded and reaped explicitly: on macOS it otherwise spawns
# GoogleUpdater/GCM children and never returns, even after the PDF is written.
set -uo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$(cd "$SRC_DIR/.." && pwd)"
NAME="${1:?usage: render.sh <name-without-extension>}"
HTML="$SRC_DIR/$NAME.html"
PDF="$OUT_DIR/$NAME.pdf"

[ -f "$HTML" ] || { echo "no such file: $HTML" >&2; exit 2; }

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || { echo "Chrome not found at: $CHROME" >&2; exit 3; }

PROFILE="$(mktemp -d)"
rm -f "$PDF"

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --no-first-run \
  --no-default-browser-check \
  --no-pdf-header-footer \
  --disable-background-networking \
  --disable-component-update \
  --disable-client-side-phishing-detection \
  --disable-sync \
  --metrics-recording-only \
  --user-data-dir="$PROFILE" \
  --virtual-time-budget=40000 \
  --run-all-compositor-stages-before-draw \
  --print-to-pdf="$PDF" \
  "file://$HTML" >/dev/null 2>&1 &
CHROME_PID=$!

# Wait for the PDF to appear and stop growing, then reap Chrome.
stable=0; last=0
for _ in $(seq 1 120); do
  sleep 1
  [ -s "$PDF" ] || continue
  cur=$(wc -c < "$PDF" | tr -d ' ')
  if [ "$cur" = "$last" ] && [ "$cur" -gt 0 ]; then
    stable=$((stable + 1))
    [ "$stable" -ge 3 ] && break
  else
    stable=0
  fi
  last="$cur"
done

kill "$CHROME_PID" 2>/dev/null
wait "$CHROME_PID" 2>/dev/null
pkill -f "user-data-dir=$PROFILE" 2>/dev/null
rm -rf "$PROFILE"

[ -s "$PDF" ] || { echo "render produced no output" >&2; exit 4; }

python3 - "$PDF" <<'PY'
import sys, re
p = sys.argv[1]
d = open(p, 'rb').read()
pages = len(re.findall(rb'/Type\s*/Page[^s]', d))
print(f"  -> {p}")
print(f"     {pages} pages | {len(d)/1024:.0f} KB")
PY
