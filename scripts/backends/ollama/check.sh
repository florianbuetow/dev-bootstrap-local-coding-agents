#!/usr/bin/env bash
# Probe Ollama binary availability and server reachability.
# Requires: HOST env var (set via eval of scripts/lib/backend.sh)
set -uo pipefail
ok() { printf "  ✓ %-9s %s\n" "$1" "$2"; }
no() { printf "  ✗ %-9s missing\n" "$1"; }
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"
echo "Ollama:"
command -v ollama >/dev/null 2>&1 \
  && ok ollama "$(ollama --version 2>/dev/null | grep -iom1 'version.*' || echo present)" \
  || no ollama
curl -fsS "$host/api/tags" >/dev/null 2>&1 && ok server "$host" || no server
