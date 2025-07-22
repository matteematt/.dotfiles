#!/bin/bash

# Session preview script for tmux session killer
# This script generates a preview of a tmux session for fzf

session="$1"

if [ -z "$session" ]; then
    echo "Error: No session name provided"
    exit 1
fi

current_session=$(tmux display-message -p "#S")

if [ "$session" = "$current_session" ]; then
    echo "Current Session"
    echo "================"
    echo "This is your current session."
    echo "Killing it will end this session."
    echo ""
    echo "Consider switching to a different session first."
else
    echo "Session: $session"
    echo "================"
    # Get all windows in this session and show each with its panes
    windows=$(tmux list-windows -t "$session" -F "#{window_index}")
    for window in $windows; do
        # Get window info with proper pluralization
        pane_count=$(tmux list-windows -t "$session" -F "#{window_panes}" | sed -n "${window}p")
        if [ "$pane_count" = "1" ]; then
            window_info=$(tmux list-windows -t "$session" -F "#{window_index}: #{window_name} (#{window_panes} pane)" | grep "^$window:")
        else
            window_info=$(tmux list-windows -t "$session" -F "#{window_index}: #{window_name} (#{window_panes} panes)" | grep "^$window:")
        fi
        echo "$window_info"
        
        # List panes for this window
        tmux list-panes -t "$session:$window" -F "    #{window_index}.#{pane_index}: #{pane_current_path} - #{pane_current_command}"
    done
    echo ""
    echo "Pane Contents:"
    echo "=============="
    
    # Get all panes for this session (iterate through windows)
    all_panes=""
    windows=$(tmux list-windows -t "$session" -F "#{window_index}")
    for window in $windows; do
        window_panes=$(tmux list-panes -t "$session:$window" -F "#{window_index}.#{pane_index}")
        all_panes="$all_panes$window_panes"$'\n'
    done
    all_panes=$(echo "$all_panes" | grep -v '^$')  # Remove empty lines
    
    # Limit to first 5 panes for better readability
    total_panes=$(echo "$all_panes" | wc -l)
    all_panes=$(echo "$all_panes" | head -5)
    pane_count=$(echo "$all_panes" | wc -l)
    
    # Show note if there are more panes
    if [ "$total_panes" -gt 5 ]; then
        echo "Note: Showing first 5 of $total_panes panes"
        echo ""
    fi
    
    if [ "$pane_count" -eq 0 ]; then
        echo "No panes found"
    else
        # Display each pane's content vertically
        pane_number=1
        for pane in $all_panes; do
            # Get pane info
            pane_path=$(tmux display-message -t "$session:$pane" -p "#{pane_current_path}" 2>/dev/null)
            pane_command=$(tmux display-message -t "$session:$pane" -p "#{pane_current_command}" 2>/dev/null)
            
            echo "Pane $pane_number ($pane): $pane_path - $pane_command"
            printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'
            
            # Capture and display pane content (last 18 lines)
            content=$(tmux capture-pane -t "$session:$pane" -p 2>/dev/null | tail -18)
            if [ -n "$content" ]; then
                echo "$content"
            else
                echo "(empty or no content)"
            fi
            
            echo ""
            pane_number=$((pane_number + 1))
        done
    fi
fi 