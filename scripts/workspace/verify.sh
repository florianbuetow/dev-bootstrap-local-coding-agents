#!/usr/bin/env bash
# Probe the served model endpoint and warn if the model is not found.
# Usage: bash scripts/workspace/verify.sh <served-model-id>
# Requires: HOST env var (set via eval of scripts/lib/backend.sh)
set -uo pipefail
served="${1:?served model id required}"
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"

if curl -fsS "$host/v1/models" 2>/dev/null | grep -qF "$served"; then
  echo "✓ verified: '$served' is served at $host/v1"
else
  echo "⚠ could not confirm '$served' at $host/v1 — it may still work; check: just check" >&2
fi
