#!/bin/bash

args=(--print-reply \
  --session \
  --dest=org.mpris.MediaPlayer2.spotify \
  /org/mpris/MediaPlayer2 \
  org.freedesktop.DBus.Properties.Get \
  string:'org.mpris.MediaPlayer2.Player')

artist_loc=27
song_loc=40

if [[ $(eval "dbus-send ${args[@]} string:'PlaybackStatus' 2> /dev/null") =~ "Playing" ]];then
  readarray metadata < <(eval "dbus-send ${args[@]} string:'Metadata'")
  artist=${metadata[$artist_loc]#*\"}
  artist=${artist%\"*}

  song=${metadata[$song_loc]#*\"}
  song=${song%\"*}

  # full text, short text (colour and bg colour omitted)
  echo "♫ $song/$artist"
  echo "$song"
fi

