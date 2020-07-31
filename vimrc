" Enabling filetype support provides filetype-specific indenting,
" syntax highlighting, omni-completion and other useful settings.
filetype plugin indent on
syntax on

" `matchit.vim` is built-in so let's enable it!
" Hit `%` on `if` to jump to `else`.
runtime macros/matchit.vim

" Get the OS
if !exists("g:os")
  if has("win64") || has("win32") || has("win16")
    let g:os = "Windows"
  else
    let g:os = substitute(system('uname'), '\n', '', '')
  endif
endif

" Set different cursors for different modes
if g:os == "Darwin"
  " MacOS
  "Mode Settings
  let &t_SI.="\e[5 q" "SI = INSERT mode
  let &t_SR.="\e[4 q" "SR = REPLACE mode
  let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)
elseif g:os == "Linux"
  let &t_SI = "\<Esc>[6 q"
  let &t_SR = "\<Esc>[4 q"
  let &t_EI = "\<Esc>[2 q"
endif

" various settings
set autoindent                 " Minimal automatic indenting for any filetype.
set smartindent 		" smart indent for better indenting
set backspace=indent,eol,start " Proper backspace behavior.
set hidden                     " Possibility to have more than one unsaved buffers.
set incsearch                  " Incremental search, hit `<CR>` to stop.
set ruler                      " Shows the current line number at the bottom-right
                               " of the screen.
set wildmenu                   " Great command-line completion, use `<Tab>` to move
set wildmode=longest:full,full
                               " around and `<CR>` to validate
set relativenumber             " add relative numbers 
set number	                   " shows the absolute number for the current line
set shiftwidth=2								" sets the shift tab and indent width to 2
set tabstop=2
set softtabstop=2
if &history < 1000
	set history = 1000
endif

" You must create the dir set, it will not do it for you!
if has('persistent_undo')      "check if your vim version supports it
  set undodir=$HOME/.vim/undo  "directory where the undo files will be stored
  set undofile                 "turn on the feature
  :silent call system('mkdir -p ' . &undodir)
endif	

" Turn off comments automatically continuing onto the next line
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" keybindings
let mapleader = ","

" Open split and get focus, remap the window movement keys
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

 " Highlight the last inserted text
 nnoremap gV `[v`]`
