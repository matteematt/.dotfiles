augroup openhelp
	au!
	autocmd! BufEnter * if &ft ==# 'help' | wincmd L | endif
augroup END
