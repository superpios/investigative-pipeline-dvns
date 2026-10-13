#!/usr/bin/env bash
# =============================================================================
# Setup unificato ecosistema Investigative DVNS (versione robusta e corretta)
# =============================================================================
set -euo pipefail

SKIP_TEST=0
if [[ "${1:-}" == "--skip-test" ]]; then
  SKIP_TEST=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXED_RUNNER="$SCRIPT_DIR/run_pipeline.sh"

# Shared path (same default as start_explorer.sh); override with DVNS_ECOSYSTEM
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE="${DVNS_ECOSYSTEM:-$REPO_ROOT/dvns-ecosystem}"
mkdir -p "$BASE"
cd "$BASE"

echo "==> Base directory: $BASE"
echo "==> Script dir: $SCRIPT_DIR"

clone() {
  local url="$1" name="$2"
  if [ -d "$name" ]; then
    echo "  already present: $name"
  else
    echo "  cloning $name..."
    git clone --depth 1 "$url" "$name"
  fi
}

clone "https://github.com/superpios/investigative-explorer-dvns.git"     investigative-explorer-dvns
clone "https://github.com/superpios/investigative-leads-generator.git"    investigative-leads-generator
clone "https://github.com/superpios/investigative-alert-engine.git"       investigative-alert-engine
clone "https://github.com/superpios/investigative-pipeline-dvns.git"      investigative-pipeline-dvns

if [ -f "$FIXED_RUNNER" ]; then
  echo "==> Installing fixed run_pipeline.sh from $FIXED_RUNNER"
  cp -f "$FIXED_RUNNER" investigative-pipeline-dvns/scripts/run_pipeline.sh
  chmod +x investigative-pipeline-dvns/scripts/run_pipeline.sh
else
  echo "WARNING: fixed run_pipeline.sh not found. Using repo version."
fi

echo "==> Creating virtual environment"
python3 -m venv .venv
source .venv/bin/activate

echo "==> Installing dependencies"
pip install -q --upgrade pip
pip install -q "pyyaml>=6.0" "pandas>=2.0" "fastapi>=0.110" "uvicorn>=0.29" "pytest" "networkx" "polars" "pyarrow" "duckdb" || true

if [ "$SKIP_TEST" -eq 0 ]; then
  echo "==> Running pipeline smoke test (fixture)"
  cd investigative-pipeline-dvns
  bash scripts/run_pipeline.sh --fixture
  cd ..
fi

echo "Ecosistema pronto in: $BASE"
echo "Prossimi passi: source $BASE/.venv/bin/activate"
