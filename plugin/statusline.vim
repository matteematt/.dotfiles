function! GitBranch()
  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
  let l:branchname = GitBranch()
  return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

set laststatus=2																						" Always show the status bar

set statusline=																							" clear the existing status bar
set statusline+=%#PmenuSel#																	" set highlight group colour to PmenuSel
set statusline+=%{StatuslineGit()}													" show the git branch
set statusline+=%#LineNr#																		" set the highlight group to LineNr
set statusline+=\ %f																				" path to the file in the buffer
set statusline+=%m																					" modified flag for the file in the buffer
set statusline+=%=																					" separation point between right and left aligned items
set statusline+=%#CursorColumn#															" set highlight group colour to the cursor column
set statusline+=\ %y																				" type of file e.g [vim]
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}	" show file encoding e.g. utf-8
set statusline+=\[%{&fileformat}\]													" show file format e.g. [unix]
set statusline+=\ %p%%																			" the percentage down the file the cursor is on, and add % symbol
set statusline+=\ %l:%c																			" the line and column position of the cursor
set statusline+=\
