# Source this file to source all applicable shell configuration in this directory
# Cross platform for OS

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

# Commands
# RipGrep Files
alias rgf="rg -uu --files | rg --invert-match \.git | rg"

# Includes from /shell and their aliases

source ~/.dotfiles/shell/git_extras.sh
source ~/.dotfiles/shell/dir_jumping.sh

#git diff list
alias gdl="getDiffByList"
#git add last
alias gal="addLastDiffFile"
#git update rebase
alias gur="getUpdateWithRebase"
# git view (and) stage
alias gvs="gitViewAndStage"
alias cd="pushChangedDirToList"
alias cdd="changeDirFromHistory"
alias cdf="changeDirShortcut"
alias fcb="~/.dotfiles/shell/switch_branch.sh"
alias gc="git commit"
