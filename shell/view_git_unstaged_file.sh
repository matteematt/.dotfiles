#!/bin/sh
# Used in gitViewAndStage and getDiffByList
# Prints unstaged git file according to the git status
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# else prints error message

# Expected input examples, a status code and a path separated by a tab
# M	~/test.txt
# R	~/my banana.txt

# if $FZF_PREVIEW_COLUMNS doesn't exist set it to be tput cols
# this is dependent on whether it runs via gitViewAndStage or getDiffByList
FZF_PREVIEW_COLUMNS=${FZF_PREVIEW_COLUMNS:-$(tput cols)}

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

