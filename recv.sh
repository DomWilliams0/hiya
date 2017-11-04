#!/usr/bin/bash

# load common options
source hiya.sh

HOST="0.0.0.0"
CLIENT_IP=""

FIFO=/tmp/hiya-$(whoami)-fifo

parse_client_ip() {
	CLIENT_IP=$(echo $1 | sed -n 's/.*Connection from \([^\n]\+\):.*/\1/p')
}

listen() {
	echo Listening on $HOST:$PORT

	rm -f $FIFO
	mkfifo $FIFO
	exec 3<>$FIFO

	while true; do
		# flush fifo
		dd if=$FIFO of=/dev/null iflag=nonblock >/dev/null 2>&1

		set -e
		err=$(ncat -v -l $HOST $PORT 2>&1 1>&3)
		set +e

		parse_client_ip "$err"

		read -r version <&3
		read -r msg_type <&3

		if [[ $version != $VERSION ]]; then
			echo "message version $version doesn't match our version $VERSION"
			continue
		fi
		if [[ $msg_type != "MSG" ]]; then
			echo "unrecognised message type '$msg_type'"
			continue
		fi

		read -r msg <&3

		# TODO resolve ip -> name if in profiles
		notify-send "Message from $CLIENT_IP" "$(echo $msg | base64 -d | gunzip -c)"

	done

	exec 3>&-
}

trap "rm -f $FIFO" EXIT
listen
