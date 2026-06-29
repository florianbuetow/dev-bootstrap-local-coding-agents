#!/usr/bin/env bash
# Print the path to a Node binary that qwen-code can actually run on.
#
# Why this exists: qwen-code 0.15.x injects an undici dispatcher into the OpenAI
# SDK that breaks on Node >= 24 — every model call dies with
# "Connection error (cause: fetch failed)" before it even reaches the server,
# while plain curl/fetch to the same endpoint work. See qwen-code issues #4274
# and #4035. Homebrew's default `node` is now 26, so the bootstrap pins an LTS
# (Node 22, falling back to 20) and always launches qwen under it.
#
# Usage: node_bin="$(bash scripts/lib/qwen-node.sh)" || handle "missing"
for v in node@22 node@20; do
  p="$(brew --prefix "$v" 2>/dev/null)/bin/node"
  [ -x "$p" ] && { echo "$p"; exit 0; }
done
exit 1
