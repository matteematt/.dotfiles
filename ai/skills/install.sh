#!/bin/bash

# Install AI skills for Claude Code and Codex by symlinking each skill
# directory into the tool's user-level skills folder:
#   Claude Code: ~/.claude/skills/<name>
#   Codex:       ~/.agents/skills/<name>
#
# Claude Code used to need SKILL.md symlinked file-by-file
# (https://github.com/anthropics/claude-code/issues/14836); it now follows
# symlinked skill directories, so supporting files (scripts, references,
# agents/) come along too. Old per-file installs are migrated automatically.

set -euo pipefail

SKILLS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.agents/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"
mkdir -p "$CODEX_SKILLS_DIR"

# link_skill <src dir> <dest>
# Points <dest> at <src>. Replaces an existing symlink. A real directory is
# replaced only if everything in it is a symlink back into <src> (the old
# per-file layout); anything else is left alone with a warning.
link_skill() {
  local src="$1" dest="$2" f

  if [ -d "$dest" ] && [ ! -L "$dest" ]; then
    for f in "$dest"/* "$dest"/.[!.]*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      if [ ! -L "$f" ] || [[ "$(readlink "$f")" != "$src"/* ]]; then
        echo "not replacing existing skill directory: $dest" >&2
        return 0
      fi
    done
    find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
    rmdir "$dest"
  fi

  ln -sfn "$src" "$dest"
}

for skill_dir in "$SKILLS_SRC"/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  skill_name="${skill_dir##*/}"
  codex_dest="$CODEX_SKILLS_DIR/$skill_name"

  link_skill "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"

  # Skills that only make sense in Claude Code (e.g. they rely on its Agent
  # tool or model names) carry a CLAUDE_ONLY marker and are not linked for Codex.
  if [ -f "$skill_dir/CLAUDE_ONLY" ]; then
    [ -L "$codex_dest" ] && rm "$codex_dest"
    continue
  fi

  link_skill "$skill_dir" "$codex_dest"
done
