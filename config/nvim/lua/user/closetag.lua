vim.cmd [[
" filetypes like xml, html, xhtml, ...
" These are the file types where this plugin is enabled.
"
let g:closetag_filetypes = 'html,xhtml,phtml,typescript,javascript'
let g:closetag_filenames = '*.html,*.ts,*.js'

" dict
" Disables auto-close if not in a "valid" region (based on filetype)
" (This does not work with the template region from web components)
" let g:closetag_regions = {
"     \ 'typescript': 'jsxRegion,tsxRegion',
"     \ 'javascript': 'jsxRegion',
"     \ 'typescript.tsx': 'jsxRegion,tsxRegion',
"     \ 'javascript.jsx': 'jsxRegion',
"     \ 'typescriptreact': 'jsxRegion,tsxRegion',
"     \ 'javascriptreact': 'jsxRegion',
"     \ }

" Shortcut for closing tags, default is '>'
" Changing this because of <> also being used for templates/generics in languages like typescript
let g:closetag_shortcut = '<leader>>'
]]
