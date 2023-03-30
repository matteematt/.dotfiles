#!/bin/bash

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

fzfLsPreview() {
	echo "fzf --ansi --tac --header \"$1\" --preview 'CLICOLOR_FORCE=1 ls -al -G --color=auto {}'"
}
