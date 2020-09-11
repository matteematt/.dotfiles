let s:gitBranch=""
if g:has_git
	" get the git major and minor version number
	" getting branch name on older versions (2.21 >=) was causing slowdown
	let s:gitversion = system("git --version | cut -d' ' -f 3  | cut -d '.' -f 1-2")
	if (str2float(s:gitversion) >= 2.22)
		augroup GetGitBranch
			au!
			au BufWritePre,BufReadPre * call s:GetGitBranch()
		augroup END
	endif
endif

function! s:GetGitBranch()
	let l:gitBranch = system("git branch --show-current")
	" need to delete what I think is a newline char at the end
	" v:shell_error catches this not being a git repo, but also not show
	" for any other reason
	let s:gitBranch =  v:shell_error ? "" : " ⎇ ".l:gitBranch[0:strlen(l:gitBranch)-2]." "
endfunction

let s:modesDict={
	\ "n": ' NORMAL ',
	\ "i": ' INSERT ',
	\ "R": 'REPLACE ',
	\ "v": ' VISUAL ',
	\ "V": 'VISUAL-L',
	\ "": 'VISUAL-B',
	\ "t": 'TERMINAL',
	\ }
let s:lastMode="n"

function! s:GetModeText()
	let l:mode = mode()
	if has_key(s:modesDict, l:mode)
		let s:lastMode = l:mode
	endif
	return " ".s:modesDict[s:lastMode]." "
endfunction

function! s:GetModeColour()
	let l:mode = mode()
	if (l:mode =~# '\v(i|R)')
		return "%#DiffAdd#"
	elseif (l:mode =~# '\v(v|V|)')
		return "%#DiffText#"
	elseif (l:mode =~# '\v(t)')
		return "%#ToolbarButton#"
	else
		return "%#PMenuSel#"
	endif
endfunction

" Only show the mode for the statusline of the current window
" Only works on version vim > 8.1.1372
function! s:GetShowMode()
	return g:statusline_winid == win_getid(winnr())
endfunction

function! CreateStatusLine()
	let l:statusline=""
	if s:GetShowMode()
		let l:statusline.=s:GetModeColour()
		let l:statusline.=s:GetModeText()
	endif
	let l:statusline.="%#VisualNOS#"															" set highlight group colour to VisualNOS
	let l:statusline.=s:gitBranch																	" show the git branch
	let l:statusline.="%#LineNr#"																	" set the highlight group to LineNr
	let l:statusline.=" %f"																				" path to the file in the buffer
	let l:statusline.="%m"																				" modified flag for the file in the buffer
	let l:statusline.="%="																				" separation point between right and left aligned items
	let l:statusline.="%#CursorColumn#"														" set highlight group colour to the cursor column
	let l:statusline.=" %y"																				" type of file e.g [vim]
	let l:statusline.=" %{&fileencoding?&fileencoding:&encoding}"	" show file encoding e.g. utf-8
	let l:statusline.="\[%{&fileformat}\]"												" show file format e.g. [unix]
	let l:statusline.=" %p%%"																			" the percentage down the file the cursor is on, and add % symbol
	let l:statusline.=" %l:%c "																		" the line and column position of the cursor
	return	l:statusline
endfunction

set laststatus=2																						" Always show the status bar
set statusline=%!CreateStatusLine()

