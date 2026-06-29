#!/usr/bin/env bash
# Ensure a model is available via ollama, then print its id to stdout.
# Usage: bash scripts/backends/ollama/download.sh <id> [fmt] [key]
# (fmt and key are accepted for a uniform signature but unused by ollama.)
# Idempotent: if the model is already pulled it is reused — nothing is downloaded.
set -euo pipefail
id="${1:?model id required}"
host="${HOST:-http://127.0.0.1:11434}"

# Already pulled? Match against /api/tags (exact, or default ':latest' tag).
present="$(curl -fsS "$host/api/tags" 2>/dev/null | ID="$id" python3 -c '
import json, sys, os
want = os.environ["ID"]
for m in json.load(sys.stdin).get("models", []):
    name = m.get("name", "")
    if name == want or name == want + ":latest" or name.split(":")[0] == want:
        print(name); sys.exit(0)
' 2>/dev/null || true)"

if [ -n "$present" ]; then
  echo "✓ '$present' already pulled — reusing it (no download)" >&2
  echo "$present"
  exit 0
fi

echo "▸ ollama pull $id  (large download — be patient)" >&2
ollama pull "$id"
echo "$id"
