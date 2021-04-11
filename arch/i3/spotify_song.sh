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
      *'string "PlaybackStatus"') [[ "${data[i+1]}" =~ "Playing" ]] \
        && playing=1 || exit 0;;
      *'string "xesam:artist"') artist="${data[i+2]}";;
      *'string "xesam:album"') album="${data[i+1]}";;
      *'string "xesam:title"') title="${data[i+1]}";;
      *) continue ;;
    esac
  done

  # Show artist if available, but use album name if not
  # This is used for podcasts where the podcast name is the album name
  if [[ "$artist" =~ '""' ]]; then
    from=${album#*\"}
    from=${from%\"*}
  else
    from=${artist#*\"}
    from=${from%\"*}
  fi

  title=${title#*\"}
  title=${title%\"*}
  # full text, short text (colour and bg colour omitted)
  echo "♫ $title/$from"
  echo "$title"
fi
