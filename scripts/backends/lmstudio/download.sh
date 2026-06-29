#!/usr/bin/env bash
# Ensure a model is served by LM Studio, then print its served id to stdout.
# Usage: bash scripts/backends/lmstudio/download.sh <id> <fmt> <key>
# Requires: HOST and LMS_BIN env vars (set via eval of scripts/lib/backend.sh)
#
# Idempotent: if the requested model is already served (matched by its id or by
# its identifier key), it is reused as-is and NOTHING is downloaded or reloaded.
set -euo pipefail
id="${1:?model id required}"
fmt="${2:?format required}"
key="${3:?key required}"
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"
lms_bin="${LMS_BIN:?LMS_BIN env var required (eval scripts/lib/backend.sh first)}"

# Echo the served id if $id or $key is already in /v1/models, else nothing.
serving() {
  curl -fsS "$host/v1/models" 2>/dev/null \
    | ID="$id" KEY="$key" python3 -c '
import json, sys, os
data = json.load(sys.stdin).get("data", [])
targets = {os.environ["ID"], os.environ["KEY"]}
for m in data:
    if m.get("id", "") in targets:
        print(m["id"]); sys.exit(0)
' 2>/dev/null || true
}

# Fast path: already loaded -> reuse it, do not download.
served="$(serving)"
if [ -n "$served" ]; then
  echo "✓ '$served' already loaded in LM Studio — reusing it (no download)" >&2
  echo "$served"
  exit 0
fi

# Not present: fetch and load. Intermediate failures are tolerated on purpose;
# the verification below is the real gate (fail-closed on the wrong/absent model).
echo "▸ lms get $id --$fmt  (large download — be patient)" >&2
"$lms_bin" get "$id" "--$fmt" --yes >&2 \
  || echo "  warning: 'lms get' returned non-zero; continuing to load/verify" >&2
"$lms_bin" load "$id" --identifier "$key" >/dev/null 2>&1 \
  || echo "  warning: 'lms load' returned non-zero; continuing to verify" >&2

served="$(serving)"
if [ -z "$served" ]; then
  loaded="$(curl -fsS "$host/v1/models" 2>/dev/null \
    | python3 -c 'import json,sys; print([m["id"] for m in json.load(sys.stdin).get("data",[])])' \
    2>/dev/null || echo 'none/unreachable')"
  echo "error: model '$id' (identifier '$key') is not loaded in LM Studio." >&2
  echo "       Currently loaded: $loaded" >&2
  echo "       Load it in the LM Studio app, or check the catalog name (just models)." >&2
  exit 1
fi
echo "$served"
