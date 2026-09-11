#!/usr/bin/env bash
# Claude Code Stop + Notification hook — signals across tmux so you know a window
# needs you, WITHOUT falsely crying "done" when the agent has only paused.
#
# Four outcomes:
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
#               permission_prompt leaves it alone, so once you approve and walk away
#               the window reads as working rather than idle. Interrupting a turn
#               (ctrl-c/esc) fires NO hook at all — Claude Code has no interrupt
#               event — so nothing here ever clears the marker and it lingers until
#               that pane's next turn runs to completion. No idle_prompt
#               Notification arrives to rescue it either — measured over several
#               minutes, with the input box both populated and empty. The switcher
#               compensates by disbelieving the marker once the pane stops
#               repainting (see BUSY_STALE_SECS in agent_switch.sh), and a dead
#               Claude drops out of its list entirely (it only lists panes with a
#               live agent process).
#
# background_tasks is a JSON array on the Stop payload (Claude Code 2.1.145+);
# each entry is a running shell ("type":"shell") OR subagent ("type":"subagent").
# Empty array ⇒ truly done. It is null on Notification events, so we only trust it
# for Stop. Verified empirically (both task kinds appear) before relying on it.
#
# For DONE/APPROVAL the bell/notification stay SILENT whenever your tmux client is
# already sitting on the Claude window — you'll see it when you look.

# Fast path for the PostToolUse heartbeat: the event is implied by the argument, so
# skip the payload read and the jq calls entirely. This runs on EVERY tool call, so
# it must stay down to a single tmux invocation. Silent, and always exit 0.
if [ "${1:-}" = "working" ]; then
  # -F expands the value as a format, so this is "keep the existing stamp, else
  # stamp now" in a single tmux call: the marker holds the time the CURRENT turn
  # started, and the heartbeat must not reset that clock on every tool call.
  # A tool actually ran, so any permission prompt has been answered: clearing
  # @claude_blocked rides along in the same tmux invocation, keeping this path at
  # one fork however many markers it maintains.
  [ -n "${TMUX:-}" ] && tmux set -wF ${TMUX_PANE:+-t "$TMUX_PANE"} @claude_busy \
    "#{?@claude_busy,#{@claude_busy},$(date +%s)}" \; \
    set -uw ${TMUX_PANE:+-t "$TMUX_PANE"} @claude_blocked 2>/dev/null
  exit 0
fi

payload=$(cat)   # the hook JSON on stdin
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // empty'   2>/dev/null)
ntype=$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null)
# Running background tasks (shells + subagents). null/empty/absent all collapse to 0.
pending=$(printf '%s' "$payload" | jq '(.background_tasks | length) // 0' 2>/dev/null)
[ -z "$pending" ] && pending=0

[ -z "${TMUX:-}" ] && exit 0   # not inside tmux → nothing to flag

p="${TMUX_PANE:-}"

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
if [ "$event" = "Stop" ] || { [ "$event" = "Notification" ] && [ "$ntype" != "permission_prompt" ]; }; then
  tmux set -uw ${p:+-t "$p"} @claude_busy 2>/dev/null
fi

# Every event this hook sees is the agent coming to rest in some sense — finished,
# gone idle, or blocked on you — so stamp WHEN. tmux's own #{window_activity} can't
# answer this: it means "anything was output in this window", which a repaint on
# visiting resets, so an agent idle for hours reads as seconds old once you have
# glanced at it. permission_prompt counts here even though it does not clear
# @claude_busy: the wait for you starts at the prompt.
case "$event" in
  Stop | Notification) tmux set -w ${p:+-t "$p"} @claude_idle_at "$(date +%s)" 2>/dev/null ;;
esac

# BLOCKED — waiting on you for an approval, specifically. The bell already says
# "this window wants you", but it is a TAB signal: it clears the moment you glance
# at the window. Look at a prompt, decline to answer it and walk away and the bell
# is gone while the agent is still sat there — @claude_busy is still set from before
# the prompt, so it reads as working. This marker is what survives the glance. Set
# by the one event that means blocked, cleared by everything else this hook sees
# (and by the PostToolUse heartbeat, since a tool running proves you approved).
if [ "$event" = "Notification" ] && [ "$ntype" = "permission_prompt" ]; then
  tmux set -w ${p:+-t "$p"} @claude_blocked 1 2>/dev/null
else
  tmux set -uw ${p:+-t "$p"} @claude_blocked 2>/dev/null
fi

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
