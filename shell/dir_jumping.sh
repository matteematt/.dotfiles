# Use fzf to choose a dir to jump to from a list of favourites
function changeDirShortcut {
	chosen_dir=$(cat ~/.dotfiles/shell/fav_dirs_$(uname -s) | fzf | tr -d '[:cntrl:]')
  cd "$chosen_dir"
  unset chosen_dir
}

zmodload -F zsh/datetime p:EPOCHSECONDS
zmodload -F zsh/stat b:zstat
zmodload -F zsh/system b:zsystem

# The directory history is an append-only log of "<dir> <epoch>" lines. Spaces
# in a path are encoded as <spc;> so that every entry stays two fields.
: ${CDHISTORY_FILE:=$HOME/.cache/cdhistory}
# Most recently used directories kept when the log is compacted
: ${CDHISTORY_MAX_ENTRIES:=1000}
# Compact once the log passes this size (~2000 appends at ~73 bytes a line)
: ${CDHISTORY_COMPACT_BYTES:=153600}

# Records the current directory in the history log
# ignores git worktree and /tmp directories
# The entry is a single append, which the OS writes whole, so concurrent shells
# can never interleave or clobber each other's lines. Duplicate entries are
# left to accumulate rather than rewriting the whole log on every `cd`.
function __pushchangeddirToListSave {
  [[ $PWD == *_worktrees_git* ]] && return 0
  [[ $PWD == */tmp* ]] && return 0

  [[ -d ${CDHISTORY_FILE:h} ]] || mkdir -p "${CDHISTORY_FILE:h}"
  print -r -- "${PWD// /<spc;>} $EPOCHSECONDS" >> "$CDHISTORY_FILE"

  # Collapse the accumulated duplicates once the log outgrows its threshold
  local -a log_stat
  if zstat -A log_stat +size "$CDHISTORY_FILE" 2>/dev/null &&
     (( log_stat[1] > CDHISTORY_COMPACT_BYTES )); then
    (__cdhistoryCompact &) &>/dev/null
  fi
  return 0
}

# Rewrites the log keeping the newest entry per directory, capped at the most
# recent CDHISTORY_MAX_ENTRIES
# Only one compaction may run at a time, since two would trample each other's
# output. The lock is never taken on the `cd` path, is skipped rather than
# waited on, and flock drops it automatically if this process dies, so a killed
# compaction cannot wedge the next one.
# The live log is moved aside rather than overwritten, so nothing but an append
# ever writes to it: a concurrent `cd` recreates the log with its own append
# instead of writing into the copy being compacted.
function __cdhistoryCompact {
  local old lockfd
  : >> "$CDHISTORY_FILE.lock"   # flock will not create the lock file itself
  zsystem flock -t 0 -f lockfd "$CDHISTORY_FILE.lock" 2>/dev/null || return 1

  if old=$(mktemp "$CDHISTORY_FILE.compacting.XXXXXX"); then
    if mv -f "$CDHISTORY_FILE" "$old" 2>/dev/null; then
      awk 'NF == 2 && $2 ~ /^[0-9]+$/ { seen[$1] = $2 }
           END { for (dir in seen) print dir, seen[dir] }' "$old" |
        sort -k2,2n | tail -n "$CDHISTORY_MAX_ENTRIES" >> "$CDHISTORY_FILE"
    fi
    rm -f "$old"
  fi

  exec {lockfd}>&-
}

# Prints the history log oldest first, one entry per directory
# Malformed lines and directories that no longer exist are dropped, so neither
# a deleted worktree nor a line spliced by an interrupted compaction can reach
# the jump list
function __cdhistoryList {
  [[ -f $CDHISTORY_FILE ]] || return 0

  local dir
  awk 'NF == 2 && $2 ~ /^[0-9]+$/ { seen[$1] = $2 }
       END { for (dir in seen) print seen[dir], dir }' "$CDHISTORY_FILE" |
    sort -n | tail -n "$CDHISTORY_MAX_ENTRIES" | cut -d" " -f2- |
    while IFS= read -r dir; do
      dir=${dir//<spc;>/ }
      [[ -d $dir ]] && print -r -- "$dir"
    done
  return 0
}

# After a normal 'cd' records the dir in the history log
# "$@" keeps every form of the real cd working: bare `cd` to $HOME, `cd -`,
# `cd -q dir`, and the two argument `cd old new` substitution
# `builtin cd` so that re-sourcing this file after .zshrc has aliased `cd` to
# this function cannot turn the call below into infinite recursion
function pushChangedDirToList {
  builtin cd "$@" || return
  __pushchangeddirToListSave
}

# Use fzf to choose a dir to jump to from the history
function changeDirFromHistory {
  chosen_dir=$(eval "$(fzfLsPreview "History Jump")" <<< "$(__cdhistoryList)")

  # Only proceed if fzf returned a selection (not cancelled with Esc/Ctrl-C)
  if [[ -d "$chosen_dir" ]]; then
    pushChangedDirToList "$chosen_dir"
  fi
}

# Find all directories inside of a git project and jump to it
# Works in a git repo or in a worktree
function changeDirInsideGitProject {
  local ignore_flag=""

  # Parse -I argument
  while getopts "I" opt; do
    case $opt in
      I)
        ignore_flag="-I"
        ;;
      *)
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  if ! top_level="$(git rev-parse --show-toplevel)"; then
    return 1
  fi

  chosen_dir=$(eval "$(fzfLsPreview "Project Jump" "$top_level/")" <<< "$(cd "$top_level" && echo "$(fd --type directory $ignore_flag)
/")" )

  # Only proceed if fzf returned a selection (not cancelled with Esc/Ctrl-C)
  if [[ -n "$chosen_dir" ]]; then
    chosen_dir="$top_level/$chosen_dir"
    if [[ -d "$chosen_dir" ]]; then
      pushChangedDirToList "$chosen_dir"
    fi
  fi
}


# Find all branches inside of the projects _worktrees_git to jump to
function changeWorktreeProject {
  top_level="$(cd "$(pwd | awk -v FS="_worktrees_git/" '{print $1}')" && git rev-parse --show-toplevel)"
  chosen_dir=$(cd "$top_level" && find ./_worktrees_git -type d -exec test -e '{}/.git' ';' -print -prune | cut -c 18- | fzf --header "Worktree Jump" --preview "cd $top_level/_worktrees_git/{} && git log")

  # Only proceed if fzf returned a selection (not cancelled with Esc/Ctrl-C)
  if [[ -n "$chosen_dir" ]]; then
    chosen_dir="$top_level/_worktrees_git/$chosen_dir"
    if [[ -d "$chosen_dir" ]]; then
      pushChangedDirToList "$chosen_dir"
    fi
  fi
}

