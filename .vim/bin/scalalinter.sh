#!/bin/bash

config_file="$HOME/.dotfiles/config/linting/scalastyle_config.xml"

if [[ $# == 0 ]]; then
	# Checking that scalastyle is executable and config file is accessible
	hash scalastyle 1> /dev/null || exit 1
	ls "$config_file" 1> /dev/null || exit 1
else
	# Run the linter with the filename being $1 and format for quickfix window using awk
	scalastyle -c "$config_file" "$1" | awk '{
		if (match($0,/(?:error|warning)\sfile=(.+)\smessage=(.+)\s+line=(.+)\scolumn=(.+)/,m))
			print sprintf("%s:%s:%s: %s - %s", m[2], m[4], m[5], m[1], m[3])
		else if (match($0,/(?:error|warning)\sfile=(.+)\smessage=(.+)\s+line=(.+)/,m))
			print sprintf("%s:%s:0: %s - %s", m[2], m[4], m[1], m[3])
		}'
fi
