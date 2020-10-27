" ----------------------------------------
" Initialise the startup buffer text contents

let s:sectionsLen = exists('g:startup_section_len') ? g:startup_section_len : 5

function! s:StartupScreen()
	call s:ShowTitle()
	call append('$', "")
	call s:ShowRecentProjectFilesBlock()
	call append('$', "")
	call s:ShowOldfilesBlock()
endfunction

function! s:ShowTitle()
	let title = [
				\ ' ___      ___  ___      _____ ______       ',
				\ '|\  \    /  /||\  \    |\   _ \  _   \     ',
				\ '\ \  \  /  / /\ \  \   \ \  \\\__\ \  \    ',
				\ ' \ \  \/  / /  \ \  \   \ \  \\|__| \  \   ',
				\ '  \ \    / /    \ \  \   \ \  \    \ \  \  ',
				\ '   \ \__/ /      \ \__\   \ \__\    \ \__\ ',
				\ '    \|__|/        \|__|    \|__|     \|__| ']

	for line in l:title
		call append('$', ' ' . line)
	endfor
endfunction

function! s:ShowRecentProjectFilesBlock()
	if !has("viminfo") | return | endif
	let chooseList = []
	let currDir = getcwd()
	let i = 0
	for item in v:oldfiles
		if expand(item) =~ currDir
			call add(chooseList, '['.i.'] ' . item)
		endif
		let i += 1
	endfor

	call append('$', "  ### PROJECT FILES")
	if len(chooseList) == 0
		call append('$', "  -- No recent files to list from this working directory")
	else
		for item in chooseList[0:s:sectionsLen-1]
			call append('$', "  " . item)
		endfor
	endif
endfunction

function! s:ShowOldfilesBlock()
	if !has("viminfo") | return | endif
	let chooseList = []
	let i = 0
	for item in v:oldfiles[0:s:sectionsLen-1]
		call add(chooseList, '['.i.'] ' . item)
		let i += 1
	endfor

	call append('$', "  ### RECENT FILES")
	if len(chooseList) == 0
		call append('$', "  -- No recent files to list")
	else
		for item in chooseList
			call append('$', "  " . item)
		endfor
	endif
endfunction

" TODO: Add choosing previous layouts if I ever start using that functionality

" ----------------------------------------
" Initialise the startup buffer functionality
function! s:InitStartupBuffer()
	" Don't run if: we have commandline arguments, we don't have an empty
	" buffer, if we've not invoked as vim or gvim, or if we'e start in insert mode
	if argc() || line2byte('$') != -1 || v:progname !~? '^[-gmnq]\=vim\=x\=\%[\.exe]$' || &insertmode
		return
	endif

	" Start a new buffer ...
	enew

	" ... and set some options for it
	setlocal
				\ bufhidden=wipe
				\ buftype=nofile
				\ nobuflisted
				\ nocursorcolumn
				\ nocursorline
				\ nolist
				\ nonumber
				\ noswapfile
				\ norelativenumber
				\ nospell

	set filetype=startup

	call s:StartupScreen()

	" No modifications to this buffer
	setlocal nomodifiable nomodified

	" When we go to insert mode start a new buffer, and start insert
	nnoremap <buffer><silent> e :enew<CR>
	nnoremap <buffer><silent> i :enew <bar> startinsert<CR>
	nnoremap <buffer><silent> o :enew <bar> startinsert<CR>
endfunction

" Run after "doing all the startup stuff"
autocmd VimEnter * call <SID>InitStartupBuffer()
