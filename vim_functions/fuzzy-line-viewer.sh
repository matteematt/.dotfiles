#!/bin/bash

# $1 = the current highlighted line in the fzf viewer
# split this by :
# 1st index is the filename
# 2nd index is the line number
# 3rd index is the rest
IFS=':' read -r -a array <<< "$1"; 
file_name="${array[0]}"
# Need to trim away the file icon and the whitespace left behind
file_name="$(echo "$file_name" | tr -dc '`\0-\177`' | tr -d '[:space:]')"
printf "  $file_name l:${array[1]}\n\n"
bat --theme="OneHalfDark" --style=changes --color always "$file_name" | tail -n +"${array[1]}" | head -n 20
