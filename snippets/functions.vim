"Contains the functions which call the snippets in VIM

" Go to the neareset replace point and be ready to replace
nnoremap <leader>ss /<<$\d<CR>ca"

" React scripts

" imports imrc
nnoremap <leader>sreacti :-1read ~/.vim/snippets/javascript/react_imports.jsx<CR>o<Esc>
" import react class
nnoremap <leader>sreactc :-1read ~/.vim/snippets/javascript/react_class.jsx<CR>
" import react functional stateless component
nnoremap <leader>sreactf :-1read ~/.vim/snippets/javascript/react_fsc.jsx<CR>

" import enzyme and jest boilerplate
nnoremap <leader>senzyme :-1read ~/.vim/snippets/javascript/jest_boilerplate.js<CR>
