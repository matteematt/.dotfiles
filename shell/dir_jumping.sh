# Use fzf to choose a dir to jump to from a list of favourites
function changeDirShortcut {
  chosen_dir=`cat ~/.dotfiles/shell/fav_dirs_$(uname -s) | fzf | tr -d '[:cntrl:]'`
  cd "$chosen_dir"
  unset chosen_dir
}

# Saves the current directory in a history file, ordered by last access time,
# removes duplicates, and keeps the previous 1000
# TODO: Does not work properly on filepaths with a space in
function pushChangedDirToListSave {
  cdhistory="$HOME/.dotfiles/data/cdhistory"
  touch "$cdhistory"
  echo "`pwd` `date +'%s'`" >> "$cdhistory"
  sort -r "$cdhistory" | sort -k1,1 --unique | sort -k 2,2 | tail -n 1000 > "$cdhistory.tmp"
  mv -f "$cdhistory.tmp" "$cdhistory"
}
# After a normal 'cd' calls function to save dir in the background
function pushChangedDirToList {
  cd $1
	(pushChangedDirToListSave &) &>/dev/null
}

# Use fzf to choose a dir to jump to from the history
function changeDirFromHistory {
  cdhistory="$HOME/.dotfiles/data/cdhistory"
  chosen_dir=`rev "$cdhistory" | cut -d" " -f 2- | rev | fzf --tac`
  if [[ -d "$chosen_dir" ]]; then
    cd "$chosen_dir"
  fi
}
