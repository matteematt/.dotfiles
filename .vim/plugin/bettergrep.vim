" Search using ripgrep if installed
" Formatted for the vim quickfix window
" Use quotes around your search term to use regex. I can't make this default though
" As I want to be able to pass through file globs for searching too
" Usage examples:
" Search for regex pattern matching either Function or function
" RipGrep '[Ff]unction'
" The same, but only search through markdown files
" RipGrep '[Ff]unction' **/*.md
if g:has_rg
	function! BetterGrep(pattern)
		cgetexpr system("rg --vimgrep -- " . a:pattern)
	endfunction

	command! -nargs=1 RipGrep :call BetterGrep(<q-args>)
	nnoremap <leader>f :RipGrep<space>
endif
