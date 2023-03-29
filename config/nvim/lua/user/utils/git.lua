local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local showFileFromCommit = function(commit_sha)
	vim.cmd(vim.api.nvim_replace_termcodes('normal <C-w>v<C-w>l', true, true, true))
	vim.cmd(string.format(":Gitsigns show %s", commit_sha))
end

local fzf_file_changes = function(opts)
	local fullpath = vim.fn.expand("%:p")
	local cmd = { "git", "log", "--oneline", "--follow", "--", fullpath }

	opts = opts or {}
	pickers.new(opts, {
		prompt_title = fullpath .. " history",
		finder = finders.new_oneshot_job(cmd, opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection == nil then
					return
				end
				-- sha is the selection string up until the first space
				local sha = selection[1]:match("^(%S+)")
				showFileFromCommit(sha)
			end)
			map("i", "<ESC>", actions.close)
			return true
		end,
	}):find()
end

local _chooseFileCommitsViaFzf = function()
	fzf_file_changes()
end

return {
	choose_file_commits_via_fzf = _chooseFileCommitsViaFzf,
}
