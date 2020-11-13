# Prints unstaged git file according to the git status
# trims ' characters as they are added by fzf preview which calls this script
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# else prints error message

# Expected input examples
# M ~/test.txt
# 'D ~/banana.txt'

input=`echo "$1" | tr -d \'`
status_code=`echo "$input" | cut -d" " -f1`
file_path=`echo "$input" | cut -d" " -f2`
case "$status_code" in
  "U")
    bat $file_path
    ;;
  "M")
    git diff $file_path | bat
    ;;
  "D")
    echo "File '$file_path' deleted or renamed"
    ;;
  *)
    echo "Unknown git status $status_code"
    ;;
esac

