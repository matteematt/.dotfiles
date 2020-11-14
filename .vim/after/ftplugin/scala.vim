setlocal include=^\\s*import
setlocal includeexpr=substitute(v:fname,'\\.','/','g')
