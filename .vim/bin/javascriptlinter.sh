#!/bin/bash

config_file=".eslintrc"
file_extensions=("" ".js" ".json")

function configPath() {
	local config_file_path=$(realpath "$(pwd)/$1/$config_file")
	for ext in "${file_extensions[@]}"; do
		[[ -f "$config_file_path$ext" ]] && echo "$config_file_path$ext" && return 0
	done
	[[ "$config_file_path" == "/.eslintrc" ]] && return 1
	configPath "$1/.."
}

# Get the config file path (and bail on failure)
config_file_path=$(configPath "") || exit 1

case $# in
	0)
		# Checking that eslint is executable
		hash eslint 1> /dev/null || exit 1
		;;
	1)
		# Run the linter in error reporting mode, filename is $1
		eslint --format unix -c "$config_file_path" "$1"
		;;
	2)
		# Run linter in fix mode, filename is $2
		eslint --fix -c "$config_file_path"  "$2"
		;;
esac
