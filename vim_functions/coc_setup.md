# How to setup COC language servers

The first step required is to install coc itself. Install it with the vim package manager being used. If the package manager in use does not support post install scripts then you need to navigate to the installed directory and then run the install `yarn install --frozen-lockfile`. There are some additional configs required in a .vimrc, they are tracked in vim_functions/coc_setup.vim.

More info [can be found here](https://github.com/neoclide/coc.nvim)

# Addons

You can download addons for coc

## Marketplace

Install the marketplace with `:CocInstall coc-marketplace`. Once it is installed you can invoke it with `:CocList marketplace` to fuzzy search fo the available addons.

# Language servers

Each language needs their own server to be insalled and configured with the text editor. This usually requires a system install and a vim plugin. Below are instructions for each language done so far.

## Groovy

1. [Download and setup to repo](https://github.com/prominic/groovy-language-server) and build it with gradle
2. Add the required config in `coc-settings.json`
```
  "languageserver": {
    "groovy": {
      "command": "java",
      "args" : ["-jar", "/path/to/groovy-language-server-all.jar"],
      "filetypes": ["groovy"]
     }
  }
```
Not sure this is actually working though

## C Family

[coc-ccls](https://github.com/MaskRay/ccls/wiki) appears to be the preferred language server for the C family of languages. The other option is `clangd`.

1. Build the package. Many distributions have a simple way such as `sudo pacman -Sy ccls` or using `brew install ccls` on MacOS.
2. Download and install `coc-ccls` with with marketplace in vim
- `extension.js` did not appear to be in the place vim was expecting so I had to symlink it to the expected location
3. Create a JSON compilation database at the project root
- I had look with BEAR from the AUR and then running `$ bear <build command>` -> `$ brear makepp shed`
4. Add required config in `coc-settings.json`
```
   "languageserver": {
     "ccls": {
       "command": "ccls",
       "filetypes": ["c", "cpp", "objc", "objcpp"],
       "rootPatterns": [".ccls", "compile_commands.json", ".vim/", ".git/", ".hg/"],
       "initializationOptions": {
          "cache": {
            "directory": "/tmp/ccls"
          }
        }
     }
   }
 ```


## Scala

[coc-metals](https://github.com/scalameta/coc-metals) 
