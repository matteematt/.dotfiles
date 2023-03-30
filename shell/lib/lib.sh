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

# Use FZF to preview a list of directories using `eval` where you pipe in using <<< the directories stream
# See usage in `changeDirInsideGitProject` as an example.
# `CLICOLOR_FORCE=1` is needed to force color output in `ls`, along with `-G` for mac and `--color=auto` for linux
# `--ansi` is needed to force color output in fzf reading the ANSI colour codes
# `"$1"` sets the title shown in the fzf box.
# `"$2"` optionally sets a directory to the text in fzf to preview (for example to prepend the project root).
fzfLsPreview() {
	echo "fzf --ansi --tac --header \"$1\" --preview 'CLICOLOR_FORCE=1 ls -al -G --color=auto $2{}'"
}
