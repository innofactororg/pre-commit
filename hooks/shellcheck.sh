#!/usr/bin/env bash

set -e

# OSX GUI apps do not pick up environment variables the same way as Terminal apps and there are no easy solutions,
# especially as Apple changes the GUI app behavior every release (see https://stackoverflow.com/q/135688/483528). As a
# workaround to allow GitHub Desktop to work, add this (hopefully harmless) setting here.
export PATH=$PATH:/usr/local/bin

exit_status=0
enable_list=""
exclude_list=""
include_list=""
severity="info"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo 'This check needs shellcheck from https://github.com/koalaman/shellcheck'
  exit 1
fi

parse_arguments() {
	while (($# > 0)); do
		# Grab param and value splitting on " " or "=" with parameter expansion
		local PARAMETER="${1%[ =]*}"
		local VALUE="${1#*[ =]}"
		if [[ "$PARAMETER" == "$VALUE" ]]; then VALUE="$2"; fi
		shift
		case "$PARAMETER" in
		--enable|-o)
			enable_list="$enable_list $VALUE"
			;;
		--exclude|-e)
			exclude_list="$exclude_list $VALUE"
			;;
		--include|-i)
			include_list="$include_list $VALUE"
			;;
		--severity|-S)
			severity="$VALUE"
			;;
		-*)
			echo "Error: Unknown option: $PARAMETER" >&2
			exit 1
			;;
		*)
			files="$files $PARAMETER"
			;;
		esac
	done
	# remove preceeding space
	enable_list="${enable_list## }"
	include_list="${include_list## }"
	exclude_list="${exclude_list## }"
}

parse_arguments "$@"

for FILE in $files; do
	SHEBANG_REGEX='^#!\(/\|/.*/\|/.* \)\(\(ba\|da\|k\|a\)*sh\|bats\)$'
	if (head -1 "$FILE" | grep "$SHEBANG_REGEX" >/dev/null); then
		if ! shellcheck ${enable_list:+ --enable="$enable_list"} ${exclude_list:+ --exclude="$exclude_list"} ${include_list:+ --include="$include_list"} --severity="$severity" "$FILE"; then
			exit_status=1
		fi
	elif [[ "$FILE" =~ .+\.(sh|bash|dash|ksh|ash|bats)$ ]]; then
		echo "$FILE: missing shebang"
		exit_status=1
	fi
done

exit $exit_status
