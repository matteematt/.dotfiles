#!/bin/sh
# Used in gitWorktreeCleanup's preview window
# Prints the opening of a merged pull request's body, given the JSON file that
# gitWorktreeCleanup already fetched as $1 and the pull request number as $2

# Reads the file rather than calling gh. fzf reruns a preview on every move of
# the cursor, so anything over the network here shows as a visible stall while
# scrolling the list; the body is already in the fetch that built the picker, so
# this is a local jq query and returns at once.
[ -n "$1" ] && [ -s "$1" ] && [ -n "$2" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

lines=${WORKTREE_PR_BODY_LINES:-8}

# Indented to line up with the MERGED header in __renderWorktreeRisks
jq -r --arg n "$2" --argjson lines "$lines" '
    .[]
    | select((.number | tostring) == $n)
    | (.body // "")
    | gsub("\r"; "")
    | gsub("&nbsp;"; "")
    | split("\n")
    | map(select(test("\\S")))
    | .[0:$lines]
    | map("             " + .)
    | .[]
  ' "$1" 2>/dev/null
