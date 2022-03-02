local opts = { noremap = true }

local kmap = vim.api.nvim_set_keymap

-- Remap space as leader
kmap('', '<Space>', '<Nop>', opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Open the current file location in netrw
kmap('n', '<leader>w', '<C-w>v<C-w>l', opts)

-- Make jumps go to the middle of the screen and open any folds
kmap('n', 'n', 'nzzzv', opts)
kmap('n', 'N', 'Nzzzv', opts)
