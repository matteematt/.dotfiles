if has("syntax") && has("virtualedit")
  " Loop through each row and tries to find a line with a valid col to jump to
  " Return the line number, or 0 if there is no valid line
  function! s:FindJumpRow()
    " won't find anything if already on first line
    if getcurpos()[1] == 1 | return 0 | endif
    " keep searching until found candidate or top of file
    while 1
      norm k
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
      call a:callback(initialPosition, col)
    endif
    let &virtualedit=initialVE
  endfunction

  " For jumping the cursor out onto RHS whitespace
  function! s:JumpCursorCallback(initialPosition, desiredCol)
      call s:MoveCursorTo(a:desiredCol, a:initialPosition[1])
      exec "norm i "
  endfunction
  let JumpcursorCallbackRef = function("s:JumpCursorCallback")

  " For moving cursor and subsequent text in line with desired column
  function! s:PushCursorCallback(initialPosition, desiredCol)
    call setpos('.', a:initialPosition)
    let requiredWhitespaceCount = a:desiredCol - a:initialPosition[2]
    let requiredWhitespaceCount = requiredWhitespaceCount < 0 ? 0 : requiredWhitespaceCount
    exec "norm i" . repeat(" ", requiredWhitespaceCount)
  endfunction
  let PushCursorCallbackRef = function("s:PushCursorCallback")

  inoremap <C-j> :call <SID>ColJumper(JumpcursorCallbackRef)<CR>a
  inoremap <C-k> :call <SID>ColJumper(PushCursorCallbackRef)<CR>wi
endif
