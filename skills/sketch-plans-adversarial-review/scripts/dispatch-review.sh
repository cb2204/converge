#!/usr/bin/env bash
# dispatch-review.sh — Converge Pass 4: frame → dispatch a headless adversary →
# stamp the objection log. The referee is never a player: it shells out to the
# engine's OWN CLI (which authenticates itself), read-only, wrapped in a timeout.
# PROVENANCE (adversary family + input hashes) is computed HERE, not self-reported
# by the engine — so it cannot be spoofed. Fail-closed: any failure => ERROR,
# never a pass.
#
# Usage:
#   dispatch-review.sh --adversary codex|kimi|claude [--dir sketch] [--out F]
#   dispatch-review.sh --help
# Engine command is env-overridable for testing: CVG_CODEX_CMD / CVG_KIMI_CMD /
#   CVG_CLAUDE_CMD (default: the bare binary). CVG_TIMEOUT_SECS (default 300).
#
# Token (last line): REVIEW=OK | ERROR | SKIP | TIMEOUT | USAGE_ERROR
# Exit: 0 ok · 20 engine unavailable(SKIP) · 21 timeout · 22 malformed(ERROR) · 2 usage
# bash 3.2-safe; Python stdlib-only (json/hashlib) for assembly. No jq.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PLAYBOOK="$HERE/../references/attack-playbook.md"
SKETCH_DIR="sketch"
ADVERSARY="codex"
AUTHOR_FAMILY="anthropic"
OUT=""
TIMEOUT="${CVG_TIMEOUT_SECS:-300}"

usage() { sed -n '2,20p' "$0"; }
uerr() { echo "ERROR: $*" >&2; echo "REVIEW=USAGE_ERROR"; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)       usage; exit 0 ;;
    --adversary)     ADVERSARY="${2:?}"; shift 2 ;;
    --dir)           SKETCH_DIR="${2:?}"; shift 2 ;;
    --out)           OUT="${2:?}"; shift 2 ;;
    --author-family) AUTHOR_FAMILY="${2:?}"; shift 2 ;;
    --timeout)       TIMEOUT="${2:?}"; shift 2 ;;
    -*)              uerr "unknown option: $1" ;;
    *)               SKETCH_DIR="$1"; shift ;;
  esac
done
[ -n "$OUT" ] || OUT="$SKETCH_DIR/.consensus/objection-log.json"

case "$ADVERSARY" in
  codex)  FAMILY=openai;    CMD="${CVG_CODEX_CMD:-codex}";   KIND=codex ;;
  kimi)   FAMILY=moonshot;  CMD="${CVG_KIMI_CMD:-kimi}";     KIND=kimi ;;
  claude) FAMILY=anthropic; CMD="${CVG_CLAUDE_CMD:-claude}"; KIND=claude ;;
  *) uerr "unknown adversary '$ADVERSARY' (codex|kimi|claude)" ;;
esac

[ -d "$SKETCH_DIR" ] || uerr "no swimlane tree at $SKETCH_DIR/"
if [ "$FAMILY" = "$AUTHOR_FAMILY" ]; then
  echo "WARN: adversary '$ADVERSARY' is the SAME family as the author ($AUTHOR_FAMILY) — weak (self-preference). Prefer codex or kimi." >&2
fi
if ! command -v "$CMD" >/dev/null 2>&1; then
  echo "SKIP: adversary engine '$ADVERSARY' ($CMD) is not installed — try another --adversary or run cvg doctor." >&2
  echo "REVIEW=SKIP"; exit 20
fi

# ── FRAME: the critic prompt = the playbook + every plan file ─────────────────
PROMPT="$(mktemp)"; JUDG="$(mktemp)"
trap 'rm -f "$PROMPT" "$JUDG"' EXIT
{
  cat "$PLAYBOOK" 2>/dev/null || true
  echo; echo "=== PLANS TO ATTACK (sketch/swimlane-*/) ==="
  for f in "$SKETCH_DIR"/swimlane-*/*.md; do
    [ -e "$f" ] || continue
    echo; echo "----- $f -----"; cat "$f"
  done
} > "$PROMPT"

# ── DISPATCH: headless, read-only, wrapped in a wall-clock cap ────────────────
# timeout(1) is GNU coreutils; macOS ships neither by default → try timeout, then
# gtimeout, else run uncapped with a warning (mandatory-timeout is best-effort here).
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_BIN="gtimeout"
else echo "WARN: no timeout binary (brew install coreutils for gtimeout) — running uncapped." >&2; fi
to() { if [ -n "$TIMEOUT_BIN" ]; then "$TIMEOUT_BIN" "$TIMEOUT" "$@"; else "$@"; fi; }

echo "cvg review · dispatch → $ADVERSARY ($FAMILY) · read-only · cap ${TIMEOUT}s${TIMEOUT_BIN:+ ($TIMEOUT_BIN)}" >&2
RC=0
case "$KIND" in
  codex)  to "$CMD" exec --sandbox read-only - < "$PROMPT" > "$JUDG" 2>/dev/null || RC=$? ;;
  kimi)   to "$CMD" --print --output-format stream-json -p "$(cat "$PROMPT")" > "$JUDG" 2>/dev/null || RC=$? ;;
  claude) to "$CMD" -p "$(cat "$PROMPT")" --output-format json --tools Read,Grep --disallowedTools "Edit,Write" > "$JUDG" 2>/dev/null || RC=$? ;;
esac
if [ "$RC" -eq 124 ]; then echo "TIMEOUT after ${TIMEOUT}s." >&2; echo "REVIEW=TIMEOUT"; exit 21; fi

# ── ASSEMBLE + STAMP: provenance computed by the referee, not the engine ──────
ENGINE_VERSION="$("$CMD" --version 2>/dev/null | head -1 | tr -d '\n' | cut -c1-40 || true)"
export CVG_PROMPT="$PROMPT"
set +e
python3 - "$JUDG" "$SKETCH_DIR" "$OUT" "$ADVERSARY" "$FAMILY" "$ENGINE_VERSION" "$KIND" <<'PY'
import json, sys, hashlib, glob, os, re
judg_p, sketch, out, engine, family, ver, kind = sys.argv[1:8]
raw = open(judg_p, encoding="utf-8", errors="replace").read()
# extract the engine's JUDGMENT json (objections/verdict/fork) — the first {...} that parses
judg = None
for m in re.finditer(r'\{.*\}', raw, re.S):
    try:
        c = json.loads(m.group(0))
        if isinstance(c, dict) and ("objections" in c or "verdict" in c):
            judg = c; break
    except Exception:
        continue
if judg is None:
    sys.stderr.write("ERROR: adversary produced no parseable judgment JSON (fail-closed)\n"); sys.exit(22)
# provenance the REFEREE computes (not self-reported)
inputs = []
for f in sorted(glob.glob(os.path.join(sketch, "swimlane-*", "*.md"))):
    if os.path.basename(os.path.dirname(f)).startswith("."): continue
    rel = os.path.relpath(f, sketch)
    inputs.append({"path": rel, "sha256": hashlib.sha256(open(f, "rb").read()).hexdigest()})
prompt_sha = hashlib.sha256(open(os.environ.get("CVG_PROMPT", "/dev/null"), "rb").read()).hexdigest() if os.environ.get("CVG_PROMPT") else ""
log = {
    "schema_version": "1.0", "pass": "4-consensus",
    "adversary": {"engine_id": engine, "model": judg.get("model", engine), "family": family,
                  "engine_version": ver or "unknown", "sandbox_mode": "read-only"},
    "author": {"model": "claude", "family": "anthropic"},
    "verdict": judg.get("verdict", "REVISE"),
    "prompt_sha256": prompt_sha,
    "inputs": inputs,
    "objections": judg.get("objections", []),
    "cross_lane_interfaces": judg.get("cross_lane_interfaces", []),
    "fork": judg.get("fork", {}),
    "open_questions": judg.get("open_questions", []),
    "rounds_run": judg.get("rounds_run", 1),
}
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
json.dump(log, open(out, "w"), indent=2)
print("stamped %d objection(s), %d input(s) → %s" % (len(log["objections"]), len(inputs), out))
PY
PRC=$?
set -e

if [ "$PRC" -ne 0 ]; then echo "REVIEW=ERROR"; exit 22; fi
echo "REVIEW=OK"
exit 0
