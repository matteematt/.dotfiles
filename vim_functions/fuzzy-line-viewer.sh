#!/bin/bash

# $1 = the current highlighted line in the fzf viewer
# split this by :
# 1st index is the filename
# 2nd index is the line number
# 3rd index is the rest
IFS=':' read -r -a array <<< "$1"; 
printf "  ${array[0]} l:${array[1]}\n\n"
bat --theme="OneHalfDark" --style=changes --color always "${array[0]}" | tail -n +"${array[1]}" | head -n 20
