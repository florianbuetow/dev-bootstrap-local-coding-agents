#!/usr/bin/env bash
# Validate or interactively select a backend.
# Usage: bash scripts/lib/select-backend.sh [backend]
# Outputs: ollama | lmstudio   (normalises lm-studio -> lmstudio)
backend="${1:-}"

if [ -n "$backend" ]; then
  case "$backend" in
    ollama)              echo "ollama";   exit 0 ;;
    lmstudio|lm-studio)  echo "lmstudio"; exit 0 ;;
    *) echo "unknown backend: '$backend' (use ollama | lmstudio)" >&2; exit 1 ;;
  esac
fi

if [ ! -t 0 ]; then
  echo "non-interactive: pass a backend, e.g. just init <dest> ollama qwen" >&2; exit 1
fi

echo "Select a backend:" >&2
PS3="backend # "
select b in "ollama" "lmstudio"; do
  [ -n "${b:-}" ] && { echo "$b"; exit 0; }
done
