# git_extras.sh contains functions to help working with git
# __formatGitStatus returns formatted output of git status unstaged changes
# gitViewAndStage fuzzy choose unstage change to add, with inline preview
# getDiffByList fuzzy choose unstaged change, view nice formatted output and set $chosen_file to this file
# addLastDiffFile git add $chosen_file if set
# getUpdateWithRebase pull latest changes and automatically rebase this branch (assuming no conflicts)

# Both formatters below read `git status --porcelain -z`. The -z form is what
# makes a path containing a space survive: its records are NUL separated and
# its paths are never quoted or escaped, unlike those of the human readable
# output and of plain --porcelain. It is also unaffected by the locale.
# Each record is "XY <path>", X being the state of the file in the index and Y
# its state in the working tree, so the path starts at offset 3. A rename or a
# copy is followed by a second record holding the original path, which is not
# an entry in its own right and so is skipped.

# Unfortunately can't work out if a file is renamed before the "new" file
# is checked in and the "deleted" file is checked in
# If in a git directory returns git status formatted with
# M<tab>x - for file x modified
# R<tab>x - for file x deleted
# U<tab>x - for untracked file x
# D<tab>x - for untracked directory x
# for all *unstaged* files
# The code and the path are separated by a tab rather than a space, as a path
# is allowed to contain spaces but not tabs in any name worth supporting
# returns exit code 1 if this is not a git directory
function __formatGitStatus() {
  git branch --show-current &>/dev/null || { echo "Error: not a git directory";return 1; }

  local -a entries
  local porcelain entry entry_path skip=0
  porcelain="$(git status --porcelain -z)"
  entries=(${(0)porcelain})
  for entry in "${entries[@]}"; do
    if [[ $skip -eq 1 ]]; then
      skip=0
      continue
    fi
    [[ "${entry[1]}" == [RC] ]] && skip=1
    entry_path="${entry:3}"
    # The working tree letter, so an untracked file reads "?", and a file both
    # staged and edited since reads "M" here as well as in the staged listing
    case "${entry[2]}" in
      "M"|"T") printf 'M\t%s\n' "$entry_path" ;;
      "D") printf 'R\t%s\n' "$entry_path" ;;
      # git collapses a wholly untracked directory into a single entry with a
      # trailing slash, which is what separates D from U
      "?") [[ "$entry_path" == */ ]] && printf 'D\t%s\n' "$entry_path" || printf 'U\t%s\n' "$entry_path" ;;
    esac
  done
}

# Returns git status formatted with
# M<tab>x - for file x modified
# R<tab>x - for file x deleted
# A<tab>x - for file x added
# for all *staged* files
# returns exit code 1 if this is not a git directory
function __formatStagedGitStatus() {
  git branch --show-current &>/dev/null || { echo "Error: not a git directory";return 1; }

  local -a entries
  local porcelain entry entry_path skip=0
  porcelain="$(git status --porcelain -z)"
  entries=(${(0)porcelain})
  for entry in "${entries[@]}"; do
    if [[ $skip -eq 1 ]]; then
      skip=0
      continue
    fi
    [[ "${entry[1]}" == [RC] ]] && skip=1
    entry_path="${entry:3}"
    # The index letter, so "?" for an untracked file falls through and is left
    # out, as is a rename: unstaging only the new path would leave the
    # deletion of the old one behind
    case "${entry[1]}" in
      "M"|"T") printf 'M\t%s\n' "$entry_path" ;;
      "D") printf 'R\t%s\n' "$entry_path" ;;
      "A") printf 'A\t%s\n' "$entry_path" ;;
    esac
  done
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

  # Check if working tree is clean (including untracked files)
  if [ -z "$(git status --porcelain)" ]; then
    echo "Working tree is clean - nothing to stage"
    return 0
  fi

  chosen_files=$(__formatGitStatus | fzf -m --delimiter=$'\t' --with-nth 2 --header "File Staging (TAB to select multiple, ctrl-u/ctrl-d to scroll preview)" --preview-window=right,70% --bind 'ctrl-u:preview-up,ctrl-d:preview-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down' --preview '$HOME/.dotfiles/shell/view_git_unstaged_file.sh {}')
  if [ -z "$chosen_files" ]; then
    return
  else
    # Convert newline-separated files to array
    files_array=(${(f)chosen_files})

    # Stage each selected file
    for file in "${files_array[@]}"; do
      file_path="${file#*$'\t'}"
      git add -- "$file_path"
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

  # printf rather than echo, as echo would expand a backslash in a file name
  chosen_files=$(echo "$staged_files" | fzf -m --delimiter=$'\t' --with-nth 2 --header "File Unstaging (TAB to select multiple)" --preview-window=right,70% --preview 'git diff --cached -- "$(printf "%s" {} | cut -f2-)"')
  if [ -z "$chosen_files" ]; then
    return
  else
    # Convert newline-separated files to array
    files_array=(${(f)chosen_files})

    # Unstage each selected file
    for file in "${files_array[@]}"; do
      file_path="${file#*$'\t'}"
      git reset HEAD -- "$file_path"
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
  chosen_file=$(__formatGitStatus | fzf --delimiter=$'\t' --with-nth 2)
  if [ -z "$chosen_file" ]; then
    return
  fi
  file_path="${chosen_file#*$'\t'}"
  ~/.dotfiles/shell/view_git_unstaged_file.sh "$chosen_file"
  unset chosen_file
}

function addLastDiffFile() {
  if [[ -v file_path ]];
  then
    git add -- "$file_path"
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
		echo "Wrong number of arguments to function"
		return 1;
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

# Lists every process whose working directory is inside $1, one
# "<pid>\t<command>\t<cwd>" line each. Used to spot a shell, editor or claude
# session still sitting in a worktree before it gets deleted.
# Only the working directory is checked - a process that merely holds a file
# open under the worktree is not reported, as scanning every open file on the
# system takes seconds rather than milliseconds.
# Returns 1 when there is no way to inspect processes at all, so that the
# caller can say so rather than read "no output" as "nothing is running".
function __worktreeProcesses() {
	local dir link cwd
	dir="$(cd "$1" 2>/dev/null && pwd -P)" || return 0

	if [[ -d /proc/self ]]; then
		# Linux: read /proc directly rather than depend on lsof being
		# installed. ${link:A} resolves the cwd symlink, and leaves it
		# unresolved - so unable to match $dir - for other users' processes.
		for link in /proc/<1->/cwd(N); do
			cwd="${link:A}"
			if [[ "$cwd" == "$dir" || "$cwd" == "$dir"/* ]]; then
				printf '%s\t%s\t%s\n' "${${link:h}:t}" "$(<${link:h}/comm)" "$cwd"
			fi
		done
		return 0
	fi

	command -v lsof >/dev/null 2>&1 || return 1

	# macOS: lsof resolves symlinks, hence comparing against the physical path
	# above. Running from / stops the lsof and awk processes matching $dir
	# themselves, and passing $dir through the environment keeps it out of
	# awk's argv.
	(cd / && lsof -w -d cwd -F pcn 2>/dev/null | dir="$dir" awk '
		/^p/ { pid = substr($0, 2) }
		/^c/ { cmd = substr($0, 2) }
		/^n/ {
			path = substr($0, 2)
			if (path == ENVIRON["dir"] || index(path, ENVIRON["dir"] "/") == 1) {
				print pid "\t" cmd "\t" path
			}
		}')
	return 0
}

# Filters "<pid>\t<command>\t<cwd>" lines on stdin down to the processes whose
# working directory is inside $1
function __processesUnder() {
	dir="$1" awk -F'\t' 'NF == 3 && ($3 == ENVIRON["dir"] || index($3, ENVIRON["dir"] "/") == 1)'
}

# Summarises "<pid>\t<command>\t<cwd>" lines on stdin as a command name list,
# e.g. "nvim, zsh"
function __processNames() {
	cut -f2 | sort -u | paste -sd, - | sed 's/,/, /g'
}

# Prints "$1 $2", pluralising $2 unless there is exactly one of them
function __plural() {
	if [[ "$1" == "1" ]]; then
		print -r -- "$1 $2"
	else
		print -r -- "$1 ${2}s"
	fi
}

# Works out what would be lost by deleting each worktree named in $@, filling in
# active_map, dirty_map, unpushed_map and a short risk_map summary for each.
# zsh scopes dynamically, so these arrays and $all_procs, $top_level and
# $worktree_root are the caller's.
function __collectWorktreeRisks() {
	local branch worktree
	local -a parts
	for branch in "$@"; do
		worktree="$worktree_root/$branch"
		parts=()

		active_map[$branch]="$(print -r -- "$all_procs" | __processesUnder "$worktree")"
		if [[ -n "${active_map[$branch]}" ]]; then
			parts+=("IN USE ($(print -r -- "${active_map[$branch]}" | __processNames))")
		fi

		# Anything git would refuse to throw away, were rm -rf not doing it
		dirty_map[$branch]="$(git -C "$worktree" status --porcelain 2>/dev/null | grep -c . | tr -d ' ')"
		if [[ "${dirty_map[$branch]}" == "0" ]]; then
			dirty_map[$branch]=""
		else
			parts+=("DIRTY")
		fi

		# Commits reachable from no other branch and no remote, so deleting the
		# branch is the last thing standing between them and the reflog. This is
		# stricter than git branch -d, which only consults the upstream or HEAD.
		unpushed_map[$branch]="$(git -C "$top_level" rev-list --count "$branch" --not --exclude="$branch" --branches --remotes 2>/dev/null)"
		if [[ -z "${unpushed_map[$branch]}" || "${unpushed_map[$branch]}" == "0" ]]; then
			unpushed_map[$branch]=""
		else
			parts+=("${unpushed_map[$branch]} UNPUSHED")
		fi

		risk_map[$branch]="${(j:, :)parts}"
	done
}

# Prints the indented reasons that $1 is unsafe to delete, one per line, for
# both the picker preview and the report before deleting. Reads the caller's
# maps by dynamic scope, as above.
function __renderWorktreeRisks() {
	local branch="$1" pid cmd cwd
	if [[ -n "${active_map[$branch]}" ]]; then
		print -r -- "${active_map[$branch]}" | while IFS=$'\t' read -r pid cmd cwd; do
			printf '     %-20s pid %-7s %s\n' "$cmd" "$pid" "$cwd"
		done
	fi
	if [[ -n "${dirty_map[$branch]}" ]]; then
		printf '     %-20s %s\n' "DIRTY" "$(__plural "${dirty_map[$branch]}" "uncommitted or untracked file")"
	fi
	if [[ -n "${unpushed_map[$branch]}" ]]; then
		printf '     %-20s %s\n' "UNPUSHED" "$(__plural "${unpushed_map[$branch]}" "commit") on no other branch or remote"
	fi
}

# List all branches inside the projects to remove
# Worktrees with a process still running inside them, uncommitted changes, or
# commits held nowhere else are reported and skipped. Pass -f to be asked about
# those instead, rather than skipping them.
function gitWorktreeCleanup {
	local force=0
	local skipped=0

	while getopts "f" opt; do
		case $opt in
			f)
				force=1
				;;
			*)
				echo "usage: gitWorktreeCleanup [-f]"
				return 1
				;;
		esac
	done
	shift $((OPTIND-1))

	top_level="$(cd "$(pwd | awk -v FS="_worktrees_git/" '{print $1}')" && git rev-parse --show-toplevel)"
	if ! [[ -d "$top_level/_worktrees_git" ]]; then
		echo "Error: No worktree directory"
		return 2;
	fi
	# A single process scan covers every worktree, so marking them up below is
	# string matching rather than one scan each
	local worktree_root all_procs
	local can_check=1
	worktree_root="$(cd "$top_level/_worktrees_git" && pwd -P)"
	if ! all_procs="$(__worktreeProcesses "$worktree_root")"; then
		can_check=0
		print -P "%B%F{red}Warning: cannot check for running processes, install lsof to have worktrees still in use flagged%f%b"
	fi

	# Build the picker list rather than piping find straight into fzf, so that
	# anything unsafe is already marked before it can be chosen
	local -A active_map dirty_map unpushed_map risk_map
	local -a fzf_lines safe_lines unsafe_lines worktree_branches
	local branch detail
	worktree_branches=(${(f)"$(cd "$top_level" && find ./_worktrees_git -type d -exec test -e '{}/.git' ';' -print -prune | cut -c 18-)"})
	worktree_branches=(${worktree_branches:#})
	__collectWorktreeRisks "${worktree_branches[@]}"
	for branch in "${worktree_branches[@]}"; do
		if [[ -n "${risk_map[$branch]}" ]]; then
			# The reasons go in a third field that --with-nth hides from the
			# list and only the preview window expands, keeping the lines short.
			# Newlines are escaped because a field cannot span lines, and the
			# leading one keeps fzf from trimming the first line's indent away.
			detail="$(__renderWorktreeRisks "$branch")"
			detail="${detail//\\/\\\\}"
			unsafe_lines+=($'\e[1;31m'"$branch"$'\t✗\e[0m\t'"\\n${detail//$'\n'/\\n}")
		else
			safe_lines+=("$branch"$'\t'$'\t')
		fi
	done
	# fzf draws the first line at the bottom next to the prompt and grows
	# upwards, so listing the safe worktrees first is what puts the unsafe ones
	# at the top of the screen, away from where the cursor starts
	fzf_lines=("${safe_lines[@]}" "${unsafe_lines[@]}")

	if [[ ${#fzf_lines[@]} -eq 0 ]]; then
		echo "Error: No worktrees found"
		return 2;
	fi

	git_branches=$(print -rl -- "${fzf_lines[@]}" | fzf -m --ansi --delimiter=$'\t' --with-nth=1,2 --tabstop=20 --header "Worktree Cleanup (TAB to select multiple)" --preview "[ -n {3} ] && { printf '\033[1;31m!! NOT SAFE TO DELETE\033[0m\n%b\n' {3}; printf '%*s\n\n' \${FZF_PREVIEW_COLUMNS:-40} '' | sed 's/ /─/g'; }; cd $worktree_root/{1} && git log")
	if [[ "$git_branches" == '' ]]; then
		echo "Error: No branches selected for cleanup"
		return 3;
	fi

	# fzf returns whole lines, the branch name is everything before the tab
	branches_array=(${${(f)git_branches}%%$'\t'*})

	# The list above can sit on screen for a while, so check the selection again
	# for anything that changed in the meantime before acting on it
	if [[ $can_check -eq 1 ]]; then
		all_procs="$(__worktreeProcesses "$worktree_root")"
	fi
	__collectWorktreeRisks "${branches_array[@]}"

	# Show confirmation with all selected branches, flagging the unsafe ones
	echo "Selected branches for cleanup:"
	for branch in "${branches_array[@]}"; do
		if [[ -n "${risk_map[$branch]}" ]]; then
			print -P "  - $branch %B%F{red}(${risk_map[$branch]})%f%b"
		else
			echo "  - $branch"
		fi
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

		if [[ -n "${risk_map[$git_branch]}" ]]; then
			print -P "\n%B%F{red}!! $git_branch is not safe to delete:%f%b"
			__renderWorktreeRisks "$git_branch"

			# One prompt covers every reason, rather than one prompt per reason
			if [[ $force -eq 0 ]]; then
				print -P "%F{red}   Skipping $git_branch - rerun with -f to delete it anyway%f"
				skipped=$((skipped + 1))
				continue
			fi

			if ! read -q "choice?   Delete $git_branch anyway? [y/N]"; then
				echo "\n   Skipping $git_branch"
				skipped=$((skipped + 1))
				continue
			fi
			echo ""
		fi

		# git worktree remove keeps the worktree bookkeeping straight and makes
		# a separate prune unnecessary. --force is safe here only because the
		# checks above already covered what git would have refused over.
		echo "\nCleaning up $chosen_dir"
		if ! git -C "$top_level" worktree remove --force "$chosen_dir"; then
			echo "Falling back to removing $chosen_dir by hand"
			rm -rf "$chosen_dir"
			git -C "$top_level" worktree prune
		fi
		echo "Cleaning up branch $git_branch"
		git -C "$top_level" branch -D "$git_branch"
	done

	# -f can delete the directory the shell is sitting in, which leaves the
	# shell with no working directory at all
	if ! [[ -d "$PWD" ]]; then
		echo "\nWorking directory was deleted, moving to $top_level"
		cd "$top_level"
	fi

	if [[ $skipped -gt 0 ]]; then
		print -P "\n%B%F{red}Skipped $skipped worktree(s) that were not safe to delete%f%b"
	fi
	return 0;
}
