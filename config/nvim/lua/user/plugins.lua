local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
	packer_bootstrap = fn.system(
		{'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path}
	)
	print "Installing packer close and open Neovim..."
	vim.cmd [[packadd packer.nvim]]
end

-- Every time we update this file, rerun packer to update the plugins
vim.cmd [[
	augroup packer_user_config
		autocmd!
		autocmd BufWritePost plugins.lua source <afile> | PackerSync
	augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	print "Unable to load packer, lua/user/plugins.lua"
	return
end

-- Have packer use a popup window
packer.init {
	display = {
		open_fn = function()
			return require("packer.util").float { border = "rounded" }
		end,
	},
}

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'

	-- Required for other plugins
	use 'nvim-lua/popup.nvim'
	use 'nvim-lua/plenary.nvim'

	-- cmp plugins
	use "hrsh7th/nvim-cmp"
	use "hrsh7th/cmp-buffer"
	use "hrsh7th/cmp-path"
	use "hrsh7th/cmp-cmdline"
	use "saadparwaiz1/cmp_luasnip"
	use "hrsh7th/cmp-nvim-lsp"
	use "hrsh7th/cmp-nvim-lua"

	-- snippets
	use "L3MON4D3/LuaSnip" -- snippet engine
	use "rafamadriz/friendly-snippets" -- a bunch of snippets

	-- plugins
	use "neovim/nvim-lspconfig"
	use "williamboman/nvim-lsp-installer" -- language server installer

	-- telescope <C-q> to add to quickfix list
	use "nvim-telescope/telescope.nvim"

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require('packer').sync()
	end
end)
