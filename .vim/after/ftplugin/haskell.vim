let g:haskell_indent_where = 3
set tabstop=8 softtabstop=0 expandtab shiftwidth=2 smarttab

inoreabbrev <buffer> modulem module Main wheremain :: IO ()main =

command! -buffer -nargs=0 FormatMS call formatting#HaskellMultiline()
