# Used in gitViewAndStage and getDiffByList
# Prints unstaged git file according to the git status
# trims ' characters as they are added by fzf preview which calls this script
# Untracked file - view file
# Modified file - view diff
# Deleted file - says the file is deleted or renamed
# else prints error message

# Expected input examples
# M ~/test.txt
# 'R ~/banana.txt'

# if $FZF_PREVIEW_COLUMNS doesn't exist set it to be tput cols
# this is dependent on whether it runs via gitViewAndStage or getDiffByList
FZF_PREVIEW_COLUMNS=${FZF_PREVIEW_COLUMNS:-$(tput cols)}

input=`echo "$1" | tr -d \'`
status_code=`echo "$input" | cut -d" " -f1`
file_path=`echo "$input" | cut -d" " -f2`
case "$status_code" in
  "U")
    bat --theme="OneHalfDark" --style=numbers,changes --color always "$file_path"
    ;;
  "M")
		git diff "$file_path" | delta "-w$FZF_PREVIEW_COLUMNS"
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

