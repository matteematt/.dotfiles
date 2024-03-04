vim.cmd([[ let g:has_git = executable("git") ]])

require("user.options")
require("user.keymaps")
require("user.plugins")
require("user.cmp")
require("user.lsp")
require("user.telescope")
require("user.treesitter")
require("user.autopairs")
require("user.colourscheme")
require("user.gitsigns")
require("user.closetag")
require("user.hydra")
require("user.indent-blankline")
require("user.devicons")
