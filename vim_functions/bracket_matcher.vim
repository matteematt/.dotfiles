" Inserts a matching pair of matching brackets [{(
" Deletes the matching pair if they are adjacent
" Adds an extra line of space if these are on the right of the cursor during <CR>
" All toggled using g:use_ide_brackets

"let g:use_ide_brackets = 1

if !exists("g:use_ide_brackets")
    let g:use_ide_brackets = 0
endif



if g:use_ide_brackets == 1
    inoremap { {}<Esc>i
    inoremap [ []<Esc>i
    inoremap ( ()<Esc>i
endif
