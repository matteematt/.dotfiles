-- Set the colour scheme (taken from vimrc)
local colourscheme = "onedarkpro"

--Because this actually loads the colour scheme on success it messes
--with colourschemes that with to set options such as onedarkpro
-- local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colourscheme)
--
-- if not status_ok then
	-- vim.notify("Colour scheme " .. colourscheme .. " not found!")
	-- return
-- end

if colourscheme == "onedarkpro" then

	require("onedarkpro").setup({
  colors = {
		onedark = {
			-- Vivid colors from https://github.com/Binaryify/OneDark-Pro
			red = "#ef596f",
			green = "#89ca78",
			cyan = "#2bbac5",
			purple = "#d55fde",
		},
  }, -- Override default colors or create your own
  highlights = {}, -- Override default highlight groups or create your own
  filetypes = { -- Override which filetype highlight groups are loaded
    -- See the 'Configuring filetype highlights' section for the available list
  },
  plugins = { -- Override which plugin highlight groups are loaded
	nvim_lsp = true,
	polygot = true,
	treesitter = true,
    -- See the 'Supported plugins' section for the available list
  },
  styles = { -- For example, to apply bold and italic, use "bold,italic"
    types = "NONE", -- Style that is applied to types
    numbers = "NONE", -- Style that is applied to numbers
    strings = "NONE", -- Style that is applied to strings
    comments = "italic", -- Style that is applied to comments
    keywords = "bold", -- Style that is applied to keywords
    constants = "NONE", -- Style that is applied to constants
    functions = "bold", -- Style that is applied to functions
    operators = "NONE", -- Style that is applied to operators
    variables = "NONE", -- Style that is applied to variables
    conditionals = "NONE", -- Style that is applied to conditionals
    virtual_text = "NONE", -- Style that is applied to virtual text
  },
  options = {
    bold = true, -- Use bold styles?
    italic = true, -- Use italic styles?
    underline = true, -- Use underline styles?
    undercurl = true, -- Use undercurl styles?

    cursorline = true, -- Use cursorline highlighting?
    transparency = true, -- Use a transparent background?
    terminal_colors = true, -- Use the theme's colors for Neovim's :terminal?
    highlight_inactive_windows = false, -- When the window is out of focus, change the normal background?
  }
})

vim.cmd("colorscheme onedark")

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
