#!/bin/sh
input=$(cat)

# Pull every field in one jq pass, one value per line. Not tab-separated: tab is
# IFS whitespace, so runs of empty fields would collapse and shift later values.
# Absent fields read back as empty; trailing ones just leave their var unset.
{
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r used
  IFS= read -r cwd
  IFS= read -r rl5_used
  IFS= read -r rl5_reset
  IFS= read -r rl7_used
  IFS= read -r rl7_reset
} <<EOF
$(echo "$input" | jq -r '[
  .model.display_name,
  .effort.level,
  .context_window.used_percentage,
  .workspace.current_dir,
  .rate_limits.five_hour.used_percentage,
  .rate_limits.five_hour.resets_at,
  .rate_limits.seven_day.used_percentage,
  .rate_limits.seven_day.resets_at
] | map(if . == null then "" else tostring end) | .[]' 2>/dev/null)
EOF

now=$(date +%s)

# ANSI escape sequences as literal ESC bytes (ANSI-C quoting, portable in sh)
ESC=$'\033'
ESC_RESET="${ESC}[0m"
ESC_YELLOW="${ESC}[33m"
ESC_GREEN="${ESC}[32m"
ESC_AMBER="${ESC}[33m"
ESC_RED="${ESC}[31m"
ESC_BLUE="${ESC}[34m"
ESC_CYAN="${ESC}[36m"
ESC_MAGENTA="${ESC}[35m"
ESC_GREY="${ESC}[90m"

BAR_WIDTH=16
DIVIDER="│"

# Width of a full-screen pane on this laptop, used whenever the real width
# cannot be read (outside tmux there is no way to obtain it - the status line
# runs with no controlling terminal at all).
DEFAULT_COLS=187

# Quota windows: length in seconds, and the absolute usage scale both share
FIVE_HOUR_SECS=18000
SEVEN_DAY_SECS=604800
QUOTA_AMBER_PCT=80
QUOTA_RED_PCT=100

# Burn is how far ahead of the clock the spending is, in percentage points:
# usage% minus elapsed%. Level pace reads 0 and the quota then lasts exactly to
# the reset. Positive is spending brought forward; negative is quota in hand for
# how far through the window we are.
BURN_GREEN_PTS=1
BURN_AMBER_PTS=10
BURN_RED_PTS=25

# Real pane width when tmux can tell us. Target our own pane explicitly: an
# untargeted query answers for whichever pane is active, which is often another
# session. pane_width rather than client_width, so it survives a detached client.
cols=$DEFAULT_COLS
if [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null 2>&1; then
  tmux_cols=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
  case "$tmux_cols" in
    ''|*[!0-9]*) ;;
    *) cols=$tmux_cols ;;
  esac
fi

# ${#} counts display columns only under a UTF-8 locale; under LC_ALL=C it
# counts bytes and every measurement would be wrong. Probe once, and if the
# locale is byte-oriented, skip adapting rather than lay out from bad numbers.
probe="█"
if [ ${#probe} -eq 1 ]; then
  can_measure=1
else
  can_measure=""
fi

# Render a block bar for percentage $1. Clamped, so a reading over 100 (or a
# negative one) can never stretch or invert the bar.
bar() {
  _filled=$(( $1 * BAR_WIDTH / 100 ))
  [ "$_filled" -lt 0 ] && _filled=0
  [ "$_filled" -gt "$BAR_WIDTH" ] && _filled="$BAR_WIDTH"

  _out=""
  _i=0
  while [ "$_i" -lt "$_filled" ]; do
    _out="${_out}█"
    _i=$(( _i + 1 ))
  done
  while [ "$_i" -lt "$BAR_WIDTH" ]; do
    _out="${_out}░"
    _i=$(( _i + 1 ))
  done

  printf '%s' "$_out"
}

# Usage colour for percentage $1: green below $2, amber from $2, red from $3.
# The meters run on different scales, hence the explicit thresholds.
usage_color() {
  if [ "$1" -ge "$3" ]; then
    printf '%s' "$ESC_RED"
  elif [ "$1" -ge "$2" ]; then
    printf '%s' "$ESC_AMBER"
  else
    printf '%s' "$ESC_GREEN"
  fi
}

# Compact time remaining for $1 seconds: 3d04h, 2h30m, or 47m
duration() {
  _mins=$(( ($1 + 59) / 60 ))
  if [ "$_mins" -ge 1440 ]; then
    printf '%dd%02dh' "$(( _mins / 1440 ))" "$(( (_mins % 1440) / 60 ))"
  elif [ "$_mins" -ge 60 ]; then
    printf '%dh%02dm' "$(( _mins / 60 ))" "$(( _mins % 60 ))"
  else
    printf '%dm' "$_mins"
  fi
}

# Burn in percentage points for $1 usage %, $2 reset stamp, $3 window seconds.
# Silent when there is no usage or the reset has already passed.
burn_pts() {
  [ -n "$1" ] && [ -n "$2" ] || return 0
  _left=$(( $(printf "%.0f" "$2") - now ))
  [ "$_left" -gt 0 ] || return 0

  # The window is assumed to have opened $3 seconds before it resets, so
  # elapsed% is how far through it we are
  _elapsed=$(( ($3 - _left) * 100 / $3 ))
  [ "$_elapsed" -lt 0 ] && _elapsed=0
  printf '%d' "$(( $(printf "%.0f" "$1") - _elapsed ))"
}

# One quota meter: $1 label, $2 usage %, $3 reset stamp, $4 window seconds,
# $5 non-empty to draw the bar. Silent when there is no usage figure.
quota_seg() {
  [ -n "$2" ] || return 0

  _pct=$(printf "%.0f" "$2")
  _color=$(usage_color "$_pct" "$QUOTA_AMBER_PCT" "$QUOTA_RED_PCT")
  _eta=""
  _burn=""

  # Time until the window resets ($3 is epoch seconds). Suppressed, along with
  # the burn figure, when the timestamp is already past - the reading is stale.
  if [ -n "$3" ]; then
    _left=$(( $(printf "%.0f" "$3") - now ))
    if [ "$_left" -gt 0 ]; then
      _eta=" $(duration "$_left")"
      _pts=$(burn_pts "$2" "$3" "$4")

      if [ "$_pts" -ge "$BURN_RED_PTS" ]; then
        _burn_color="$ESC_RED"
      elif [ "$_pts" -ge "$BURN_AMBER_PTS" ]; then
        _burn_color="$ESC_AMBER"
      elif [ "$_pts" -ge "$BURN_GREEN_PTS" ]; then
        _burn_color="$ESC_GREEN"
      else
        _burn_color="$ESC_GREY"
      fi

      # %+d so the sign is carried on both sides of level pace
      _burn=$(printf " %sBurn %+d%%%s" "$_burn_color" "$_pts" "$ESC_RESET")
    fi
  fi

  if [ -n "$5" ]; then
    printf '%s%s: [%s] %d%%%s%s%s' \
      "$_color" "$1" "$(bar "$_pct")" "$_pct" "$_eta" "$ESC_RESET" "$_burn"
  else
    printf '%s%s: %d%%%s%s%s' \
      "$_color" "$1" "$_pct" "$_eta" "$ESC_RESET" "$_burn"
  fi
}

# Context window usage: green < 50%, amber 50-79%, red 80%+. $1 non-empty to
# draw the bar.
ctx_seg_of() {
  [ -n "$used" ] || return 0
  _u=$(printf "%.0f" "$used")
  _c=$(usage_color "$_u" 50 80)
  if [ -n "$1" ]; then
    printf '%sCtx: [%s] %d%%%s' "$_c" "$(bar "$_u")" "$_u" "$ESC_RESET"
  else
    printf '%sCtx: %d%%%s' "$_c" "$_u" "$ESC_RESET"
  fi
}

# Colour by model family; display names are prefixed "Opus 5 (1M context)", "Sonnet 5", ...
# Opus and anything unrecognised keep the original yellow
case "$model" in
  Sonnet*) model_color="$ESC_CYAN" ;;
  Haiku*)  model_color="$ESC_GREEN" ;;
  Fable*)  model_color="$ESC_MAGENTA" ;;
  *)       model_color="$ESC_YELLOW" ;;
esac

# Colour by effort, cool (low) through to hot (max); xhigh keeps the original yellow
case "$effort" in
  low)    effort_color="$ESC_BLUE" ;;
  medium) effort_color="$ESC_CYAN" ;;
  high)   effort_color="$ESC_GREEN" ;;
  max)    effort_color="$ESC_RED" ;;
  *)      effort_color="$ESC_YELLOW" ;;
esac

# Build model segment; brackets and separator take the model colour
model_seg=""
if [ -n "$model" ]; then
  # .effort.level is only present for models that support effort levels
  if [ -n "$effort" ]; then
    model_seg="${model_color}[${model} · ${effort_color}${effort}${model_color}]${ESC_RESET}"
  else
    model_seg="${model_color}[${model}]${ESC_RESET}"
  fi
fi

# Branch / worktree segment, derived from git rather than from the payload: the
# payload's .worktree object only covers Claude-managed worktrees and is absent
# in a main working tree, so it showed nothing almost all of the time.
wt_seg=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  # A single rev-parse answers all four questions, in argument order
  {
    IFS= read -r git_branch
    IFS= read -r git_dir
    IFS= read -r git_common_dir
    IFS= read -r git_top
  } <<EOF
$(git -C "$cwd" rev-parse --abbrev-ref HEAD --git-dir --git-common-dir --show-toplevel 2>/dev/null)
EOF

  if [ -n "$git_branch" ]; then
    # A detached HEAD reports the literal "HEAD"; show the short sha instead
    if [ "$git_branch" = "HEAD" ]; then
      git_branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    fi

    # A linked worktree has its own git dir; prefix with the worktree directory name
    if [ -n "$git_dir" ] && [ "$git_dir" != "$git_common_dir" ]; then
      wt_label="$(basename "$git_top"):${git_branch}"
    else
      wt_label="$git_branch"
    fi

    wt_seg="${ESC_GREY}${wt_label}${ESC_RESET}"
  fi
fi

# Assemble one candidate line: $1 non-empty draws bars, $2 non-empty includes 7d.
# Sections are joined with a dim divider, so a missing one never leaves a stray
# divider or a leading/trailing separator behind.
render() {
  _seven=""
  [ -n "$2" ] && _seven=$(quota_seg "7d" "$rl7_used" "$rl7_reset" "$SEVEN_DAY_SECS" "$1")

  _line=""
  for _seg in \
    "$model_seg" \
    "$(ctx_seg_of "$1")" \
    "$(quota_seg "5h" "$rl5_used" "$rl5_reset" "$FIVE_HOUR_SECS" "$1")" \
    "$_seven" \
    "$wt_seg"
  do
    [ -n "$_seg" ] || continue
    if [ -n "$_line" ]; then
      _line="${_line} ${ESC_GREY}${DIVIDER}${ESC_RESET} ${_seg}"
    else
      _line="$_seg"
    fi
  done

  printf '%s' "$_line"
}

# Display columns of $1, ignoring the colour escapes
visual_width() {
  _plain=$(printf '%s' "$1" | sed "s/${ESC}\[[0-9;]*m//g")
  printf '%d' "${#_plain}"
}

out=$(render 1 1)

# Adapt only when the width is trustworthy and the full line will not fit.
# Under pace there is nothing to watch on the weekly quota, so it goes entirely;
# over pace it is worth keeping, and the bars are given up across the board
# instead - the labels and figures carry the same information in far less space.
if [ -n "$can_measure" ] && [ "$(visual_width "$out")" -gt "$cols" ]; then
  burn7=$(burn_pts "$rl7_used" "$rl7_reset" "$SEVEN_DAY_SECS")
  if [ -n "$burn7" ] && [ "$burn7" -le 0 ]; then
    out=$(render 1 "")
  else
    out=$(render "" 1)
  fi
fi

printf '%s' "$out"
