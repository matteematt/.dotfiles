" My test of fzf using the vim inbuilt terminal 

if has('terminal')

	function Tapi_recieveFileToEdit(bufnum, arglist)
		"echo a:bufnum
		execute 'close'
		if a:arglist[0] != ''
			let fileToEdit=a:arglist[0]
			execute 'silent e' l:fileToEdit
		endif
	endfunc

	nnoremap <leader>o :call term_start('./test.sh', {'term_finish':'close', 'term_name': 'choose file'})<Enter>
endif
