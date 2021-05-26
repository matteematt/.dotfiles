" Plugin which is used to toggle comments for various filetypes

function comments#CommentCheckVimscript(checkLine)
	let l:matchIndex = match(a:checkLine, '^\s*"')
	return (l:matchIndex == -1) ? 0 : 1
endfunction

function comments#CommentCheckCStyle(checkLine)
	let l:matchIndex = match(a:checkLine, '^\s*\/\/')
	return (l:matchIndex == -1) ? 0 : 1
endfunction

function comments#CommentCheckHaskellStyle(checkLine)
	let l:matchIndex = match(a:checkLine, '^\s*--')
	return (l:matchIndex == -1) ? 0 : 1
endfunction

function comments#CommentCheckShellStyle(checkLine)
	let l:matchIndex = match(a:checkLine, '^\s*#')
	return (l:matchIndex == -1) ? 0 : 1
endfunction

let s:commentCommands = {
	\"vim": {"cmd": "comments#CommentCheckVimscript", "add":'0I f"2xhx', "del": 'I" '},
	\"cstyle": {"cmd": "comments#CommentCheckCStyle", "add":'0I f/3xhx', "del": 'I// '},
	\"haskellstyle": {"cmd": "comments#CommentCheckHaskellStyle", "add":'0I f-3xhx', "del": 'I-- '},
	\"shellstyle": {"cmd": "comments#CommentCheckShellStyle", "add":'0I f#2xhx', "del": 'I# '}
	\}

" TODO: javascriptreact needs to be improved for different types of comments in jsx blocks
let s:filetypesMap = {
	\"vim":"vim",
	\"javascript":"cstyle",
	\"javascriptreact":"cstyle",
	\"typescript":"cstyle",
	\"typescriptreact":"cstyle",
	\"scala":"cstyle",
	\"java":"cstyle",
	\"groovy":"cstyle",
	\"c":"cstyle",
	\"cpp":"cstyle",
	\"sh":"shellstyle",
	\"python":"shellstyle",
	\"yaml":"shellstyle",
	\"yaml.docker-compose":"shellstyle",
	\"dockerfile":"shellstyle",
	\"zsh":"shellstyle",
	\"haskell":"haskellstyle",
	\}

function s:ToggleComments() range
	" This is a comment
	let l:fileType = &filetype
	if !has_key(s:filetypesMap, l:fileType)
		echo "Comment toggle not setup for filetype: " . l:fileType
		return
	endif

	let cursorPos = getcurpos()
	let l:checkLine = getline(a:firstline)

	let l:cmdDict = s:commentCommands[s:filetypesMap[l:fileType]]
	let l:CheckCmd = function(l:cmdDict["cmd"])
	let l:cmd = l:CheckCmd(l:checkLine) ? l:cmdDict["add"] : l:cmdDict["del"]
	execute a:firstline . "," . a:lastline  . " normal " . l:cmd

	call setpos('.', cursorPos)
endfunction

nnoremap <leader>cc :call <SID>ToggleComments()<CR>
vnoremap <leader>cc :call <SID>ToggleComments()<CR>
