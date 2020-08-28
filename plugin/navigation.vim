" Vim script functions and snippets to aid with navigation

" TODO: Need to account for file names not being added
function GotoRelativeFile()
	let l:baseDir = getcwd()
	cd %:p:h
	norm gf
	execute "cd ".l:baseDir
endfunction
