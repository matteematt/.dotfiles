" Launch python three straight away so vim launches in python 3 mode instead of python 2
if has('python3')
python3 << endPy
endPy
endif

filetype off  " required
let mapleader = ","

set encoding=UTF-8

"=== OS Specific Settings

" Get the OS
if !exists("g:os")
  if has("win64") || has("win32") || has("win16")
    let g:os = "Windows"
  else
    let g:os = substitute(system('uname'), '\n', '', '')
  endif
endif

if g:os == "Darwin"
  " MacOS
  "Mode Settings
  let &t_SI.="\e[5 q" "SI = INSERT mode
  let &t_SR.="\e[4 q" "SR = REPLACE mode
  let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)
  " fzf location for OSX
  set rtp+=/usr/local/opt/fzf
elseif g:os == "Linux"
  let &t_SI = "\<Esc>[6 q"
  let &t_SR = "\<Esc>[4 q"
  let &t_EI = "\<Esc>[2 q"
  set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf
endif

"=== Plugins

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" insert or delete brackets, parens, quotes in pair
Plugin 'jiangmiao/auto-pairs'
" Devicons needed for preview with fzf
Plugin 'ryanoasis/vim-devicons'
" Wrapper for Fzf
Plugin 'junegunn/fzf.vim'
" Plugin for formatting files such as javascrupt files
Plugin 'prettier/vim-prettier'
" Plugin for doing line commeting, <leader>cc and <leader>cu
Plugin 'scrooloose/nerdcommenter'
" Displays the git status icons next to files in NERDTree
Plugin 'Xuyuanp/nerdtree-git-plugin'
" Adds rainbow matching brackets
Plugin 'luochen1990/rainbow'
" PluginManager for vim
Plugin 'VundleVim/Vundle.vim'
" Defines functions which are used in other scripts
Plugin 'vim-scripts/L9'
" Used as a file expolorer
Plugin 'scrooloose/nerdtree'
" Show git diff inmfo at the side
Plugin 'mhinz/vim-signify'
" Surround for html tags
Plugin 'tpope/vim-surround'
" Show the colour in css
Plugin 'ap/vim-css-color'
" Multiple selections like from sublime text, <C-n>
Plugin 'terryma/vim-multiple-cursors'
" Show info in the statusbar
Plugin 'bling/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
" Highlight match tags in html files
Plugin 'gregsexton/matchtag'
" Large but fast syntax language pack
Plugin 'sheerun/vim-polyglot'
" Opens a tree view to look at undos
Plugin 'mbbill/undotree'
" Allows easy viewing of marks
Plugin 'Yilin-Yang/vim-markbar'
" Autocompletion, has a readme in the dotfiles for more install sutff
Plugin 'neoclide/coc.nvim'

" Colours
Plugin 'flrnd/candid.vim'
Plugin 'morhetz/gruvbox'
Plugin 'jacoborus/tender.vim'
Plugin 'phanviet/vim-monokai-pro'
Plugin 'joshdick/onedark.vim'
Plugin 'godlygeek/csapprox'
Plugin 'ChrisKempson/Tomorrow-Theme'

call vundle#end()
filetype plugin indent on

" ==== Colors and other basic settings
" Colour schemes
if $TERM == "xterm-256color"
  set t_Co=256
  set termguicolors
endif
set background=dark
colorscheme onedark

set fillchars+=vert:\|
syntax enable
syntax on
set ruler
set hidden
set number
set laststatus=2
set smartindent
set st=2 sw=2 et
set shiftwidth=2
set tabstop=2
set softtabstop=2
"let g:vim_json_syntax_conceal = 0
" set colorcolumn=80
:set guioptions-=m  "remove menu bar
:set guioptions-=T  "remove toolbar
:set guioptions-=r  "remove right-hand scroll bar
:set guioptions-=L  "remove left-hand scroll bar
":set lines=999 columns=999
set ttimeoutlen=50
" Disable mouse
set mouse=c
" Disable swap file warning
set shortmess+=A
set relativenumber
set number
set showcmd
set ignorecase
set smartcase
set gdefault
if &history < 1000
  set history=1000
endif

" Folds
set foldmethod=indent " set the automatic fold function
set nofoldenable  "" but dont close folds by default
set foldlevelstart=99 " dont be greedy when toggling folds
nnoremap <space> za


" ====PLUGIN SETTINGS===

" ==== COC
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" I think this allows the autocomplete to detect when you used bacspace
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
if has('patch8.1.1068')
  " Use `complete_info` if your (Neo)Vim version supports it.
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  imap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" ==== Prettier
" single quotes over double quotes
" Prettier default: false
let g:prettier#config#single_quote = 'false'

nmap <Leader>' <Plug>ToggleMarkbar
let g:markbar_peekaboo_apostrophe_mapping = '<leader>m'
" only display alphabetic marks a-i and A-I
let g:markbar_peekaboo_marks_to_display = 'abcdefghejklmopqrstuvwxyzABCDEFGHEJKLMOPQRSTUVWXYZ'
" number of lines of context to retrieve per mark
let g:markbar_num_lines_context = 3
" set the oufile mark format
let g:markbar_file_mark_format_string = '%s'
let g:markbar_file_mark_arguments = ['fname']
let g:markbar_peekaboo_section_separation = 1
let g:markbar_context_indent_block = 2
let g:markbar__peekaboo_context_indent_block = 2

" ==== NERDTREE
let NERDTreeIgnore = ['__pycache__', '\.pyc$', '\.o$', '\.so$', '\.a$', '\.swp', '*\.swp', '\.swo', '\.swn', '\.swh', '\.swm', '\.swl', '\.swk', '\.sw*$', '[a-zA-Z]*egg[a-zA-Z]*', '.DS_Store']

let NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0

" Open nerdtree
map <C-e> :NERDTreeToggle<CR>

let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle
" Vim Airline settings
"Show buffers at the top of the window if there is only one tab
let g:airline#extensions#tabline#enabled = 1
" Show the buffer number
let g:airline#extensions#tabline#buffer_nr_show = 1
" Set the seperator for the tabs
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#eclim#enabled = 0
" Set Airline bar theme
let g:airline_theme='bubblegum'

" ====MOVEMENT COMMADNS====
nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>

" Move up and down through visual lines
nnoremap j gj
nnoremap k gk

" Highlight the last inserted text
nnoremap gV `[v`]`

" Force to not use the arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Open split and get focus, remap the window movement keys
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" You must create the dir set, it will not do it for you!
if has('persistent_undo')      "check if your vim version supports it
  set undodir=$HOME/.vim/undo  "directory where the undo files will be stored
  set undofile                 "turn on the feature
  :silent call system('mkdir -p ' . &undodir)
endif

autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" ===Special Keybindings

" toggle hlsearch
let searchcolourcounter=0
function! ToggleHLSearch()
  let g:searchcolourcounter = g:searchcolourcounter + 1
  if g:searchcolourcounter % 2 == 1
    set hlsearch
  else
    set nohlsearch
  endif
endfunction
nnoremap <leader>h :call ToggleHLSearch()<CR>

" Delete a buffer but dont delete the split
nnoremap <leader>bd :b#<bar>bd#<CR>

" Use the FZF Buffers selection
nnoremap <leader><leader> :Buffers<CR>

" Load all buffers from file, useful if git brnach has changed
map <Leader>la :set noconfirm<CR>:bufdo e<CR>:set confirm<CR>

" Un-highlight items selected with / or * etc

nnoremap <leader>u :UndotreeToggle<CR>

command! W :wa

nnoremap <leader>t :!ctags -R .<CR>

"===Imports

" Snippets functions
source ~/dotfiles/snippets/functions.vim
" Different print snippets for differernt file types
source ~/dotfiles/vim_functions/fill-output.vim

" FZF.vim settings
" Rquires bat, ripgrep, vim-devicons, FZF on the shell, and fzf.vim
" Open the GFiles command with fzf which ignores .git folder
nnoremap <silent> <leader>o :call Fzf_dev()<CR>
source ~/dotfiles/vim_functions/fuzzy-file-viewer-config.vim
nnoremap <silent> <leader>f :call Fzf_lines()<CR>
source ~/dotfiles/vim_functions/fuzzy-line-viewer-config.vim

" Convert from project root to relative between files
source ~/dotfiles/vim_functions/path-converter.vim

" Get import path relative to project root
source ~/dotfiles/vim_functions/code-imports.vim

" Import the list of misc functions
source ~/dotfiles/vim_functions/misc-functions.vim

" ====PER FILETYPE SETTINGS====

" Autogroup is used so autocmd are not applied multiple times

" Show spaces and other characters in yml and python
augroup configgroup
  autocmd!
  autocmd BufWritePre * :call StripTrailingWhitespaces()
  autocmd Filetype yaml source ~/dotfiles/ftconfig/showblankspaces.vim
  autocmd Filetype python source ~/dotfiles/ftconfig/showblankspaces.vim
augroup END

augroup configgroup
  autocmd!
  autocmd Filetype javascriptreact :set ft=javascript
augroup END
