-- Set the colour scheme (taken from vimrc)
--

local colourscheme = "gruvbit"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colourscheme)

if not status_ok then
	vim.notify("Colour scheme " .. colourscheme .. " not found!")
	return
end

vim.cmd [[
	if (has("termguicolors"))
		set termguicolors
		let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
		let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
	endif

	function! s:setup_gruvbit_colourscheme() abort
			hi Comment gui=italic cterm=italic
			hi Statement gui=bold cterm=bold
			hi VertSplit guibg=NONE ctermbg=NONE
	endfunc
	augroup colorscheme_change | au!
			au ColorScheme * call s:setup_gruvbit_colourscheme()
	augroup END
	colorscheme gruvbit

	" If we are running in alacritty we can set the terminal background, so we
	" let that background pass through rather than use vim. We do this because
	" otherwise the background doesn't look right when using tmux
	"if !has('gui_running') && &term =~ '^\%(alacritty\)'
		hi Normal guibg=NONE ctermbg=NONE
	"endif

	" Set the highlight line back to the underline
	" hi clear CursorLine
	" hi CursorLine gui=underline cterm=underline
]]
