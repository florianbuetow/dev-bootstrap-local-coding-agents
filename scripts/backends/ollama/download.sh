#!/usr/bin/env bash
# Pull a model via ollama and print the served model id to stdout.
# Usage: bash scripts/backends/ollama/download.sh <id> [fmt] [key]
# (fmt and key are unused; accepted so callers can use a uniform signature)
set -euo pipefail
id="${1:?model id required}"
echo "▸ ollama pull $id  (large download — be patient)" >&2
ollama pull "$id"
echo "$id"
