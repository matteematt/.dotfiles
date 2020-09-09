" Run an async job to generate tag files using universal ctags

if executable("ctags")
	function! tags#runAsyncTagsCallback(channel)
		let l:initJob = ch_getjob(a:channel)
		let l:initJobInfo = job_info(l:initJob)
		let l:jobExitCode = str2nr(l:initJobInfo["exitval"])
		let l:msg = (l:jobExitCode != 0) ? "Error generating tags file" : "Generated tags file"
		echo l:msg
	endfunction

	function! s:runAsyncTagsGeneration()
		call job_start("ctags -R .", {"close_cb":"tags#runAsyncTagsCallback"})
	endfunction

	nnoremap <leader>t :call <SID>runAsyncTagsGeneration()<CR>
endif
