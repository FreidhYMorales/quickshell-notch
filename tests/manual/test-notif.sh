#!/usr/bin/env bash
# Manual check for the centre notch notification toast (story 01).
# Run the notch shell first (`qs -p shell/shell.qml`, old shell stopped).
# Usage: tests/manual/test-notif.sh <case>
#   normal   one toast that hides after its timeout
#   actions  hover shows Open / Later; the clicked action is printed here
#   replace  one toast whose text changes in place after 2s (same id)
#   close    the app closes its own toast after 2s
#   burst    5 in a row: the first stays, then newest first, with +N
set -euo pipefail

case "${1:-}" in
normal)
	notify-send -a "Firefox" -i firefox "Tab loaded" "rust-lang.org finished loading."
	;;
actions)
	notify-send -a "Discord" -i discord -A default=Open -A open=Open -A later=Later \
		"Juan" "Are we playing tonight?"
	;;
replace)
	id=$(notify-send -p -a "Downloads" "Downloading" "10%")
	sleep 2
	notify-send -r "$id" -a "Downloads" "Downloading" "90%"
	;;
close)
	id=$(notify-send -p -a "Timer" "Closing soon" "The app closes this in 2s.")
	sleep 2
	gdbus call --session --dest org.freedesktop.Notifications \
		--object-path /org/freedesktop/Notifications \
		--method org.freedesktop.Notifications.CloseNotification "$id" >/dev/null
	;;
burst)
	for i in 1 2 3 4 5; do
		notify-send -a "Burst" "Notification $i" "Burst test, $i of 5."
	done
	;;
*)
	echo "usage: $0 normal|actions|replace|close|burst" >&2
	exit 1
	;;
esac
