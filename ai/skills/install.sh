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

# github-review
mkdir -p "$CLAUDE_SKILLS_DIR/github-review"
ln -sf "$SKILLS_SRC/github-review/SKILL.md" "$CLAUDE_SKILLS_DIR/github-review/SKILL.md"

# commit-message
mkdir -p "$CLAUDE_SKILLS_DIR/commit-message"
ln -sf "$SKILLS_SRC/commit-message/SKILL.md" "$CLAUDE_SKILLS_DIR/commit-message/SKILL.md"

# allow-commit
mkdir -p "$CLAUDE_SKILLS_DIR/allow-commit"
ln -sf "$SKILLS_SRC/allow-commit/SKILL.md" "$CLAUDE_SKILLS_DIR/allow-commit/SKILL.md"
