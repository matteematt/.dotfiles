" This will be expanded on in the future
" Uses an external program to lint the code, for now eslint for javascript

" 1. Copy the current buffer file to a temp file
" 2. Run the linter on the temp file
" 3. Delete the range in the current buffer that has just been linted
" 4. read the temporary file into the gap that has just been deleted

if !has("job") || version < 800
	" Non-compatible version of vim
else
	" TODO: The error stuff does not currently work, so need to manually check if not working
	let s:javascriptLike = "eslint --fix"
	let s:cmdMappings = {
				\ "javascript": s:javascriptLike,
				\ "javascriptreact": s:javascriptLike
				\}

	function linting#LinterFixSuccessCallback(channel)
		let cursorPos = getcurpos()
		normal ggdG
		execute "0read " . g:linterCurrentFile
		call setpos('.', cursorPos)
		execute "silent !rm " . g:linterCurrentFile
		unlet g:linterCurrentFile
		redraw!
	endfunction

	function linting#LinterFixErrCallback(channel, message)
		echo "In the error callback"
		echo a:channel
		echo a:message
	endfunction

	function s:RunLinterFix()
		if exists('g:linterCurrentFile')
			echo "Already running lint job " . g:linterCurrentFile
			return
		endif
		let g:linterCurrentFile = expand("%s").".lint"
		let l:fileType=&filetype

		if !has_key(s:cmdMappings, l:fileType)
			echo "Linting not set up for filetype: " . l:fileType
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
		call job_start(s:cmdMappings[l:fileType]." ".g:linterCurrentFile, {
			\"close_cb": "linting#LinterFixSuccessCallback",
			\"err_cb": "linting#LinterFixErrCallback"
			\})
	endfunction

	" lint fix
	map <leader>lf :call <SID>RunLinterFix()<CR>
endif
