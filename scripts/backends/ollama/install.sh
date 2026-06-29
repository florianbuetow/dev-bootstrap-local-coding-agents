#!/usr/bin/env bash
# Install/upgrade Ollama to a version recent enough for current models.
# Old ollama returns HTTP 412 ("requires a newer version of Ollama") when
# pulling 2026-era models (gemma4, qwen3.6, ...), so keep it current.
set -euo pipefail
cur() { ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }

if ! command -v ollama >/dev/null 2>&1; then
  echo "  installing ollama..."
  brew install ollama
elif brew list ollama >/dev/null 2>&1; then
  before="$(cur)"
  echo "  ensuring ollama is up to date..."
  brew upgrade ollama 2>/dev/null || true
  if [ "$before" != "$(cur)" ]; then
    echo "  ollama upgraded; restarting server to use the new version..."
    brew services restart ollama >/dev/null 2>&1 || true
  fi
else
  echo "  ! ollama $(cur) is installed outside Homebrew ($(command -v ollama 2>/dev/null))."
  echo "    Installing Homebrew's ollama so new models can be pulled..."
  brew install ollama 2>/dev/null || true
  echo "    If 'ollama --version' still shows the old one, the non-brew binary shadows"
  echo "    brew's — remove it (or put $(brew --prefix)/bin first on PATH), then stop the"
  echo "    old server (pkill -x ollama) so 'just serve' starts the current one."
fi
echo "✓ ollama ready ($(cur))"
