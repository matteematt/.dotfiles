local status_ok, lsp_zero = pcall(require, "lsp-zero")
if not status_ok then
	print("Unable to load plugin : lsp_zero")
	return
end

-- lsp_attach is where you enable features that only work
-- if there is a language server active in the file
local lsp_attach = function(client, bufnr)
	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "ggi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
	-- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	-- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
	vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting()' ]])
end

lsp_zero.extend_lspconfig({
	sign_text = true,
	lsp_attach = lsp_attach,
	capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

lsp_zero.ui({
	float_border = 'rounded',
	sign_text = {
		error = '✘',
		warn = '▲',
		hint = '⚑',
		info = '»',
	},
	hover = {
		enabled = true,
		border = 'rounded',
		max_width = 80,
		max_height = 20,
	}
})

-- Define border characters with simple string format for Neovim 0.11+
local border_chars = "rounded"

-- Configure diagnostics with rounded borders
vim.diagnostic.config({
	virtual_text = false,
	float = {
		border = border_chars,
	},
})

-- Apply floating window styling to match editor background with darker borders
vim.api.nvim_create_autocmd({"VimEnter", "ColorScheme"}, {
  callback = function()
    -- Get Normal background color for consistent styling
    local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
    local normal_bg_hex = normal_hl.bg and string.format("#%06x", normal_hl.bg) or "NONE"
    
    -- Try to get TelescopeBorder highlight color for consistency
    local telescope_border_hl = vim.api.nvim_get_hl(0, { name = "TelescopeBorder" })
    local border_color
    
    -- If TelescopeBorder is defined, use its color
    if telescope_border_hl.fg then
      border_color = string.format("#%06x", telescope_border_hl.fg)
    else
      -- Fallback to Comment highlight color
      local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
      border_color = comment_hl.fg and string.format("#%06x", comment_hl.fg) or "#6a6a6a"
    end
    
    -- Set colors to editor background
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = normal_bg_hex })
    vim.api.nvim_set_hl(0, "Pmenu", { bg = normal_bg_hex })
    
    -- Use the border color from telescope or fallback to comment
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = border_color, bg = normal_bg_hex })
  end,
  group = vim.api.nvim_create_augroup("CustomFloatHighlights", { clear = true })
})

require('mason').setup({})
-- Set up border for all windows, including hover
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border_chars
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

require('mason-lspconfig').setup({
	handlers = {
		function(server_name)
			if server_name == 'lua_ls' then
				require('lspconfig')[server_name].setup({
					settings = {
						Lua = {
							diagnostics = {
								globals = { 'vim' }
							}
						}
					}
				})
				return
			end
			require('lspconfig')[server_name].setup({})
		end,
	},
})

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

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

local kind_icons = {
	Text = "",
	Method = "m",
	Function = "",
	Constructor = "",
	Field = "",
	Variable = "",
	Class = "",
	Interface = "",
	Module = "",
	Property = "",
	Unit = "",
	Value = "",
	Enum = "",
	Keyword = "",
	Snippet = "",
	Color = "",
	File = "",
	Reference = "",
	Folder = "",
	EnumMember = "",
	Constant = "",
	Struct = "",
	Event = "",
	Operator = "",
	TypeParameter = "",
	Copilot = "",
}

cmp.setup({
	sources = {
		{ name = 'nvim_lsp' },
	},
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item)
			-- Kind icons
			vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
			-- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
			vim_item.menu = ({
				nvim_lsp = "[LSP]",
				nvim_lua = "[LUA]",
				luasnip = "[Snippet]",
				buffer = "[Buffer]",
				path = "[Path]",
			})[entry.source.name]
			return vim_item
		end,
	},
	mapping = cmp.mapping.preset.insert({
		-- Navigate between completion items
		['<C-p>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
		['<C-n>'] = cmp.mapping.select_next_item({ behavior = 'select' }),

		-- `Enter` key to confirm completion
		['<CR>'] = cmp.mapping.confirm({ select = false }),

		-- Ctrl+Space to trigger completion menu
		['<C-Space>'] = cmp.mapping.complete(),

		-- Navigate between snippet placeholder
		['<C-f>'] = cmp_action.vim_snippet_jump_forward(),
		['<C-b>'] = cmp_action.vim_snippet_jump_backward(),

		-- Scroll up and down in the completion documentation
		['<C-u>'] = cmp.mapping.scroll_docs(-4),
		['<C-d>'] = cmp.mapping.scroll_docs(4),
	}),
	snippet = {
		expand = function(args)
			vim.snippet.expand(args.body)
		end,
	},
	confirm_opts = {
		behavior = cmp.ConfirmBehavior.Replace,
		select = false,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	experimental = {
		ghost_text = true,
		native_menu = false,
	},
})
