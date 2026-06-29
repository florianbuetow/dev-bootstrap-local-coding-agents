#!/usr/bin/env bash
# Validate or interactively select a model, then resolve its backend-specific id.
# Usage: bash scripts/lib/select-model.sh <backend> <fmt> [model_key]
# Outputs: <key>|<backend-specific-model-id>
set -euo pipefail

backend="${1:?backend required}"
fmt="${2:?fmt required}"
model_key="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load catalog into parallel arrays
keys=(); labels=(); omlx=(); ogguf=(); lmsname=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # fields: key|label|params|size|quant|ollama-mlx-tag|ollama-gguf-tag|lmstudio-name
  IFS='|' read -r k label params size quant a b l <<< "$line"
  keys+=("$k")
  labels+=("$label  —  $params · $size · $quant")
  omlx+=("$a"); ogguf+=("$b"); lmsname+=("$l")
done < <(bash "$SCRIPT_DIR/catalog.sh" --parse)

# Find model by key or prompt interactively
sel=-1
if [ -n "$model_key" ]; then
  for i in "${!keys[@]}"; do
    [ "${keys[$i]}" = "$model_key" ] && { sel=$i; break; }
  done
  [ "$sel" -lt 0 ] && { echo "unknown model '$model_key' — run: just models" >&2; exit 1; }
fi

if [ "$sel" -lt 0 ]; then
  if [ ! -t 0 ]; then
    echo "non-interactive: pass a model key, e.g. ... $backend qwen" >&2; exit 1
  fi
  fmtU="$(echo "$fmt" | tr '[:lower:]' '[:upper:]')"
  echo "Select a model ($fmtU build will be downloaded):" >&2
  PS3="model # "
  select c in "${labels[@]}"; do [ -n "${c:-}" ] && { sel=$((REPLY-1)); break; }; done
fi

key="${keys[$sel]}"

# Resolve backend-specific model identifier
if [ "$backend" = "ollama" ]; then
  # Apple Silicon uses the MLX-optimized ollama tag (e.g. qwen3.6:35b-mlx);
  # Intel/Linux uses the plain tag (qwen3.6:35b). Per the model catalog source.
  if [ "$fmt" = "mlx" ]; then id="${omlx[$sel]}"; else id="${ogguf[$sel]}"; fi
else
  # LM Studio picks the mlx vs gguf build at download time (lms get --$fmt).
  id="${lmsname[$sel]}"
fi

echo "$key|$id"
