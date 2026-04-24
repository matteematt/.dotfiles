#!/usr/bin/env bash
# Print the current session name (with trailing space) only when it fits
# alongside the window tabs and right-side status within the client's width.
#
# Usage: session_name_if_fits.sh [LEFT_PADDING]
#   LEFT_PADDING: columns reserved to the left of this output (default 0).
#                 Set to match any leading spaces in `status-left`.
#
# Width budget:
#   left_padding + windows_total + session_label + status_right <= client_width

set -eu

# Width reserved for leading spaces in status-left. Override per-platform.
left_padding=${1:-0}

session_name=$(tmux display -p '#S')

# Skip tmux's auto-generated numeric names — only surface names the user set.
if [[ "$session_name" =~ ^[0-9]+$ ]]; then
    exit 0
fi

client_width=$(tmux display -p '#{client_width}')

# Approximate rendered width of `status-right` ("HH:MM:SS | Weekday DD Mon  ").
status_right=30

# Per-tab overhead: leading space + "N: " + trailing space, plus one separator.
# Widest index assumed single-digit; bump to 7 if you routinely go past 9 tabs.
tab_overhead=6

windows_total=0
while IFS= read -r name; do
    windows_total=$((windows_total + ${#name} + tab_overhead))
done < <(tmux list-windows -F '#W')

# " name " — trailing space so it doesn't butt against the first tab.
session_label=$((${#session_name} + 1))

required=$((left_padding + windows_total + session_label + status_right))

if (( required <= client_width )); then
    printf '%s ' "$session_name"
fi
