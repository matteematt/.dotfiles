# Source this file to source all applicable shell configuration in this directory
# Cross platform for OS

########################################
# SECRETS & Local config
########################################

[ -f "$HOME/.secrets.sh" ] && source "$HOME/.secrets.sh"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
#
########################################
# PLUGINS
########################################

# Used to defer loading of git integration to make loading faster
source ~/.dotfiles/shell/lib/zsh-defer.plugin.zsh

########################################
# SETTINGS & OPTIONS
########################################

setopt NO_CASE_GLOB

# Set up zsh history
export HISTFILE="$HOME/.cache/.zsh_history"
export SAVEHIST=20000
export HISTSIZE=20000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS

# Set coloured man pages
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

########################################
# Completions
########################################

# Configuration for completion system
setup_completion_styles() {
  # case insensitive path-completion
  zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
  # partial completion suggestions
  zstyle ':completion:*' list-suffixes
  zstyle ':completion:*' expand prefix suffix
}

# Create a wrapper function for compdef at the start
# buffering the input and output. This handles the functionality
# before the real function is lazily loaded in
function compdef() {
  [[ -z $compdef_queue ]] && compdef_queue=()
  compdef_queue+=("compdef $*")
}

# Initialize completion system - call directly or via zsh-defer
initialize_completion_system() {
  # Initialize the completion system
  autoload -Uz compinit
  compinit

  # Set up completion styles
  setup_completion_styles

  # Run stored compdef calls
  local compdef_call
  for compdef_call in $compdef_queue; do
    eval $compdef_call
  done
  unset compdef_queue

  # Restore original compdef function
  unfunction compdef
  autoload -Uz compdef
}

# For immediate initialization (Arch Linux)
function setup_immediate_completion() {
  initialize_completion_system
}

# For deferred initialization (macOS)
function setup_deferred_completion() {
  zsh-defer initialize_completion_system
}

##############################
# Open prompt in editor [1]
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

##############################
# Vim keybindings
bindkey -v

# Change the cursor shape depending on the current vim mode [2]
function zle-keymap-select zle-line-init
{
    case $KEYMAP in
        vicmd)      print -n -- "\E]50;CursorShape=0\C-G";;  # block cursor
        viins|main) print -n -- "\E]50;CursorShape=1\C-G";;  # line cursor
    esac

    zle reset-prompt
    zle -R
}
function zle-line-finish
{
    print -n -- "\E]50;CursorShape=0\C-G"  # block cursor
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# Allows you to usebackspace like normal (same as set backspace=indent eol start in vim)
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char

########################################
# PROMPT
########################################

# Add the current time to the right hand side of the prompt
RPROMPT="%*"

# Main prompt
# Green tick or ? with error code
# Current directory name
PROMPT='%(?.%F{green}✓.%F{red}?%?)%f %B%F{cyan}%1~%f%b'

# Initialize empty vcs_info_msg_0_
vcs_info_msg_0_=''

# Function to setup vcs_info
function load_vcs_info() {
    autoload -Uz vcs_info
    precmd_vcs_info() { vcs_info }
    precmd_functions+=( precmd_vcs_info )
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚ '
    zstyle ':vcs_info:*' unstagedstr '● '
    zstyle ':vcs_info:*' formats ' %F{blue}git:(%f%F{167}%m%u%c%b%f%F{blue})%f'
    zstyle ':vcs_info:*' actionformats ' %F{red}git:(%f%F{red}%B%m%u%c%b%f%F{red})%f'
    zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

    # Define the untracked files hook
    +vi-git-untracked() {
        if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
            git status --porcelain | grep -m 1 '^??' &>/dev/null
        then
            hook_com[misc]='? '
        fi
    }

    vcs_info
}

# Defer loading of vcs_info
zsh-defer load_vcs_info

PROMPT+=\$vcs_info_msg_0_
setopt prompt_subst

# Show % or # depending whether the prompt has privileged access
PROMPT+=' %# '

########################################
# ALIAS
########################################

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
source ~/.dotfiles/shell/ai.sh
source ~/.dotfiles/shell/lib/lib.sh

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
alias cdp="changeDirInsideGitProject"
alias cwp="changeWorktreeProject"
alias fcb="~/.dotfiles/shell/switch_branch.sh"
alias gc="git commit"
alias gcm="checkoutPrimaryGitBranch"
alias gsc="gitShowCommits"
# Rebase a branch with all commits since master, so we can squash before we rebase on master (saves multiple merge conflicts)
alias grs='git rebase -i HEAD~$(git rev-list --count master..)'

# tmux attach
alias ta="tmux attach"

alias wipe='clear && printf "\e[3J"'

alias llmc='openLLMinEditor'

# [1]
# https://unix.stackexchange.com/questions/6620/how-to-edit-command-line-in-full-screen-editor-in-zsh

# [2]
# https://unix.stackexchange.com/a/344028

# [3]
# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
# https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/
# https://github.com/zsh-users/zsh/blob/f9e9dce5443f323b340303596406f9d3ce11d23a/Misc/vcs_info-examples#L155-L170
# https://stackoverflow.com/questions/49744179/zsh-vcs-info-how-to-indicate-if-there-are-untracked-files-in-git
