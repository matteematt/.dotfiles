" Very simple fuzzy file picker for *nix terminals

if g:os == "Windows" || !g:has_rg || !g:has_fzf
	echoerr "Unsupported OS or fzf not in path"
else
	let s:fzfPreview = g:has_bat ?
		\ ' --preview "bat --theme="OneHalfDark" --style=numbers --color always {} | head -'.&lines.'"' : ''
	" TODO: Probably don't need the rg check seen as the script already does that
	let s:fileCmd= g:has_rg ? 'rg --files --hidden --follow --glob "\!.git/*" | ' : ''

	function FuzzyFilePicker()
		let chosenFileLoc="$TMPDIR/vimpickfile"
		silent !clear
		execute "silent !rm -f ".chosenFileLoc
		execute "silent !".s:fileCmd."fzf".s:fzfPreview." > ".chosenFileLoc
		redraw!
		if v:shell_error
			" Error with the shell - or just didn't pick an item
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
