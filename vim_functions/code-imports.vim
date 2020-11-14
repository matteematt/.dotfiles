" Code for importing files into other files in various languages

" ES6 Javascipt modules
function! ES6ImportPath()
python3 << endPython
import os
import vim
import re
import subprocess

def getCurrLine():
    cursorLineNo = int(vim.eval("line('.')"))
    currentLine = vim.current.buffer[cursorLineNo - 1]
    return currentLine

def getModuleName(currentLine):
    moduleName = re.findall(r"import\s+\{?\s*(\w+)", currentLine)
    if len(moduleName) == 0:
        raise ValueError("Unable to parse ES6 JS Import on current line")
    return moduleName[0]

def searchForExportedFile(moduleName):
    shellOutput = os.popen('grep -ir --exclude-dir={node_modules,lcov-report,.git} "' + moduleName + '" . | grep export').read()
    outputLines = shellOutput.splitlines()
    if len(outputLines) == 0:
        raise ValueError("No match for module " + moduleName + " found")
    matchedFiles = map(lambda line: line.split(":")[0], outputLines)
    if len(outputLines) > 1:
        raise ValueError("Multiple files matched : ", matchedFiles)
    else:
        return matchedFiles[0]

def formatAndInsertFileName(fileName):
    fileName = fileName.replace("'", "\"")
    vim.command("normal A \"%s\"" % fileName)

try:
    currentLine = getCurrLine()
    moduleName = getModuleName(currentLine)
    exportedFileName = searchForExportedFile(moduleName)
    formatAndInsertFileName(exportedFileName)
except Exception as e: print(e)

endPython
endfunction

command! ImportES6 call ES6ImportPath()
