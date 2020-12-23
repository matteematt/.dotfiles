#!/bin/zsh
# https://github.com/junegunn/fzf/wiki/Examples#git
# fcb - checkout git branch (including remote branches)
local branches branch
branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
    fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
