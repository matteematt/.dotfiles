# Dotfiles

This repo contains all of my configuration across multiple platforms. The main platforms I use are Arch Linux and MacOS.
Platform specific configurations for Arch are in the `arch/` directory, general configuration are across the other
directories.

## Dependencies

It is likely stating the obvious but many of these scripts and configurations contained in this repository require the
[GNU Core Utils](https://www.gnu.org/software/coreutils/) installed. For MacOS this may require specific core utils to
have the GNU versions specifically downloaded, such as `gawk` so the `match` function can be used, which is not included
in the BSD-like version of `awk` that MacOS ships with.

This repository additionally makes heavy use of some of the "replacement" core util packages. Eventually I might get
around to writing the scripts to fall back on the original core utils if the "replacement" versions are not installed.
For now the main extra programmes required are:

* [bat](https://github.com/sharkdp/bat) which is a `cat` clone with syntax highlighting and git integration
* [fzf](https://github.com/junegunn/fzf) which allows you to fuzzy match on a line from standard input
* [rg](https://github.com/BurntSushi/ripgrep) which is a `grep` clone written in rust

All of the above "replacement" utils can be installed using `brew` or `linuxbrew`.

## Configurations

The following sections summarise the configuration that each directory controls.

### Arch

The configuration files that are specific for my Arch Linux install (e.g. i3 and XOrg) are found in the `arch/`
directory.

### Data

Any scripts or commands that require to save data to the filesystem save the data to the `data/` directory. An example
of a data file is the history list of `cd` commands for the history jumper command. All files in the `data/` directory
are in the `.gitignore`

### Fonts

The following fonts I have included into this repository that I use for my terminal and text editors. They are fonts
freely downloadable on the internet that I have patched with the [Nerd fonts patching tool](https://www.nerdfonts.com).
* Monaco Nerd Font Complete Mono.otf
* Source Code Pro Nerd Font Complete Mono.ttf

### Install Script

`install.sh` is a very basic installation script for installing some of these configuration files in this repo to the
main filesystem. An example of this is symlinking the `.vim/` directory to `~/.vim/`. This is a crude script which
doesn't check for overwriting files for example. Some extra installation for `vim` is required (such as installing
`vim-polyglot` plugin) is required. Explanation for this is found in the `.vim/README.md`.

### Linting

Configuration for linting programmes is found in the `linting/` directory.

### Shell

Shell scripts and general configurations are found in the `shell/` directory. Platform specific configurations are found
in their platform directory - for example the Arch specific configuration is in `arch/.zshrc`. The root configuration to
source is `shell/.zshrc` which includes the other configurations in that file. This directory also includes some shell
scripts. For more info see `shell/README.md`.

### Wiki

The `wiki/` directory contains markdown documents for information I find useful for myself.

## Licensing

All of *my* configurations are licensed under the GPL licence. However, some files in this repo are from other places on
the internet and I did not create them.

```
All of my configuration files
Copyright (C) 2020 Matt Walker

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

The exceptions are the files which are included from other places on the internet - they follow the original licences
that they are under. These files include:

* Monaco Nerd Font Complete Mono.otf - [© 1990-91 Apple Computer Inc. © 1990-91 Type Solutions Inc. © 1990-91 The Font Bureau Inc.](https://www.cufonfonts.com/font/monaco). If you believe that this font is in violation of copyright and isn't legal, please let me know in order for the font to be removed or revised.
* Source Code Pro Nerd Font Complete Mono.ttf = [These fonts are licensed under the Open Font License. You can use them freely in your products & projects - print or digital, commercial or otherwise. However, you can't sell the fonts on their own.](https://fonts.google.com/specimen/Source+Code+Pro#standard-styles)
* External vim plugins, more info on that in `.vim/README.md`
