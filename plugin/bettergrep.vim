if executable('rg')
	function! BetterGrep(pattern)
		cgetexpr system("rg --vimgrep " . a:pattern)
	endfunction

	nnoremap <leader>f :call BetterGrep("")<left><left>
endif
