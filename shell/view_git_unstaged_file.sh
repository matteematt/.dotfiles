#!/bin/sh
# Used in gitViewAndStage, both for its preview window and for its ctrl-o
# Prints unstaged git file according to the git status
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# else prints error message

# Expected input examples, a status code and a path separated by a tab
# M	src/test.txt
# R	src/my banana.txt

# fzf sets $FZF_PREVIEW_COLUMNS to the width of the preview window, so falling
# back to tput cols is what fills the screen when ctrl-o clears it instead
FZF_PREVIEW_COLUMNS=${FZF_PREVIEW_COLUMNS:-$(tput cols)}

# `git status --porcelain` reports its paths from the repository root rather
# than from the caller, which is what lets a listing read the same way
# whichever directory gitViewAndStage was run in, so move there before using
# one: a path like src/main.c means nothing from inside src itself
cd "$(git rev-parse --show-toplevel)" || exit 1

# A tab is what separates the two, as a path is allowed to contain spaces.
# fzf already quotes the line it passes in, so it arrives as a single argument
# with no quoting of its own to undo
status_code=`printf '%s' "$1" | cut -f1`
file_path=`printf '%s' "$1" | cut -f2-`
case "$status_code" in
  "U")
    bat --theme="OneHalfDark" --style=numbers,changes --color always "$file_path"
    ;;
  "M")
		git diff --text -- "$file_path" | delta "-w$FZF_PREVIEW_COLUMNS"
    ;;
  "D")
    printf 'New Dir %s\n\n' "$file_path"
    ls "$file_path"
    ;;
  "R")
    echo "File '$file_path' deleted or renamed"
    ;;
  *)
    echo "Unknown git status $status_code"
    ;;
esac

