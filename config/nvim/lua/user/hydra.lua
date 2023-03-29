local status_ok, hydra = pcall(require, "hydra")
if not status_ok then
	print("Unable to load plugin : hydra")
	return
end

-- GIT

local hint_git = [[
^^ Git
^
_[_: Prev hunk
_]_: Next hunk
_b_: Toggle blame
_d_: Diff file
_t_: Telescope
_h_: File history
_<Esc>_: Exit
]]

local git_hydra = hydra({
	name = "Git",
	hint = hint_git,
	config = {
		color = "pink",
		hint = {
			border = "rounded",
			offset = 2,
		},
	},
	heads = {
		{ "]", "<cmd>Gitsigns next_hunk<CR>", { silent = true, desc = "next hunk" } },
		{ "[", "<cmd>Gitsigns prev_hunk<CR>", { silent = true, desc = "prev hunk" } },
		{ "b", "<cmd>Gitsigns toggle_current_line_blame<CR>", { silent = true, desc = "toggle diff" } },
		{ "d", "<cmd>Gitsigns diffthis<CR>", { silent = true, exit = true, desc = "diff file" } },
		{ "t", "<cmd>Telescope git_status<CR>", { silent = true, exit = true, desc = "telescope changes" } },
		{ "h", require("user.utils.git").choose_file_commits_via_fzf, { exit = true, nowait = true, desc = "file history" } },
		{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
	},
})

-- LSP

local hint_lsp = [[
^^ LSP
^
_d_: Definition _D_: Declaration _i_: Implementation _r_: References _s_: Signature help
_I_: Info _R_: Rename
_[_: Prev diagnostic _]_: Next diagnostic _l_: Diagnostics loclist _f_: Diagnostics float _t_: Diagnostics telescope
_<Esc>_: Exit
]]

local lsp_hydra = hydra({
	name = "LSP",
	hint = hint_lsp,
	config = {
		color = "pink",
		hint = {
			border = "rounded",
			offset = 2,
		},
	},
	heads = {
		{ "d", "<cmd>lua vim.lsp.buf.definition()<CR>", { exit = true, nowait = true, desc = "definition" } },
		{ "D", "<cmd>lua vim.lsp.buf.declaration()<CR>", { exit = true, nowait = true, desc = "declaration" } },
		{ "i", "<cmd>lua vim.lsp.buf.implementation()<CR>", { exit = true, nowait = true, desc = "implementation" } },
		{ "r", "<cmd>lua vim.lsp.buf.references()<CR>", { exit = true, nowait = true, desc = "references" } },
		{ "s", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { exit = true, nowait = true, desc = "signature_help" } },

		{ "I", "<cmd>lua vim.lsp.buf.hover()<CR>", { exit = true, nowait = true, desc = "hover" } },
		{ "R", "<cmd>lua vim.lsp.buf.rename()<CR>", { exit = true, nowait = true, desc = "rename" } },

		{
			"[",
			'<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>',
			{ nowait = true, desc = "diagnostic prev" },
		},
		{
			"]",
			'<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>',
			{ nowait = true, desc = "diagnostic next" },
		},
		{ "f", "<cmd>lua vim.diagnostic.open_float()<CR>", { nowait = true, desc = "diagnostics float" } },
		{ "l", "<cmd>lua vim.diagnostic.setloclist()<CR>", { nowait = true, desc = "diagnostics loclist" } },
		{ "t", "<cmd>Telescope diagnostics<CR>", { nowait = true, exit = true, desc = "diagnostics telescope" } },

		{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
	},
})

-- Misc

local hint_misc = [[
^^ Miscellaneous
^
_r_: Reload buffers
_s_: Source buffer vimscript/lua
_[_: Auto-fix prev spelling issue
_]_: Auto-fix next spelling issue
_m_: Marks in telescope
_j_: Jumplist in telescope
_<Esc>_: Exit
]]

local misc_hydra = hydra({
	name = "Miscellaneous",
	hint = hint_misc,
	config = {
		color = "pink",
		hint = {
			border = "rounded",
			offset = 2,
		},
	},
	heads = {
		{ "r", require("user.utils.misc").reload_session, { exit = true, nowait = true, desc = "reload" } },
		{ "s", "<cmd>so %<CR>", { exit = true, nowait = true, desc = "source file" } },

		-- can we improve with this https://stackoverflow.com/questions/5312235/how-do-i-correct-vim-spelling-mistakes-quicker
		{ "[", "[s1z=<c-o>", { nowait = true, desc = "prev spelling error" } },
		{ "]", "]s1z=<c-o>", { nowait = true, desc = "next spelling error" } },

		{ "m", "<cmd>Telescope marks<CR>", { nowait = true, exit = true, desc = "marks in telescope" } },
		{ "j", "<cmd>Telescope jumplist<CR>", { nowait = true, exit = true, desc = "jumplist in telescope" } },

		{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
	},
})

-- Could export more than one hydra
return {
	git_hydra = git_hydra,
	lsp_hydra = lsp_hydra,
	misc_hydra = misc_hydra,
}
