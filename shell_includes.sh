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
alias dcup="docker-compose up"
