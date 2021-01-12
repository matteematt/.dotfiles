#!/bin/bash

args=(--print-reply \
  --session \
  --dest=org.mpris.MediaPlayer2.spotify \
  /org/mpris/MediaPlayer2 \
  org.freedesktop.DBus.Properties.GetAll \
  string:'org.mpris.MediaPlayer2.Player')

readarray -t data < <(dbus-send "${args[@]}" 2> /dev/null)

if [[ ${#data[@]} -ne 0 ]];then
  for i in "${!data[@]}"; do
    case "${data[i]}" in
      *'string "xesam:artist"') artist="${data[i+2]}";;
      *'string "xesam:title"') title="${data[i+1]}";;
      *'string "PlaybackStatus"') [[ "${data[i+1]}" =~ "Playing" ]] \
        && playing=1 || exit 0;;
      *) continue ;;
    esac
    if [[ -n $artist ]] && [[ -n $title ]] && [[ -n $playing ]];then
      break
    fi
  done
  artist=${artist#*\"}
  artist=${artist%\"*}

  title=${title#*\"}
  title=${title%\"*}
  # full text, short text (colour and bg colour omitted)
  echo "♫ $title/$artist"
  echo "$title"
fi
