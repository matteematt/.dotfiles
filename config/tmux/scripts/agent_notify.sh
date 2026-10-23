#!/usr/bin/env bash
# Claude Code / Codex lifecycle hook — signals across tmux so you know a window
# needs you, WITHOUT falsely crying "done" when the agent has only paused.
#
# Usage: agent_notify.sh <claude|codex> [working|notify|desktop] [arguments...]
#
# The @claude_* tmux option names below are retained as a compatibility interface.
# Existing tmux formats, active Claude sessions, and older dotfile revisions all
# understand them; their values now describe whichever agent owns the window.
#
# Four outcomes:
#   1. DONE     (Stop, no background work) — agent finished and control is back
#               with you. Rings the tmux bell (window flags red in the
#               SESSION_ALERTS_ strip + the prefix+s [!] marker) and pops a macOS
#               notification with sound. Clears the pending marker.
#   2. PENDING  (Claude Stop, but background_tasks still running) — the agent went idle
#               yet will AUTO-RESUME when a background shell/subagent finishes.
#               No bell, no sound, NO macOS notification: just a passive ⋯ marker
#               on the window tab (the @claude_pending user option, rendered in
#               tmux.conf). It's set regardless of which app/window is focused, so
#               it's there whenever you glance over — that tab marker is the whole
#               signal for this case, since nothing actually needs you.
#   3. APPROVAL (Claude Notification/permission_prompt or Codex PermissionRequest)
#               — blocked mid-task needing your
#               approval. Bell + macOS notification with sound, and sets
#               @claude_blocked, which unlike the bell outlives you glancing at the
#               window — it clears when a tool actually runs, i.e. when you answer.
#
#   4. BUSY     (UserPromptSubmit) — you just handed it work. Sets @claude_busy to
#               the unix time the turn STARTED, and stops there. Every other event
#               this hook sees means the agent has come to rest, so they all clear
#               it. Nothing is drawn on the tab for this one: it exists so
#               agent_switch.sh can tell "actively working" apart from "idle since
#               forever", sort accordingly, and show how long each has been at it.
#               Re-armed on every PostToolUse (registered with the "working"
#               argument), which is what makes it survive an approval:
#               the approval event leaves it alone, so once you approve and walk away
#               the window reads as working rather than idle. Interrupting a turn
#               (ctrl-c/esc) fires NO hook event in Claude Code, so nothing here
#               ever clears the marker and it lingers until
#               that pane's next turn runs to completion. No idle_prompt
#               Notification arrives to rescue it either — measured over several
#               minutes, with the input box both populated and empty. The switcher
#               compensates by disbelieving the marker once the pane stops
#               repainting (see BUSY_STALE_SECS in agent_switch.sh), and a dead
#               Claude drops out of its list entirely (it only lists panes with a
#               live agent process).
#
# background_tasks is a JSON array on the Claude Stop payload (Claude Code 2.1.145+);
# each entry is a running shell ("type":"shell") OR subagent ("type":"subagent").
# Empty array ⇒ truly done. It is null on Notification events, so we only trust it
# for Stop. Verified empirically (both task kinds appear) before relying on it.
#
# For DONE/APPROVAL the bell/notification stay SILENT whenever your tmux client is
# already sitting on the agent window — you'll see it when you look.

agent=${1:-}
mode=${2:-}
case "$agent" in
  claude) agent_label="Claude" ;;
  codex)  agent_label="Codex" ;;
  *) exit 0 ;;
esac

terminal_is_front() {
  local front
  front=$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
  case "$front" in *"Alacritty"*) return 0 ;; esac
  return 1
}

send_macos_notification() {
  local body=$1 title=$2
  command -v osascript >/dev/null 2>&1 || return 0
  # Pass dynamic text as argv rather than interpolating it into AppleScript. This
  # keeps quotes and other characters in tmux session names harmless.
  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Submarine"' \
    -e 'end run' \
    "$body" "$title" >/dev/null 2>&1
}

# A Codex lifecycle hook cannot reach macOS UI services, but it can already reach
# the tmux server to set markers and ring BEL. Ask that host-side server to launch
# this script's small desktop-only mode for events (currently approval requests)
# that Codex's external `notify` callback does not support.
relay_macos_notification_via_tmux() {
  local command
  printf -v command '%q ' "$0" "$agent" desktop "$1" "$2"
  tmux run-shell -b "$command" 2>/dev/null
}

if [ "$mode" = "desktop" ]; then
  terminal_is_front && exit 0
  send_macos_notification "${3:-}" "${4:-$agent_label}"
  exit 0
fi

# Codex's `notify` config is deliberately separate from its lifecycle hooks. Stop
# hooks run inside Codex's restricted execution context, which can update tmux but
# cannot talk to macOS notification services. `notify` is the documented host-side
# path for an external desktop alert and receives its payload as one JSON argument.
# It must not touch the tmux markers or ring BEL: the Stop hook already did that.
if [ "$mode" = "notify" ]; then
  payload=${3:-}
  [ "$(printf '%s' "$payload" | jq -r '.type // empty' 2>/dev/null)" = "agent-turn-complete" ] || exit 0

  p=${TMUX_PANE:-}
  sess=''
  if [ -n "$p" ]; then
    sess=$(tmux display -p -t "$p" '#S' 2>/dev/null)
    wactive=$(tmux display -p -t "$p" '#{window_active}' 2>/dev/null)
    sattached=$(tmux display -p -t "$p" '#{session_attached}' 2>/dev/null)
    # Match the Claude behavior: no system alert if this pane is already visible.
    [ "$wactive" = "1" ] && [ -n "$sattached" ] && [ "$sattached" != "0" ] && exit 0
  fi
  terminal_is_front && exit 0

  # Outside tmux (or after its pane has gone), keep the title useful by naming the
  # working directory. Inside tmux, retain the established "agent · session" title.
  if [ -z "$sess" ]; then
    cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
    sess=${cwd##*/}
    [ -n "$sess" ] || sess='turn complete'
  fi
  send_macos_notification "finished" "${agent_label} · ${sess}"
  exit 0
fi

# Which tmux pane to flag. Normally just $TMUX_PANE, inherited from the pane that
# launched claude. A BACKGROUND session breaks that: forking/sending a session to the
# background re-hosts it under the Claude daemon (`claude --bg-pty-host …`, parented
# to launchd), and the claude left in the pane is only a viewer attached to it. Hooks
# run in the background process, which has no TMUX or TMUX_PANE, so every marker and
# the bell silently stopped for that pane.
#
# Fallback, for background sessions only: the one pane whose shell is running claude
# in the session's cwd. Gated on a bg-pty-host ancestor so a claude outside tmux
# (Claude.app, a plain terminal) in the same directory never lights up a tmux pane.
# Two candidate panes is ambiguous, so neither is flagged.
is_bg_session() {
  # Walk our own ancestry in one ps snapshot, looking for the daemon's pty host.
  # Starts at our parent, and matches the flag as a whole word, so a command line
  # that merely mentions it (this script being grepped, say) is not mistaken for it.
  ps -axo pid=,ppid=,args= | awk -v p=$PPID '
    { pid = $1; ppid[pid] = $2; $1 = $2 = ""; args[pid] = $0 " " }
    END {
      while (p > 1 && (p in ppid)) {
        if (args[p] ~ / --bg-pty-host /) exit 0
        p = ppid[p]
      }
      exit 1
    }'
}

resolve_pane() {
  [ -n "${TMUX_PANE:-}" ] && { printf '%s' "$TMUX_PANE"; return; }
  local cwd=$1 match='' id pid path
  [ -n "$cwd" ] || return
  # Only Claude currently detaches hook execution from the pane that launched it.
  # Codex retains TMUX_PANE; without it, matching by cwd could flag an unrelated
  # Codex process outside tmux.
  [ "$agent" = "claude" ] || return
  is_bg_session || return
  while IFS=$'\t' read -r id pid path; do
    [ "$path" = "$cwd" ] || continue
    pgrep -P "$pid" -f claude >/dev/null 2>&1 || continue
    [ -n "$match" ] && return
    match=$id
  done < <(tmux list-panes -a -F "#{pane_id}	#{pane_pid}	#{pane_current_path}" 2>/dev/null)
  printf '%s' "$match"
}

# Fast path for the PostToolUse heartbeat: the event is implied by the argument, so
# skip the payload read and the jq calls entirely. This runs on EVERY tool call, so
# it must stay down to a single tmux invocation. Silent, and always exit 0. (A
# background session pays for a pane lookup here instead; see resolve_pane.)
if [ "$mode" = "working" ]; then
  p=${TMUX_PANE:-}
  [ -z "$p" ] && p=$(resolve_pane "$(jq -r '.cwd // empty' 2>/dev/null)")
  # -F expands the value as a format, so this is "keep the existing stamp, else
  # stamp now" in a single tmux call: the marker holds the time the CURRENT turn
  # started, and the heartbeat must not reset that clock on every tool call.
  # A tool actually ran, so any permission prompt has been answered: clearing
  # @claude_blocked rides along in the same tmux invocation, keeping this path at
  # one fork however many markers it maintains.
  [ -n "$p" ] && tmux set -wF -t "$p" @claude_busy \
    "#{?@claude_busy,#{@claude_busy},$(date +%s)}" \; \
    set -uw -t "$p" @claude_blocked 2>/dev/null
  exit 0
fi

payload=$(cat)   # the hook JSON on stdin
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // empty'   2>/dev/null)
ntype=$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null)
is_approval=0
if { [ "$event" = "Notification" ] && [ "$ntype" = "permission_prompt" ]; } || \
   [ "$event" = "PermissionRequest" ]; then
  is_approval=1
fi
# Running background tasks (shells + subagents). null/empty/absent all collapse to 0.
pending=$(printf '%s' "$payload" | jq '(.background_tasks | length) // 0' 2>/dev/null)
[ -z "$pending" ] && pending=0

p=$(resolve_pane "$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)")
[ -z "$p" ] && exit 0   # not inside tmux (or no pane to pin it on) → nothing to flag

# BUSY is set by the one event that means work just started, and cleared by every
# other event this hook receives — a Stop of either flavour, or a Notification of
# any type (permission_prompt, idle_prompt, MCP auth: all of them mean the agent is
# waiting rather than working). Cleared BEFORE the filter below so the ignored
# notification types still count. Note UserPromptSubmit stdout is fed back into
# Claude's context, so this path must stay silent and MUST exit 0 — a non-zero exit
# would block the prompt.
if [ "$event" = "UserPromptSubmit" ]; then
  # A new turn: stamp unconditionally, restarting the clock, and drop any stale
  # block (you can interrupt a permission prompt and just type something else).
  tmux set -w ${p:+-t "$p"} @claude_busy "$(date +%s)" \; \
    set -uw ${p:+-t "$p"} @claude_blocked 2>/dev/null
  exit 0
fi
# ...and cleared by anything meaning the turn came to rest: a Stop of either
# flavour, or an idle/auth Notification. A permission_prompt is deliberately NOT
# such an event — it's blocked mid-turn and carries straight on once you approve,
# so the marker has to outlive it. That's the whole point of keeping this separate
# from the bell: the bell is a TAB signal and self-clears the moment you glance at
# the window, whereas @claude_busy tracks what the agent is actually doing, so the
# switcher can still show ▸ after you've approved and walked away.
if [ "$event" = "Stop" ] || [ "$event" = "Interrupt" ] || \
   { [ "$event" = "Notification" ] && [ "$ntype" != "permission_prompt" ]; }; then
  tmux set -uw ${p:+-t "$p"} @claude_busy 2>/dev/null
fi

# Every event this hook sees is the agent coming to rest in some sense — finished,
# gone idle, or blocked on you — so stamp WHEN. tmux's own #{window_activity} can't
# answer this: it means "anything was output in this window", which a repaint on
# visiting resets, so an agent idle for hours reads as seconds old once you have
# glanced at it. permission_prompt counts here even though it does not clear
# @claude_busy: the wait for you starts at the prompt.
case "$event" in
  Stop | Notification | PermissionRequest | Interrupt)
    tmux set -w ${p:+-t "$p"} @claude_idle_at "$(date +%s)" 2>/dev/null
    ;;
esac

# BLOCKED — waiting on you for an approval, specifically. The bell already says
# "this window wants you", but it is a TAB signal: it clears the moment you glance
# at the window. Look at a prompt, decline to answer it and walk away and the bell
# is gone while the agent is still sat there — @claude_busy is still set from before
# the prompt, so it reads as working. This marker is what survives the glance. Set
# by the one event that means blocked, cleared by everything else this hook sees
# (and by the PostToolUse heartbeat, since a tool running proves you approved).
if [ "$is_approval" -eq 1 ]; then
  tmux set -w ${p:+-t "$p"} @claude_blocked 1 2>/dev/null
else
  tmux set -uw ${p:+-t "$p"} @claude_blocked 2>/dev/null
fi

# An interrupt is a quiet transition back to idle. Codex exposes this event, so it
# can clean up immediately instead of waiting for the stale-output fallback.
if [ "$event" = "Interrupt" ]; then
  tmux set -uw ${p:+-t "$p"} @claude_pending 2>/dev/null
  exit 0
fi

# Only an approval notification is worth a ping; ignore Claude idle_prompt (Stop
# already covers "done while away") and the MCP auth/elicitation types. Ignore any
# unexpected hook event rather than accidentally announcing it as completion.
case "$event" in
  Stop) ;;
  Notification) [ "$is_approval" -eq 1 ] || exit 0 ;;
  PermissionRequest) ;;
  *) exit 0 ;;
esac

# Reconcile the passive pending marker on every Stop, regardless of focus, so it
# reflects reality whether or not you're looking.
#   PENDING → set ⋯ and stop here: the tab marker is the entire signal (no bell,
#             no notification). It clears when you switch to the window
#             (session-window-changed hook in tmux.conf) or on the next DONE Stop,
#             so it can't get stuck after an interrupted/crashed session.
#   DONE    → clear ⋯ and fall through to the bell + "finished" notification.
if [ "$event" = "Stop" ]; then
  if [ "$agent" = "claude" ] && [ "$pending" -gt 0 ]; then
    tmux set -w ${p:+-t "$p"} @claude_pending 1 2>/dev/null
    exit 0
  fi
  tmux set -uw ${p:+-t "$p"} @claude_pending 2>/dev/null
fi

# From here it's DONE (Stop, no background work) or APPROVAL (permission_prompt).
sess=$(tmux display      -p ${p:+-t "$p"} '#S' 2>/dev/null)
tty=$(tmux display       -p ${p:+-t "$p"} '#{pane_tty}' 2>/dev/null)
wactive=$(tmux display   -p ${p:+-t "$p"} '#{window_active}' 2>/dev/null)
sattached=$(tmux display -p ${p:+-t "$p"} '#{session_attached}' 2>/dev/null)

# Your tmux client is already on this window → you'll see it; don't bell/notify.
[ "$wactive" = "1" ] && [ -n "$sattached" ] && [ "$sattached" != "0" ] && exit 0

# You're elsewhere: ring the bell (BEL 0x07, non-printing) so tmux flags the window.
[ -n "$tty" ] && printf '\a' > "$tty" 2>/dev/null

# Codex's host-side `notify` command owns completion alerts. PermissionRequest has
# no equivalent external event, so relay just that alert through the tmux server.
# Keeping both out of this restricted hook process avoids the macOS UI failure and
# prevents completed turns from notifying twice.
if [ "$agent" = "codex" ]; then
  [ "$is_approval" -eq 1 ] && \
    relay_macos_notification_via_tmux "needs approval" "${agent_label} · ${sess}"
  exit 0
fi

# Still in the terminal, just on another window/session → the red strip is enough.
terminal_is_front && exit 0

# You've left the terminal → pop a macOS notification to pull you back. Text and
# sound reflect the outcome: Stop = finished and idle; permission_prompt = blocked
# mid-task waiting for your approval.
if [ "$event" = "Stop" ]; then
  send_macos_notification "finished" "${agent_label} · ${sess}"
else
  send_macos_notification "needs approval" "${agent_label} · ${sess}"
fi
