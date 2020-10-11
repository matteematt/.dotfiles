if has("syntax") && has("virtualedit")
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

  function! s:MoveCursorTo(x, y)
    let cursorPos = getcurpos()
    let cursorPos[1] = a:y
    let cursorPos[2] = a:x
    call setpos('.', cursorPos)
  endfunction

  " jumps the cursor in line with the next non-blank character in above lines
  function! s:JumpCursorCol()
    let initialPosition = getcurpos()
		let initialVE = &virtualedit
    set virtualedit=all
    let candidateRow = s:FindJumpRow()
    call setpos('.', initialPosition)
    if candidateRow != 0
      call s:MoveCursorTo(initialPosition[2], candidateRow)
      call search("\\s\\ze\\S", 'z', line('.'))
      let col = getcurpos()[2]
      call s:MoveCursorTo(col, initialPosition[1])
      exec "norm i "
    endif
    let &virtualedit=initialVE
  endfunction

  inoremap <C-j> :call <SID>JumpCursorCol()<CR>a
endif
