# git_extras.sh contains functions to help working with git
# __formatGitStatus returns formatted output of git status unstaged changes
# gitViewAndStage fuzzy choose unstage change to add, with inline preview
# getDiffByList fuzzy choose unstaged change, view nice formatted output and set $chosen_file to this file
# addLastDiffFile git add $chosen_file if set
# getUpdateWithRebase pull latest changes and automatically rebase this branch (assuming no conflicts)

# Unfortunately can't work out if a file is renamed before the "new" file
# is checked in and the "deleted" file is checked in
# If in a git directory returns git status formatted with
# M x - for file x modified
# R x - for file x deleted
# U x - for untracked file x
# D x - for untracked directory x
# for all *unstaged* files
# returns exit code 1 if this is not a git directory
function __formatGitStatus() {
  git branch --show-current &>/dev/null || { echo "Error: not a git directory";return 1; }
  formatted=$(git status | awk 'BEGIN {parseMode=0} \
  { \
    if (parseMode==1) { \
      if (match($0,/^\s+deleted:\s*(.+)/)) {print "R " $2}; \
      if (match($0,/^\s+modified:\s*(.+)/)) {print "M " $2}; \
    }; \
    if (parseMode==2) { \
      if (match($0,/^\s+(.)\//)) {print "D " $1;} \
      else if (match($0,/^\s+(.)/)) {print "U " $1;} \
    }; \
    if ($0 ~ /Changes not staged for commit/) {parseMode=1}; \
    if ($0 ~ /to include in what will be committed/) {parseMode=2}; \
  }')
  echo "$formatted"
}

# Similar to getDiffByList but views the output in bat inline and
# selecting an option automatically calls 'git add' on it
function gitViewAndStage() {
  chosen_file=$(__formatGitStatus | fzf --with-nth 2 --preview-window=right,70% --preview '$HOME/.dotfiles/shell/view_git_unstaged_file.sh {}')
  if [ -z "$chosen_file" ]; then
    return
  else
    git add $(echo "$chosen_file" | cut -d" " -f2)
    unset chosen_file
  fi
}

function getDiffByList() {
  chosen_file=$(__formatGitStatus | fzf --with-nth 2)
  if [ -z "$chosen_file" ]; then
    return
  fi
  file_path=$(echo "$chosen_file" | cut -d" " -f2)
  ~/.dotfiles/shell/view_git_unstaged_file.sh "$chosen_file"
  unset chosen_file
}

function addLastDiffFile() {
  if [[ -v file_path ]];
  then
    git add "$file_path"
    unset file_path
  else
    echo "No previous file diffed"
    return 1
  fi
}

function gitCheckoutWorktree() {
	root_dir=$(git rev-parse --show-toplevel)
	worktree_dir="$root_dir/_worktrees_git/"

	# branch name is the first argument if only one passed, flags is the first argument if two are passed and branch name is the second
	if [ "$#" -eq 2 ]; then
		flags="$1"
		branch_name="$2"
		git worktree add "$flags" "$worktree_dir/$branch_name" "$branch_name"
	elif  [ "$#" -eq 1 ]; then
		branch_name="$1"
		git worktree add "$worktree_dir/$branch_name" "$branch_name"
	else
		cd -
		echo "Wrong number of arguments to function"
		exit 1;
	fi
	echo "Checked out $branch_name at $worktree_dir/$branch_name"
	cd -
}

# Performs the same job as the update button on giuthub when a branch
# is behind master, but with rebase instead
function getUpdateWithRebase() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git pull
  git checkout master
  git pull
  git checkout "$branch"
  git rebase origin/master
  git push --force-with-lease
}

function gitShowCommits() {
	commit=$(git log --oneline | fzf --preview-window=right,70% --preview 'git show {+1} | delta -w$FZF_PREVIEW_COLUMNS')
	if [ -n "$commit" ]; then
		hash=$(echo "$commit" | cut -d" " -f1)
		git show "$hash"
		echo "\n>> $commit"
	fi
}

