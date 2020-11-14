" Outfill out the equivalent print statement of a certain language

function! FillPrintStatement()
python3 << endPython
import vim

print_commands = {
  "vim": "normal Iecho <<$1",
  "sh": "normal Iecho <<$1",
  "jsx": "normal Iconsole.log(<<$1)",
  "js": "normal Iconsole.log(<<$1)",
  "cpp": "normal Iprintf(<<$1);",
  "c": "normal Iprintf(<<$1);"
}

def getPrintStatementForCurrentFile():
  fileType = vim.eval("expand('%:e')")
  if fileType in print_commands:
    return print_commands[fileType]
  else:
    raise ValueError("Unsupported file type : " + fileType)

try:
  printStatement = getPrintStatementForCurrentFile()
  vim.command(printStatement)

except Exception as e: print(e)

endPython
endfunction

command! SnipPrint call FillPrintStatement()
nnoremap <leader>e :SnipPrint<CR>^/<<$\d<CR>4s
