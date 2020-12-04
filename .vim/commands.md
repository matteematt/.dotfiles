# Vim Custom Commands

This file contains a list of vim custom commands that are more niche than the commands that are found in the main
document. For example these are commands that only work on one filetype.

## Haskell

## Format Multiline String

Sets a command `FormatMS` local to the current buffer. This will convert a contiguous line of text into a correctly
formatted Haskell multi-line string. For example:
```
254
53
333
65
```
becomes:
```
x = "254\n\
\53\n\
\333\n\
\65"
```
