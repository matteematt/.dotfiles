" Make a quick and simple file picker using the quickfix menu and
" rg. Quickfix menu is automatically opened due to autocmd in 
" bettergrep.vim

if executable('rg')
	function! FindFile(args)
		let rgcmd="rg -uu --files | rg --invert-match \.git | rg"
		return system(join([rgcmd] + a:000), ' ')
	endfunction

	command! -nargs=+ FilePicker cgetexpr FindFile(<f-args>)
endif
