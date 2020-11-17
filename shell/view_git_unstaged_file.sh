# Prints unstaged git file according to the git status
# trims ' characters as they are added by fzf preview which calls this script
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# else prints error message

# Expected input examples
# M ~/test.txt
# 'R ~/banana.txt'

input=`echo "$1" | tr -d \'`
status_code=`echo "$input" | cut -d" " -f1`
file_path=`echo "$input" | cut -d" " -f2`
case "$status_code" in
  "U")
    bat --theme="OneHalfDark" --style=numbers,changes --color always "$file_path"
    ;;
  "M")
    first_change=`git diff "$file_path" | awk '{if (match($0,/^@+\s+-?([0-9]+).+@+/,m)) {print m[1];exit 0}}'`
    bat --theme="OneHalfDark" --style=numbers,changes --color always $file_path | tail -n+$first_change
    ;;
  "D")
    echo "New Dir $file_path\n\n`ls $file_path`"
    ;;
  "R")
    echo "File '$file_path' deleted or renamed"
    ;;
  *)
    echo "Unknown git status $status_code"
    ;;
esac

