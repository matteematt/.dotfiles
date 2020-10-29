" Used to generate the dictionary lists at resources/syntaxdictionaries/

" remove non-alphanumeric characters
%s/[^a-zA-Z0-9]/ /
" move each token onto a separate line
%s/\s\+//
" remove tokens that are only numeric characters
%g/^[0-9].$/norm dd
" remove lines that are only one character
%g/^.$/norm dd
" remove any blank lines
%g/^$/norm dd
" sort and remove duplicates
%!sort -u
