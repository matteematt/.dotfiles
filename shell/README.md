# Shell Dotfiles

General shell scripts and configurations are found in this directory. These shell scripts have been written on and are
used for the `zsh` shell, but they may work on other shells too. Including the `.zshrc` file contains miscellaneous
cross-platform configurations and also includes the other shell scripts in this directory too.

## Configurations

### Directory Jumping

The `dir_jumping.sh` file contains shell functions to make moving around the file system on the command line far quicker
and painless.

* `changeDirShortcut` - Use fzf to choose a directory to jump to from a list of favourites. Aliased to `cdf` in `.zshrc`.
* `pushChangedDirToList` - When you change a directory the jumped directory is added to a history file, contains the
		last 100 unique entries. Overwrites the standard `cd` in the `.zshrc`.
* `changeDirFromHistory` - Use fzf to jump to one of the directors saved from the usage of the last command.

### GIT Extras

The `git_extras.sh` file contains shell functions to wrap up git functionality I use a lot, mainly to do with staging
files ready for commit.

* `gitViewAndStage` use fzf with a bat preview to view unstaged files, selecting them stages them. Aliased to `gvs` in
		the `.zshrc`.
* `getDiffByList` use fzf to preview unstaged files, selecting them outputs the file and saves the filename to
		`$chosen_file`. Aliased to `gdl` in the `.zshrc`.
* `addLastDiffFile` stages the filename from `$chosen_file`. Aliases to `gal` in the `.zshrc`.

## Scripts

### View Unstaged File

The `view_git_unstaged_file.sh` script outputs a file name in a certain way depending on the git status of the file.

* Untracked files are viewed to standard output
* Modified files are viewed by their diff compared to master
* Deleted files print a message saying the file has been deleted or renamed
* Unknown file status prints error message

## Other Files

### Extra Platform Specific

The `Darwin_includes.sh` and `Linux_includes.sh` are shell scripts which contain very minor configurations for the OS
specifically.

### Favourite Directories Lists

The `fav_dirs_Darwin` and `fav_dirs_Linux` files contain a list of favourite directories to jump to on each platform.
