#!/usr/bin/env bash
# Probe LM Studio binary availability and server reachability.
# Requires: HOST and LMS_BIN env vars (set via eval of scripts/lib/backend.sh)
set -uo pipefail
ok() { printf "  ✓ %-9s %s\n" "$1" "$2"; }
no() { printf "  ✗ %-9s missing\n" "$1"; }
host="${HOST:?HOST env var required (eval scripts/lib/backend.sh first)}"
lms_bin="${LMS_BIN:-$HOME/.lmstudio/bin/lms}"
echo "LM Studio:"
[ -x "$lms_bin" ] \
  && ok lms "$("$lms_bin" --version 2>/dev/null | head -1 || echo present)" \
  || no lms
curl -fsS "$host/v1/models" >/dev/null 2>&1 && ok server "$host" || no server
