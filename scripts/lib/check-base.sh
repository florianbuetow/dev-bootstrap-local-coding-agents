#!/usr/bin/env bash
# Probe base tools: brew, a qwen-compatible Node (node@22/20), and qwen-code.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ok() { printf "  ✓ %-12s %s\n" "$1" "$2"; }
no() { printf "  ✗ %-12s %s\n" "$1" "${2:-missing}"; }
echo "Base:"

command -v brew >/dev/null 2>&1 && ok brew "$(brew --version | head -1)" || no brew

if node_bin="$(bash "$HERE/qwen-node.sh" 2>/dev/null)"; then
  ok node "$("$node_bin" --version) (qwen-compatible: $node_bin)"
else
  no node "no node@22/node@20 — run: just install-deps <backend>"
fi

# Warn if the default `node`/`qwen` on PATH would run qwen on an incompatible Node.
if command -v node >/dev/null 2>&1; then
  major="$(node --version 2>/dev/null | sed 's/^v//; s/\..*//')"
  [ -n "$major" ] && [ "$major" -ge 24 ] 2>/dev/null \
    && printf "  ! %-12s default PATH node is %s — qwen must run via 'just run' (node@22)\n" "note" "$(node --version)"
fi

if qwen_cli="$(bash "$HERE/qwen-cli.sh" 2>/dev/null)"; then
  ok qwen-code "$qwen_cli"
else
  no qwen-code "not installed — run: just install-deps <backend>"
fi
