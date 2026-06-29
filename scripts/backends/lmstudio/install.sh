#!/usr/bin/env bash
# Install LM Studio and bootstrap the lms CLI (idempotent).
# Accepts LMS_BIN env var from scripts/lib/backend.sh; falls back to default path.
set -euo pipefail
lms_bin="${LMS_BIN:-$HOME/.lmstudio/bin/lms}"
if ! command -v lms >/dev/null 2>&1 && [ ! -x "$lms_bin" ]; then
  [ -d "/Applications/LM Studio.app" ] \
    || { echo "  installing LM Studio..."; brew install --cask lm-studio; }
fi
[ -x "$lms_bin" ] && "$lms_bin" bootstrap >/dev/null 2>&1 || true
echo "✓ lmstudio ready"
