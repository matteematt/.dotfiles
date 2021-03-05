function! Test(A,L,P) abort
	let buffText = []
	for bufIndex in range(1, bufnr('$'))
		" filter buffers with non-blank buftype, such as help
		if bufexists(bufIndex) &&
					\ (getbufvar(bufIndex, '&buftype', 'error') == '' ||
					\ getbufvar(bufIndex, '&buftype', 'error') == 'terminal')
			call add(buffText, bufname(bufIndex))
		endif
	endfor
	if len(a:A) > 0 && exists("*matchfuzzy")
		return matchfuzzy(buffText, a:A)
	else
		return buffText
	endif
endfunction

function! SwitchToBuffer(args) abort
	let changeTo = len(a:args) < 1 ? '#' : a:args
	execute ":buffer " . changeTo
endfunction

" <C-z> is my wildcharm
command! -nargs=? -bar -complete=customlist,Test FuzzyBuffer call SwitchToBuffer(<q-args>)
nnoremap <leader><leader> :FuzzyBuffer<space><C-z>
