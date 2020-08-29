" Vim script functions and snippets to aid with navigation

" Some languages have their imports not explicitly defined the file extension
" so the suffixesadd option can be used to account for extensions when using
" the normal mode gf command. Set this option depending on the current filetype
augroup suffixes
	autocmd!

	let jsLike = ".js,.jsx,.json,.test.js"
	let associations = [
				\["javascript", jsLike],
				\["javascriptreact", jsLike],
				\["json", jsLike],
				\["python", ".py,.pyw"]
				\]

	for ft in associations
		execute "autocmd FileType " . ft[0] . " setlocal suffixesadd=" . ft[1]
	endfor
augroup END
