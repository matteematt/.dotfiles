" My test of fzf using the vim inbuilt terminal 
" This is no longer used because a better way is just to use fzf through the shell and a temporary file
" the below script is left because it demonstrates using the terminal api to communicate

"""""" ./test.sh
"#!/bin/sh
"
"#chosen_file=`rg -uu --files | rg --invert-match \.git | fzf`
"chosen_file=`fzf`
"
"# <ESC> = CTRL-V ESC
"# ^G = CTRL-V 007 (bell character)
"# printf '<ESC>]51;["call", "cmd" [...args]<07>'
"signal=`printf ']51;["call", "Tapi_recieveFileToEdit", ["%s", 14]]' "$chosen_file"`
"echo $signal

if 0
	function Tapi_recieveFileToEdit(bufnum, arglist)
		echo a:arglist
		if a:arglist[0] != ''
			let fileToEdit=a:arglist[0]
			execute 'silent e' l:fileToEdit
		endif
	endfunc

	function StartTerminalFilePicker()
		enew
		call term_start('./test.sh', {'term_name': 'choose file', 'term_finish': 'close', 'curwin': 1})
		"call term_start('./test.sh', {'term_name': 'choose file', 'curwin': 1})
	endfunc

endif
