#!/usr/bin/env bash
# Swap the running Quickshell between the old bar and the notch shell, and
# remap the Hyprland keybinds to whichever one should be live.
#
# Usage: notch-cutover.sh cutover|rollback
#
# Every path can be overridden for tests:
#   HYPR_DIR          Hyprland config (default ~/.config/hypr)
#   NOTCH_CONFIG_DIR  deployed notch config (default ~/.config/quickshell/notch)
#   STATE_DIR         backups (default ~/.local/state/quickshell-notch/cutover)
#   QS                quickshell binary (default qs)

set -euo pipefail

HYPR_DIR="${HYPR_DIR:-$HOME/.config/hypr}"
NOTCH_CONFIG_DIR="${NOTCH_CONFIG_DIR:-$HOME/.config/quickshell/notch}"
STATE_DIR="${STATE_DIR:-$HOME/.local/state/quickshell-notch/cutover}"
QS="${QS:-qs}"

KEYBINDS="$HYPR_DIR/deadlock/keybinds.lua"
EXECS="$HYPR_DIR/deadlock/execs.lua"

die() {
    echo "notch-cutover: $*" >&2
    exit 1
}

preflight_notch() {
    [[ -f "$NOTCH_CONFIG_DIR/shell.qml" ]] ||
        die "notch config not found at $NOTCH_CONFIG_DIR/shell.qml (run the dotfiles deploy first)"
    [[ -f "$KEYBINDS" ]] || die "keybinds not found at $KEYBINDS"
    [[ -f "$EXECS" ]] || die "autostart not found at $EXECS"
}

# The first cutover keeps the originals; a second run must not overwrite them
# with already-rewritten files.
backup() {
    mkdir -p "$STATE_DIR"
    [[ -e "$STATE_DIR/keybinds.lua" ]] || cp -p "$KEYBINDS" "$STATE_DIR/keybinds.lua"
    [[ -e "$STATE_DIR/execs.lua" ]] || cp -p "$EXECS" "$STATE_DIR/execs.lua"
}

rewrite_notch() {
    perl -pi -e 's/\Qlocal quickshell = "quickshell"\E/local quickshell = "qs -c notch"/' "$EXECS"
    perl -pi -e 's/\Qlocal qsIpc = "qs ipc call"\E/local qsIpc = "qs -c notch ipc call"/' "$KEYBINDS"
    perl -pi -e 's/\QqsIpc .. " dashboard toggle"\E/qsIpc .. " controlcenter open"/' "$KEYBINDS"
    perl -pi -e 's/\QqsIpc .. " notifications toggle"\E/qsIpc .. " controlcenter notifications"/' "$KEYBINDS"
    perl -pi -e 's/\QqsIpc .. " calendar toggle"\E/qsIpc .. " expanded toggle"/' "$KEYBINDS"
    perl -pi -e 's/\QqsIpc .. " powermenu toggle"\E/qsIpc .. " power open"/' "$KEYBINDS"
    perl -pi -e 's/\Q"qs ipc call lock lock"\E/"qs -c notch ipc call lock lock"/' "$KEYBINDS"
    perl -pi -e 's/\Qdescrip("Toggle Dashboard")\E/descrip("Open Control Center")/' "$KEYBINDS"
    perl -pi -e 's/\Qdescrip("Toggle Notifications")\E/descrip("Open Notifications")/' "$KEYBINDS"
    perl -pi -e 's/\Qdescrip("Toggle Calendar")\E/descrip("Toggle Expanded Notch")/' "$KEYBINDS"
    perl -pi -e 's/\Qdescrip("Toggle Power Menu")\E/descrip("Open Power Menu")/' "$KEYBINDS"
}

# Never leave the old bar and the notch running together: they fight over the
# notification D-Bus name, the polkit agent and idle locking.
stop_shells() {
    "$QS" kill >/dev/null 2>&1 || true
    sleep 0.5
}

restore_old() {
    if [[ -e "$STATE_DIR/keybinds.lua" ]]; then
        cp -p "$STATE_DIR/keybinds.lua" "$KEYBINDS"
    fi
    if [[ -e "$STATE_DIR/execs.lua" ]]; then
        cp -p "$STATE_DIR/execs.lua" "$EXECS"
    fi
    rm -f "$STATE_DIR/keybinds.lua" "$STATE_DIR/execs.lua"
}

case "${1:-}" in
cutover)
    preflight_notch
    stop_shells
    backup
    rewrite_notch
    "$QS" -c notch -d
    ;;
rollback)
    if [[ ! -e "$STATE_DIR/keybinds.lua" ]] && [[ ! -e "$STATE_DIR/execs.lua" ]]; then
        echo "notch-cutover: nothing to roll back"
        exit 0
    fi
    stop_shells
    restore_old
    "$QS" -d
    ;;
*)
    die "usage: notch-cutover.sh cutover|rollback"
    ;;
esac
