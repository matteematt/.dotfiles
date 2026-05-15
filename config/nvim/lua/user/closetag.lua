vim.cmd [[
let g:closetag_filetypes = 'html,xhtml,phtml,typescript,javascript'
let g:closetag_filenames = '*.html,*.ts,*.js'

" Override default '>' because <> is also used for templates/generics in TypeScript
let g:closetag_shortcut = '<leader>>'
]]
