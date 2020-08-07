" Very simple fuzzy file picker for *nix terminals

if g:os == "Windows" || !executable("rg")
	echoerr "Unsupported OS or fzf not in path"
else
	let s:fzfPreview = executable("bat") ? 
		\ ' --preview "bat --theme="OneHalfDark" --style=numbers --color always {} | head -'.&lines.'"' : ''
	let s:fileCmd= executable("rg") ? 'rg --files --hidden --follow --glob "\!.git/*" | ' : ''

	function FuzzyFilePicker()
		let chosenFileLoc="$TMPDIR/vimpickfile"
		silent !clear
		execute "silent !rm ".chosenFileLoc
		execute "silent !".s:fileCmd."fzf".s:fzfPreview." > ".chosenFileLoc
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
