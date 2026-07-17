#!/bin/bash
# launcher.sh — miniature of `cvg work`: the CLI OUTSIDE the loop (Seat B).
# It (1) spawns an entire agentic loop as ONE subprocess, then
#      (2) verifies the result ITSELF — never trusting the loop's self-report.
#
# Run from the converge repo root:
#   bash docs/demos/launcher.sh

echo "[cvg-work mini] step 1: spawning the whole agentic loop as a subprocess..."
python3 docs/demos/agentic-loop.py > /tmp/loop_output.txt 2>&1
echo "[cvg-work mini] loop finished. Its SELF-REPORT was:"
echo "    $(tail -1 /tmp/loop_output.txt)"
echo
echo "[cvg-work mini] step 2: REFEREE runs independently (ignore the self-report):"
if bash tests/e2e-test-engine/evals/smoke.sh; then
  echo "[cvg-work mini] verdict: VERIFIED -> task would move to done"
else
  echo "[cvg-work mini] verdict: RED -> feed failure back, retry (bounded by budget)"
fi
