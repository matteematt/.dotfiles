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
_<Esc>_: Exit
]]

local git_hydra = hydra({
	name = "Git",
	hint = hint_git,
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

-- LSP

local hint_lsp = [[
^^ LSP
^
_d_: Definition _D_: Declaration _i_: Implementation _r_: References _s_: Signature help
_I_: Info _R_: Rename
_[_: Prev diagnostic _]_: Next diagnostic _l_: Diagnostics loclist _f_: Diagnostics float
_<Esc>_: Exit
]]

local lsp_hydra = hydra({
	name = "LSP",
	hint = hint_lsp,
	config = {
		color = 'pink',
		hint = {
			border = 'rounded',
			offset = 2,
		},
	},
	heads = {
		{'d',  "<cmd>lua vim.lsp.buf.definition()<CR>", {exit = true, nowait = true, desc = 'definition'}},
		{'D',  "<cmd>lua vim.lsp.buf.declaration()<CR>", {exit = true, nowait = true, desc = 'declaration'}},
		{'i',  "<cmd>lua vim.lsp.buf.implementation()<CR>", {exit = true, nowait = true, desc = 'implementation'}},
		{'r',  "<cmd>lua vim.lsp.buf.references()<CR>", {exit = true, nowait = true, desc = 'references'}},
		{'s',  "<cmd>lua vim.lsp.buf.signature_help()<CR>", {exit = true, nowait = true, desc = 'signature_help'}},


		{'I',  "<cmd>lua vim.lsp.buf.hover()<CR>", {exit = true, nowait = true, desc = 'hover'}},
		{'R',  "<cmd>lua vim.lsp.buf.rename()<CR>", {exit = true, nowait = true, desc = 'rename'}},

		{'[', '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', {nowait = true, desc = 'diagnostic prev'}},
		{']', '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', {nowait = true, desc = 'diagnostic next'}},
		{'f', '<cmd>lua vim.diagnostic.open_float()<CR>', {nowait = true, desc = 'diagnostics float'}},
		{'l', '<cmd>lua vim.diagnostic.setloclist()<CR>', {nowait = true, desc = 'diagnostics loclist'}},

		{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
	},
})

-- Could export more than one hydra
return {
	git_hydra = git_hydra,
	lsp_hydra = lsp_hydra,
}
