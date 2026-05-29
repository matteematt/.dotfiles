#!/usr/bin/env bash
# Claude Code Stop / Notification hook.
# Rings the bell on Claude's tmux pane (so the window gets the red bell flag,
# which the SESSION_ALERTS_ status segment surfaces across every session) and
# pops a macOS notification tagged with the session name — but only when you're
# NOT already looking at that window, to avoid spam while you're watching.

cat >/dev/null 2>&1            # drain the hook JSON on stdin (unused)

[ -z "${TMUX:-}" ] && exit 0   # not inside tmux → nothing to flag

p="${TMUX_PANE:-}"
sess=$(tmux display -p ${p:+-t "$p"} '#S' 2>/dev/null)
tty=$(tmux display  -p ${p:+-t "$p"} '#{pane_tty}' 2>/dev/null)
focused=$(tmux display -p ${p:+-t "$p"} '#{&&:#{window_active},#{session_attached}}' 2>/dev/null)

# Is the terminal the frontmost macOS app? (lsappinfo needs no special perms.)
TERM_APP="Alacritty"
front=$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
case "$front" in *"$TERM_APP"*) term_front=1 ;; *) term_front=0 ;; esac

# Truly looking at it = active window of an attached session AND terminal is
# frontmost → do nothing (no bell beep, no popup) so your live Claude chat is quiet.
[ "$focused" = "1" ] && [ "$term_front" = "1" ] && exit 0

# Otherwise ring the bell (BEL 0x07, non-printing) so tmux flags the window and it
# shows in the red cross-session strip.
[ -n "$tty" ] && printf '\a' > "$tty" 2>/dev/null

# OS popup only when you've left the terminal for another app; while you're in the
# terminal the red strip already tells you which session wants you.
[ "$term_front" = "1" ] && exit 0

if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"needs you\" with title \"Claude · ${sess}\" sound name \"Submarine\"" >/dev/null 2>&1
fi
