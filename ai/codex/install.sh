#!/bin/bash

# Install global Codex configuration by symlinking it from this repository.
# Codex may append trusted hook hashes, project trust, and TUI choices through
# the symlink; keeping one canonical file prevents the live config drifting from
# the setup a fresh machine receives.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.toml"
CODEX_DIR="$HOME/.codex"
DEST="$CODEX_DIR/config.toml"

mkdir -p "$CODEX_DIR"

if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  cp "$DEST" "$DEST.pre-dotfiles.bak"
  echo "backed up existing config.toml -> $DEST.pre-dotfiles.bak"
fi

ln -sfn "$SRC" "$DEST"
echo "linked $DEST -> $SRC"
