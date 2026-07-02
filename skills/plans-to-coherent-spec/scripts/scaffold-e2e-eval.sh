#!/usr/bin/env bash
# scaffold-e2e-eval.sh — Converge Pass 5A (Specify, Fork A): stamp the ONE
# end-to-end eval that governs the whole coherent spec.
#
# Fork A's unit of trust is the WHOLE system, not a task. So this pass produces
# exactly ONE eval, at specs/e2e-eval.sh, that drives the real flow end to end:
#     make seed  →  make land  →  dbt build  →  query gold.*  →  hit serving
# and asserts the FAR END: a known seed yields the expected gold shape AND the
# expected API/MCP answer. This script writes a runnable, repo-grounded skeleton
# of that eval (real Make targets, the real warehouse path, the real read-only
# connection contract); the author then fills in the concrete assertions once the
# frozen E4 gold contract is pinned.
#
# The skeleton is deliberately RED until the medallion (dbt) and serving
# (src/serving) layers exist — that is correct for Fork A: the eval is the single
# artifact Execution (Pass 8 · The Loop) drives to GREEN. Each stage prints a
# precise, actionable reason when it is not yet built, so a RED run names the gap.
#
# Usage:
#   scaffold-e2e-eval.sh                       Write specs/e2e-eval.sh
#   scaffold-e2e-eval.sh --specs-dir specs/    Override the specs directory
#   scaffold-e2e-eval.sh --force               Overwrite an existing eval
#   scaffold-e2e-eval.sh --help
#
# Produces: <specs-dir>/e2e-eval.sh  (chmod +x, runnable, bash -n clean)
# Exit:     0 = written; 1 = usage error / refused to clobber
#
# bash 3.2-safe (runs on macOS system /bin/bash). No associative arrays, no
# mapfile. Mirrors the style of .claude/skills/task-spec/scripts/_lib.sh.

set -euo pipefail

SPECS_DIR="specs"
FORCE=false

usage() { sed -n '2,25p' "$0"; }

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# ── Parse args ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)    usage; exit 0 ;;
    --specs-dir)  SPECS_DIR="${2:?--specs-dir needs a path}"; shift 2 ;;
    --force)      FORCE=true; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)  echo "Unexpected argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Strip a trailing slash so the path composes cleanly.
SPECS_DIR="${SPECS_DIR%/}"
[ -n "$SPECS_DIR" ] || die "--specs-dir resolved to empty."

OUT="$SPECS_DIR/e2e-eval.sh"

mkdir -p "$SPECS_DIR"
if [ -e "$OUT" ] && [ "$FORCE" != true ]; then
  die "$OUT already exists. Re-run with --force to overwrite (you will lose filled-in assertions)."
fi

# ── Emit the eval skeleton ────────────────────────────────────────────────────
# Heredoc is quoted ('EOF') so nothing here is expanded now — the generated
# script keeps its own $VARS, $(...) and "$@" verbatim.
cat > "$OUT" <<'EOF'
#!/usr/bin/env bash
# e2e-eval.sh — THE single end-to-end eval for the coherent spec (Converge 5A).
#
# The unit of trust is the WHOLE system: sources -> gold -> serving answers.
# This eval drives the REAL flow and asserts the FAR END. Done = this is GREEN.
#
#   make seed   -> generate a known, deterministic dataset in Postgres
#   make land   -> Postgres -> raw.* in the DuckDB warehouse (read-only ATTACH)
#   dbt build   -> raw.* -> bronze.* -> silver.* -> gold.*  (+ dbt tests)
#   query gold  -> the expected gold shape for the known seed
#   serving     -> the FastAPI endpoint + MCP tool return the expected answer
#
# One eval, end to end, unambiguous pass/fail. It is RED until the medallion and
# serving layers are built — that is by design: Execution (Pass 8) drives it to
# GREEN. Each stage below prints a precise reason when its layer is not yet built.
#
# Run from the repo root:  bash specs/e2e-eval.sh
# bash 3.2-safe. No associative arrays, no mapfile.

set -uo pipefail   # NB: not -e — we want to run every stage and report all gaps.

# ── Repo grounding (single sources of truth) ─────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Canonical warehouse path (env override wins; matches src/warehouse/paths.py).
WAREHOUSE="${DUCKDB_DATABASE:-src/warehouse/warehouse.duckdb}"
# The .venv python the repo standardizes on (uv-managed).
PYBIN="${PYBIN:-.venv/bin/python}"
[ -x "$PYBIN" ] || PYBIN="python3"

# Deterministic seed knobs — a KNOWN input is what makes the far-end assertion
# meaningful. Keep these fixed so the expected gold shape is reproducible.
SEED="${SEED:-42}"
CUSTOMERS="${CUSTOMERS:-500}"
PRODUCTS="${PRODUCTS:-200}"
ORDERS="${ORDERS:-5000}"

FAILS=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1" >&2; FAILS=$((FAILS + 1)); }
note() { printf '  ....  %s\n' "$1"; }
stage() { printf '\n== %s ==\n' "$1"; }

# Run a read-only SQL scalar against the warehouse; echoes the value or "" on
# error. Uses the repo's own connect_read_only() contract via a tiny python
# shim so the eval honors the SAME read-only invariant the serving layer must.
gold_scalar() {
  # $1 = SQL returning exactly one scalar column, one row.
  "$PYBIN" - "$1" <<'PY' 2>/dev/null
import sys
from src.warehouse.connection import connect_read_only
sql = sys.argv[1]
con = connect_read_only()
try:
    row = con.execute(sql).fetchone()
    print("" if row is None or row[0] is None else row[0])
finally:
    con.close()
PY
}

# Does a schema.table exist in the warehouse?  echoes "1" / "0".
gold_has_table() {
  # $1 = schema, $2 = table
  gold_scalar "SELECT count(*) FROM information_schema.tables \
               WHERE table_schema='$1' AND table_name='$2'"
}

# ── Stage 1 — SEED (known, deterministic source) ─────────────────────────────
stage "seed — deterministic Postgres source"
if make seed CUSTOMERS="$CUSTOMERS" PRODUCTS="$PRODUCTS" ORDERS="$ORDERS" SEED="$SEED" >/dev/null 2>&1; then
  pass "make seed (seed=$SEED, orders=$ORDERS)"
else
  fail "make seed failed — is Postgres up? (make up) — cannot establish a known input"
fi

# ── Stage 2 — LAND (Postgres -> raw.* ; the single crossing) ─────────────────
stage "land — Postgres -> raw.* in DuckDB (read-only ATTACH bridge)"
if make land >/dev/null 2>&1; then
  pass "make land"
  RAW_ORDERS="$(gold_scalar "SELECT count(*) FROM raw.raw_orders")"
  if [ -n "$RAW_ORDERS" ] && [ "$RAW_ORDERS" -gt 0 ] 2>/dev/null; then
    pass "raw.raw_orders landed ($RAW_ORDERS rows)"
  else
    fail "raw.raw_orders is empty after land — the source floor is missing"
  fi
else
  fail "make land failed — Postgres -> raw.* bridge did not run"
fi

# ── Stage 3 — dbt build (raw -> bronze -> silver -> gold + tests) ────────────
# The medallion is Component A. It is not scaffolded until Execution builds it;
# until a dbt project exists, this stage reports the gap precisely (RED), which
# is the correct Fork-A signal, not a false green.
stage "dbt build — medallion raw.* -> gold.* (+ dbt tests)"
DBT_PROJECT="$(ls dbt_project.yml */dbt_project.yml 2>/dev/null | head -1 || true)"
if [ -z "$DBT_PROJECT" ]; then
  fail "no dbt_project.yml found — the medallion (Component A) is not built yet. \
Execution must scaffold dbt and the bronze/silver/gold models; then this stage runs 'dbt build'."
elif command -v dbt >/dev/null 2>&1; then
  DBT_DIR="$(dirname "$DBT_PROJECT")"
  if ( cd "$DBT_DIR" && dbt build >/dev/null 2>&1 ); then
    pass "dbt build (models + tests green)"
  else
    fail "dbt build failed — a model or dbt test is RED (run 'dbt build' in $DBT_DIR to see which)"
  fi
else
  fail "dbt not on PATH — install dbt-duckdb (uv add dbt-duckdb) to run the medallion build"
fi

# ── Stage 4 — GOLD shape (the internal contract, owned by Component A) ────────
# Assert the gold-table interface the serving half binds to. Fill in the exact
# columns/counts once the frozen E4 gold schema.yml is committed by Component A.
stage "gold — the internal contract (gold.* shape for the known seed)"
for tbl in gold_revenue_by_category gold_customer_segments gold_order_health \
           gold_payment_reconciliation gold_freshness; do
  if [ "$(gold_has_table gold "$tbl")" = "1" ]; then
    pass "gold.$tbl exists"
    # TODO(author): assert the FAR-END shape for the known seed, e.g.:
    #   REV="$(gold_scalar "SELECT round(sum(revenue),2) FROM gold.gold_revenue_by_category")"
    #   [ "$REV" = "<expected-for-seed-42>" ] && pass "revenue total" || fail "revenue total ($REV)"
  else
    fail "gold.$tbl missing — Component A has not emitted this mart (frozen E4 contract)"
  fi
done
# Atomic-publish invariant (Codex C5): every gold mart shares ONE _gold_run_id.
# TODO(author): once gold exists, assert a single generation is visible:
#   RUNIDS="$(gold_scalar "SELECT count(DISTINCT _gold_run_id) FROM ( \
#     SELECT _gold_run_id FROM gold.gold_revenue_by_category UNION ALL \
#     SELECT _gold_run_id FROM gold.gold_order_health )")"
#   [ "$RUNIDS" = "1" ] && pass "single _gold_run_id" || fail "half-published gold ($RUNIDS ids)"

# ── Stage 5 — SERVING (the far end: endpoint + MCP tool answer) ──────────────
# Component B is read-only over gold.*. Assert that the SAME frozen question is
# answered identically by the FastAPI endpoint and the MCP tool (same B1 core =>
# same answer), and that the answer matches the gold shape asserted above.
stage "serving — FastAPI endpoint + MCP tool answer the frozen question"
if [ -d src/serving ]; then
  pass "src/serving present"
  # TODO(author): start the API (or import the query core) and assert the answer.
  # Endpoint parity example (fill the expected value for the known seed):
  #   ANS="$("$PYBIN" -m src.serving.query core revenue_by_category 2>/dev/null || true)"
  #   [ -n "$ANS" ] && pass "revenue_by_category answered" || fail "no serving answer"
  # MCP/endpoint parity: the MCP tool MUST return the same value as its endpoint.
  note "fill the endpoint+MCP answer assertions (must equal the gold shape above)"
  fail "serving answer assertions not yet filled — spec is not converged until they are"
else
  fail "src/serving missing — the serving layer (Component B) is not built yet. \
Execution must add the read-only query core + endpoints + MCP tools over gold.*."
fi

# ── Verdict ──────────────────────────────────────────────────────────────────
stage "verdict"
if [ "$FAILS" -eq 0 ]; then
  echo "GREEN — the whole system is converged: seed -> land -> gold -> serving all pass."
  exit 0
else
  echo "RED — $FAILS check(s) failed. The coherent spec is not yet done." >&2
  echo "Feed the first failing stage back into the loop and revise; done = this eval is GREEN." >&2
  exit 1
fi
EOF

chmod +x "$OUT"

echo "Created $OUT (executable)."
echo "Next: freeze the E4 gold contract, then fill the FAR-END assertions marked TODO(author)."
echo "Syntax check: bash -n $OUT"
