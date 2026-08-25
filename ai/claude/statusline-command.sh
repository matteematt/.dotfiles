#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# ANSI escape sequences as literal ESC bytes (ANSI-C quoting, portable in sh)
ESC_RESET=$'\033[0m'
ESC_YELLOW=$'\033[33m'
ESC_GREEN=$'\033[32m'
ESC_AMBER=$'\033[33m'
ESC_RED=$'\033[31m'
ESC_BLUE=$'\033[34m'
ESC_CYAN=$'\033[36m'
ESC_MAGENTA=$'\033[35m'

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

# Build context progress bar segment
ctx_seg=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar_width=16
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))

  # Choose color: green (<50%), yellow (50-79%), red (80%+)
  if [ "$used_int" -ge 80 ]; then
    color="$ESC_RED"
  elif [ "$used_int" -ge 50 ]; then
    color="$ESC_AMBER"
  else
    color="$ESC_GREEN"
  fi

  # Build filled and empty portions of the bar
  bar_filled=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar_filled="${bar_filled}█"
    i=$(( i + 1 ))
  done
  bar_empty=""
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar_empty="${bar_empty}░"
    i=$(( i + 1 ))
  done

  ctx_seg=" ${color}[${bar_filled}${bar_empty}] ${used_int}%${ESC_RESET}"
fi

# Combine: model then context bar
printf "%s%s" "$model_seg" "$ctx_seg"
