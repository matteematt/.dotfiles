#!/bin/bash
# Searchable cheatsheet of tmux prefix-table bindings. Annotated (custom)
# bindings are emitted last — with fzf's default layout the end of input
# is rendered immediately above the prompt, so they're what the eye lands
# on first.

noted=$(tmux list-keys -N -T prefix)
# `-aN` shows every key, substituting the note where one exists. Subtract
# the noted lines to get only the defaults.
defaults=$(tmux list-keys -aN -T prefix | grep -vFxf <(printf '%s\n' "$noted"))

{ printf '%s\n' "$defaults"; printf '%s\n' "$noted"; } \
    | fzf --prompt='bindings> '
