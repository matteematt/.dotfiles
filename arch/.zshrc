source ~/.dotfiles/shell/.zshrc

# Shell settings
export SSH_KEY_PATH="~/.ssh/rsa_id"
export PATH=/home/linuxbrew/.linuxbrew/bin/:$PATH
# Used for setting the TMP directory the same way as MacOS for vim scripts
export TMPDIR="/tmp/"
export EDITOR="vim"

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
########################################
# ALIAS
########################################

alias update="sudo informant check && sudo pacman -Syu && yay -Syu"
alias ls="ls --color=auto --human-readable"
alias icloud="firefox -P default https://www.icloud.com/notes &"
alias windows="systemctl reboot --boot-loader-entry=auto-windows"

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
# Requires fzf from linuxbrew
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

# Setup shell prompt suggestions using history
# Requires cloning git repo
source ~/installs/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

# Setup zsh-syntax-highlighting
# Requires installing via pacman or AUR
# Sourcing this must be at the end of the .zshrc
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
