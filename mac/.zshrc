source ~/.dotfiles/shell/.zshrc

export PATH="$PATH:/Users/mwa75/.cargo/bin"

alias vim='/Applications/MacVim.app/Contents/MacOS/Vim'
alias ls="ls -G"

precmd() { print "" }
RPROMPT="%*"

########################################
# PLUGINS
########################################

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Setup shell prompt suggestions using history
# Requires cloning git repo
source ~/installs/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

export SBT_OPTS="-Xmx4G -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -Xss2M -Duser.timezone=GMT -Xmx6144m"

# Setup zsh-syntax-highlighting
# Requires installing via pacman or AUR
# Sourcing this must be at the end of the .zshrc
source /usr/local/Cellar/zsh-syntax-highlighting/0.7.1/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
