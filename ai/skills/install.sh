#!/bin/bash

# Install AI skills for Claude Code.
#
# Claude Code does not yet follow directory symlinks when discovering skills,
# so each skill's files must be symlinked individually into ~/.claude/skills/.
# See: https://github.com/anthropics/claude-code/issues/14836

set -euo pipefail

SKILLS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"

# handoff
mkdir -p "$CLAUDE_SKILLS_DIR/handoff"
ln -sf "$SKILLS_SRC/handoff/SKILL.md" "$CLAUDE_SKILLS_DIR/handoff/SKILL.md"
