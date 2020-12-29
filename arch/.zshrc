########################################
# SETTINGS & OPTIONS
########################################

setopt NO_CASE_GLOB

# Set up zsh history
export HISTFILE="$HOME/.cache/.zsh_history"
export SAVEHIST=10000
export HISTSIZE=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS

# Autocompletion behaviour when pressing tab
autoload -Uz compinit && compinit
# case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
# partial completion suggestions
zstyle ':completion:*' list-suffixes zstyle ':completion:*' expand prefix suffix

# Shell settings
export SSH_KEY_PATH="~/.ssh/rsa_id"
export PATH=/home/linuxbrew/.linuxbrew/bin/:$PATH
# Used for setting the TMP directory the same way as MacOS for vim scripts
export TMPDIR="/tmp/"
export EDITOR="vim"

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

# If in a git repo then show the branch name [3]
# and indicate unstaged, staged, and untracked change
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '✚ '
zstyle ':vcs_info:*' unstagedstr '● '
zstyle ':vcs_info:*' formats ' %F{blue}(%m%u%c%b)%f'
zstyle ':vcs_info:*' actionformats ' %F{%mred}(%m%u%c%b)%f'
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
vcs_info
PROMPT+=\$vcs_info_msg_0_
setopt prompt_subst

+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep -m 1 '^??' &>/dev/null
    then
        hook_com[misc]='? '
    fi
}


# Show % or # depending whether the prompt has privileged access
PROMPT+=' %# '

########################################
# ALIAS
########################################

alias update="sudo informant check && sudo pacman -Syu"
alias ls="ls --color=auto"
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

# Setup zsh-syntax-highlighting
# Requires cloning git repo
source ~/installs/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

# Setup zsh-syntax-highlighting
# Requires installing via pacman or AUR
# Sourcing this must be at the end of the .zshrc
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# [1]
# https://unix.stackexchange.com/questions/6620/how-to-edit-command-line-in-full-screen-editor-in-zsh

# [2]
# https://unix.stackexchange.com/a/344028

# [3]
# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
# https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/
# https://github.com/zsh-users/zsh/blob/f9e9dce5443f323b340303596406f9d3ce11d23a/Misc/vcs_info-examples#L155-L170
# https://stackoverflow.com/questions/49744179/zsh-vcs-info-how-to-indicate-if-there-are-untracked-files-in-git
