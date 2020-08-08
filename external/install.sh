#!/bin/bash

shopt -s extglob

for D in ./undotree-master/*; do
	if [ -d "${D}" ]; then
		cp -r "${D}/"* "$HOME/.vim/${D##*/}/"
	fi
done


