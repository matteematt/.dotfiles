#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ANSI escape sequences as literal ESC bytes (ANSI-C quoting, portable in sh)
ESC_RESET=$'\033[0m'
ESC_YELLOW=$'\033[33m'
ESC_GREEN=$'\033[32m'
ESC_AMBER=$'\033[33m'
ESC_RED=$'\033[31m'

# Build model segment
model_seg=""
if [ -n "$model" ]; then
  model_seg="[${model}]"
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
printf "%s%s%s%s" "$ESC_YELLOW" "$model_seg" "$ESC_RESET" "$ctx_seg"
