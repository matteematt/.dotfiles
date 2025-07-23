#!/bin/bash

# Interactive tmux session killer
# Uses fzf with simplified preview

# Get all tmux sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

if [ -z "$sessions" ]; then
    echo "No sessions found"
    exit 0
fi

# Use fzf to select sessions (multiple selection with -m flag)
selected_sessions=$(echo "$sessions" | fzf -m \
    --prompt="Select sessions to kill: " \
    --preview="$(dirname "$0")/session_preview.sh {}" \
    --preview-window=up:90% \
    --header="Tab: select/deselect | Ctrl+A: select all | Ctrl+D: deselect all | Enter: confirm")

if [ -z "$selected_sessions" ]; then
    echo "No sessions selected"
    exit 0
fi

# Confirm before killing
echo "Selected sessions to kill:"
echo "$selected_sessions"
echo ""
read -p "Are you sure you want to kill these sessions? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    # Kill each selected session
    while IFS= read -r session; do
        if [ -n "$session" ]; then
            # Check if it's the current session
            current_session=$(tmux display-message -p "#S")
            if [ "$session" = "$current_session" ]; then
                echo "Skipping current session: $session"
                continue
            fi

            tmux kill-session -t "$session" 2>/dev/null
            echo "Killed session: $session"
        fi
    done <<< "$selected_sessions"

    echo "Sessions killed successfully"
    sleep 2
else
    echo "Session killing cancelled"
    sleep 2
fi
