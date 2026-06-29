#!/usr/bin/env bash
# Emit `export ...` lines that put Homebrew (and brew-installed tools) on PATH.
# Usage: eval "$(bash scripts/lib/brew-env.sh)"
#
# Handles both Homebrew prefixes:
#   - Apple Silicon -> /opt/homebrew
#   - Intel         -> /usr/local
# If brew is not installed yet, emits nothing and exits 0 (a no-op eval), so
# callers can safely run this before the install step has created brew.
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$brew" ] && { "$brew" shellenv; exit 0; }
done
exit 0
