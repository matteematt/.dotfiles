#!/bin/bash

if [[ $# == 0 ]]; then
	# Checking that hlint is executable and config file is accessible
	hash hlint 1> /dev/null || exit 1
else
	# Run the linter with the filename being $1 and format for quickfix window using awk
	# Matching lines format (in order)
	# Main.hs:114:94: Suggestion: Redundant $
	# Main.hs:102:48-50: Warning: Redundant bracket
	# Main.hs:(91,30)-(92,59): Suggestion: Replace case with maybe
	hlint "$1" | awk '{
	if (match($0,/^(.+\.hs):(\w+):(\w+):\s(.+)/,m))
		print sprintf("%s:%s:%s: %s", m[1], m[2], m[3], m[4])
	else if (match($0,/^(.+\.hs):(\w+):(\w+)-\w+:\s(.+)/,m))
		print sprintf("%s:%s:%s: %s", m[1], m[2], m[3], m[4])
	else if (match($0,/^(.+\.hs):\((\w+),(\w+)\)-\((\w+),\w+\):\s(.+)/,m))
		print sprintf("%s:%s:%s: (%s lines) %s", m[1], m[2], m[3], (m[4]-m[2]+1), m[5])
	}'
fi
