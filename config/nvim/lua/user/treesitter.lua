-- Configure rainbow-delimiters if available
local rainbow_status_ok, rainbow = pcall(require, "rainbow-delimiters")
if rainbow_status_ok then
	vim.g.rainbow_delimiters = {
		max_file_lines = 10000,
		strategy = {
			[''] = rainbow.strategy['global'],
		},
	}
end

local status_ok, treesitter = pcall(require, "nvim-treesitter")
if not status_ok then
	print("Error starting treesitter")
	return
end

treesitter.setup {
	install_dir = vim.fn.stdpath('data') .. '/site'
}

-- Enable treesitter for all files except large ones
local max_filesize = 100 * 1024 -- 100 KB
vim.api.nvim_create_autocmd({"FileType"}, {
	callback = function(ev)
		local bufnr = ev.buf

		-- Only enable when we have a filetype
		if vim.bo[bufnr].filetype == "" then
			return
		end

		-- Skip special buffers (nofile, prompt, quickfix) to prevent crashes in floats
		local buftype = vim.bo[bufnr].buftype
		if buftype == "nofile" or buftype == "prompt" or buftype == "quickfix" then
			return
		end

		-- Check file size
		local file_path = vim.api.nvim_buf_get_name(bufnr)
		local ok, stats = pcall(vim.uv.fs_stat, file_path)

		-- Skip large files
		if ok and stats and stats.size > max_filesize then
			pcall(vim.treesitter.stop, bufnr)
			return
		end

		-- Safely enable treesitter for this buffer
		pcall(function()
			if vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) then
				vim.treesitter.start(bufnr)
			end
		end)
	end
})

-- Enable experimental treesitter-based indentation except for YAML
local indent_status, _ = pcall(function()
	vim.api.nvim_create_autocmd({"FileType"}, {
		pattern = {"*"},
		callback = function()
			local ft = vim.bo.filetype
			if ft ~= "yaml" then
				local has_indent, _ = pcall(require, "nvim-treesitter")
				if has_indent and type(require("nvim-treesitter").indentexpr) == "function" then
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end
		end
	})
end)
if not indent_status then
	print("Note: Treesitter indentation could not be set up")
end

-- Add a command to manually update treesitter parsers
local parsers_to_install = {
	"bash", "c", "cpp", "css", "dockerfile", "go", "html", "javascript",
	"json", "lua", "markdown", "markdown_inline", "python", "rust", "sql", "toml", "typescript",
	"vim", "yaml", "zig", "scala", "java", "kotlin", "php", "ruby", "xml",
	"cmake", "make", "ninja", "diff", "git_rebase", "gitcommit", "gitignore",
	"vimdoc", "query", "regex", "comment",
}
vim.api.nvim_create_user_command("TSUpdateAll", function()
	print("Updating all treesitter parsers...")
	for _, parser in ipairs(parsers_to_install) do
		local install_result, _ = pcall(function()
			treesitter.install(parser)
		end)
		if install_result then
			print("✓ Updated parser: " .. parser)
		else
			print("✗ Failed to update parser: " .. parser)
		end
	end
	print("Treesitter parser update complete!")
end, { desc = "Update all treesitter parsers" })
