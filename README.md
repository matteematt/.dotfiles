# Dotfiles

## Setup
Require vundle to install the vim plugins, `$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim`

Symlink files, assuming dotfiles cloned into home dir

- `$ ln -s ~/.dotfiles/.vimrc ~/.vimrc`
- `$ ln -s ~/.dotfiles/snippets ~/.vim/snippets`

Some plugins require additional installation

- vim-prettier requires `$ npm install` to be ran in its bundle directory
- YouCompleteMe requires its source to be compiled using `$ python install.py` (requires cmake)
- fzf files setup requires multiple items
	- FZF (shell)
	- ripgrep (shell)
	- vim-devicons
	- FZF.vim

## Themes

(For Elementary OS themes)[https://medium.com/@s0rata/customizing-elementary-os-5-0-theme-icons-cursor-78a879e57635]
