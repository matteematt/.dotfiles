-- Debug script to check Treesitter status
-- Run with :luafile ~/.dotfiles/config/nvim/lua/user/script/debug_treesitter.lua

local function print_header(title)
  print(string.rep("=", 40))
  print(title)
  print(string.rep("=", 40))
end

-- Check Neovim version
print_header("Neovim Version")
print("Version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
print("Has Neovim 0.11.0: " .. tostring(vim.fn.has('nvim-0.11.0') == 1))

-- Check Treesitter branch
print_header("Treesitter Branch")
local branch_cmd = "cd " .. vim.fn.shellescape(vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter') .. " && git branch --show-current"
local handle = io.popen(branch_cmd)
local branch = handle:read("*a")
handle:close()
print("Current branch: " .. branch)

-- Check active parsers
print_header("Installed Parsers")
local parsers_cmd = "ls " .. vim.fn.shellescape(vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter/parser')
local handle = io.popen(parsers_cmd)
local parsers = handle:read("*a")
handle:close()
print("Parser count: " .. vim.fn.len(vim.fn.split(parsers, "\n")))

-- Check treesitter health
print_header("Treesitter Health Check")
print("Run :checkhealth nvim-treesitter for a complete health check")

-- Check current buffer highlighting
if vim.bo.filetype ~= "" then
  print_header("Current Buffer Info")
  print("Filetype: " .. vim.bo.filetype)
  print("Size: " .. vim.fn.getfsize(vim.fn.expand("%")) .. " bytes")
  print("Treesitter enabled: " .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))
end

print("\nTo update all parsers, run: :TSUpdate all")
print("To check syntax tree: :TSHighlightCapturesUnderCursor")