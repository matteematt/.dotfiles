if g:has_ctags

	if g:has_fzf
		" Jump to tag under cursor, but if there is more than one use fzf to preview
		let s:tagFileLoc=expand("$TMPDIR/vimtagfile")
		let s:chosenTagLoc=expand("$TMPDIR/vimchosentag")
		let s:fzfCmd = "fzf --with-nth 2 < " . s:tagFileLoc . " --preview 'echo {} | cut -d\" \" -f3-"

		" Need to escape certain characters like "[" which are used as groups in regex
		function! tags#EscapeJumpCmd(cmd)
			return substitute(a:cmd, "\\(\\[\\|\\]\\)", "\\\\\\1", "g")
		endfunction

		function! tags#FuzzyTagPicker(tags)
			execute "silent !rm " . s:tagFileLoc . " " . s:chosenTagLoc
			let i = 0
			let writeList = []
			for tagMatch in a:tags
				call add(writeList, i . " " . tagMatch["filename"] . " " . tagMatch["cmd"])
				let i += 1
			endfor
			call writefile(writeList, s:tagFileLoc)
			let l:previewCmd = g:has_bat ? " | bat --theme=\"OneHalfDark\" --color always -p -l " . &filetype . "'" : "'"
			execute "silent !" . s:fzfCmd . l:previewCmd . " > " . s:chosenTagLoc
			redraw!
			if v:shell_error
				" Error with the shell - or just didn't pick an item
			else
				if filereadable(s:chosenTagLoc)
					let contents = readfile(s:chosenTagLoc, '', 1)
					if !empty(contents)
						let splitString = split(contents[0], " ")
						let rawCmd = join(splitString[2:])
						let escapedCmd = tags#EscapeJumpCmd(rawCmd)
						execute "edit " . splitString[1]
						execute escapedCmd
					endif
				else
					echoerr "Unable to read a valid file at ".expandedFilePath
				endif
			endif
		endfunction

		function! s:CustomTagJump()
			let l:tag = expand("<cword>")
			let l:fileName = expand("%")
			let l:tags = taglist(l:tag, l:fileName)
			if empty(l:tags)
				echo "Tag '" . l:tag . "' not in tag file"
			elseif len(l:tags) == 1
				execute "edit " . l:tags[0]["filename"]
				execute tags#EscapeJumpCmd(l:tags[0]["cmd"])
			else
				" Multiple tags to choose from, so need to use fuzzy picker
				call tags#FuzzyTagPicker(l:tags)
			endif
		endfunction

		nnoremap <leader>] :call <SID>CustomTagJump()<CR>
	endif

	" Run an async job to generate tag files using universal ctags
	function! tags#runAsyncTagsCallback(channel)
		let l:initJob = ch_getjob(a:channel)
		let l:initJobInfo = job_info(l:initJob)
		let l:jobExitCode = str2nr(l:initJobInfo["exitval"])
		let l:msg = (l:jobExitCode != 0) ? "Error generating tags file" : "Generated tags file"
		echo l:msg
	endfunction

	function! s:runAsyncTagsGeneration()
		call job_start("ctags -R .", {"close_cb":"tags#runAsyncTagsCallback"})
	endfunction

	nnoremap <leader>t :call <SID>runAsyncTagsGeneration()<CR>
endif
