#!/bin/bash

# Install dependancies such as fzf here, consider the OS!
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
  cp Monaco\ Nerd\ Font\ Complete\ Mono.otf ~/.local/share/fonts
  sudo fc-cache -fv
  gsettings set org.gnome.desktop.interface monospace-font-name "Monaco Nerd Font Mono 11"
elif [[ "$unamestr" == 'Darwin' ]]; then
  platform='mac'
fi

brew install fzf
$(brew --prefix)/opt/fzf/install
brew install bat
brew install ripgrep

# Get fonts
brew tap homebrew/cask-fonts
# Get the liberation mono nerd font

# Perform the symlinks here
ln -s ~/dotfiles/.vimrc ~/.vimrc
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/arch/.xinitrc ~/.xinitrc
ln -s ~/dotfiles/arch/.Xresources ~/.Xresources

# Other

# Set the global gitignore
git config --global core.excludesfile ~/dotfiles/.gitignore_global

