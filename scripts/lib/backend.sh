#!/usr/bin/env bash
# Resolve host, apikey, and lms_bin for a backend.
# Usage: eval "$(bash scripts/lib/backend.sh <backend> <ollama_host> <lmstudio_host>)"
# Sets:  HOST  APIKEY  LMS_BIN
backend="${1:?backend required}"
ollama_host="${2:-http://127.0.0.1:11434}"
lmstudio_host="${3:-http://127.0.0.1:1234}"

case "$backend" in
  ollama)
    printf 'HOST=%s\nAPIKEY=ollama\nLMS_BIN=\n' "$ollama_host"
    ;;
  lmstudio|lm-studio)
    lms_bin="$(command -v lms 2>/dev/null || echo "$HOME/.lmstudio/bin/lms")"
    printf 'HOST=%s\nAPIKEY=lm-studio\nLMS_BIN=%s\n' "$lmstudio_host" "$lms_bin"
    ;;
  *)
    echo "error: unknown backend '$backend' (use ollama | lmstudio)" >&2
    exit 1
    ;;
esac
