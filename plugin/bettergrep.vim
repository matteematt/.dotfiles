if executable('rg')
	set grepprg=rg\ --vimgrep
endif

function! BetterGrep(...)
	return system(join([&grepprg] + a:000), ' ')
endfunction

" ! allows command to take a bang modifier like :q!
" -nargs=+    Arguments must be supplied, but any number are allowed
" -complete=file_in_path	file and directory names in |'path'|
" -bar allows | to chain command
command! -nargs=+ -complete=file_in_path BetterGrep cgetexpr BetterGrep(<f-args>)
command! -nargs=+ -complete=file_in_path LBetterGrep lgetexpr BetterGrep(<f-args>)
