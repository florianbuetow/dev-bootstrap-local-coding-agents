#!/usr/bin/env bash
# Model catalog — the canonical source of model data.
# Usage: bash scripts/lib/catalog.sh [--parse | --list]
#   --parse (default): emit raw pipe-delimited rows (8 fields each)
#   --list:            print a formatted table with arch detection
#
# Row schema (7 pipes, 8 fields):
#   key | label | params | size | quant | ollama-mlx-tag | ollama-gguf-tag | lmstudio-name

_rows() {
  echo 'qwen|Qwen3.6 35B-A3B|35B (3B active MoE)|~22GB|4-bit (Q4_K_M)|qwen3.6:35b-mlx|qwen3.6:35b|qwen/qwen3.6-35b-a3b'
  echo 'north|North Mini Code 1.0|~35B-A3B (MoE)|~22GB|4-bit (Q4_K_M)|north-mini-code-1.0|north-mini-code-1.0|north-mini-code'
  echo 'nemotron|Nemotron 3 Nano|~30B|~19GB|4-bit (Q4_K_M)|nemotron-3-nano:30b|nemotron-3-nano:30b|nemotron-3-nano'
  echo 'gemma|Gemma 4 E2B|E2B (~2B active)|~8GB|4-bit (Q4_K_M)|gemma4:e2b|gemma4:e2b|gemma-4-e2b-it'
}

_validate() {
  local line="$1" pipes="${1//[^|]}"
  if [ "${#pipes}" -ne 7 ]; then
    echo "catalog: malformed row (expected 7 pipes): $line" >&2; exit 1
  fi
}

case "${1:---parse}" in
  --parse)
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      _validate "$line"
      echo "$line"
    done < <(_rows)
    ;;
  --list)
    arch="$(uname -m)"
    fmt="GGUF"; [ "$arch" = "arm64" ] && fmt="MLX"
    echo "Detected $arch -> default download format: $fmt"
    echo
    printf "  %-9s %-22s %-20s %-7s %-14s\n" KEY MODEL PARAMS SIZE QUANT
    printf "  %-9s %-22s %-20s %-7s %-14s\n" "---" "-----" "------" "----" "-----"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      _validate "$line"
      IFS='|' read -r key label params size quant _ <<< "$line"
      printf "  %-9s %-22s %-20s %-7s %-14s\n" "$key" "$label" "$params" "$size" "$quant"
    done < <(_rows)
    echo
    echo "Use: just init <dest> <ollama|lmstudio> <key>"
    ;;
  *)
    echo "usage: catalog.sh [--parse | --list]" >&2; exit 1 ;;
esac
