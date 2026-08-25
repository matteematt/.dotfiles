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
  IFS= read -r rl_used
  IFS= read -r rl_reset
} <<EOF
$(echo "$input" | jq -r '[
  .model.display_name,
  .effort.level,
  .context_window.used_percentage,
  .workspace.current_dir,
  .rate_limits.five_hour.used_percentage,
  .rate_limits.five_hour.resets_at
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
# The two meters run on different scales, hence the explicit thresholds.
usage_color() {
  if [ "$1" -ge "$3" ]; then
    printf '%s' "$ESC_RED"
  elif [ "$1" -ge "$2" ]; then
    printf '%s' "$ESC_AMBER"
  else
    printf '%s' "$ESC_GREEN"
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

# Context window usage: green < 50%, amber 50-79%, red 80%+
ctx_seg=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  ctx_color=$(usage_color "$used_int" 50 80)
  ctx_seg="${ctx_color}Ctx: [$(bar "$used_int")] ${used_int}%${ESC_RESET}"
fi

# 5-hour rate limit: green < 80%, amber 80-99%, red at 100%
rl_seg=""
if [ -n "$rl_used" ]; then
  rl_int=$(printf "%.0f" "$rl_used")
  rl_color=$(usage_color "$rl_int" 80 100)

  # Time until the window resets (.resets_at is epoch seconds). Suppressed only
  # when the timestamp is already in the past, i.e. the reading is stale.
  rl_eta=""
  if [ -n "$rl_reset" ]; then
    reset_int=$(printf "%.0f" "$rl_reset")
    mins_left=$(( (reset_int - $(date +%s) + 59) / 60 ))
    if [ "$mins_left" -gt 0 ]; then
      if [ "$mins_left" -ge 60 ]; then
        rl_eta=$(printf " %dh%02dm" "$(( mins_left / 60 ))" "$(( mins_left % 60 ))")
      else
        rl_eta=" ${mins_left}m"
      fi
    fi
  fi

  rl_seg="${rl_color}5h: [$(bar "$rl_int")] ${rl_int}%${rl_eta}${ESC_RESET}"
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

# Join whichever sections exist with a dim divider, so a missing one never
# leaves a stray divider or a leading/trailing separator behind
out=""
for seg in "$model_seg" "$ctx_seg" "$rl_seg" "$wt_seg"; do
  [ -n "$seg" ] || continue
  if [ -n "$out" ]; then
    out="${out} ${ESC_GREY}${DIVIDER}${ESC_RESET} ${seg}"
  else
    out="$seg"
  fi
done

printf '%s' "$out"
