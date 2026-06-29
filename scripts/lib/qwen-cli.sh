#!/usr/bin/env bash
# Print the path to qwen-code's entry script, to be run with a compatible Node
# (see qwen-node.sh). We run the script directly instead of the `qwen` wrapper
# because the wrapper hard-codes an incompatible Node in its shebang.
#
# Resolution order:
#   1. the copy installed under the pinned node@22 global prefix
#   2. an on-PATH `qwen`, resolved to its real script
# Usage: qwen_cli="$(bash scripts/lib/qwen-cli.sh)" || handle "missing"

node22_prefix="$(brew --prefix node@22 2>/dev/null || true)"
if [ -n "$node22_prefix" ] && [ -x "$node22_prefix/bin/npm" ]; then
  root="$("$node22_prefix/bin/npm" root -g 2>/dev/null || true)"
  pkg="$root/@qwen-code/qwen-code/package.json"
  if [ -f "$pkg" ]; then
    entry="$(python3 -c '
import json, os, sys
p = sys.argv[1]
d = json.load(open(p))
b = d.get("bin", "")
rel = b if isinstance(b, str) else (b.get("qwen") or next(iter(b.values()), ""))
print(os.path.join(os.path.dirname(p), rel) if rel else "")
' "$pkg" 2>/dev/null)"
    [ -n "$entry" ] && [ -f "$entry" ] && { echo "$entry"; exit 0; }
  fi
fi

if command -v qwen >/dev/null 2>&1; then
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$(command -v qwen)"
  exit 0
fi
exit 1
