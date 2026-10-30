#!/usr/bin/env bash
# Dev only: a plain white wallpaper on every monitor so the black notch shapes
# stand out during manual checks. Needs a running hyprpaper (0.8+).
# Usage: tests/manual/dev-bg.sh white|restore
#   white    saves the current wallpapers, then sets white everywhere
#   restore  puts the saved wallpapers back
set -euo pipefail

dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-notch"
saved="$dir/dev-bg.saved"
white="$dir/white.png"

set_wallpaper() {
	hyprctl hyprpaper wallpaper "$1,$2" >/dev/null
}

case "${1:-}" in
white)
	mkdir -p "$dir"
	[[ -f "$white" ]] || magick -size 16x16 xc:white "$white"
	active=$(hyprctl hyprpaper listactive)
	# Keep the first save: running `white` twice must not save white itself.
	if [[ ! -f "$saved" ]]; then
		printf '%s\n' "$active" >"$saved"
	fi
	while IFS= read -r line; do
		[[ -n "$line" ]] && set_wallpaper "${line%%: *}" "$white"
	done <<<"$active"
	echo "white background on; restore with: $0 restore"
	;;
restore)
	if [[ ! -f "$saved" ]]; then
		echo "nothing saved; run '$0 white' first" >&2
		exit 1
	fi
	while IFS= read -r line; do
		[[ -n "$line" ]] && set_wallpaper "${line%%: *}" "${line#*: }"
	done <"$saved"
	rm -f "$saved"
	echo "wallpapers restored"
	;;
*)
	echo "usage: $0 white|restore" >&2
	exit 1
	;;
esac
