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
	brew install fd
	brew install delta
  cargo install zellij
  ln -s ~/.dotfiles/config/zellij.yml ~/.config/zellij
  ln -s ~/.dotfiles/mac/.zshrc ~/.zshrc

	echo "Need to install cron job for ~/.dotfiles/mac/device_battery_checker.sh"
fi

brew install fzf
$(brew --prefix)/opt/fzf/install
brew install bat
brew install ripgrep
brew install yq
brew install isacikgoz/taps/tldr

# Get fonts
brew tap homebrew/cask-fonts
# Get the liberation mono nerd font

# Perform the general symlinks here
ln -s ~/.dotfiles/config/alacritty/config.toml ~/.alacritty.toml
ln -s ~/.dotfiles/config/haskell/ghci.conf ~/.ghc/ghci.conf
ln -s ~/.dotfiles/config/haskell/haskeline ~/.haskeline
ln -s ~/.dotfiles/config/global.sbt ~/.sbt/1.0/
ln -s ~/.dotfiles/config/nvim ~/.config
ln -s ~/.dotfiles/config/tmux/ ~/.config

# Set up global git commands
git config --global core.excludesfile ~/.dotfiles/config/git/.gitignore_global
git config --global core.hooksPath ~/.dotfiles/config/git/hooks
git config --global core.editor vim

git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle "diff3"
git config --global diff.colorMoved "default"
git config --global delta.side-by-side true
