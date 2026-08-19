#!/bin/sh
# Used in gitViewAndStage, both for its preview window and for its ctrl-o
# Prints unstaged git file according to the git status
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# Unmerged file - names the conflict and views the diff of both sides
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

# Views a file as it stands in the working tree
viewWorkingTreeFile() {
  bat --theme="OneHalfDark" --style=numbers,changes --color always "$1"
}

# A tab is what separates the two, as a path is allowed to contain spaces.
# fzf already quotes the line it passes in, so it arrives as a single argument
# with no quoting of its own to undo
status_code=`printf '%s' "$1" | cut -f1`
file_path=`printf '%s' "$1" | cut -f2-`
case "$status_code" in
  "U")
    viewWorkingTreeFile "$file_path"
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
  "C")
    # The listing collapses all seven unmerged states into one code, so ask git
    # which one this is: the diff below shows what each side did but not which
    # side dropped the file, and that is what deciding to stage turns on. It
    # also settles how to show the file, as git only has a diff for the two
    # states holding content on both sides of the merge - for the rest it
    # prints "* Unmerged path" and nothing else, leaving the content that
    # survived as all there is to go on
    case "`git status --porcelain -- "$file_path" | head -n 1 | cut -c1-2`" in
      "DD") echo "Unmerged: deleted on both sides"; view=file ;;
      "AU") echo "Unmerged: added by us"; view=file ;;
      "UD") echo "Unmerged: deleted by them"; view=file ;;
      "UA") echo "Unmerged: added by them"; view=file ;;
      "DU") echo "Unmerged: deleted by us"; view=file ;;
      "AA") echo "Unmerged: added on both sides"; view=diff ;;
      *) echo "Unmerged: modified on both sides"; view=diff ;;
    esac
    echo
    if [ ! -e "$file_path" ]; then
      echo "Not in the working tree, so staging it accepts the deletion"
    elif [ "$view" = "diff" ]; then
      # delta renders the combined diff as one pane per side of the merge,
      # which reads better than the raw conflict markers
      git diff --text -- "$file_path" | delta "-w$FZF_PREVIEW_COLUMNS"
    else
      viewWorkingTreeFile "$file_path"
    fi
    ;;
  *)
    echo "Unknown git status $status_code"
    ;;
esac

