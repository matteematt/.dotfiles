#!/bin/bash

# This shows the matches line in colour and then surrounding lines in greyscale
# but is more resource intensive than line viewer one

# $1 = the current highlighted line in the fzf viewer
# split this by :
# 1st index is the filename
# 2nd index is the line number
# 3rd index is the rest
IFS=':' read -r -a array <<< "$1"; 
file_name="${array[0]}"
# Need to trim away the file icon and the whitespace left behind
file_name="$(echo "$file_name" | tr -dc '`\0-\177`' | tr -d '[:space:]')"
sel_line="${array[1]}"
total_lines="$2"
max_section_len=$((($total_lines - 3) / 2 ))

s1_start=$(($sel_line - $max_section_len ))
[[ $s1_start -lt 0 ]] && s1_start=0
s1_len=$(( $sel_line - $s1_start - 1))

s2_start=$(( $sel_line + 1 ))
printf "  $file_name l:$sel_line\n\n"
[[ $s1_len -eq 0 ]] || bat --theme="OneHalfDark" --style=changes --color never "$file_name" | tail -n +"$s1_start" | head -n "$s1_len"
bat --theme="OneHalfDark" --style=changes --color always "$file_name" | tail -n +"${array[1]}" | head -n 1
bat --theme="OneHalfDark" --style=changes --color never "$file_name" | tail -n +"$s2_start" | head -n "$max_section_len"
