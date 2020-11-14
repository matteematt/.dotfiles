# VIM Tricks

## Open all buffers with a string matching an expression

This uses `ripgrep` but could easily be substituted for `grep` if `ripgrep` is not installed.

1. `:r! rg -F "<search-string>"` will place the search output in the current buffer. `-F` sets to search for literal strings rather than parse as regex.
2. `:%norm f:d$` will go to each line, move the cursor to the colon character and then delete the rest of the line, just leaving the file name.
3. `:%sort u` will remove duplicate file names (happens if the same file matches the string mulitple times)
4. Record a macro `qq gf<C-6>j` and play it on each line. Executes goto file, and then switch back to the buffer with the file names and go down a line.
