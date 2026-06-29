#!/usr/bin/env bash
# Start the Ollama server and wait up to 30s for it to respond.
# Requires: HOST env var (set via eval of scripts/lib/backend.sh)
set -euo pipefail
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"

if curl -fsS "$host/api/tags" >/dev/null 2>&1; then
  echo "✓ Ollama already running"; exit 0
fi

log="${TMPDIR:-/tmp}/qwen-coder-ollama.log"
echo "▸ starting 'ollama serve' (log: $log)..."
nohup ollama serve >"$log" 2>&1 &
ollama_pid=$!

for _ in $(seq 1 30); do
  curl -fsS "$host/api/tags" >/dev/null 2>&1 && { echo "✓ Ollama up"; exit 0; }
  sleep 1
done

kill "$ollama_pid" 2>/dev/null || true
echo "✗ Ollama not ready in 30s — see $log" >&2; exit 1
