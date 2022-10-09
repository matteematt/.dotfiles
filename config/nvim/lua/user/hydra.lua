local status_ok, hydra = pcall(require, "hydra")
if not status_ok then
	print("Unable to load plugin : hydra")
	return
end

local hint = [[
^^ Git
^
_[_: Prev hunk
_]_: Next hunk
_b_: Toggle blame
_d_: Diff file
_<Esc>_: Exit
]]

local git_hydra = hydra({
	name = "Git",
	hint = hint,
	config = {
		color = 'pink',
		hint = {
			border = 'rounded',
			offset = 2,
		},
	},
	heads = {
		{ "]", "<cmd>Gitsigns next_hunk<CR>", { silent = true, desc = "next hunk" } },
		{ "[", "<cmd>Gitsigns prev_hunk<CR>", { silent = true, desc = "prev hunk" } },
		{ "b", "<cmd>Gitsigns toggle_current_line_blame<CR>", { silent = true, desc = "toggle diff" } },
		{ "d", "<cmd>Gitsigns diffthis<CR>", { silent = true, exit = true, desc = "diff file" } },
		{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
	},
})

-- Could export more than one hydra
return {
	git_hydra = git_hydra,
}
