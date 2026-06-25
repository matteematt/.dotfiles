#!/usr/bin/env bash
# Claude Code Stop + Notification hook — signals across tmux so you know a window
# needs you, WITHOUT falsely crying "done" when the agent has only paused.
#
# Three outcomes:
#   1. DONE     (Stop, no background work) — agent finished and control is back
#               with you. Rings the tmux bell (window flags red in the
#               SESSION_ALERTS_ strip + the prefix+s [!] marker) and pops a macOS
#               notification with sound. Clears the pending marker.
#   2. PENDING  (Stop, but background_tasks still running) — the agent went idle
#               yet will AUTO-RESUME when a background shell/subagent finishes.
#               No bell, no sound, NO macOS notification: just a passive ⋯ marker
#               on the window tab (the @claude_pending user option, rendered in
#               tmux.conf). It's set regardless of which app/window is focused, so
#               it's there whenever you glance over — that tab marker is the whole
#               signal for this case, since nothing actually needs you.
#   3. APPROVAL (Notification/permission_prompt) — blocked mid-task needing your
#               approval. Bell + macOS notification with sound.
#
# background_tasks is a JSON array on the Stop payload (Claude Code 2.1.145+);
# each entry is a running shell ("type":"shell") OR subagent ("type":"subagent").
# Empty array ⇒ truly done. It is null on Notification events, so we only trust it
# for Stop. Verified empirically (both task kinds appear) before relying on it.
#
# For DONE/APPROVAL the bell/notification stay SILENT whenever your tmux client is
# already sitting on the Claude window — you'll see it when you look.

payload=$(cat)   # the hook JSON on stdin
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // empty'   2>/dev/null)
ntype=$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null)
# Running background tasks (shells + subagents). null/empty/absent all collapse to 0.
pending=$(printf '%s' "$payload" | jq '(.background_tasks | length) // 0' 2>/dev/null)
[ -z "$pending" ] && pending=0

[ -z "${TMUX:-}" ] && exit 0   # not inside tmux → nothing to flag

p="${TMUX_PANE:-}"

# Only a permission_prompt notification is worth a ping; ignore idle_prompt (Stop
# already covers "done while away") and the MCP auth/elicitation types.
[ "$event" = "Notification" ] && [ "$ntype" != "permission_prompt" ] && exit 0

# Reconcile the passive pending marker on every Stop, regardless of focus, so it
# reflects reality whether or not you're looking.
#   PENDING → set ⋯ and stop here: the tab marker is the entire signal (no bell,
#             no notification). It clears when you switch to the window
#             (session-window-changed hook in tmux.conf) or on the next DONE Stop,
#             so it can't get stuck after an interrupted/crashed session.
#   DONE    → clear ⋯ and fall through to the bell + "finished" notification.
if [ "$event" = "Stop" ]; then
  if [ "$pending" -gt 0 ]; then
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

# Still in the terminal, just on another window/session → the red strip is enough.
TERM_APP="Alacritty"
front=$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
case "$front" in *"$TERM_APP"*) exit 0 ;; esac

# You've left the terminal → pop a macOS notification to pull you back. Text and
# sound reflect the outcome: Stop = finished and idle; permission_prompt = blocked
# mid-task waiting for your approval.
command -v osascript >/dev/null 2>&1 || exit 0
if [ "$event" = "Stop" ]; then
  osascript -e "display notification \"finished\" with title \"Claude · ${sess}\" sound name \"Submarine\"" >/dev/null 2>&1
else
  osascript -e "display notification \"needs approval\" with title \"Claude · ${sess}\" sound name \"Submarine\"" >/dev/null 2>&1
fi
