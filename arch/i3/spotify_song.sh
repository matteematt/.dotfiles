#!/bin/bash

metadata=$(dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata') || exit 0

if [[ "$(dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus')" =~ "Playing" ]];then
  song=$(grep xesam:title -A 1 <<< "$metadata" | tail -n 1)
  song=${song#*\"}
  song=${song%\"*}

  artist=$(grep xesam:artist -A 2 <<< "$metadata" | tail -n 1)
  artist=${artist#*\"}
  artist=${artist%\"*}

  # full text, short text (colour and bg colour omitted)
  echo "♫ $song/$artist"
  echo "$song"
fi

