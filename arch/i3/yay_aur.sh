#!/bin/bash

updates=`yay -Qu | wc -l`

# full test, short text, colour, (background colour, not set)
[ "$updates" -ne "0" ] \
  && echo " $updates aur update$([ "$updates" -eq "1" ] && echo "" || echo "s")"
[ "$updates" -ne "0" ] && echo "$updates"
[ "$updates" -ne "0" ] && echo "#FF1000"
