#!/usr/bin/env bash
# Local / CI runner for the full DVNS investigative cycle.
# Usage:
#   ./scripts/run_pipeline.sh                  # uses live clones
#   ./scripts/run_pipeline.sh --fixture        # uses testdata/relations
#   RELATIONS_DIR=/path/to/relations ./scripts/run_pipeline.sh
#
# Exit codes:
#   0  success (including zero leads — conservative OK)
#   1  fail-closed on invalid/missing input
#   2  missing dependencies or fatal error

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${ROOT}/output"
USE_FIXTURE=0
EXPLORER_URL="https://github.com/superpios/investigative-explorer-dvns.git"
LEADS_URL="https://github.com/superpios/investigative-leads-generator.git"
ALERT_URL="https://github.com/superpios/investigative-alert-engine.git"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture) USE_FIXTURE=1; shift ;;
    --work) WORK="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--fixture] [--work DIR]"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "${WORK}"/{input,leads,ranked,history,repos}
cd "${WORK}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 2; }
}
need git
need python3

echo "==> Ensuring Python deps"
python3 -m pip install -q "pyyaml>=6.0" "pandas>=2.0"

clone_or_update() {
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" fetch --depth 1 origin main
    git -C "$dir" checkout -f origin/main
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

echo "==> Cloning / updating component repos"
clone_or_update "$LEADS_URL"  repos/leads
clone_or_update "$ALERT_URL"  repos/alert

if [ "$USE_FIXTURE" -eq 1 ]; then
  RELATIONS="${ROOT}/testdata/relations"
  echo "==> Using fixture relations: $RELATIONS"
else
  if [ -n "${RELATIONS_DIR:-}" ]; then
    RELATIONS="$RELATIONS_DIR"
  else
    clone_or_update "$EXPLORER_URL" repos/explorer
    RELATIONS="repos/explorer/data/relations"
  fi
  echo "==> Using relations: $RELATIONS"
fi

if [ ! -d "$RELATIONS" ]; then
  echo "ERROR: relations directory not found: $RELATIONS"
  exit 2
fi

echo "==> [1/4] Adapt Explorer → generator input"
python3 repos/leads/scripts/adapt_explorer.py \
  --relations "$RELATIONS" \
  --output input

echo "==> [2/4] Generate conservative leads"
set +e
python3 repos/leads/scripts/apply_rules.py \
  --input input \
  --output leads \
  --rules repos/leads/rules/rules_v0.1.yaml
RC=$?
set -e
if [ -f leads/manifest.json ]; then
  echo "--- manifest ---"
  cat leads/manifest.json
  echo "----------------"
fi
if [ $RC -ne 0 ]; then
  echo "FAIL-CLOSED: invalid input (exit $RC)"
  exit 1
fi

echo "==> [3/4] Rank leads + history"
python3 repos/alert/scripts/rank_leads.py \
  --input leads \
  --output ranked \
  --history history \
  --rules repos/alert/rules/ranking_v0.1.yaml

echo "==> [4/4] Export feed (optional)"
if [ -f ranked/ranked_leads.json ]; then
  python3 repos/alert/scripts/export_feed.py \
    --input ranked \
    --output ranked/feed.md 2>/dev/null || true
fi

echo "==> Audit"
python3 "${ROOT}/scripts/audit_output.py" \
  --ranked ranked/ranked_leads.json \
  --manifest leads/manifest.json \
  --history history || true

echo ""
echo "DONE. Outputs in: ${WORK}"
ls -la ranked/ history/ leads/ 2>/dev/null || true
if [ -f ranked/ranked_leads.json ]; then
  python3 -c "
import json
r=json.load(open('ranked/ranked_leads.json'))
print(f'Ranked leads: {len(r)}')
for L in r[:15]:
    print(f\"  #{L.get('rank_position')} score={L.get('priority_score')} {L.get('id')}\")
"
fi
