#!/bin/bash

# Install global Claude Code config by symlinking it from the repo into ~/.claude.
#
# Verified safe to symlink settings.json: Claude Code resolves the symlink and
# writes atomically at the *target* path (temp file + rename in the repo dir), so
# the symlink in ~/.claude survives `/config` writes AND changes you make in the
# app propagate straight back into the repo — zero drift, edit from either side.
# statusline-command.sh is never rewritten by Claude, so it's a plain symlink too.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

for f in settings.json statusline-command.sh; do
  dest="$CLAUDE_DIR/$f"
  # Preserve any pre-existing real file before replacing it with the symlink.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    cp "$dest" "$dest.pre-dotfiles.bak"
    echo "backed up existing $f -> $dest.pre-dotfiles.bak"
  fi
  ln -sf "$SRC/$f" "$dest"
  echo "linked $dest -> $SRC/$f"
done
