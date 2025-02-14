#!/bin/bash

echo "updating"
brew update && brew upgrade

echo -e "\\nbackup files and package names"
brew list --versions > ~/.dotfiles/mac/brewlist.txt
rsync -av  $HOME/.cache/ $HOME/.cache.backup/

if command -v llm >/dev/null 2>&1; then
    echo "Updating llm"
		# llm install llm-claude-3
		# llm models default claude-3-5-sonnet-latest
		llm install llm-gemini
		llm models default gemini-2.0-flash
else
    echo "llm is not installed"
fi


echo -e "\\nUpdate nvim packages with"
echo "nvim $HOME/.dotfiles/config/nvim/lua/user/plugins.lua"
