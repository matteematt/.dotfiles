# NEOVIM

This is an overview of my neovim config. I have started working on this since March 2022.
I have mainly just aimed for feature parity with my vim setup, though a lot of the functionality
such as autocompletion is obviously a lot better because it uses language servers.

## Config

### init.lua

This is the bootstrapping file for the rest of my config. Simple a lua file that contains `require`
statement for the rest of the config. All the rest bits of the main config live in `/lua/user`.

### /lua/user

#### Autopairs.lua

Config for the autopairs plugin (automatically adding in extra brackets for example).

#### Cmp.lua

Contains config for setting up the autocompletion. The available methods are:
* LSP (nvim lsp)
* LUA (nvim lua)
* Snippets (luasnip)
* Buffer (Other text from the buffer)
* Path (Data from filesystem path)

This file contains other things like keybindings that we can change. Look at the documentation on their github
for other options we can set.

> We are using icons for the completion which require nerdfonts

#### Colourscheme

Settings for my colourscheme which is mostly taken from my `vimrc` file. Sets up the colours correctly, and
then calls the initialisation function for gruvbit. I then disable the background otherwise it clashes with
the terminal background when using tmux.

#### Gitsigns

Plugin which wraps git integration. I am mostly just using it for change indicators in the sign column and keybindings
for jumping between changes. Could alter more settings such as keybindings here.

I didn't like the colour scheme which came with the plugin so I set my own highlight groups at the bottom, and then use
them instead.

#### Keymaps

Settings custom keybindings. Mostly things from my `vimrc` or just calling functionality from the plugins.

#### Options

This is setting up miscellaneous settings an options. First I have a table which we loop over just to set simple options.
More complicated options are then set using vimscript at the bottom of this file. This is where most of the miscellaneous
settings from the `vimrc` file are.

#### Plugins

Set up with `packer.nvim`. Added bootstrap code for packer so it automatically installs itself when first running neovim.
Then an autocommand is set so when you save the file it will automatically refresh/install the plugins. Add new plugins by
adding them to the startup hook at the bottom.

#### Telescope

Place to put settings for the `Telescope` plugin. However, I am not setting any settings so my file is blank.

#### Treesitter

Concerned with the settings for Treesitter. This is mostly just the default settings from their github.

#### LSP

This directory contains file which are used for the LSP config. To add a new LSP.

1. Use `:LspInstall` to look what LSPs are available. Choose what we want
2. We can use `:LspInfo` to check the status of the LSP for the current file type.
3. We can use `:LspInstallInfo` to managed the installed LSPs. Use `i` to install one, and `x` to remove.
4. If we want custom settings on the LSP clients as explained by each ones readme, we can add the options
under the settings directory, and then call these settings in the `lsp-installer.nvim` file.

##### Settings

This directory contains Lua files which are used for the specific settings for each LSP client we have configured. If we add
more LSP clients then we add our settings in here and add their bindings into `lsp-installer.nvim`.

##### Handlers

This is the main handling code for the LSP completion. A lot of the basic settings are put in here, such as what icons to
show in the signs column when there are diagnostics errors. At the bottom there is an `on_attach` hook which is ran when
initialising each language server. Here we can tweak settings for each LSP as it boots such as turning off their diagnostics
functionality for example.

##### init.nvim

Bootstrap file which runs the other initialisation files.

##### lsp-installer

Settings for attaching the language servers to nvim. If we want extra settings for each LSP then we can add this here.

##### null-ls

This is an extra client which is used for linting and diagnostics (think prettier/scalalint). If you go to the github
links which are in the file then we can see what builtin functionality is available for certain diagnostics types.

> Unlike the other LSP functionality which we can install using the commands in the LSP section, we need to manually
> install the binaries which are found here. For example for prettier you would do `$ brew install prettier` on MacOS.
> We require the binary to be in the `$PATH`. We can add extra settings for each diagnostics client in this file.

### Plugin

This is similar to the standard `plugin` directory from vim. The only thing of note in here is `ported.vim` which
sources over some of my plugins from vim.

* Statusline, gives me my custom statusline
* Startscreen, gives me my custom startscreen
* Misc, just some general functionality
* Comments, my simple comments plugin for commenting and uncommenting lines
* Zoom, which allows you to quickly view a buffer in an expanded view, and
	then retstore the previous view

### After

Symlinks to the `after` directory from my vim config, contains filetype settings such as showing blank space icons
in `yaml` and `python` languages.

### Colors

Symlinks to the `colors` directory from my vim config, so I can get my colourschemes

### Syntax

Symlinks to the `syntax` directory from my vim config, so I can get my custom syntax highlighting definitions. An
example of this is my custom syntax for my startup screen.

## Acknowledgements

[Great Tutorial Series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ)
