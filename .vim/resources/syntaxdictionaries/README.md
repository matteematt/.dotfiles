# Generating Syntax Dictionaries

To generate the files in this directory I did the following using `zsh`:
1. Download a large open source project for the programming language, such as a compiler
2. Flatten all files from subdirectories for the downloaded project, where `x` is the directory
```
# Faster but doesn't work if there are too many files
mv x/*/**/*(.D) x
# Works on a larger number of files
find x -mindepth 2 -type f -exec mv -f '{}' x ';'
```
3. `cd` into the directory
4. Remove all of the directories `rm -R -- *(/)`
5. Remove all files that are not for the programming language we are generating this file for
6. Merge all files in the directory into one `cat * > merged-file`
7. Process this merged file to get a list of useful keywords
