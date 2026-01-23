-- Native LSP Setup for Neovim 0.11+
-- Replaces lsp-zero functionality

-- 1. Setup Mason (manage external tools)
require('mason').setup({})

-- 2. Setup Capabilities for Completion
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- 3. Setup Mason LSP Config (bridge between Mason and lspconfig)
require('mason-lspconfig').setup({
	handlers = {
		-- Default handler for all servers
		function(server_name)
			if server_name == 'lua_ls' then
				require('lspconfig')[server_name].setup({
					capabilities = capabilities,
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
			require('lspconfig')[server_name].setup({
				capabilities = capabilities,
			})
		end,
	},
})

-- 4. Keymaps and Autocommands on LspAttach
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		local opts = { noremap = true, silent = true, buffer = ev.buf }
		local client = vim.lsp.get_client_by_id(ev.data.client_id)

		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
		vim.keymap.set('n', 'K', function()
			-- Get the client for the current buffer to find its offset encoding
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
			
			vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result, ctx, config)
				if err then
					print("LSP Error: " .. tostring(err))
					return
				end
				if not (result and result.contents) then
					print("No hover info")
					return
				end
				-- result.contents can be string, MarkupContent, or MarkedString[]
				local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
				                				if vim.tbl_isempty(markdown_lines) then
				                					print("No hover content")
				                					return
				                				end
				                				-- Use plaintext to prevent crashes with Markdown highlighting
				                				vim.lsp.util.open_floating_preview(markdown_lines, "plaintext", { border = "rounded" })
				                			end)
				                		end, opts)		vim.keymap.set('n', 'ggi', vim.lsp.buf.implementation, opts)
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
		-- vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
		
		-- Diagnostics keymaps
		vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
		vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
		vim.keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
		vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
		
		-- Format command
		vim.api.nvim_buf_create_user_command(ev.buf, 'Format', function()
			vim.lsp.buf.format({ async = true })
		end, {})
	end,
})

-- 5. Diagnostic Configuration
vim.diagnostic.config({
	virtual_text = false,
	float = {
		border = 'rounded',
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '✘',
			[vim.diagnostic.severity.WARN] = '▲',
			[vim.diagnostic.severity.HINT] = '⚑',
			[vim.diagnostic.severity.INFO] = '»',
		},
	},
})

-- 6. UI Customization (Borders & Highlights)
-- Apply floating window styling to match editor background with darker borders
-- vim.api.nvim_create_autocmd({"VimEnter", "ColorScheme"}, {
--   callback = function()
--     -- Get Normal background color for consistent styling
--     local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
--     local normal_bg_hex = normal_hl.bg and string.format("#%06x", normal_hl.bg) or "NONE"
    
--     -- Try to get TelescopeBorder highlight color for consistency
--     local telescope_border_hl = vim.api.nvim_get_hl(0, { name = "TelescopeBorder" })
--     local border_color
    
--     -- If TelescopeBorder is defined, use its color
--     if telescope_border_hl.fg then
--       border_color = string.format("#%06x", telescope_border_hl.fg)
--     else
--       -- Fallback to Comment highlight color
--       local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
--       border_color = comment_hl.fg and string.format("#%06x", comment_hl.fg) or "#6a6a6a"
--     end
    
--     -- Set colors to editor background
--     vim.api.nvim_set_hl(0, "NormalFloat", { bg = normal_bg_hex })
--     vim.api.nvim_set_hl(0, "Pmenu", { bg = normal_bg_hex })
    
--     -- Use the border color from telescope or fallback to comment
--     vim.api.nvim_set_hl(0, "FloatBorder", { fg = border_color, bg = normal_bg_hex })
--   end,
--   group = vim.api.nvim_create_augroup("CustomFloatHighlights", { clear = true })
-- })

-- Ensure floating windows have borders by default using standard handlers
-- vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
--   if not (result and result.contents) then
--     print("No hover info")
--     return
--   end
--   print("Hover data received. Contents type: " .. type(result.contents))
--   -- vim.lsp.util.open_floating_preview(result.contents, "markdown", config)
-- end

-- vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
--   vim.lsp.handlers.signature_help, {
--     border = "rounded"
--   }
-- )

-- 7. Completion Setup (nvim-cmp)
local cmp = require('cmp')

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
			vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
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
		['<C-p>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
		['<C-n>'] = cmp.mapping.select_next_item({ behavior = 'select' }),
		['<CR>'] = cmp.mapping.confirm({ select = false }),
		['<C-Space>'] = cmp.mapping.complete(),
		
		-- Native snippet jumping
		['<C-f>'] = cmp.mapping(function(fallback)
			if vim.snippet.active({ direction = 1 }) then
				vim.snippet.jump(1)
			else
				fallback()
			end
		end, { "i", "s" }),
		['<C-b>'] = cmp.mapping(function(fallback)
			if vim.snippet.active({ direction = -1 }) then
				vim.snippet.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),

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
