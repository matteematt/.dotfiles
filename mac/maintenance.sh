#!/bin/bash

echo "updating"
brew update && brew upgrade

echo -e "\\nbackup files and package names"
brew list --versions > ~/.dotfiles/mac/brewlist.txt
rsync -av  $HOME/.cache/ $HOME/.cache.backup/

echo -e "\\nUpdate nvim packages with"
echo "nvim $HOME/.dotfiles/config/nvim/lua/user/plugins.lua"
