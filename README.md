# VIM

## Dependencies 

Current dependencies are `ripgrep`

I like to have as little dependencies as possible so I have bundled the colour schemes into this repo. 

### XCode Colour Scheme

The original [can be found here](https://github.com/arzg/vim-colors-xcode).
To update the colour schemes with the repo if git is installed.	arzg/vim-colors-xcode is licensed under the ISC License.
```
git clone https://github.com/arzg/vim-colors-xcode.git $TMPDIR/vim-colors-xcode
cp -r $TMPDIR/vim-colors-xcode/{autoload,colors,doc} ~/.vim
```

To enable and with italics
```
color xcodedarkhc
augroup vim-colors-xcode
    autocmd!
augroup END

autocmd vim-colors-xcode ColorScheme * hi Comment        cterm=italic gui=italic
autocmd vim-colors-xcode ColorScheme * hi SpecialComment cterm=italic gui=italic
```

### OneDark Colour Scheme

The original [can be found here](https://github.com/joshdick/onedark.vim.git).
This colour scheme is licensed under the MIT Licence.
```
git clone https://github.com/joshdick/onedark.vim.git $TMPDIR/onedark
cp -r $TMPDIR/onedark/{autoload,colors} ~/.vim
```

Use the readme in the repo to set up the colour scheme. The vimrc in this repo sets up to use 256 colours and italics.
A fallback option can be set in case the terminal in use does not support 256 colours. 
Italics can be disabled if the terminal doesn't support it. iTerm2 can be set [following the instructions here](https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/)
