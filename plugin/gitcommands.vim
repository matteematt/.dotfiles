" My set of plugins to work with git

if executable("git")
	function GitDiffFile(...)
		let l:branchToCompare = (a:0 == 1) ? a:1 : "master"
		let l:compareFileLoc = "$TMPDIR/vimcomparefile"
		let l:returnText = system("git show ".l:branchToCompare.":".expand("%s")." > ".l:compareFileLoc)
		redraw!
		" Any error message would be returned making the string non-empty
		if empty(l:returnText)
			execute "vertical diffsplit ".l:compareFileLoc
			set nomodifiable
		else
			echoerr l:returnText
		endif
	endfunction

	function MergeConflictList()
		cgetexpr system('rg --vimgrep "<<<<<<< HEAD"')
	endfunction
endif
