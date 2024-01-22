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
