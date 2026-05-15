-- Native LSP Setup for Neovim 0.11+
-- Replaces lsp-zero functionality

-- 1. Setup lazydev (Neovim API type definitions for lua_ls)
local lazydev_ok, lazydev = pcall(require, 'lazydev')
if lazydev_ok then
	lazydev.setup()
end

-- 2. Setup Mason (manage external tools)
require('mason').setup({})

-- 3. Setup Capabilities for Completion
-- Apply nvim-cmp capabilities to every LSP server. mason-lspconfig v2 auto-enables
-- installed servers via vim.lsp.enable(), so this is how capabilities get through.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

-- 4. Setup Mason LSP Config (bridge between Mason and lspconfig)
-- Servers chosen to cover every filetype handled by ~/.dotfiles/.vim/plugin/comments.vim.
-- Scala (metals) and Haskell (hls) intentionally skipped — not used on this machine.
require('mason-lspconfig').setup({
	ensure_installed = {
		'bashls',                   -- sh, zsh
		'clangd',                   -- c, cpp
		'dockerls',                 -- dockerfile
		'groovyls',                 -- groovy
		'jdtls',                    -- java
		'jsonls',                   -- jsonc
		'kotlin_language_server',   -- kotlin
		'lua_ls',                   -- lua
		'pyright',                  -- python
		'rust_analyzer',            -- rust
		'ts_ls',                    -- javascript, typescript, jsx, tsx
		'vimls',                    -- vim
		'yamlls',                   -- yaml, yaml.docker-compose
	},
})

-- 5. Keymaps and Autocommands on LspAttach
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		local opts = { noremap = true, silent = true, buffer = ev.buf }

		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
		vim.keymap.set('n', 'ggi', vim.lsp.buf.implementation, opts)
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

		-- Diagnostics keymaps
		vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
		vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
		vim.keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
		vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
		vim.keymap.set('n', '<leader>dy', require("user.utils.misc").copy_line_diagnostics, opts)

		-- Format command
		vim.api.nvim_buf_create_user_command(ev.buf, 'Format', function()
			vim.lsp.buf.format({ async = true })
		end, {})
	end,
})

-- 6. Diagnostic Configuration
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = { current_line = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '✘',
			[vim.diagnostic.severity.WARN] = '▲',
			[vim.diagnostic.severity.HINT] = '⚑',
			[vim.diagnostic.severity.INFO] = '»',
		},
	},
})

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
		{ name = 'lazydev', group_index = 0 },
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
