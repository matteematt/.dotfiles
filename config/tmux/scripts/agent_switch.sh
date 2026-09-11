#!/usr/bin/env bash
# Jump to the agent pane that wants you — an fzf popup listing every tmux pane
# running an agentic CLI, sorted so the ones asking for attention float to the top.
#
# Adapted from @codethread's tmux-agent-switch, which is the source of the pane
# discovery approach (one `ps` snapshot, newest-child-of-the-pane-shell, match on
# full argv) and the display/preview layout:
#   https://github.com/codethread/dots/blob/main/home/.local/bin/tmux-agent-switch
#
# What's different here:
#   * ALERT AWARENESS. His version lists panes in tmux's enumeration order with no
#     notion of which agent is waiting. This one reads the two signals
#     claude_notify.sh already raises and sorts/marks by them:
#       !  window bell flag  — DONE or needs-approval, rung while you were elsewhere
#          (the same signal behind the red tab and the SESSION_ALERTS_ strip)
#          @claude_blocked also raises ! — waiting on you to answer a permission
#          prompt. Same mark deliberately, since it means the same thing to you, but
#          unlike the bell it outlives a glance at the window: it clears only when a
#          tool runs, i.e. when you actually answer
#       ▸  @claude_busy      — actively working: you gave it a prompt and no Stop
#          or Notification has landed since
#       ⋯  @claude_pending   — stopped, but background work will auto-resume it
#       *  the pane you're sitting in right now
#     All are window-scoped; bell and @claude_pending self-clear when you visit, so
#     the list only ever
#     shouts about agents you haven't looked at since they asked. Previewing does
#     NOT clear them: capture-pane reads a pane without visiting its window.
#   * Sessions are named "<repo>(<branch>)" here (see name_session_from_git.sh), so
#     they're split into separate columns instead of his "pandora--tool__repo" parse.
#   * Agent list trimmed to what's actually installed (claude, codex, aider) — his
#     regex matches bare `cl`/`pi`, which also hit any path containing those words.
#
# Note tmux's own #{pane_current_command} is useless for this: Claude Code sets its
# process name to its version, so panes report "2.1.267" rather than "claude".
# Hence the ps snapshot.
#
# Deliberately bash-3.2 compatible (macOS /bin/bash): indexed arrays keyed by PID
# rather than `declare -A`, no mapfile.
#
# Usage: agent_switch.sh [--debug] [--json]
#   --debug  print the pane list plus captured content, no fzf
#   --json   print discovered panes as JSON (needs jq) and exit
#   --popup=<client>  internal: the second half, already inside the tmux popup

set -u

US=$'\037'  # unit separator: display subfields (session names and paths can hold
TAB=$'\t'   # anything except these), TAB: machine fields for cut/read

# Matched against the full argv, so `node …/cli.js` style launches still resolve.
AGENT_REGEX='(^|[^[:alnum:]_-])(claude|codex|aider)([^[:alnum:]_-]|$)'
# Bare executable names worth a second look; node/bun only count if argv also
# matches AGENT_REGEX, so a random node process isn't listed as an agent.
AGENT_EXECS='^(claude|codex|aider|node|bun)$'

DEBUG_MODE=0
JSON_MODE=0
POPUP_MODE=0
CLIENT=''

# Absolute path to self, so the popup can re-invoke us. The keybinding passes an
# absolute path already; the guard covers being run as ./agent_switch.sh.
SELF=$0
case "$SELF" in /*) ;; *) SELF="$PWD/$SELF" ;; esac

# Legend for the popup, one row: marks on the left, keys flushed right. Colours must
# match the marks in align_candidates. The keys half earns its place because list
# mode hides the prompt, leaving nothing on screen to hint that / searches.
LEGEND_MARKS=$'\033[1;31m!\033[0m needs you   \033[32m▸\033[0m working   \033[33m⋯\033[0m background work   * you are here'
# Key then what it does, split on the first space. Kept as pairs rather than one
# string so build_header can colour the two halves differently and still measure the
# printable width.
LEGEND_KEYS_SPEC=( 'j/k move' 'd/u scroll' 'ctrl-o expand' '/ search' 'enter jump' 'esc/q quit' )

# fzf opens with its input field hidden (--no-input), so the list reads as a vim
# buffer: bare letters navigate instead of filtering. Pressing / reveals the field
# and unbinds every one of these, or you could not type a "j" into the query; esc
# hides it again and rebinds them. Anything ctrl-prefixed is safe in both modes and
# so stays out of this list.
LIST_KEYS='j,k,g,G,d,u,q,/'

# esc keeps both of its meanings: quit from list mode, leave search from search mode.
# A key holds one binding, so the branch happens at run time off $FZF_INPUT_STATE.
#
# The catch is that fzf drops clear-query when it shares a transform's output with
# hide-input — either order, silently — which would drop you back into a list still
# filtered by a query you can no longer see. Split across two events it works, so esc
# only clears the query, and the change event that clearing fires does the hiding.
# That also means backspacing a query away returns you to list mode on its own, which
# is the same state by a different route. An esc pressed on an already-empty query
# has no change to ride, so it hides the input itself.
ESC_ACTION="transform:if [[ \$FZF_INPUT_STATE != enabled ]]; then echo abort; \
elif [[ -n \$FZF_QUERY ]]; then echo clear-query; \
else echo 'hide-input+rebind($LIST_KEYS)'; fi"
CHANGE_ACTION="transform:[[ -z \$FZF_QUERY ]] && echo 'hide-input+rebind($LIST_KEYS)'"

# The gap between the two halves depends on the popup's width, so the header is
# built at render time. Padding counts characters with the colour codes stripped —
# ${#LEGEND_MARKS} would count the escapes as printable and shove the keys off the
# right edge. Narrow terminals stack the halves rather than overlapping them.
build_header() {
	local cols marks_plain keys keys_plain entry key label pad
	# tmux, not tput: the header is built inside $(build_header), so tput's stdout is
	# a pipe rather than a terminal and it answers with a bare 80 every time. The
	# popup is opened at -w 100%, so the client's width is the popup's width.
	cols=$(tmux display -p ${CLIENT:+-c "$CLIENT"} '#{client_width}' 2>/dev/null)
	[[ -n "$cols" && $cols -gt 0 ]] || cols=$(tput cols 2>/dev/null)
	[[ -n "$cols" && $cols -gt 0 ]] || cols=80

	# Cyan key, dimmed description — cyan is the one colour the marks do not already
	# use, so a key never reads as a status mark. The plain copy is built alongside,
	# since the coloured one cannot be measured.
	keys=''
	keys_plain=''
	for entry in "${LEGEND_KEYS_SPEC[@]}"; do
		key=${entry%% *}
		label=${entry#* }
		if [[ -n "$keys" ]]; then
			keys+='   '
			keys_plain+='   '
		fi
		keys+=$'\033[36m'"$key"$'\033[0m\033[2m '"$label"$'\033[0m'
		keys_plain+="$key $label"
	done

	marks_plain=$(printf '%s' "$LEGEND_MARKS" | sed $'s/\033\\[[0-9;]*m//g')
	# fzf indents the header by the pointer column; one more spare keeps the last
	# character clear of the right edge, where a wrap would cost a whole row.
	pad=$(( cols - 3 - ${#marks_plain} - ${#keys_plain} ))
	if [[ $pad -lt 3 ]]; then
		printf '%s\n%s' "$LEGEND_MARKS" "$keys"
		return
	fi
	printf '%s%*s%s' "$LEGEND_MARKS" "$pad" '' "$keys"
}

usage() {
	sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0"
	exit 0
}

for arg in "$@"; do
	case "$arg" in
		--debug) DEBUG_MODE=1 ;;
		--json) JSON_MODE=1 ;;
		--popup=*) POPUP_MODE=1 CLIENT=${arg#--popup=} ;;
		-h | --help) usage ;;
		*)
			echo "agent_switch.sh: unknown argument '$arg'" >&2
			exit 1
			;;
	esac
done

command -v tmux >/dev/null 2>&1 || { echo 'agent_switch.sh: tmux is required' >&2; exit 1; }

if [[ $DEBUG_MODE -eq 0 && $JSON_MODE -eq 0 ]]; then
	if ! command -v fzf >/dev/null 2>&1; then
		echo 'agent_switch.sh: fzf is required' >&2
		exit 1
	fi
	# List mode needs --no-input and show-input/hide-input, which landed in fzf 0.56.
	# Without this guard an older fzf fails inside the popup, where you cannot read it.
	fzf_ver=$(fzf --version 2>/dev/null)
	fzf_ver=${fzf_ver%% *}
	fzf_minor=${fzf_ver#*.}
	fzf_minor=${fzf_minor%%.*}
	if [[ ${fzf_ver%%.*} -eq 0 && ${fzf_minor:-0} -lt 56 ]]; then
		echo "agent_switch.sh: fzf 0.56+ required for list mode (found $fzf_ver)" >&2
		exit 1
	fi
fi

if [[ $JSON_MODE -eq 1 ]] && ! command -v jq >/dev/null 2>&1; then
	echo 'agent_switch.sh: jq is required for --json' >&2
	exit 1
fi

if [[ -z "${TMUX:-}" ]] && ! tmux list-clients >/dev/null 2>&1; then
	echo 'agent_switch.sh: no running tmux client found' >&2
	exit 1
fi

# PID-keyed lookups from ONE ps call — per-pane ps calls make the popup crawl.
declare -a PROCESS_ARGS NEWEST_CHILD

snapshot_processes() {
	local ppid pid args
	while read -r ppid pid args; do
		PROCESS_ARGS[$pid]=$args
		# Highest PID among a shell's children ≈ the foreground job you launched.
		if [[ -z "${NEWEST_CHILD[$ppid]:-}" ]] || ((pid > NEWEST_CHILD[ppid])); then
			NEWEST_CHILD[$ppid]=$pid
		fi
	done < <(ps -axo ppid=,pid=,args=)
}

# Compact relative age: 12s, 4m, 1h4m, 2d3h.
fmt_age() {
	local s=$1
	[[ $s -lt 0 ]] && s=0
	if [[ $s -lt 60 ]]; then
		AGE="${s}s"
	elif [[ $s -lt 3600 ]]; then
		AGE="$((s / 60))m"
	elif [[ $s -lt 86400 ]]; then
		AGE="$((s / 3600))h$(((s % 3600) / 60))m"
	else
		AGE="$((s / 86400))d$(((s % 86400) / 3600))h"
	fi
}

agent_label() {
	local exec_name=$1 args=$2
	case "$exec_name" in
		claude | codex | aider) AGENT_LABEL=$exec_name ;;
		*)
			# A node/bun wrapper: name it from whatever the argv mentions.
			if [[ "$args" =~ claude ]]; then AGENT_LABEL=claude
			elif [[ "$args" =~ codex ]]; then AGENT_LABEL=codex
			elif [[ "$args" =~ aider ]]; then AGENT_LABEL=aider
			else AGENT_LABEL=$exec_name
			fi
			;;
	esac
}

# One line per agent pane, priority-sorted:
#   <prio>US<sortkey>US<mark>US<repo>US<branch>US<idx>US<tool>US<age>US<path> TAB <pane_id> TAB <target>
list_agent_panes() {
	local pane_format now
	now=$(date +%s)
	snapshot_processes
	# The user options are emitted as an explicit 0/1 rather than "" / "1". TAB is an
	# IFS *whitespace* character, so `read` collapses runs of it — an empty field in
	# the middle silently shifts every later value one slot left, which is how
	# @claude_pending first showed up wearing @claude_busy's mark. Never let a field
	# in here be empty.
	pane_format="#{session_name}${TAB}#{window_index}${TAB}#{pane_index}${TAB}#{pane_id}${TAB}#{pane_pid}${TAB}#{pane_current_path}${TAB}#{pane_active}${TAB}#{window_active}${TAB}#{session_attached}${TAB}#{window_bell_flag}${TAB}#{?@claude_blocked,1,0}${TAB}#{?@claude_busy,#{@claude_busy},0}${TAB}#{?@claude_pending,1,0}${TAB}#{window_activity}${TAB}#{?@claude_idle_at,#{@claude_idle_at},0}"

	while IFS=$TAB read -r session window_index pane_index pane_id pane_pid pane_path \
		pane_active window_active session_attached bell blocked busy pending activity idle_at; do
		local pid args exec_name tool prio mark repo branch short_path sortkey age ref

		pid=${NEWEST_CHILD[$pane_pid]:-$pane_pid}
		args=${PROCESS_ARGS[$pid]:-}
		[[ -z "$args" ]] && continue
		exec_name=${args%% *}
		exec_name=${exec_name##*/}

		if [[ ! "$args" =~ $AGENT_REGEX ]] && [[ ! "$exec_name" =~ $AGENT_EXECS ]]; then
			continue
		fi
		if [[ "$exec_name" =~ ^(node|bun)$ ]] && [[ ! "$args" =~ $AGENT_REGEX ]]; then
			continue
		fi

		agent_label "$exec_name" "$args"
		tool=$AGENT_LABEL

		# Needs-you first, then the two in-flight states, then everything idle. The
		# flags are window-scoped, so two agent panes sharing a window both light
		# up — the pane index column tells them apart.
		if [[ "$blocked" == '1' || "$bell" == '1' ]]; then
			prio=0 mark='!'
		elif [[ "$busy" != '0' ]]; then
			prio=1 mark='▸'
		elif [[ "$pending" == '1' ]]; then
			prio=2 mark='⋯'
		elif [[ "$pane_active" == '1' && "$window_active" == '1' && "${session_attached:-0}" != '0' ]]; then
			prio=3 mark='*'
		else
			prio=3 mark=' '
		fi

		# One column, two meanings, from whichever stamp the state makes meaningful:
		#   working  → @claude_busy, when the turn started (its window_activity is
		#              always "just now", since it is emitting constantly)
		#   anything → @claude_idle_at, when the agent last came to rest
		# #{window_activity} is only the fallback, for a pane whose agent has not
		# stopped since the marker existed, or one with no hooks at all (codex,
		# aider). It answers "was anything output here", so it is reset by a repaint
		# when you visit the window — which is exactly the wrong thing to measure.
		# The lower bounds reject a stale marker from the scheme where @claude_busy
		# held "1"; those self-heal on the window's next turn.
		if [[ $prio -eq 1 && $busy -gt 1000000000 ]]; then
			ref=$busy
		elif [[ $idle_at -gt 1000000000 ]]; then
			ref=$idle_at
		else
			ref=$activity
		fi
		fmt_age $((now - ref))
		age=$AGE

		# Secondary key, on the same stamp the age column shows so the two agree. The
		# three marked tiers keep tmux's own order (alphabetical by session, then
		# window/pane index), so they all share key 0 and the stable sort leaves them
		# alone. Idle panes sort least-recently-idle last; negated so a single
		# ascending numeric sort gives descending time.
		if [[ $prio -eq 3 ]]; then
			sortkey="-$ref"
		else
			sortkey=0
		fi

		repo=$session branch=''
		[[ "$session" =~ ^(.+)\((.+)\)$ ]] && { repo=${BASH_REMATCH[1]}; branch=${BASH_REMATCH[2]}; }

		short_path=${pane_path/#$HOME/\~}

		printf '%s\n' "${prio}${US}${sortkey}${US}${mark}${US}${repo}${US}${branch}${US}${window_index}.${pane_index}${US}${tool}${US}${age}${US}${short_path}${TAB}${pane_id}${TAB}${session}:${window_index}"
	done < <(tmux list-panes -a -F "$pane_format") |
		# Tier first, then the secondary key; -s keeps tmux's order wherever both are
		# equal, so the marked tiers don't reshuffle under you between invocations.
		sort -t"$US" -s -k1,1n -k2,2n
}

# Pads columns to a common width and drops the sort key. The window.pane index is
# rendered ONLY for sessions holding more than one agent pane, since that is the
# only case where two rows would otherwise be indistinguishable — the bell and the
# state markers are window-scoped, so same-session rows can carry identical marks.
# When no session is doubled up the column disappears entirely. Colour is applied
# after padding so the escapes never enter the width arithmetic.
align_candidates() {
	local lines=() keys=() idxs=() line rest display
	local prio sortkey mark repo branch idx tool age path
	local w_repo=0 w_branch=0 w_tool=0 w_age=0 w_idx=0
	local key seen='' dupes='' RS=$'\036'

	while IFS= read -r line; do lines+=("$line"); done
	[[ ${#lines[@]} -eq 0 ]] && return

	for line in "${lines[@]}"; do
		display=${line%%$TAB*}
		IFS=$US read -r prio sortkey mark repo branch idx tool age path <<<"$display"
		[[ ${#repo} -gt $w_repo ]] && w_repo=${#repo}
		[[ ${#branch} -gt $w_branch ]] && w_branch=${#branch}
		[[ ${#tool} -gt $w_tool ]] && w_tool=${#tool}
		[[ ${#age} -gt $w_age ]] && w_age=${#age}

		# repo+branch identifies the session. Delimited with RS so one key cannot
		# partially match another, and the needle is quoted so a branch name
		# containing glob characters stays literal.
		key="${RS}${repo}${US}${branch}${RS}"
		keys+=("$key")
		idxs+=("$idx")
		if [[ "$seen" == *"$key"* ]]; then
			[[ "$dupes" != *"$key"* ]] && dupes="$dupes$key"
		else
			seen="$seen$key"
		fi
	done

	local i=0
	for key in "${keys[@]}"; do
		if [[ "$dupes" == *"$key"* ]] && [[ ${#idxs[$i]} -gt $w_idx ]]; then
			w_idx=${#idxs[$i]}
		fi
		i=$((i + 1))
	done

	local label mark_out
	i=0
	for line in "${lines[@]}"; do
		rest=${line#*$TAB}
		display=${line%%$TAB*}
		IFS=$US read -r prio sortkey mark repo branch idx tool age path <<<"$display"
		[[ "$dupes" != *"${keys[$i]}"* ]] && idx=''
		i=$((i + 1))
		case "$mark" in
			'!') mark_out=$'\033[1;31m!\033[0m' ;;
			'▸') mark_out=$'\033[32m▸\033[0m' ;;
			'⋯') mark_out=$'\033[33m⋯\033[0m' ;;
			*) mark_out=$mark ;;
		esac
		if [[ $w_idx -gt 0 ]]; then
			printf -v label '%s  %-*s  %-*s  %*s  %-*s  %*s  %s' \
				"$mark_out" \
				"$w_repo" "$repo" \
				"$w_branch" "$branch" \
				"$w_idx" "$idx" \
				"$w_tool" "$tool" \
				"$w_age" "$age" \
				"$path"
		else
			printf -v label '%s  %-*s  %-*s  %-*s  %*s  %s' \
				"$mark_out" \
				"$w_repo" "$repo" \
				"$w_branch" "$branch" \
				"$w_tool" "$tool" \
				"$w_age" "$age" \
				"$path"
		fi
		printf '%s%s%s\n' "$label" "$TAB" "$rest"
	done
}

debug_panes() {
	local raw=$1 display pane_id target prio sortkey mark repo branch idx tool age path
	if [[ -z "$raw" ]]; then
		echo 'No agent panes found.'
		return
	fi
	while IFS=$TAB read -r display pane_id target; do
		IFS=$US read -r prio sortkey mark repo branch idx tool age path <<<"$display"
		echo '──────────────────────────────────────────'
		printf 'MARK: %s  PRIO: %s  TOOL: %s  AGE: %s\n' "[$mark]" "$prio" "$tool" "$age"
		printf 'REPO: %s  BRANCH: %s  IDX: %s\n' "$repo" "$branch" "$idx"
		printf 'PANE: %s  TARGET: %s  PATH: %s\n' "$pane_id" "$target" "$path"
		echo '┄┄┄ last 20 lines ┄┄┄'
		tmux capture-pane -ep -t "$pane_id" 2>/dev/null | tail -20
		echo
	done <<<"$raw"
}

json_panes() {
	local raw objects=() display pane_id target
	local prio sortkey mark repo branch idx tool age path preview alert busy_json pending_json
	raw=$(list_agent_panes)
	[[ -z "$raw" ]] && { printf '[]\n'; return; }

	while IFS=$TAB read -r display pane_id target; do
		IFS=$US read -r prio sortkey mark repo branch idx tool age path <<<"$display"
		alert=false busy_json=false pending_json=false
		[[ "$mark" == '!' ]] && alert=true
		[[ "$mark" == '▸' ]] && busy_json=true
		[[ "$mark" == '⋯' ]] && pending_json=true
		preview=$(tmux capture-pane -p -t "$pane_id" 2>/dev/null |
			grep -v '^[─━═[:space:]]*$' | tail -20)
		objects+=("$(jq -n \
			--arg repo "$repo" --arg branch "$branch" --arg idx "$idx" \
			--arg tool "$tool" --arg age "$age" --arg path "$path" --arg pane_id "$pane_id" \
			--arg target "$target" --arg preview "$preview" \
			--argjson alert "$alert" --argjson busy "$busy_json" \
			--argjson pending "$pending_json" \
			'{repo:$repo,branch:$branch,index:$idx,tool:$tool,age:$age,path:$path,
			  pane_id:$pane_id,target:$target,alert:$alert,busy:$busy,pending:$pending,
			  preview:$preview}')")
	done <<<"$raw"

	printf '%s\n' "${objects[@]}" | jq -s '.'
}

main() {
	if [[ $JSON_MODE -eq 1 ]]; then
		json_panes
		exit 0
	fi

	if [[ $DEBUG_MODE -eq 1 ]]; then
		debug_panes "$(list_agent_panes)"
		exit 0
	fi

	# First half: get a popup on screen NOW and do the work inside it. Building the
	# candidate list costs ~150ms (mostly the ps snapshot) and fzf-tmux's wrapper
	# script another ~140ms before it even creates the popup — that was ~300ms of
	# dead air between the keypress and anything appearing. tmux draws a native
	# popup in ~10ms, so the wait now happens with the window already up.
	if [[ $POPUP_MODE -eq 0 ]]; then
		local client
		client=$(tmux display -p '#{client_name}' 2>/dev/null)
		[[ -z "$client" ]] && client=$(tmux list-clients -F '#{client_name}' 2>/dev/null | head -1)
		exec tmux display-popup ${client:+-c "$client"} -E -B -w 100% -h 100% "'$SELF' '--popup=$client'"
	fi

	# Second half: inside the popup. The client is passed in rather than inferred,
	# because a popup is not a pane — switch-client here has no current client of
	# its own to fall back on.
	printf '\n  \033[2m⟳ scanning panes…\033[0m\n'

	local candidates selected pane_id target header
	header=$(build_header)
	candidates=$(list_agent_panes | align_candidates)

	if [[ -z "$candidates" ]]; then
		tmux display-message ${CLIENT:+-c "$CLIENT"} 'No agents running'
		exit 0
	fi

	# --with-nth=1 shows only the padded label; {2} hands the preview the pane id.
	selected=$(printf '%s\n' "$candidates" |
		fzf --ansi \
			--margin='1,0,0,0' \
			--prompt='agents> ' \
			--layout=reverse-list \
			--header="$header" \
			--delimiter="$TAB" \
			--with-nth=1 \
			--preview='tmux capture-pane -ep -t {2}' \
			--preview-window='down,70%,wrap' \
			--no-input \
			--bind 'enter:accept' \
			--bind 'j:down,k:up,g:first,G:last,q:abort' \
			--bind 'd:preview-half-page-down,u:preview-half-page-up' \
			--bind 'ctrl-o:change-preview-window(down,99%,wrap|down,70%,wrap)' \
			--bind "/:show-input+unbind($LIST_KEYS)" \
			--bind "esc:$ESC_ACTION" \
			--bind "change:$CHANGE_ACTION") || exit 0

	[[ -z "$selected" ]] && exit 0
	pane_id=$(printf '%s' "$selected" | cut -f2)
	target=$(printf '%s' "$selected" | cut -f3)

	# Visiting the window is what clears its bell / @claude_pending marker.
	tmux switch-client ${CLIENT:+-c "$CLIENT"} -t "$target"
	tmux select-pane -t "$pane_id"
}

main "$@"
