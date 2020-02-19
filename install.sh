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
brew install isacikgoz/taps/tldr

# Get fonts
brew tap homebrew/cask-fonts
# Get the liberation mono nerd font

# Perform the symlinks here
ln -s ~/dotfiles/.vimrc ~/.vimrc
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/arch/.xinitrc ~/.xinitrc
ln -s ~/dotfiles/arch/.Xresources ~/.Xresources
ln -s ~/dotfiles/arch/i3/config ~/.config/i3
ln -s ~/dotfiles/arch/i3/i3blocks.conf ~/.config/i3
ln -s ~/dotfiles/arch/terminator/config ~/.config/terminator

# Check that vim snippets are added to ~/.vim/snippets but it looks like that is done automatically

# Other

# ZSH plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set the global gitignore
git config --global core.excludesfile ~/dotfiles/.gitignore_global
