#!/usr/bin/env bash
# Detect the download format based on CPU architecture.
# Usage: bash scripts/lib/arch.sh [force_fmt]
# Outputs: mlx | gguf
force_fmt="${1:-}"
if [ -n "$force_fmt" ]; then
  echo "$force_fmt"
elif [ "$(uname -m)" = "arm64" ]; then
  echo "mlx"
else
  echo "gguf"
fi
