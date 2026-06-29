#!/usr/bin/env bash
# Install Ollama via Homebrew (idempotent).
set -euo pipefail
command -v ollama >/dev/null 2>&1 || { echo "  installing ollama..."; brew install ollama; }
echo "✓ ollama ready"
