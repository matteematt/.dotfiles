local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
	return
end

telescope.setup({
	defaults = {
		file_ignore_patterns = {
			"node_modules",
		},
	},
})

-- Disable folding in Telescope's result window.
vim.api.nvim_create_autocmd("FileType", { pattern = "TelescopeResults", command = [[setlocal foldlevelstart=999]] })

-- Style Telescope borders to match the theme
vim.api.nvim_create_autocmd({"VimEnter", "ColorScheme"}, {
  callback = function()
    -- Get Normal background color for consistency
    local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
    local normal_bg_hex = normal_hl.bg and string.format("#%06x", normal_hl.bg) or "NONE"
    
    -- Get Comment highlight color for border
    local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
    local border_color = comment_hl.fg and string.format("#%06x", comment_hl.fg) or "#6a6a6a"
    
    -- Set all telescope border highlights
    vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border_color, bg = normal_bg_hex })
    vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = border_color, bg = normal_bg_hex })
    vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = border_color, bg = normal_bg_hex })
    vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = border_color, bg = normal_bg_hex })
  end,
  group = vim.api.nvim_create_augroup("TelescopeHighlights", { clear = true })
})
