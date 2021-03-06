#!/bin/bash

shopt -s extglob

for D in ./undotree-master/*; do
	if [ -d "${D}" ]; then
		cp -r "${D}/"* "$HOME/.dotfiles/.vim/${D##*/}/"
	fi
done

git clone https://github.com/sheerun/vim-polyglot ~/.dotfiles/.vim/pack/default/start/vim-polyglot
