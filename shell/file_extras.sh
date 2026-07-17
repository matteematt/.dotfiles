# file_extras.sh contains functions to help with everyday file operations
# moveAndPrintPath moves file(s) into the current directory and echoes their new absolute path(s)

# Move one or more files/dirs into the current directory and print each new
# absolute path. Handy for dragging file(s) in from Finder (or a Linux file
# manager) and having the terminal both move them here and tell you where
# they landed. Missing sources are reported and skipped without aborting the
# rest. Uses only coreutils (mv/basename/realpath) so it works on macOS and Linux.
function moveAndPrintPath {
  if [ "$#" -eq 0 ]; then
    echo "Usage: mvpp <source> [source ...]" >&2
    return 1
  fi

  local src rc=0
  for src in "$@"; do
    if [ ! -e "$src" ]; then
      echo "Error: '$src' does not exist" >&2
      rc=1
      continue
    fi

    if mv -- "$src" .; then
      realpath -- "./$(basename -- "$src")"
    else
      rc=1
    fi
  done

  return "$rc"
}
