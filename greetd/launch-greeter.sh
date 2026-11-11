#!/bin/sh
# Start the notch greeter inside cage. greetd runs this as the `greeter` user
# after opening a logind session for it, so the seat, DRM node and input
# devices come from logind; no extra groups or seatd are needed.
#
# Environment:
#   NOTCH_GREETD_VISUAL_DIR  published wallpaper/palette directory
#   NOTCH_GREETD_SCALE       Qt scale for the greeter; must match the monitor
#                            scale in the Hyprland config (cage reports 1).
set -eu

: "${NOTCH_GREETD_VISUAL_DIR:=/var/lib/quickshell-notch-greetd}"
export NOTCH_GREETD_VISUAL_DIR

: "${NOTCH_GREETD_SCALE:=2}"
export QT_SCALE_FACTOR="$NOTCH_GREETD_SCALE"

# Session greetd starts after authentication: the same entry SDDM launches.
: "${NOTCH_GREETD_SESSION:=uwsm start -e -D Hyprland hyprland.desktop}"
export NOTCH_GREETD_SESSION

# pam_systemd normally provides this; fall back to a private directory.
if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "${XDG_RUNTIME_DIR:-}" ]; then
	XDG_RUNTIME_DIR=$(mktemp -d "${TMPDIR:-/tmp}/notch-greeter.XXXXXX")
	chmod 700 "$XDG_RUNTIME_DIR"
	export XDG_RUNTIME_DIR
fi
if [ -z "${HOME:-}" ] || [ ! -d "${HOME:-}" ]; then
	HOME=$XDG_RUNTIME_DIR
	export HOME
fi

here=$(unset CDPATH && cd -- "$(dirname -- "$0")" && pwd)
# -s allows VT switching (escape hatch); -d suppresses cage's own title bar and
# close button around the greeter surface.
exec /usr/bin/cage -s -d -- /usr/bin/qs -p "$here/../greetd-shell.qml"
