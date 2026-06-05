#!/usr/bin/env bash
# Claude Code Stop + Notification hook — pings so you know to go back to a window.
# Acts on: Stop (Claude finished a response) and Notification/permission_prompt
# (Claude is blocked needing approval). Ignores Notification/idle_prompt (a ~60s
# "still waiting" nag that fires even after you've seen the result and moved on)
# and the MCP auth/elicitation notification types.
# To avoid pinging a window you're actively working in, it stays SILENT whenever
# your tmux client is already sitting on the Claude window (you'll see it when you
# look at the terminal). It only flags/pops for a window you've moved away from:
# rings the bell on the pane (so tmux flags the window in the SESSION_ALERTS_ strip
# and the prefix+s [!] marker) and pops a macOS notification to pull you back.

payload=$(cat)   # the hook JSON on stdin
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // empty'   2>/dev/null)
ntype=$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null)

[ -z "${TMUX:-}" ] && exit 0   # not inside tmux → nothing to flag

# Only a permission_prompt notification is worth a ping; ignore idle_prompt (Stop
# already covers "done while away") and the MCP auth/elicitation types.
[ "$event" = "Notification" ] && [ "$ntype" != "permission_prompt" ] && exit 0

p="${TMUX_PANE:-}"
sess=$(tmux display      -p ${p:+-t "$p"} '#S' 2>/dev/null)
tty=$(tmux display       -p ${p:+-t "$p"} '#{pane_tty}' 2>/dev/null)
wactive=$(tmux display   -p ${p:+-t "$p"} '#{window_active}' 2>/dev/null)
sattached=$(tmux display -p ${p:+-t "$p"} '#{session_attached}' 2>/dev/null)

# Your tmux client is already on this window → you'll see it; don't ping at all.
[ "$wactive" = "1" ] && [ -n "$sattached" ] && [ "$sattached" != "0" ] && exit 0

# You're elsewhere: ring the bell (BEL 0x07, non-printing) so tmux flags the window.
[ -n "$tty" ] && printf '\a' > "$tty" 2>/dev/null

# Still in the terminal, just on another window/session → the red strip is enough.
TERM_APP="Alacritty"
front=$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
case "$front" in *"$TERM_APP"*) exit 0 ;; esac

# You've left the terminal for another app → pop a notification to pull you back.
# Message reflects which event fired: Stop = response complete and idle;
# permission_prompt = blocked mid-task waiting for your approval.
if [ "$event" = "Stop" ]; then
  msg="finished"
else
  msg="needs approval"
fi
if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"${msg}\" with title \"Claude · ${sess}\" sound name \"Submarine\"" >/dev/null 2>&1
fi
