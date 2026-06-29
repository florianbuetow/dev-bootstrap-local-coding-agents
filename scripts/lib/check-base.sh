#!/usr/bin/env bash
# Probe availability of base tools: brew, node, qwen-code.
set -uo pipefail
ok() { printf "  ✓ %-9s %s\n" "$1" "$2"; }
no() { printf "  ✗ %-9s missing\n" "$1"; }
echo "Base:"
command -v brew >/dev/null 2>&1 && ok brew "$(brew --version | head -1)" || no brew
command -v node >/dev/null 2>&1 && ok node "$(node --version)"            || no node
command -v qwen >/dev/null 2>&1 && ok qwen "$(qwen --version 2>/dev/null)" || no qwen
