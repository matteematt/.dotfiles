local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	packer_bootstrap = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and open Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

function backup_sync_packer()
	local snapshot_dir = os.getenv("HOME") .. "/.dotfiles/config/nvim/plugin/snapshot"
	local date = os.date("%y%m%d")
	local snapshot_file = snapshot_dir .. "/snapshot_" .. date .. ".json"
	if fn.filereadable(snapshot_file) == 0 then
		print("Creating snapshot")
		vim.cmd("PackerSnapshot " .. snapshot_file)
		print("Snapshot created at: " .. snapshot_file)
	end

	-- source the current file
	vim.cmd("source " .. vim.fn.expand("%"))
	-- call packer sync
	vim.cmd("PackerSync")
end

-- Every time we update this file, rerun packer to update the plugins
vim.cmd([[
	augroup packer_user_config
		autocmd!
		autocmd BufWritePost plugins.lua :lua backup_sync_packer()
	augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	print("Unable to load packer, lua/user/plugins.lua")
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	-- Required for other plugins
	use("nvim-lua/popup.nvim")
	use("nvim-lua/plenary.nvim")

	-- telescope <C-q> to add to quickfix list
	use("nvim-telescope/telescope.nvim")

	-- Treesitter
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	use("nvim-treesitter/playground")
	use("p00f/nvim-ts-rainbow")

	-- Autopairs
	-- use("windwp/nvim-autopairs")

	-- git
	use("lewis6991/gitsigns.nvim")

	-- Undotree
	use("mbbill/undotree")

	-- Colourscheme
	use("olimorris/onedarkpro.nvim")

	-- Automatically close (x)html tags
	use("alvan/vim-closetag")

	-- Syntax highlighting for csv files
	use("mechatroner/rainbow_csv")

	-- Hydra modes
	use("nvimtools/hydra.nvim")

	use("nvim-tree/nvim-web-devicons")

	--
	use({ "lukas-reineke/indent-blankline.nvim" })

	use({ 'VonHeikemen/lsp-zero.nvim', branch = 'v4.x' })
	use({ 'williamboman/mason.nvim' })
	use({ 'williamboman/mason-lspconfig.nvim' })
	use({ 'neovim/nvim-lspconfig' })
	use({ 'hrsh7th/cmp-nvim-lsp' })
	use({ 'hrsh7th/nvim-cmp' })

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require("packer").sync()
	end
end)
