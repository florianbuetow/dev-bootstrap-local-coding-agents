#!/usr/bin/env bash
# Start the LM Studio server and wait up to 30s for it to respond.
# Requires: HOST and LMS_BIN env vars (set via eval of scripts/lib/backend.sh)
set -euo pipefail
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"
lms_bin="${LMS_BIN:?LMS_BIN env var required (eval scripts/lib/backend.sh first)}"

echo "▸ starting LM Studio server..."
"$lms_bin" server start >/dev/null 2>&1 || true

for _ in $(seq 1 30); do
  curl -fsS "$host/v1/models" >/dev/null 2>&1 && { echo "✓ LM Studio server up"; exit 0; }
  sleep 1
done
echo "✗ LM Studio server not ready in 30s" >&2; exit 1
