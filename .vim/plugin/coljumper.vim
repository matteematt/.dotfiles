if has("syntax") && has("virtualedit")
  " Loop through each row and tries to find a line with a valid col to jump to
  " Return the line number, or 0 if there is no valid line
  function! s:FindJumpRow()
    " won't find anything if already on first line
    if getcurpos()[1] == 1 | return 0 | endif
    " keep searching until found candidate or top of file
    while 1
      norm k
			" Find if there is a non whitespace after a whitespace on the current
			" line
      let findLine = search("\\s\\ze\\S", 'nz', line('.'))
      if findLine | return findLine | endif
      if getcurpos()[1] == 1 | return 0 | endif
    endwhile
  endfunction

  " Move the cursor to x,y position in the current buffer
  function! s:MoveCursorTo(x, y)
    let cursorPos = getcurpos()
    let cursorPos[1] = a:y
    let cursorPos[2] = a:x
    call setpos('.', cursorPos)
  endfunction

  " Main function
  function! s:ColJumper(callback)
    let initialPosition = getcurpos()
		let initialVE = &virtualedit
    set virtualedit=all
    let candidateRow = s:FindJumpRow()
    call setpos('.', initialPosition)
    if candidateRow != 0
      call s:MoveCursorTo(initialPosition[2], candidateRow)
      call search("\\s\\ze\\S", 'z', line('.'))
      let col = getcurpos()[2]
			echomsg "col = " + col
      call a:callback(initialPosition, col)
    endif
    let &virtualedit=initialVE
  endfunction

 	 		 		 	 													 											" test

	" For jumping the cursor out onto RHS whitespace
	function! s:JumpCursorCallback(initialPosition, desiredCol)
		echomsg "JumpCursorCallback"
		if &expandtab == "noexpandtab"
			call setpos('.', a:initialPosition)
			let tabWidth = &tabstop
			let count = a:desiredCol - a:initialPosition[2]
			let count = count < 0 ? 0 : count
			" Tabs required is the number of spaces needed divided by how many
			" spaces a tab is, and we need to round up if there is a remainder
			let count = (count / l:tabWidth) + (count % l:tabWidth == 0 ? 0 : 1)
			exec "norm a" . repeat("	", count)
		else
			" If we are using tabs instead of spaces then we can just insert space
			call s:MoveCursorTo(a:desiredCol, a:initialPosition[1])
			exec "norm i "
		endif
	endfunction
	let JumpcursorCallbackRef = function("s:JumpCursorCallback")

  " For moving cursor and subsequent text in line with desired column
  function! s:PushCursorCallback(initialPosition, desiredCol)
    call setpos('.', a:initialPosition)  					" test comment
		" if &expandtab == "noexpandtab"
		if 0
			echomsg "Doing this "
			let tabWidth = &tabstop
			echomsg a:desiredCol + " " + a:initialPosition[2]
			let count = a:desiredCol - a:initialPosition[2]
			let count = count < 0 ? 0 : count
			" Tabs required is the number of spaces needed divided by how many
			" spaces a tab is, and we need to round up if there is a remainder
			let count = (count / l:tabWidth) + (count % l:tabWidth == 0 ? 0 : 1)
			exec "norm i" . repeat("	", count)
		else
			let requiredWhitespaceCount = a:desiredCol - a:initialPosition[2]
			let requiredWhitespaceCount = requiredWhitespaceCount < 0 ? 0 : requiredWhitespaceCount
			exec "norm i" . repeat(" ", requiredWhitespaceCount)
		endif
  endfunction
  let PushCursorCallbackRef = function("s:PushCursorCallback")

  inoremap <C-j> :call <SID>ColJumper(JumpcursorCallbackRef)<CR>a
  inoremap <C-k> :call <SID>ColJumper(PushCursorCallbackRef)<CR>wi
endif
