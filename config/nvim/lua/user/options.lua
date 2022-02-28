local options = {
	autoindent=true,
	smartindent=true,
	backspace="indent,eol,start",
	hidden= true,
	incsearch= true,
	ruler= true,
	wildmenu= true,
	wildmode="longest:full,full",
	number=true,
	shiftwidth=2,
	tabstop=2,
	softtabstop=2,
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
}

-- g:startup_section_len = 10     -- set the number of recent items to show on my custom startup screen
-- g:markdown_fenced_languages = [--html","python","vim","scala"]
-- g:netrw_fastbrowse = 0      -- keeping fastbrowse on sometimes makes the netrw buffers not close
-- vim.cmd "set errorformat=%A%f:%l:%c:%m,%-G\\s%#,%-G%*\\d\ problem%.%#"

for k,v in pairs(options) do
	vim.opt[k] = v
end

vim.opt.shortmess:append "a"
vim.cmd "set fillchars=fold:\\ ,vert:│"
vim.cmd "set matchpairs+=<:>"
vim.cmd "set wildcharm=<C-z>"
vim.cmd "set formatoptions-=cro"
