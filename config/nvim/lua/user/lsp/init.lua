local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
	print("unable to start plugin lspconfig")
	return
end

require("user.lsp.mason")
require("user.lsp.handlers").setup()
require("user.lsp.null-ls")

Filetypes_connected = {}

vim.api.nvim_create_autocmd("LspTokenUpdate", {
	callback = function(_)
		local filetype = vim.bo.filetype
		if Filetypes_connected[filetype] then
			return
		end
		print("Lsp attatched for filetype: " .. filetype)
		Filetypes_connected[filetype] = true
	end,
})

vim.api.nvim_create_autocmd("LspDetach", {
	callback = function(args)
		local filetype = vim.bo.filetype
		Filetypes_connected[filetype] = false
	end,
})
