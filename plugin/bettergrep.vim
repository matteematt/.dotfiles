if executable('rg')
	set grepprg=rg\ --vimgrep
endif

function! BetterGrep(...)
	return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
endfunction

" ! allows command to take a bang modifier like :q!
" -nargs=+    Arguments must be supplied, but any number are allowed
" -complete=file_in_path	file and directory names in |'path'|
" -bar allows | to chain command
" cgetexpr fills the expression into the quickfixes menu
command! -nargs=+ -complete=file_in_path BetterGrep cgetexpr BetterGrep(<f-args>)
command! -nargs=+ -complete=file_in_path LBetterGrep lgetexpr BetterGrep(<f-args>)

" Automatically open the quickfix window with the expr is activated
" Automatically close the quickfix window when an item is selected
augroup quickfix
	autocmd!
	autocmd QuickFixCmdPost cgetexpr cwindow
	autocmd QuickFixCmdPost lgetexpr lwindow
	autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>
augroup END

nnoremap <leader>f :BetterGrep  **<left><left><left>
