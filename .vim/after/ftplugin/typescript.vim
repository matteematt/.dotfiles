setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

function! s:SnipTSDescribe()
	norm idescribe((€kb"€kb'', () => {})€ýakf'a
endfunction
" [s]nippet [d]escribe
nnoremap <buffer> <leader>sd :call <SID>SnipTSDescribe()<CR>
