#!/usr/bin/env bash
# Rename the current tmux session to "<repo>/<branch>" based on the focused
# pane's working directory. Falls back to a short SHA when HEAD is detached.

set -eu

cwd=$(tmux display -p '#{pane_current_path}')

if ! git_common=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null); then
    tmux display-message "Not in a git repo"
    exit 0
fi

# `--git-common-dir` points at the shared `.git`, so its parent is the main
# repo root even when we're sitting inside a worktree (where `--show-toplevel`
# would give the worktree dir instead).
git_common_abs=$(cd "$cwd" && cd "$git_common" && pwd)
repo=$(basename "$(dirname "$git_common_abs")")
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD)

# Detached HEAD → use a short SHA so the name still distinguishes the session.
if [[ "$branch" == "HEAD" ]]; then
    branch=$(git -C "$cwd" rev-parse --short HEAD)
fi

name="${repo}(${branch})"

# tmux session names cannot contain `.` or `:`.
name=${name//./-}
name=${name//:/-}

# A leading dash would be mistaken for a flag by tmux; strip any.
while [[ "$name" == -* ]]; do name=${name#-}; done
[[ -z "$name" ]] && { tmux display-message "Derived session name is empty"; exit 0; }

current=$(tmux display -p '#S')

if [[ "$name" == "$current" ]]; then
    tmux display-message "Session already named '$name'"
    exit 0
fi

# If another session already owns this name (e.g. a second window/session on
# the same repo+branch), refuse to rename rather than create a confusing
# duplicate. Surface a clear message instead of tmux's terse "duplicate
# session" error, then exit non-zero so the failure is visible.
if tmux has-session -t "=$name" 2>/dev/null; then
    tmux display-message "Session '$name' already exists — switch to it instead of opening a second one"
    exit 1
fi

tmux rename-session -t "$current" "$name"
tmux display-message "Session renamed to '$name'"
