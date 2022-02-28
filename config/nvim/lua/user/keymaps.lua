local opts = { noremap = true }

local keymap = vim.api.nvim_set_keymap

-- Remap space as leader
keymap('', '<Space>', '<Nop>', opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "


