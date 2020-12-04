" Contains helper functions for formatting code/text in various languages

" Formats the code block the cursor is currently in as a Haskell multi-line string
" does not work on a string with empty lines
function! formatting#HaskellMultiline()
  " Set mark t to the top and mark b to the bottom
  norm vipmbomt
  " Add a temporary variable name and opening quote
  norm Ix = "
  " Set the top to the bottom-1 to have \n\ at the EOL
  't,'b-1g/./norm A\n\
  " Set the top+1 to the bottom to have \ at the start
  't+1,'bg/./norm I\
  " Add a closing quote at the end of the final string
  norm 'bA"
endfunction
