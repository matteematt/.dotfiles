-- Set the colour scheme (taken from vimrc)
local colourscheme = "onedarkpro"

-- local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colourscheme)
--
-- if not status_ok then
	-- vim.notify("Colour scheme " .. colourscheme .. " not found!")
	-- return
-- end

if colourscheme == "onedarkpro" then
	vim.o.termguicolors = true
	vim.o.background = "dark" -- to load onedark
	local onedark_config = {
		-- Theme can be overwritten with 'onedark' or 'onelight' as a string
		theme = function()
			if vim.o.background == "dark" then
				return "onedark"
			else
				return "onelight"
			end
		end,
		colors = {
			onedark = {
				-- Vivid colors from https://github.com/Binaryify/OneDark-Pro
				red = "#ef596f",
				green = "#89ca78",
				cyan = "#2bbac5",
				purple = "#d55fde",
			},
		}, -- Override default colors by specifying colors for 'onelight' or 'onedark' themes
		hlgroups = {}, -- Override default highlight groups
		filetype_hlgroups = {}, -- Override default highlight groups for specific filetypes
		plugins = { -- Override which plugins highlight groups are loaded
			native_lsp = true,
			polygot = true,
			treesitter = true,
			-- NOTE: Other plugins have been omitted for brevity
		},
		styles = {
			strings = "NONE", -- Style that is applied to strings
			comments = "italic", -- Style that is applied to comments
			keywords = "bold", -- Style that is applied to keywords
			functions = "bold", -- Style that is applied to functions
			variables = "NONE", -- Style that is applied to variables
		},
		options = {
			bold = true, -- Use the themes opinionated bold styles?
			italic = true, -- Use the themes opinionated italic styles?
			underline = true, -- Use the themes opinionated underline styles?
			undercurl = true, -- Use the themes opinionated undercurl styles?
			cursorline = true, -- Use cursorline highlighting?
			transparency = true, -- Use a transparent background?
			terminal_colors = true, -- Use the theme's colors for Neovim's :terminal?
			window_unfocussed_color = false, -- When the window is out of focus, change the normal background?
		},
	}
	local onedarkpro = require("onedarkpro")
	onedarkpro.load(onedarkpro.setup(onedark_config))
elseif colourscheme == "gruvbit" then
	vim.cmd([[
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
]])
end
