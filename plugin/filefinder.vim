" Contains settings to leverge the inbuilt find function to find files
" as nicely as possible

" sets the path to the enclosing git directory if possible
" or the current directory if not
if executable('git')
	let gitDir = system("git rev-parse --show-toplevel")
	if !empty(gitDir)
		let newPath = gitDir[:-2] . "/**"
		let &path=newPath
	else
		set path = $PWD/**
	endif
else
	set path = $PWD/**
endif

" dirs to ignore
set wildignore+=*/node_modules/*
set wildignore+=*/.git/*
set wildignore+=*/undo/*
" ignore compiled and binary files
set wildignore+=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.cache
" only show files not dirs
" set wildignore+=*/

nnoremap <leader>o :find<space>
