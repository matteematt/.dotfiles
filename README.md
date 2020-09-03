# VIM

This is my vim configuration that aims to be fairly portable and lightweight, while doing everything I personally like. All of the custom plugins I have written are very likely worse versions of plugins that are publicly available, but I like to roll my own where possible. My setup is only designed and tested to work with the systems I use, currently Arch Linux and MacOS.
I am a novice at vimscript so I imagine a lot of my scripts could be improved.

## My Plugins

### Fuzzy File Picker

### StatusBar

### GitCommands

### Comments Toggle

### Misc

#### Whitespace stripper

## Dependencies

### Binaries

Current non-bundled dependencies are `rg` and `fzf` binaries. Additionally the `bat` binary will be used to preview the viewed file in the fuzzy file picker if installed. These can all be installed via brew and linuxbrew.
`fzf` and `bat` are currently only used for the file picker, which while wonderful, you could manage without them. However, `rg` is instrumental to many of the plugins and many parts of this configuration are likely to not work without it.

### Undo Tree

I have bundled [undotree](https://github.com/mbbill/undotree) in this repo, as it is the one plugin I would not want to be without.

### Vim-Polyglot

[This is a great bundle pack](https://github.com/sheerun/vim-polyglotv) of syntax highlighting which the bundle maintainers also trim for performance. This is not included in this repository as I can live without it. The line required to install/update can be found as part of `external/install.sh`

### Colour Schemes

I like to have as little dependencies as possible so I have bundled the colour schemes into this repo.

#### XCode Colour Scheme

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

#### OneDark Colour Scheme

The original [can be found here](https://github.com/joshdick/onedark.vim.git).
This colour scheme is licensed under the MIT Licence.
```
git clone https://github.com/joshdick/onedark.vim.git $TMPDIR/onedark
cp -r $TMPDIR/onedark/{autoload,colors} ~/.vim
```

Use the readme in the repo to set up the colour scheme. The vimrc in this repo sets up to use 256 colours and italics.
A fallback option can be set in case the terminal in use does not support 256 colours.
Italics can be disabled if the terminal doesn't support it. iTerm2 can be set [following the instructions here](https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/)
