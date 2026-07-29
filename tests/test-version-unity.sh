#!/usr/bin/env bash
# test-version-unity.sh — Converge ships as ONE unit, at ONE version.
#
# WHY THIS EXISTS
# Before 2026-07-29 the package carried NINE independent version lineages: the
# twelve skills declared seven different `metadata.version` values (0.3.0 .. 1.1.0)
# or none at all, `bin/cvg` said 0.21.0, `task-spec` said 3.6.0, and two gate
# scripts kept private numbers behind their own `--version` flags. Nothing
# reconciled them, so "which version of Converge is this?" had no answer — and a
# skill could be edited without anything downstream noticing.
#
# The fix is not a naming convention, it is a gate. The root VERSION file is the
# single source of truth; every declaration in the package must equal it. Bumping
# a release is then one edit plus `--sync`, and a drifted file fails CI instead of
# shipping.
#
# WHAT COUNTS AS A VERSION HERE
# RELEASE versions unify — they answer "which Converge is this?". SCHEMA/FORMAT
# versions deliberately do NOT: `format_version: 3`, `VALIDATOR_VERSION="2"`,
# `agent_contract.version: 2` and `hmac-sha256-v2` describe a DATA CONTRACT whose
# whole purpose is to change independently of the release. Conflating the two
# would force a data migration on every release, which is the opposite of what a
# schema version is for. This gate checks release versions only, and the SCHEMA
# allowlist below is the recorded distinction.
#
# Usage:
#   bash tests/test-version-unity.sh            # gate (exit 0 pass / 1 fail)
#   bash tests/test-version-unity.sh --sync     # rewrite every site to VERSION
#
# Last line is always exactly one machine token:
#   VERSION_UNITY=PASS | VERSION_UNITY=FAIL | VERSION_UNITY=SYNCED
#
# bash 3.2 safe (stock macOS). Deps: grep, sed, awk.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/.." && pwd)"
cd "$REPO" || { echo "cannot enter repo"; echo "VERSION_UNITY=FAIL"; exit 1; }

SYNC=false
[ "${1:-}" = "--sync" ] && SYNC=true

PASS=0; FAIL=0
ok()  { echo "  ok   — $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL — $1"; FAIL=$((FAIL+1)); }

echo "=================================================================="
echo "test-version-unity.sh — one package, one version"
echo "=================================================================="

# ----- the source of truth -----
if [ ! -f VERSION ]; then
  echo "  FAIL — no VERSION file at the repo root; there is no source of truth"
  echo "VERSION_UNITY=FAIL"; exit 1
fi
PKG="$(tr -d ' \t\n\r' < VERSION)"
case "$PKG" in
  [0-9]*.[0-9]*.[0-9]*) ok "VERSION declares a semver: $PKG" ;;
  *) bad "VERSION is not a semver: '$PKG'"; echo "VERSION_UNITY=FAIL"; exit 1 ;;
esac

# ----- the release-version declaration sites -----
# Each entry: <file>|<sed-anchor>|<human label>. Anchors are exact variable
# assignments so a comment mentioning a version is never mistaken for one.
SITES="
bin/cvg|CVG_VERSION|the CLI
skills/task-spec/scripts/_lib.sh|TASKSPEC_VERSION|the task-spec engine
skills/idea-to-brd/scripts/check-brd.sh|CHECK_BRD_VERSION|the Pass 0 gate
skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh|CHECK_TECH_SPEC_VERSION|the Pass 1 gate
"

echo
echo "[1] every code declaration equals VERSION"
printf '%s\n' "$SITES" | while IFS='|' read -r file var label; do
  [ -n "${file:-}" ] || continue
  if [ ! -f "$file" ]; then bad "$label: $file is missing"; continue; fi
  got="$(grep -m1 -E "^${var}=" "$file" 2>/dev/null | sed -E 's/^[A-Z_]+="?([^"]*)"?.*/\1/')"
  if [ -z "$got" ]; then
    bad "$label: no ${var}= declaration in $file"
  elif [ "$got" = "$PKG" ]; then
    ok "$label ($var) = $PKG"
  elif [ "$SYNC" = true ]; then
    sed -i.bak -E "s/^${var}=.*/${var}=\"${PKG}\"/" "$file" && rm -f "$file.bak"
    echo "  sync — $label ($var): $got -> $PKG"
  else
    bad "$label ($var) = $got, VERSION says $PKG — run with --sync"
  fi
done

# The subshell above cannot export counters back on bash 3.2 (no lastpipe), so
# re-derive the verdict from the files themselves rather than trusting a variable
# that the pipeline discarded. A gate that mis-reports its own result is worse
# than no gate.
CODE_DRIFT=0
for pair in \
  "bin/cvg:CVG_VERSION" \
  "skills/task-spec/scripts/_lib.sh:TASKSPEC_VERSION" \
  "skills/idea-to-brd/scripts/check-brd.sh:CHECK_BRD_VERSION" \
  "skills/brd-docs-to-tech-req/scripts/check-tech-spec.sh:CHECK_TECH_SPEC_VERSION"
do
  f="${pair%%:*}"; v="${pair##*:}"
  got="$(grep -m1 -E "^${v}=" "$f" 2>/dev/null | sed -E 's/^[A-Z_]+="?([^"]*)"?.*/\1/')"
  [ "$got" = "$PKG" ] || CODE_DRIFT=$((CODE_DRIFT+1))
done

# ----- every skill declares metadata.version, and it matches -----
echo
echo "[2] all twelve skills declare metadata.version = VERSION"
SKILL_N=0; SKILL_BAD=0
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  SKILL_N=$((SKILL_N+1))
  name="$(basename "$d")"
  got="$(awk '/^---[[:space:]]*$/{n++; next} n==1' "$d/SKILL.md" \
         | grep -m1 -E '^[[:space:]]+version:' | sed -E 's/.*version:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')"
  if [ "$got" = "$PKG" ]; then
    continue
  elif [ "$SYNC" = true ] && [ -n "$got" ]; then
    sed -i.bak -E "s/^([[:space:]]+)version:[[:space:]]*\"?[^\"]*\"?[[:space:]]*$/\1version: \"${PKG}\"/" "$d/SKILL.md" \
      && rm -f "$d/SKILL.md.bak" && echo "  sync — $name: $got -> $PKG"
  else
    bad "$name declares version '${got:-<none>}', VERSION says $PKG"
    SKILL_BAD=$((SKILL_BAD+1))
  fi
done
[ "$SKILL_BAD" -eq 0 ] && ok "$SKILL_N skill(s) at $PKG"

# ----- no skill may reintroduce a private release lineage -----
# A per-skill `license:` is the same failure in a different field: one shipped
# unit cannot carry two licences (task-specs-to-issues once claimed Apache-2.0
# inside an MIT repo). The root LICENSE governs; skills declare none.
echo
echo "[3] no skill carries a private licence"
LIC="$(grep -l -E '^license:' skills/*/SKILL.md 2>/dev/null | tr '\n' ' ')"
if [ -z "$LIC" ]; then
  ok "no per-skill licence claims (root LICENSE governs the unit)"
else
  bad "per-skill licence found in: $LIC — the root LICENSE governs"
fi

# ----- schema versions must NOT have been swept up -----
# The counter-test. If a future edit "unifies" a data-contract version into the
# release number, specs stop validating against their own declared schema. These
# are asserted to be UNCHANGED, which is what makes check [1] safe to automate.
echo
echo "[4] schema/format versions are deliberately NOT unified"
SCHEMA_OK=0
if grep -qE '^VALIDATOR_VERSION="2"' skills/task-spec/scripts/validate-task-spec.sh 2>/dev/null; then
  ok "VALIDATOR_VERSION stays 2 (a data contract, not a release)"
else
  bad "VALIDATOR_VERSION was changed — that is a spec-format version, not a release version"
  SCHEMA_OK=1
fi
if grep -qE 'format_version: 3' tests/uc-analytics/cvg/tasks/done/*.md 2>/dev/null; then
  ok "task-spec format_version stays 3"
else
  echo "  note — no format_version: 3 spec found to check (fixture-dependent, not a failure)"
fi

echo
echo "=================================================================="
echo "RESULTS: $PASS passed, $FAIL failed  (package version $PKG)"
if [ "$SYNC" = true ]; then
  echo "VERSION_UNITY=SYNCED"; exit 0
fi
if [ "$FAIL" -eq 0 ] && [ "$CODE_DRIFT" -eq 0 ] && [ "$SCHEMA_OK" -eq 0 ]; then
  echo "VERSION_UNITY=PASS"; exit 0
else
  echo "VERSION_UNITY=FAIL"; exit 1
fi
