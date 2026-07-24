# Converge blueprint sources

The committed HTML files in this directory are the reproducible sources for
versioned Converge blueprint PDFs under `docs/`.

## Render v5

From the repository root:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="docs/cvg-aut-systems-spine-steps-v5.pdf" \
  "file://$PWD/docs/source/cvg-aut-systems-spine-steps-v5.html"
```

The source is self-contained: inline CSS, no webfonts, no remote scripts, and
fixed A4 pages (`@page { size: A4; margin: 0; }`).

## Verification

Render every page for visual inspection:

```bash
mkdir -p tmp/pdfs/v5
pdftoppm -png -r 90 \
  docs/cvg-aut-systems-spine-steps-v5.pdf \
  tmp/pdfs/v5/page
```

Also verify:

- `pdfinfo` reports the expected title and page count;
- extracted text contains the v5, `cvg 0.13.0`, and Task-Spec `3.5.0` markers;
- the PDF has exactly one physical page per HTML `.page` section;
- no text is clipped, overlapping, or spilling below the footer;
- the source contains no external asset URLs.
