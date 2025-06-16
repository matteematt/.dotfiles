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

-- Check if we're running Neovim 0.11+ (required for main branch)
local nvim_version_ok = vim.fn.has('nvim-0.11.0') == 1

if nvim_version_ok then
	-- New configuration for main branch (Neovim 0.11+)
	local status_ok, treesitter = pcall(require, "nvim-treesitter")
	if not status_ok then
		print("Error starting treesitter")
		return
	end

	-- Basic setup for the main branch
	treesitter.setup {
		install_dir = vim.fn.stdpath('data') .. '/site'
	}

	-- Install all parsers except phpdoc
	-- The treesitter.install API has different syntax in main branch
	local install_result, _ = pcall(function() 
		treesitter.install("all") 
	end)
	if not install_result then
		print("Note: Failed to run treesitter.install, this may be expected if you're running a development version")
	end
	
	-- Disable treesitter highlighting for large files
	local max_filesize = 100 * 1024 -- 100 KB
	vim.api.nvim_create_autocmd({"BufReadPre"}, {
		callback = function(ev)
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(0))
			if ok and stats and stats.size > max_filesize then
				vim.treesitter.stop()
			end
		end
	})
	
	-- Enable experimental treesitter-based indentation except for YAML
	local indent_status, _ = pcall(function()
		vim.api.nvim_create_autocmd({"FileType"}, {
			pattern = {"*"},
			callback = function()
				local ft = vim.bo.filetype
				if ft ~= "yaml" then
					-- Check if indentexpr function exists
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
else
	-- Legacy configuration for master branch (Neovim < 0.11)
	local status_ok, configs = pcall(require, "nvim-treesitter.configs")
	if not status_ok then
		print("Error starting treesitter")
		return
	end

	configs.setup {
		ensure_installed = "all",
		sync_install = false,
		ignore_install = { "phpdoc" }, -- List of parsers to ignore installing
		highlight = {
			enable = true, -- false will disable the whole extension
			-- disable = { "" }, -- list of language that will be disabled
			disable = function(lang, buf)
				local max_filesize = 100 * 1024 -- 100 KB
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return true
				end
			end,

			additional_vim_regex_highlighting = true,
		},
		indent = { enable = true, disable = { "yaml" } },
	}
end