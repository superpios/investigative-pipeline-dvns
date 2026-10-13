#!/usr/bin/env bash
# Avvio rapido Explorer locale
set -euo pipefail

ECOSYSTEM="$(cd "$(dirname "$0")" && pwd)/dvns-ecosystem"
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
