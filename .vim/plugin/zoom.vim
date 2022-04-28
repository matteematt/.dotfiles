" Simple plugin which allows you to zoom in on one pane temporarily, and then
" restore the view again after
" Leverages :tabe % which opens the current window in a new tab (so fullscreen)
" and then closes it again restoring the previous view

let s:is_zoom = 0

function s:RunZoom()
	if s:is_zoom == 0
		tabe %
	else
		tabc
	endif
	let s:is_zoom = !s:is_zoom
endfunction

nnoremap <leader>z :call <SID>RunZoom()<CR>
