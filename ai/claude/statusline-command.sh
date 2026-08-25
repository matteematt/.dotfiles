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

# ANSI escape sequences as literal ESC bytes (ANSI-C quoting, portable in sh)
ESC_RESET=$'\033[0m'
ESC_YELLOW=$'\033[33m'
ESC_GREEN=$'\033[32m'
ESC_AMBER=$'\033[33m'
ESC_RED=$'\033[31m'
ESC_BLUE=$'\033[34m'
ESC_CYAN=$'\033[36m'
ESC_MAGENTA=$'\033[35m'
ESC_GREY=$'\033[90m'

BAR_WIDTH=16
DIVIDER="│"

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

# One quota meter: $1 label, $2 usage %, $3 reset timestamp, $4 window seconds.
# Prints the bar and percentage on the absolute scale, then time to reset and
# the burn figure, each in its own colour. Silent when there is no usage figure.
quota_seg() {
  [ -n "$2" ] || return 0

  _pct=$(printf "%.0f" "$2")
  _color=$(usage_color "$_pct" "$QUOTA_AMBER_PCT" "$QUOTA_RED_PCT")
  _eta=""
  _burn=""

  # Time until the window resets ($3 is epoch seconds). Suppressed, along with
  # the burn figure, when the timestamp is already past - the reading is stale.
  if [ -n "$3" ]; then
    _left=$(( $(printf "%.0f" "$3") - $(date +%s) ))
    if [ "$_left" -gt 0 ]; then
      _eta=" $(duration "$_left")"

      # The window is assumed to have opened $4 seconds before it resets, so
      # elapsed% is how far through it we are
      _elapsed=$(( ($4 - _left) * 100 / $4 ))
      [ "$_elapsed" -lt 0 ] && _elapsed=0
      _pts=$(( _pct - _elapsed ))

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

  printf '%s%s: [%s] %d%%%s%s%s' \
    "$_color" "$1" "$(bar "$_pct")" "$_pct" "$_eta" "$ESC_RESET" "$_burn"
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

# Context window usage: green < 50%, amber 50-79%, red 80%+
ctx_seg=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  ctx_color=$(usage_color "$used_int" 50 80)
  ctx_seg="${ctx_color}Ctx: [$(bar "$used_int")] ${used_int}%${ESC_RESET}"
fi

rl5_seg=$(quota_seg "5h" "$rl5_used" "$rl5_reset" "$FIVE_HOUR_SECS")
rl7_seg=$(quota_seg "7d" "$rl7_used" "$rl7_reset" "$SEVEN_DAY_SECS")

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

# Join whichever sections exist with a dim divider, so a missing one never
# leaves a stray divider or a leading/trailing separator behind
out=""
for seg in "$model_seg" "$ctx_seg" "$rl5_seg" "$rl7_seg" "$wt_seg"; do
  [ -n "$seg" ] || continue
  if [ -n "$out" ]; then
    out="${out} ${ESC_GREY}${DIVIDER}${ESC_RESET} ${seg}"
  else
    out="$seg"
  fi
done

printf '%s' "$out"
