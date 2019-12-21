" Converts the relative filepath the cursor is on from the project root
" To being relative between the filepath of the open buffer to the file
" Used to convert autocompleted filepaths from the root for file imports

function! ConvertRelativePath()
python3 << endPython
import vim
import os

def convertPaths(currentFilePath, relativePath, currentDir):
    importFilePath = currentDir + relativePath
    paths = [importFilePath, currentFilePath]
    calcualtedPath = os.path.relpath(paths[0], paths[1])
    return calcualtedPath

def getPathsToConvert():
    currentFilePath = vim.eval("expand('%:p:h')")
    currentDir = os.getcwd()
    buf = vim.current.buffer
    (starting_line_num, col1) = buf.mark('<')
    (ending_line_num, col2) = buf.mark('>')
    lines = vim.eval('getline({}, {})'.format(starting_line_num, ending_line_num))
    if len(lines) == 1:
        line = lines[0]
        line = line[col1:col2]
        print(line)
        line = line.replace("\"","")
        line = line[1:]
        newPath = convertPaths(currentFilePath, line, currentDir)
        if newPath[:3] != "../":
            newPath = "./" + newPath
        vim.command("normal vi\"c%s" % newPath)


getPathsToConvert();

endPython
endfunction

command! -range CRPath call ConvertRelativePath()

" import test from \"./snippets/javascript/react_imports.jsx"

