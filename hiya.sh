#!/usr/bin/bash

ARG_COUNT=$#
RECIPIENT="$1"

# config dir
if [ -z "$XDG_CONFIG_HOME" ]; then
	CONFIG_DIR=$HOME/.hiya
else
	CONFIG_DIR=$XDG_CONFIG_HOME/hiya
fi
PROFILE_DIR=$CONFIG_DIR/profiles

# constants
VERSION="0.1"
PORT=54810

# profile
# overriden by profile, if it exists
HOSTNAME=$RECIPIENT
GPG_KEY=""
ALLOW_FILES="0"
MAX_FILE_SIZE="100M"

check_args() {
	if [[ $ARG_COUNT != 1 ]]; then
		echo "usage: $0 [recipient]"
		exit 1
	fi
	# TODO parse more params
}

mk_dirs() {
	mkdir -p $PROFILE_DIR
}

load_profile() {
	mk_dirs
	profile=$PROFILE_DIR/$RECIPIENT
	if [ -f $profile ]; then
		echo "found profile for $RECIPIENT"
		source $profile
	fi

	echo hostname = $HOSTNAME
	echo gpg_key = $GPG_KEY
	echo allow_files = $ALLOW_FILES
	echo max_file_size = $MAX_FILE_SIZE
}

send_message() {
	# TODO gpg
	set -e
	{
		echo "$VERSION"
		echo "MSG"
		gzip -c | base64
	} | ncat --send-only $HOSTNAME $PORT
	set +e
	echo Message sent
}

# -----

if [[ $0 == *"hiya"* ]]; then
	check_args
	load_profile
	send_message
fi
