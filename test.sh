#!/bin/sh

chosen_file=`rg -uu --files | rg --invert-match \.git | rg vim | fzf`

# <ESC> = CTRL-V ESC
# ^G = CTRL-V 007 (bell character)
# printf '<ESC>]51;["call", "cmd" [...args]<07>'
signal=`printf ']51;["call", "Tapi_recieveFileToEdit", ["%s", 14]]' "$chosen_file"`
echo $signal
