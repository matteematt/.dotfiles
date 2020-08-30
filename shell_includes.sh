function getDiffByList {
  chosen_file=`git status -s | rev | cut -d" " -f1 | rev | fzf`
  if [ -z "$chosen_file" ]; then
    return
  fi
  status_code=`git status -s | grep $chosen_file | awk '{print $1}'`
  if [[ "$status_code" == "M" ]]; then
    #If modified this file already exists, so show diff
    git diff $chosen_file | bat
  else
    #Might not have diff so just show file
    bat $chosen_file
  fi
}

function addLastDiffFile {
  if [[ -v chosen_file ]];
  then
    git add $chosen_file
    unset chosen_file
    unset status_code
  else
    echo "No previous file diffed"
  fi
}

# Performs the same job as the update button on giuthub when a branch
# is behind master, but with rebase instead
function getUpdateWithRebase {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git checkout master
  git pull
  git checkout $branch
  git rebase origin/master
  git push --force-with-lease
}

#git diff list
alias gdl="getDiffByList"
#git add last
alias gal="addLastDiffFile"
#git update rebase
alias gur="getUpdateWithRebase"

function changeDirShortcut {
  chosen_dir=`cat ~/dotfiles/shell/fav_dirs_$(uname -s) | fzf | tr -d '[:cntrl:]'`
  cd "$chosen_dir"
  unset chosen_dir
}

alias cdf="changeDirShortcut"

# Docker alias
alias dcup="docker-compose up -V"

function dockerContainerNuke {
  docker stop $(docker ps -a -q)
  docker rm -f $(docker ps -a -q)
}

function dockerImageNuke {
  docker rmi -f $(sudo docker images -a -q)
}

alias dcnuke="dockerContainerNuke"
alias dinuke="dockerImageNuke"

function choosedToolboxScript {
  chosen_script=`ls ~/toolbox/script/ | fzf`
  echo "Exec script $chosen_script"
  if [[ -z "$chosen_script" ]]; then
  else
    eval "~/toolbox/script/$chosen_script"
  fi
}
alias toolbox="choosedToolboxScript"

# TODO: Does not work properly on filepaths with a space in
function pushChangedDirToListSave {
  cdhistory="$HOME/dotfiles/data/cdhistory"
  touch "$cdhistory"
  echo "`pwd` `date +'%s'`" >> "$cdhistory"
  sort -r "$cdhistory" | sort -k1,1 --unique | sort -k 2,2 | tail -n 1000 > "$cdhistory.tmp"
  mv -f "$cdhistory.tmp" "$cdhistory"
}
function pushChangedDirToList {
  cd $1
	(pushChangedDirToListSave &) &>/dev/null
}
alias cd="pushChangedDirToList"

function changeDirFromHistory {
  cdhistory="$HOME/dotfiles/data/cdhistory"
  chosen_dir=`rev "$cdhistory" | cut -d" " -f 2- | rev | fzf --tac`
  if [[ -d "$chosen_dir" ]]; then
    cd "$chosen_dir"
  fi
}
alias cdd="changeDirFromHistory"

# Commands
# RipGrep Files
alias rgf="rg -uu --files | rg --invert-match \.git | rg"

# Platform specific incldues
source ~/dotfiles/shell/$(uname -s)_includes.sh
