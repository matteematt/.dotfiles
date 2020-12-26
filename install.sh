#!/bin/bash

mkdir -p ~/.cache
mkdir -p ~/.config

# Install dependancies such as fzf here, consider the OS!
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
  cp ~/.dotfiles/Monaco\ Nerd\ Font\ Complete\ Mono.otf ~/.local/share/fonts
  sudo fc-cache -fv
  ln -s ~/.dotfiles/arch/.zshrc ~/.zshrc
  mkdir -p ~/.config/{i3,terminator,redshift}
  systemctl --user enable redshift.service
  ln -s ~/.dotfiles/arch/.config/redshift.conf ~/.config/redshift/redshift.conf
elif [[ "$unamestr" == 'Darwin' ]]; then
  platform='mac'
fi

brew install fzf
$(brew --prefix)/opt/fzf/install
brew install bat
brew install ripgrep
brew install isacikgoz/taps/tldr

# Get fonts
brew tap homebrew/cask-fonts
# Get the liberation mono nerd font

# Perform the symlinks here
ln -s ~/.dotfiles/.vim/ ~/.vim
ln -s ~/.dotfiles/.alacritty.yml ~/.alacritty.yml
ln -s ~/.dotfiles/.ctags.d ~/.ctags.d
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/arch/.xinitrc ~/.xinitrc
ln -s ~/.dotfiles/arch/.Xresources ~/.Xresources
ln -s ~/.dotfiles/arch/i3/config ~/.config/i3
ln -s ~/.dotfiles/arch/i3/i3blocks.conf ~/.config/i3
ln -s ~/.dotfiles/arch/terminator/config ~/.config/terminator

# Other

# ZSH plugins
#git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set the global gitignore
git config --global core.excludesfile ~/.dotfiles/.gitignore_global
git config --global core.editor vim
