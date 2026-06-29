#!/usr/bin/env bash
# Install base requirements: brew, a qwen-compatible Node (node@22), qwen-code.
# Idempotent. qwen-code breaks on Node >= 24 (undici dispatcher bug,
# qwen-code#4274), so we pin Node 22 LTS and run qwen under it (see qwen-node.sh).
set -euo pipefail
echo "▸ Ensuring base requirements..."
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
eval "$(bash "$HERE/brew-env.sh")"

if ! command -v brew >/dev/null 2>&1; then
  echo "  installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(bash "$HERE/brew-env.sh")"
fi

# Pinned, qwen-compatible Node runtime.
if brew list node@22 >/dev/null 2>&1; then
  echo "  node@22 present"
else
  echo "  installing node@22 (LTS — the runtime qwen-code needs)..."
  brew install node@22
fi
npm22="$(brew --prefix node@22)/bin/npm"

# qwen-code: reuse any existing install, else install under node@22.
if command -v qwen >/dev/null 2>&1 || "$npm22" ls -g @qwen-code/qwen-code >/dev/null 2>&1; then
  echo "  qwen-code present"
else
  echo "  installing qwen-code (under node@22)..."
  "$npm22" install -g @qwen-code/qwen-code@latest
fi

echo "✓ base requirements ready (node@22 + qwen-code)"
