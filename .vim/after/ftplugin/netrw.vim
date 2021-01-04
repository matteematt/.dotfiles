" Navigate forwards and backwards through the directory with h and l
" q to quit
" f to create a new file
" (+ to create a dir)
" (D to delete a dir)
nmap <buffer> h -
nmap <buffer> l <CR>
nmap <buffer> q :bd<CR>
map <buffer> f :normal %<CR>
