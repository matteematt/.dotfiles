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

-- Open the current file location in netrw
kmap('n','<leader>e', ':edit %:p:h<CR>', opts)

-- Use arrow keys for moving through the location and quickfix windows
kmap('n', '<Down>', ':cnext<CR>zzzv', opts)
kmap('n', '<Up>', ':cprev<CR>zzzv', opts)
kmap('n', '<Left>', ':lnext<CR>zzzv', opts)
kmap('n', '<Right>', ':lprev<CR>zzzv', opts)

-- Telescope
kmap('n', '<leader>o', ':Telescope find_files hidden=true<CR>', opts)
kmap('n', '<leader>f', ':Telescope live_grep<CR>', opts)
kmap('n', '<leader><leader>', ':Telescope buffers<CR>', opts)

-- Undotree
kmap('n', '<leader>u', ':UndotreeToggle<CR>', opts)

-- Formatting
kmap('n', '<leader>l', ':lua vim.lsp.buf.formatting_sync()<CR>',opts)

-- Terminal (make match standard vim)
kmap('t', '<C-w>N', '<C-\\><C-n>', opts)
kmap('t', '<C-w>l', '<C-\\><C-N><C-w>l', opts)
kmap('t', '<C-w>k', '<C-\\><C-N><C-w>k', opts)
kmap('t', '<C-w>j', '<C-\\><C-N><C-w>j', opts)
kmap('t', '<C-w>h', '<C-\\><C-N><C-w>h', opts)

-- Yank to clipboard
kmap('v', '<leader>yy', '"+y', opts)
kmap('n', '<leader>yp', '"+p', opts)
