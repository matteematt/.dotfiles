
local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	print("Error starting treesitter")
	return
end

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
