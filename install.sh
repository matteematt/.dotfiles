#!/bin/bash

mkdir -p ~/.cache
mkdir -p ~/.config
mkdir -p ~/.ghc
mkdir -p ~/.sbt/1.0/

# Install dependancies such as fzf here, consider the OS!
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
  mkdir ~/.local/share/fonts
  cp ~/.dotfiles/data/font/* ~/.local/share/fonts/
  sudo fc-cache -fv
  mkdir -p ~/.config/{i3,redshift}

  ln -s ~/.dotfiles/arch/.zshrc ~/.zshrc
  ln -s ~/.dotfiles/arch/redshift/redshift.conf ~/.config/redshift/redshift.conf
  ln -s ~/.dotfiles/arch/.xinitrc ~/.xinitrc
  ln -s ~/.dotfiles/arch/.Xresources ~/.Xresources
  ln -s ~/.dotfiles/arch/i3/config ~/.config/i3
  ln -s ~/.dotfiles/arch/i3/i3blocks.conf ~/.config/i3

  echo "Need to install the systemd service files for redshift and clipmenud"
  echo "These will go somewhere in ~/.config/systemd/user"
  echo "Once you have installed them you need to enable the servies"
  echo "systemctl --user enable redshift.service"
  echo "systemctl --user enable clipmenud.service"
elif [[ "$unamestr" == 'Darwin' ]]; then
  platform='mac'
  brew install coreutils
  brew install rust
  cargo install zellij
  ln -s ~/.dotfiles/config/zellij.yml ~/.config/zellij
fi

brew install fzf
$(brew --prefix)/opt/fzf/install
brew install bat
brew install ripgrep
brew install isacikgoz/taps/tldr

# Get fonts
brew tap homebrew/cask-fonts
# Get the liberation mono nerd font

# Perform the general symlinks here
ln -s ~/.dotfiles/.vim/ ~/.vim
ln -s ~/.dotfiles/.alacritty.yml ~/.alacritty.yml
ln -s ~/.dotfiles/.ctags.d ~/.ctags.d
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/config/haskell/ghci.conf ~/.ghc/ghci.conf
ln -s ~/.dotfiles/config/haskell/haskeline ~/.haskeline
ln -s ~/.dotfiles/config/global.sbt ~/.sbt/1.0/
ln -s ~/.dotfiles/config/nvim ~/.config

# Set the global gitignore
git config --global core.excludesfile ~/.dotfiles/.gitignore_global
git config --global core.editor vim
