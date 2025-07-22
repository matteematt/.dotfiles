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

# Returns git status formatted with
# M x - for file x modified
# R x - for file x deleted
# A x - for file x added
# for all *staged* files
# returns exit code 1 if this is not a git directory
function __formatStagedGitStatus() {
  git branch --show-current &>/dev/null || { echo "Error: not a git directory";return 1; }
  formatted=$(git status | awk 'BEGIN {parseMode=0} \
  { \
    if (parseMode==1) { \
      if (match($0,/^\s+deleted:\s*(.+)/)) {print "R " $2}; \
      if (match($0,/^\s+modified:\s*(.+)/)) {print "M " $2}; \
      if (match($0,/^\s+new file:\s*(.+)/)) {print "A " $2}; \
    }; \
    if ($0 ~ /Changes to be committed/) {parseMode=1}; \
    if ($0 ~ /Changes not staged for commit/) {parseMode=0}; \
  }')
  echo "$formatted"
}

function checkoutPrimaryGitBranch {
	if git rev-parse --verify master >/dev/null 2>&1; then
		git checkout master
	elif git rev-parse --verify main >/dev/null 2>&1; then
		git checkout main
	else
		primary_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
		git checkout "$primary_branch"
	fi
}

# Similar to getDiffByList but views the output in bat inline and
# selecting an option automatically calls 'git add' on it
function gitViewAndStage() {
  # Check if we're in a git repo
  git branch --show-current &>/dev/null || { echo "Error: not a git directory"; return 1; }

  # Check if working tree is clean
  if git diff-index --quiet HEAD --; then
    echo "Working tree is clean - nothing to stage"
    return 0
  fi

  chosen_files=$(__formatGitStatus | fzf -m --with-nth 2 --header "File Staging (TAB to select multiple)" --preview-window=right,70% --preview '$HOME/.dotfiles/shell/view_git_unstaged_file.sh {}')
  if [ -z "$chosen_files" ]; then
    return
  else
    # Convert newline-separated files to array
    files_array=(${(f)chosen_files})

    # Stage each selected file
    for file in "${files_array[@]}"; do
      file_path=$(echo "$file" | cut -d" " -f2)
      git add "$file_path"
			echo "Staged: $file_path"
    done

    unset chosen_files
    unset files_array
  fi
}

# Similar to gitViewAndStage but for unstaging files that are already staged
# selecting an option automatically calls 'git reset HEAD' on it
function gitUnstageFiles() {
  # Check if we're in a git repo
  git branch --show-current &>/dev/null || { echo "Error: not a git directory"; return 1; }

  # Check if there are any staged files to unstage
  staged_files=$(__formatStagedGitStatus)
  if [ -z "$staged_files" ]; then
    echo "No staged files to unstage"
    return 0
  fi

  chosen_files=$(echo "$staged_files" | fzf -m --with-nth 2 --header "File Unstaging (TAB to select multiple)" --preview-window=right,70% --preview 'git diff --cached "$(echo {} | cut -d" " -f2-)"')
  if [ -z "$chosen_files" ]; then
    return
  else
    # Convert newline-separated files to array
    files_array=(${(f)chosen_files})

    # Unstage each selected file
    for file in "${files_array[@]}"; do
      file_path=$(echo "$file" | cut -d" " -f2)
      git reset HEAD "$file_path"
      if [[ ${#files_array[@]} -gt 1 ]]; then
        echo "Unstaged: $file_path"
      fi
    done

    unset chosen_files
    unset files_array
    unset staged_files
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

function gitWorktreeCheckout() {
	root_dir=$(git rev-parse --show-toplevel)
	worktree_dir="$root_dir/_worktrees_git/"

	# branch name is the first argument if only one passed, flags is the first argument if two are passed and branch name is the second
	# it seems that if you create a new one with -b you need to have the branch name first - otherwise the path first
	if [ "$#" -eq 2 ]; then
		flags="$1"
		branch_name="$2"
		git worktree add "$flags" "$branch_name" "$worktree_dir/$branch_name"
	elif  [ "$#" -eq 1 ]; then
		branch_name="$1"
		git worktree add "$worktree_dir/$branch_name" "$branch_name"
	else
		cd -
		echo "Wrong number of arguments to function"
		exit 1;
	fi
	echo "Checked out $branch_name at $worktree_dir/$branch_name"
	cd "$worktree_dir/$branch_name"
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

# Use fzf to view previous commits and then display them using delta
# Use `tput smcup` and `tput rmcup` to view the delta pager on the
# alternative screen.
function gitShowCommits() {
	commit=$(git log --oneline | fzf --preview-window=right,70% --preview 'git show {+1} | delta -w$FZF_PREVIEW_COLUMNS')
	if [ -n "$commit" ]; then
		hash=$(echo "$commit" | cut -d" " -f1)
		# Launch the alternative screen
		tput smcup
		git show "$hash" | delta && tput rmcup
		echo "\n>> $commit"
	fi
}

# List all branches inside the projects to remove
function gitWorktreeCleanup {
	top_level="$(cd "$(pwd | awk -v FS="_worktrees_git/" '{print $1}')" && git rev-parse --show-toplevel)"
	if ! [[ -d "$top_level/_worktrees_git" ]]; then
		echo "Error: No worktree directory"
		return 2;
	fi
	git_branches=$(cd "$top_level" && find ./_worktrees_git -type d -exec test -e '{}/.git' ';' -print -prune | cut -c 18- | fzf -m --header "Worktree Cleanup (TAB to select multiple)" --preview "cd $top_level/_worktrees_git/{} && git log")
	if [[ "$git_branches" == '' ]]; then
		echo "Error: No branches selected for cleanup"
		return 3;
	fi

	# Convert newline-separated branches to array
	branches_array=(${(f)git_branches})

	# Show confirmation with all selected branches
	echo "Selected branches for cleanup:"
	for branch in "${branches_array[@]}"; do
		echo "  - $branch"
	done
	if [[ ${#branches_array[@]} -eq 1 ]]; then
		read -q "choice?Are you sure that you want to cleanup this branch? [y/N]" || return 1;
	else
		read -q "choice?Are you sure that you want to cleanup these ${#branches_array[@]} branches? [y/N]" || return 1;
	fi

	echo "\n";

	# Clean up each selected branch
	for git_branch in "${branches_array[@]}"; do
		chosen_dir="$top_level/_worktrees_git/$git_branch"
		if ! [[ -d "$chosen_dir" ]]; then
			echo "Error: Unable to find branch $git_branch on file system"
			continue
		fi

		echo "\nCleaning up $chosen_dir"
		rm -rf "$chosen_dir"
		echo "Pruning worktree references for $git_branch"
		git worktree prune
		echo "Cleaning up branch $git_branch"
		git branch -D "$git_branch"
	done
	return 0;
}
