#!/usr/bin/env bash
# Install base requirements: brew, node, qwen-code (idempotent).
set -euo pipefail
echo "▸ Ensuring base requirements..."
if ! command -v brew >/dev/null 2>&1; then
  echo "  installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
eval "$(bash "$HERE/brew-env.sh")"
command -v node >/dev/null 2>&1 || { echo "  installing node..."; brew install node; }
command -v qwen >/dev/null 2>&1 || { echo "  installing qwen-code..."; npm install -g @qwen-code/qwen-code@latest; }
echo "✓ base requirements ready"
