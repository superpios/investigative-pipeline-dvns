#!/usr/bin/env bash
# Avvio rapido Explorer locale
set -euo pipefail

# Shared path (same default as setup_ecosystem.sh); override with DVNS_ECOSYSTEM
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ECOSYSTEM="${DVNS_ECOSYSTEM:-$REPO_ROOT/dvns-ecosystem}"
if [ ! -d "$ECOSYSTEM/investigative-explorer-dvns" ]; then
  echo "Esegui prima setup_ecosystem.sh"
  exit 1
fi

cd "$ECOSYSTEM/investigative-explorer-dvns"
source "$ECOSYSTEM/.venv/bin/activate"

echo "==> Building search index..."
python scripts/build_search_index.py

echo "==> Starting local server on http://127.0.0.1:8765"
python src/server.py --port 8765
