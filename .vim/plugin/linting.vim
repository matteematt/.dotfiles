" This will be expanded on in the future
" Uses an external program to lint the code, for now eslint for javascript

" 1. Copy the current buffer file to a temp file
" 2. Run the linter on the temp file
" 3. Delete the range in the current buffer that has just been linted
" 4. read the temporary file into the gap that has just been deleted

if !has("job") || version < 800
	" Non-compatible version of vim
else
	" ===== LINTING WRAPPERS =====
	" TODO: The error stuff does not currently work, so need to manually check if not working
	let s:javascriptLikeFix = $HOME . "/.dotfiles/.vim/bin/javascriptlinter.sh --fix"
	let s:fixCmdMappings = {
				\ "javascript": s:javascriptLikeFix,
				\ "javascriptreact": s:javascriptLikeFix,
				\ "json": s:javascriptLikeFix
				\}

	function linting#LinterFixSuccessCallback(channel)
		let cursorPos = getcurpos()
		normal ggdG
		execute "keepalt 0read " . g:linterCurrentFile
		normal Gdd
		call setpos('.', cursorPos)
		execute "silent !rm " . g:linterCurrentFile
		unlet g:linterCurrentFile
		redraw!
	endfunction

	" This is used to autofix lint issues, such as with eslint --fix
	function s:RunLinterFix()
		if exists('g:linterCurrentFile')
			echo "Already running lint job " . g:linterCurrentFile
			return
		endif
		let g:linterCurrentFile = expand("%s").".lint"
		let l:fileType=&filetype

		if !has_key(s:fixCmdMappings, l:fileType)
			echo "Linting fixer not set up for filetype: " . l:fileType
			unlet g:linterCurrentFile
			return
		endif

		if !has_key(s:hasInitFiletype, l:fileType) || s:hasInitFiletype[l:fileType] == 0
			echo "Linting did not initialise correctly for filetype: " . l:fileType
			unlet g:linterCurrentFile
			return
		endif

		let l:copySignal = system("cp " . expand("%s") . " " . g:linterCurrentFile)
		if strlen(l:copySignal) != 0
			echoerr "Error reading file on disk for linting: " . trim(l:copySignal)
			unlet g:linterCurrentFile
			return
		endif

		" TODO: Handle things like errors etc
		call job_start(s:fixCmdMappings[l:fileType] . " " . g:linterCurrentFile, {
			\"close_cb": "linting#LinterFixSuccessCallback",
			\})
	endfunction

	let s:errCmdMappings = {
				\ "scala": $HOME . "/.dotfiles/.vim/bin/scalalinter.sh",
				\ "haskell": $HOME . "/.dotfiles/.vim/bin/haskelllinter.sh",
				\ "python": "pylint",
				\}
	for ft in ["javascript","javascriptreact","json"] | let s:errCmdMappings[ft] =
				\ $HOME . "/.dotfiles/.vim/bin/javascriptlinter.sh" | endfor
	for ft in ["sh","dash","ksh","bash"] | let s:errCmdMappings[ft] = "shellcheck --format=gcc" | endfor
	unlet ft

	function linting#LinterErrSuccessCallback(channel)
		if filereadable(g:linterErrFile)
			execute "lfile! " . g:linterErrFile
			if getfsize(g:linterErrFile) < 1
				echomsg "No linting errors"
			endif
		else
			echoerr "Unable to read a valid file at ".g:linterErrFile
		endif
		execute "silent !rm " . g:linterErrFile
		unlet g:linterErrFile
		redraw!
	endfunction

	" This is used to display lint issues, such as with eslint
	function s:RunLinterErrors()
		if exists('g:linterErrFile')
			echo "Already running lint job " . g:linterErrFile
			return
		endif
		let g:linterErrFile = tempname()
		let l:fileType=&filetype

		if !has_key(s:errCmdMappings, l:fileType)
			echo "Linting not set up for filetype: " . l:fileType
			unlet g:linterErrFile
			return
		endif

		if !has_key(s:hasInitFiletype, l:fileType) || s:hasInitFiletype[l:fileType] == 0
			echo "Linting did not initialise correctly for filetype: " . l:fileType
			unlet g:linterErrFile
			return
		endif

		" TODO: Handle things like errors etc
		call job_start(s:errCmdMappings[l:fileType]." ".expand("%s"), {
			\"close_cb": "linting#LinterErrSuccessCallback",
			\"out_io": "file",
			\"out_name": g:linterErrFile
			\})
	endfunction

	" lint fix
	map <leader>lf :call <SID>RunLinterFix()<CR>
	" lint and show in quickfix
	map <leader>ll :call <SID>RunLinterErrors()<CR>

	" ===== INIT =====

	" Map for each filetype and how to initialise the linting
	let s:initCmdMappings = {
				\ "scala": $HOME . "/.dotfiles/.vim/bin/scalalinter.sh",
				\ "haskell": $HOME . "/.dotfiles/.vim/bin/haskelllinter.sh",
				\ "python": '/bin/sh -c "pylint --help"',
				\}
	" Don't actually need to init ESLint, but it needs a config file so may fail if that isn't set up
	for ft in ["javascript","javascriptreact","json"] |
				\ let s:initCmdMappings[ft] = $HOME . "/.dotfiles/.vim/bin/javascriptlinter.sh" | endfor
	" Check shellcheck is installed
	for ft in ["sh","dash","ksh","bash"] |
				\ let s:initCmdMappings[ft] = '/bin/sh -c "shellcheck --help"' | endfor
	unlet ft
	let s:hasInitFiletype = {}

	function linting#LinterInitCallback(channel)
		let l:initJob = ch_getjob(a:channel)
		let l:initJobInfo = job_info(l:initJob)
		let l:jobExitCode = str2nr(l:initJobInfo["exitval"])
		if l:jobExitCode != 0
			echoerr "Error setting up linter using cmd : '" . join(l:initJobInfo["cmd"]) . "'"
			let s:hasInitFiletype[&filetype] = 0
		else
			echo "Linter initialised for filetype: " . &filetype
			let s:hasInitFiletype[&filetype] = 1
		endif
	endfunction

	function s:RunLinterInit()
		let l:fileType=&filetype
		if &filetype == "" | echomsg "Unable to detect filetype for setting up linting" | endif
		if !has_key(s:initCmdMappings, l:fileType) || has_key(s:hasInitFiletype, l:fileType)
			return
		endif
		call job_start(s:initCmdMappings[l:fileType], {"close_cb": "linting#LinterInitCallback"})
	endfunction

	augroup InitLinter
    autocmd!
    autocmd FileType javascript,json,javascriptreact,scala,sh,bash,dash,ksh,haskell,python
					\ call <SID>RunLinterInit()
	augroup END
endif
