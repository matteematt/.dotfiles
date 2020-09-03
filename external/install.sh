#!/bin/bash

shopt -s extglob

for D in ./undotree-master/*; do
	if [ -d "${D}" ]; then
		cp -r "${D}/"* "$HOME/.vim/${D##*/}/"
	fi
done

git clone https://github.com/sheerun/vim-polyglot ~/.vim/pack/default/start/vim-polyglot
