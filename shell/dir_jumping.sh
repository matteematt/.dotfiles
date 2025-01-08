# Use fzf to choose a dir to jump to from a list of favourites
function changeDirShortcut {
	chosen_dir=$(cat ~/.dotfiles/shell/fav_dirs_$(uname -s) | fzf | tr -d '[:cntrl:]')
  cd "$chosen_dir"
  unset chosen_dir
}

# Saves the current directory in a history file, ordered by last access time,
# removes duplicates, and keeps the previous 1000
# ignores git worktree directories
function __pushchangeddirToListSave {
	# return from function if the current working directory contains _worktrees_git
	if [[ $(pwd) == *"_worktrees_git"* ]] && return;
	# return from funtion if the current working directory contains /tmp
	if [[ $(pwd) == *"/tmp"* ]] && return;
  cdhistory="$HOME/.cache/cdhistory"
  touch "$cdhistory"
	echo "$(pwd | sed 's/ /<spc;>/g') $(date +'%s')" >> "$cdhistory"
  sort -r "$cdhistory" | sort -k1,1 --unique | sort -k 2,2 | tail -n 1000 > "$cdhistory.tmp"
  mv -f "$cdhistory.tmp" "$cdhistory"
}

# After a normal 'cd' calls function to save dir in the background, unless in a worktree
function pushChangedDirToList {
  cd "$1"
	(__pushchangeddirToListSave &) &>/dev/null
}

# Use fzf to choose a dir to jump to from the history
function changeDirFromHistory {
  cdhistory="$HOME/.cache/cdhistory"
	chosen_dir=$(eval "$(fzfLsPreview "History Jump")" <<< "$(rev "$cdhistory" | cut -d" " -f 2-  | rev | sed 's/<spc;>/ /g')" )
  if [[ -d "$chosen_dir" ]]; then
		pushChangedDirToList "$chosen_dir"
  fi
}

# Find all directories inside of a git project and jump to it
# Works in a git repo or in a worktree
function changeDirInsideGitProject {
  if ! top_level="$(git rev-parse --show-toplevel)"; then
    return 1
  fi
  chosen_dir=$(eval "$(fzfLsPreview "Project Jump" "$top_level/")" <<< "$(cd "$top_level" && echo "$(fd --type directory)\n/")" )

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

