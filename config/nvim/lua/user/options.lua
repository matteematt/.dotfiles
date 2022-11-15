local options = {
	autoindent=true,
	smartindent=true,
	backspace="indent,eol,start",
	hidden= true,
	-- incsearch=true,
	ruler= true,
	wildmenu= true,
	wildmode="longest:full,full",
	number=true,
	shiftwidth=2,
	tabstop=2,
	-- softtabstop=2,
	gdefault=true,
	lazyredraw=true,
	ttimeoutlen=50,
	ignorecase=true,
	smartcase=true,
	shiftround=true,
	spell=true,
	spelllang="en",
	foldmethod="indent",
	foldlevelstart=2,
	cursorline= true,
	signcolumn="yes"
}

-- g:startup_section_len = 10     -- set the number of recent items to show on my custom startup screen
-- g:markdown_fenced_languages = [--html","python","vim","scala"]
-- g:netrw_fastbrowse = 0      -- keeping fastbrowse on sometimes makes the netrw buffers not close
-- vim.cmd "set errorformat=%A%f:%l:%c:%m,%-G\\s%#,%-G%*\\d\ problem%.%#"

for k,v in pairs(options) do
	vim.opt[k] = v
end


vim.cmd [[
" Create a new autogroup for all vimrc autocmds
augroup vimrc
  autocmd!
augroup END

set nohlsearch
set matchpairs+=<:>
set wildcharm=<C-z>
set formatoptions-=cro
let g:startup_section_len = 10
set shada='50,<1000,s100,:1000,n~/nvim/shada
set shortmess+=A

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
elseif g:os == "Linux"
endif

" This autocommand tells Vim to open the quickfix window whenever a quickfix command is executed
" AND there are valid errors to display. And the list should close once it is empty
autocmd vimrc QuickFixCmdPost [^l]* cwindow
" Do same for location list
autocmd vimrc QuickFixCmdPost    l* lwindow
" Don't show spelling errors in the quickfix window (and location list)
autocmd vimrc FileType qf setlocal nospell
" Reduce CPU heavy items for very large files
" Treesitter is also disabled for files larger than 100kb
autocmd vimrc BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | set foldmethod=manual | set nospell | endif

augroup vimrc-incsearch-highlight
	autocmd!
	autocmd CmdlineEnter /,\? :set hlsearch
	autocmd CmdlineLeave /,\? :set nohlsearch
augroup END

" Don't show spelling errors or line numbers when in terminal normal mode
autocmd vimrc TermOpen * setlocal nospell
autocmd vimrc TermOpen * setlocal nonumber
autocmd vimrc TermOpen * setlocal signcolumn=no

" Set any known jsonc files to the appropriate types (they support comments)
autocmd BufRead,BufNewFile tsconfig.json set filetype=jsonc

" You must create the dir set, it will not do it for you!
if has('persistent_undo')      "check if your vim version supports it
  set undodir=$HOME/.cache/nvim/undo/  "directory where the undo files will be stored
  set undofile                 "turn on the feature
  silent call system('mkdir -p ' . &undodir)
endif
]]
