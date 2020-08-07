" Very simple fuzzy file picker for *nix terminals

if g:os == "Windows"
	echoerr "Simple fuzzy file does not currently support windows"
else
	function FuzzyFilePicker()
		let chosenFileLoc="$TMPDIR/vimpickfile"
		execute "silent !rm ".chosenFileLoc
		execute "silent !fzf > ".chosenFileLoc
		redraw!
		if v:shell_error
			echoerr "There was an error with the shell"
		else
			let expandedFilePath = expand(chosenFileLoc)
			if filereadable(expandedFilePath)
				let contents = readfile(expandedFilePath, '', 1)
				if !empty(contents)
					execute "edit ".contents[0]
				endif
			else
				echoerr "Unable to read a valid file at ".expandedFilePath
			endif
		endif
	endfunction

	nnoremap <leader>o :call FuzzyFilePicker()<Enter>
endif
