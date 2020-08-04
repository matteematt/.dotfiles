" Make a quick and simple file picker using the quickfix menu and
" rg. Quickfix menu is automatically opened due to autocmd in 
" bettergrep.vim

if executable('rg')
	function! FindFile(...)
		let rgcmd="rg -uu --files | rg --invert-match \.git | rg ".join(a:000, ' ')." | awk '{print $1\":0:0\"}'"
		echo rgcmd
		return system(rgcmd)
	endfunction

	command! -nargs=+ FilePicker cgetexpr [] <bar> caddexpr FindFile(<f-args>) <bar> cwindow

	nnoremap <leader>o :FilePicker<space>
endif
