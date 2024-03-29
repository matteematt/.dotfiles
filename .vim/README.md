# VIM

This is my vim configuration that aims to be fairly portable and lightweight, while doing everything I personally like.
All of the custom plugins I have written are very likely worse versions of plugins that are publicly available, but I
like to roll my own where possible. My setup is only designed and tested to work with the systems I use, currently Arch
Linux and MacOS.  I am a novice at vimscript so I imagine a lot of my scripts could be improved.

## My Plugins

A description of the vim plugins found in the `plugin/` directory. Keybindings are included, but note there are more
keybindings that this, such as from the `vimrc` file.

### ColJumper

This script adds two new insert mode commands which helps with lining up text.
The jumper command moves the insert mode cursor in line with the next non-whitespace character in any of the above lines, or
keeps it in place if that is not possible. An example where this is useful could be to line up the cursor column in line
with an inline comment on the above line without having to press space or tab multiple times:
```
Cursor position signified by "@"
.....
let example = "great example"               " this is a great example
let x = 23@
.....
<C-j>
NB: In this particular example <C-j> needed to be pressed multiple times as there are multiple matching patterns for the
initial cursor position.
.....
let example = "great example"               " this is a great example
let x = 23                                  @
```
The pusher commands pushes the insert mode cursor in line with the next non-whitespace character in any of the above
lines, moving subsequent text after the cursor too. This is useful to lining up text that is already present:
```
Cursor position signified by "@"
.....
bitsToInt bits = sum (map (\x -> 2^(snd x)) trueLocations)
   where size = length bits
@indices = [size-1,size-2 .. 0]
.....
<C-k>
NB: In this example the command is requested twice, once to line up with "where" and then next with "size"
.....
bitsToInt bits = sum (map (\x -> 2^(snd x)) trueLocations)
   where size = length bits
         indices = [size-1,size-2 .. 0]
```
Other examples include lining up `<-` or `=` in Haskell.
```
<C-j> - Jump the insert mode cursor
<C-k> - Push the insert mode cursor
```

### Comments Toggle

A simple plugin to toggle a range of lines as commented or uncommented.
```
<leader>cc - Toggle the comment status of the selected range of lines
```
Supported types of commenting are:
* C-Style: such as `C`, `C++`, `Java`, `Javscript`
* Shell-Style: such as `Bash` and `Python`
* Vim: for `vimscript`
* Haskell: for `haskell`

### Fuzzy Buffer Picker

When vim has `*matchfuzzy`, this is used to populate the wildmenu with buffers that match the currently input search
term. Without `*matchfuzzy` the wildmenu is simply populated with all open buffers. When the command is invoked with no
argument it simply switches to the alternative buffer (buffer `#`).
```
<leader><leader> - Open the fuzzy buffer switcher
```


### Fuzzy File Picker

A fuzzy file picker with a syntax highlighted preview window if all dependencies are installed.
```
<leader>o - Open the fuzzy file picker
```

### GitCommands

A list of functions for working with git projects.
```
GitDiffFile(branch_name) - show a vertical split with the changes from the current file and the current file on the
specified branch. The branch_name defaults to master if not specified
MergeConflictList() - populate all locations with a merge conflict in the quickfix window
```

### Linting

I have written an synchronous linter wrapper for some programming languages I use. The script is found at
`plugin/linting.vim`. Info about the required dependencies can be found further down the readme.
```
<leader>ll - Run the linter and errors are shown in the quickfix window
<leader>lf - Run the linter to automatically fix linting errors and update the buffer
```
Currently supported linting is:
* `eslint` for Javscript, JavscriptReact, Typescript, TypescriptReact, and Json. Supports Linting errors and automatically fixing of some linting
		errors
* `scalastyle` for Scala. Only supports linting errors.
* `shellcheck` for bash, dash, sh, and ksh. Only supports linting errors.
* `pylint` for python. Only supports linting errors.
* `hlint` for haskell. `hlint` supports fixing linting, but this is not yet implemented in my vim
    script.

> The vim polyglot scala plugin breaks the scala linting, you must delete the line "compiler sbt" from the scala.vim file
> The vim polyglot typescript plugin breaks the typescript linting, you must delete the line "compiler typescript" from the typescript.vim file

### RegEx Search

Use `rg` to search for a pattern and fill the quickfix window
```
<leader>f - Find
```

### StartScreen

A custom start screen that is shown when vim is loaded without any filename or args etc. Entering insert mode via `i`
`o` or `e` will open a new empty buffer like vim would. Currently shows a section with the most recently opened files,
and a section showing the most recently opened files in this project (using the current working directory).
```
g:startup_section_len = x   " sets the max number of lines to show per section to x, default 5
```

### StatusBar

A custom status bar at the bottom. Shows the current mode, filename, and other useful info. If in a git project it shows
the current branch name, updated every time a buffer is read.

### Tags

This plugin contains two functions to work with tags. To work with tags an external application such as `universal
ctags` is required.
* An asynchronous wrapper to call ctags to generate a tags file.
** Vim will check for a file `.ctagsignore` and if present will use it to ignore files and
directories when generating the tags list.
* If `fzf` is installed a binding to enhance tag jumping. Using the `<leader>]` binding the jump will be initialised for
		the `<cword>`. The user will be alerted if there is no matching tag. If there is only one match it will
		automatically be taken. If there are multiple then fzf will be used to choose via the filename. A preview window
		will show the `ex` command which matches the tag in the file. If `bat` is installed it will be used to syntax
		highlight the `ex` command.
```
<leader>t - Generate tags file
<leader>] - Jump to tag
```

### Snippets

This is not a plugin on its own, but some languages have support for snippets. This can be achieved
in two ways
1) Using the abbreviation function of vim
2) Creating a marco to write in the snippet

The first one is natural as vim will automatically insert the abbreviation into the text as you
type. The macro has to be manually activated via a command, however, it comes with the flexibility
to move the cursor as part of the snippet.

#### Currently implemented snippets:

Abbreviations:
* `haskell` - `modulem` inserts the module decleration and main method decleration and signiture

Macros:
* `typescript` - `<leader>sd` inserts a describe block and puts the cursor inside of the text param

### Zoom

Leverages the inbuilt tab commands to quickly open a window in the maximum
window size view, and then restore the view again with the same keystroke. The
keystore that has been set is `<leader>z` (for zoom).

### Misc

#### Whitespace stripper

Autocommand which strips whitespace at the end of lines just before a buffer is written to disk.

### Custom Commands

Some custom commands are listed in the `commands.md` document. Commands are moved to this separate document if they are
more niche, such as commands that only work on one filetype.

## Dependencies

### Linting & Building

I have written some wrappers for linting and building projects in vimscript that interact with shell commands. Obviously
these shell commands are required for the specific linting, but not for anything else.

#### ESLint

ESLint is used for linting Javascript projects. ESLint also has an advantage that it can be used to automatically fix a
lot of the linting errors itself.  ESLint requires a `.eslintrc` file, which will likely be a reason that the linting
has not been able to correctly initialise.

#### Scalastyle

Scalastyle is used for linting Scala projects. Scalastyle does not support automatically fixing linter errors. As
scalastyle does not support output vim quickfix format output a shell wrapper is used at `bin/scalalinter.sh` in
addition to the vimscript linter file. Scalastyle also requires a config file, the location of which on the filesystem
is also configured in the shell script.

### Binaries

Current non-bundled dependencies are `rg` and `fzf` binaries. Additionally the `bat` binary will be used to preview the
viewed file in the fuzzy file picker if installed. These can all be installed via brew and linuxbrew.  `fzf` and `bat`
are currently only used for the file picker, which while wonderful, you could manage without them. However, `rg` is
instrumental to many of the plugins and many parts of this configuration are likely to not work without it.

`universal ctags` is useful to generate `tags` file which vim supports out of the box to jump to definitions. It supports
many languages, some such as scala are not supported but config to get it to work can be found online.

### Undo Tree

I have bundled [undotree](https://github.com/mbbill/undotree) in this repo, as it is the one plugin I would not want to
be without.

### Vim-Polyglot

[This is a great bundle pack](https://github.com/sheerun/vim-polyglotv) of syntax highlighting which the bundle
maintainers also trim for performance. This is not included in this repository as I can live without it. The line
required to install/update can be found as part of `external/install.sh`

### Colour Schemes

I like to have as little dependencies as possible so I have bundled the colour schemes into this repo.

#### XCode Colour Scheme

The original [can be found here](https://github.com/arzg/vim-colors-xcode).  To update the colour schemes with the repo
if git is installed.	arzg/vim-colors-xcode is licensed under the ISC License.

```
git clone https://github.com/arzg/vim-colors-xcode.git $TMPDIR/vim-colors-xcode
cp -r $TMPDIR/vim-colors-xcode/{autoload,colors,doc} ~/.dotfiles/.vim
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
cp -r $TMPDIR/onedark/{autoload,colors} ~/.dotfiles/.vim
```

To enable
```
" README explains setting termguicolors, need extra check for tmux or nvim
colorscheme onedark
```

Use the readme in the repo to set up the colour scheme. The vimrc in this repo sets up to use 256 colours and italics.
A fallback option can be set in case the terminal in use does not support 256 colours.  Italics can be disabled if the
terminal doesn't support it. iTerm2 can be set [following the instructions
here](https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/)

#### GruvBit Colour Scheme

[This great colourscheme](https://github.com/habamax/vim-gruvbit) is based on gruvbox-hard, but with syntax groups that
I prefer.
```
git clone https://github.com/habamax/vim-gruvbit $TMPDIR/vim-gruvbit
cp -r $TMPDIR/vim-gruvbit/colors/gruvbit.vim ~/.dotfiles/.vim/colors/
# The MatchParen HL group colours don't work well on alacritty, so I find
# swapping it to be better. Change the following line
hi MatchParen guifg=#1d2021 guibg=#fe8019 gui=NONE cterm=NONE
# to
hi MatchParen guifg=#fe8019 guibg=#1d2021 gui=NONE cterm=NONE
```

To enable with bold, italics, and a small vertical split
```
function! s:setup_gruvbit_colourscheme() abort
    hi Comment gui=italic cterm=italic
    hi Statement gui=bold cterm=bold
    hi VertSplit guibg=NONE ctermbg=NONE
endfunc
augroup colorscheme_change | au!
    au ColorScheme * call s:setup_gruvbit_colourscheme()
augroup END
colorscheme gruvbit
```
