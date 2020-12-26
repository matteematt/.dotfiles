export SSH_KEY_PATH="~/.ssh/rsa_id"

alias update="sudo informant check && sudo pacman -Syu"

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

#Turn off caps lock
#To enable caps lock exec $ setxkbmap -option
#setxkbmap -option ctrl:nocaps

source ~/.dotfiles/shell/.zshrc

export PATH=/home/linuxbrew/.linuxbrew/bin/:$PATH

# Set the system for the interactive tldr man pages
export TLDR_OS=linux

# Used for setting the TMP directory the same way as MacOS for vim scripts
export TMPDIR="/tmp/"

# Adding directories to PATH:
export PATH=$PATH:/home/matt/installs/misc/emsdk
export PATH=$PATH:/home/matt/installs/misc/emsdk/upstream/emscripten
export PATH=$PATH:/home/matt/installs/misc/emsdk/node/12.9.1_64bit/bin

#Setting environment variables:
export EMSDK=/home/matt/installs/misc/emsdk
export EM_CONFIG=/home/matt/.emscripten
export EMSDK_NODE=/home/matt/installs/misc/emsdk/node/12.9.1_64bit/bin/node

# Adding fzf to path
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
