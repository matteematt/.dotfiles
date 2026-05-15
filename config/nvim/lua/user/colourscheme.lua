require("onedarkpro").setup({
	colors = {
		onedark = {
			-- Vivid colors from https://github.com/Binaryify/OneDark-Pro
			red = "#ef596f",
			green = "#89ca78",
			cyan = "#2bbac5",
			purple = "#d55fde",
		},
	},
	highlights = {},
	filetypes = {},
	plugins = {
		nvim_lsp = true,
		polygot = true,
		treesitter = true,
	},
	styles = {
		types = "NONE",
		numbers = "NONE",
		strings = "NONE",
		comments = "italic",
		keywords = "bold",
		constants = "NONE",
		functions = "bold",
		operators = "NONE",
		variables = "NONE",
		conditionals = "NONE",
		virtual_text = "NONE",
	},
	options = {
		bold = true,
		italic = true,
		underline = true,
		undercurl = true,
		cursorline = true,
		transparency = true,
		terminal_colors = true,
		highlight_inactive_windows = false,
	},
})

vim.cmd("colorscheme onedark")
