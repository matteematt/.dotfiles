########################################
# SETTINGS & OPTIONS
########################################

setopt NO_CASE_GLOB

export HISTFILE="$HOME/.cache/.zsh_history"
export SAVEHIST=10000
export HISTSIZE=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS

autoload -Uz compinit && compinit
# case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
# partial completion suggestions
zstyle ':completion:*' list-suffixes zstyle ':completion:*' expand prefix suffix

export SSH_KEY_PATH="~/.ssh/rsa_id"

export PATH=/home/linuxbrew/.linuxbrew/bin/:$PATH

# Used for setting the TMP directory the same way as MacOS for vim scripts
export TMPDIR="/tmp/"

########################################
# PROMPT
########################################

function precmd() {
    # Print a newline before the prompt, unless it's the
    # first prompt in the process.
    if [ -z "$NEW_LINE_BEFORE_PROMPT" ]; then
        NEW_LINE_BEFORE_PROMPT=1
    elif [ "$NEW_LINE_BEFORE_PROMPT" -eq 1 ]; then
        print ""
    fi
}

# Add the current time to the right hand side of the prompt
RPROMPT="%*"

# Main prompt
# Green tick or ? with error code
# Current directory name
PROMPT='%(?.%F{green}✓.%F{red}?%?)%f %B%1~%f%b'

# If in a git repo then show the branch name
# and indicate unstaged and staged changes
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '✚ '
zstyle ':vcs_info:*' unstagedstr '● '
zstyle ':vcs_info:*' formats ' %F{blue}(%u%c%b)%f'
zstyle ':vcs_info:*' actionformats ' %F{red}(%u%c%b)%f'
vcs_info
PROMPT+=\$vcs_info_msg_0_
setopt prompt_subst

# Show % or # depending whether the prompt has privileged access
PROMPT+=' %# '

########################################
# ALIAS
########################################

alias update="sudo informant check && sudo pacman -Syu"
# Contains cross platform required aliases
source ~/.dotfiles/shell/.zshrc

########################################
# PROGRAM CONFIG
########################################

# Emscripten
# Adding directories to PATH:
export PATH=$PATH:/home/matt/installs/misc/emsdk
export PATH=$PATH:/home/matt/installs/misc/emsdk/upstream/emscripten
export PATH=$PATH:/home/matt/installs/misc/emsdk/node/12.9.1_64bit/bin

#Setting environment variables:
export EMSDK=/home/matt/installs/misc/emsdk
export EM_CONFIG=/home/matt/.emscripten
export EMSDK_NODE=/home/matt/installs/misc/emsdk/node/12.9.1_64bit/bin/node

########################################
# PLUGINS
########################################


# Setup fzf
# ---------
if [[ ! "$PATH" == */home/linuxbrew/.linuxbrew/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/linuxbrew/.linuxbrew/opt/fzf/bin"
fi
# Auto-completion
# ---------------
# [[ $- == *i* ]] && source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh" 2> /dev/null
# Key bindings
# ------------
source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/key-bindings.zsh"
