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
