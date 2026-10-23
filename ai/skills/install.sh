#!/bin/bash

# Install AI skills for Claude Code and Codex.
#
# Claude Code does not yet follow directory symlinks when discovering skills,
# so each skill's files must be symlinked individually into ~/.claude/skills/.
# See: https://github.com/anthropics/claude-code/issues/14836
#
# Codex supports symlinked skill directories and discovers user-level skills
# from ~/.agents/skills/.

set -euo pipefail

SKILLS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.agents/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"
mkdir -p "$CODEX_SKILLS_DIR"

for skill_dir in "$SKILLS_SRC"/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  skill_name="${skill_dir##*/}"
  claude_dest="$CLAUDE_SKILLS_DIR/$skill_name"
  codex_dest="$CODEX_SKILLS_DIR/$skill_name"

  mkdir -p "$claude_dest"
  ln -sf "$skill_dir/SKILL.md" "$claude_dest/SKILL.md"

  if [ -e "$codex_dest" ] && [ ! -L "$codex_dest" ]; then
    echo "not replacing existing Codex skill directory: $codex_dest" >&2
    continue
  fi

  ln -sfn "$skill_dir" "$codex_dest"
done
