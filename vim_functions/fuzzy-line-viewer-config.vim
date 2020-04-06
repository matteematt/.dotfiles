" ripgrep
if executable('rg')
  let $FZF_LINES_COMMAND = 'rg --line-number --hidden --follow --glob "!.git/*" .'
  set grepprg=rg\ --vimgrep
  command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
endif

" Files + devicons
function! Fzf_lines()
  " {} is replaced to the single-quoted string of the focused line
  let l:fzf_files_options = '--preview "~/dotfiles/vim_functions/fuzzy-line-viewer-2.sh {} '.&lines.'"'

  function! s:files()
    let l:files = split(system($FZF_LINES_COMMAND), '\n')
    return s:prepend_icon(l:files)
  endfunction

  function! s:prepend_icon(candidates)
    let l:result = []
    for l:candidate in a:candidates
      let l:filename = fnamemodify(l:candidate, ':p:t')
      let l:icon = WebDevIconsGetFileTypeSymbol(l:filename, isdirectory(l:filename))
      call add(l:result, printf('%s %s', l:icon, l:candidate))
    endfor

    return l:result
  endfunction

  function! s:edit_file(item)
    let l:start_pos = stridx(a:item, ' ')
    let l:end_pos = stridx(a:item, ':')
    let l:line_num_end_pos = stridx(a:item, ':', end_pos + 1)
    let l:file_path = a:item[start_pos+1:end_pos-1]
    let l:line_num = a:item[end_pos+1:line_num_end_pos-1]
    execute 'silent e' l:file_path
    execute l:line_num
    norm zz
  endfunction

  call fzf#run({
        \ 'source': <sid>files(),
        \ 'sink':   function('s:edit_file'),
        \ 'options': '-m  -d : -n 3.. ' . l:fzf_files_options,
        \ 'top':    '60%' })
endfunction
