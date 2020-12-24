export SSH_KEY_PATH="~/.ssh/rsa_id"

alias cadence="ssh -X mtw30@eesv-cadence-t.bath.ac.uk"
alias xampp="sudo /opt/lampp/manager-linux-x64.run"
alias skillbranch="ssh sb17ab@160.153.162.140 -p 22"
alias matlab="/usr/local/MATLAB/R2018b/bin/matlab -softwareopengl"

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
