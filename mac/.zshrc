source ~/.dotfiles/shell/.zshrc

alias vim='/Applications/MacVim.app/Contents/MacOS/Vim'
alias ls="ls -G"

precmd() { print "" }
RPROMPT="%*"

########################################
# PLUGINS
########################################

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Setup shell prompt suggestions using history
# Requires cloning git repo
source ~/installs/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

# Setup zsh-syntax-highlighting
# Requires installing via pacman or AUR
# Sourcing this must be at the end of the .zshrc
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
