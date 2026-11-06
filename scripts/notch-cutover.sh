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
#   WAIT_STEPS        instance checks before giving up (default 50)
#   WAIT_INTERVAL     seconds between checks (default 0.2)

set -euo pipefail

HYPR_DIR="${HYPR_DIR:-$HOME/.config/hypr}"
NOTCH_CONFIG_DIR="${NOTCH_CONFIG_DIR:-$HOME/.config/quickshell/notch}"
STATE_DIR="${STATE_DIR:-$HOME/.local/state/quickshell-notch/cutover}"
QS="${QS:-qs}"
WAIT_STEPS="${WAIT_STEPS:-50}"
WAIT_INTERVAL="${WAIT_INTERVAL:-0.2}"

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
# notification D-Bus name, the polkit agent and idle locking. `qs kill` alone
# only picks one instance of the config it resolves, so a bar launched before
# the dotfiles move (another config path) or a dev `qs -p` would survive it.
# Kill every live instance by pid instead.
running_pids() {
    "$QS" list --all 2>/dev/null | awk '/Process ID:/ { print $3 }' || true
}

instance_count() {
    running_pids | wc -l
}

# The new shell registers a moment after it is launched and a killed one takes
# a moment to disappear, so poll instead of sleeping a fixed time.
wait_for_count() {
    local want="$1" step
    for ((step = 0; step < WAIT_STEPS; step++)); do
        [[ "$(instance_count)" -eq "$want" ]] && return 0
        sleep "$WAIT_INTERVAL"
    done
    return 1
}

stop_shells() {
    local pid
    for pid in $(running_pids); do
        "$QS" kill --pid "$pid" >/dev/null 2>&1 || true
    done
    wait_for_count 0 ||
        die "another Quickshell instance is still running: $(running_pids | tr '\n' ' ')"
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
    wait_for_count 1 ||
        die "expected one Quickshell instance after the cutover, found $(instance_count): $(running_pids | tr '\n' ' ')"
    ;;
rollback)
    if [[ ! -e "$STATE_DIR/keybinds.lua" ]] && [[ ! -e "$STATE_DIR/execs.lua" ]]; then
        echo "notch-cutover: nothing to roll back"
        exit 0
    fi
    stop_shells
    restore_old
    "$QS" -d
    wait_for_count 1 ||
        die "expected one Quickshell instance after the rollback, found $(instance_count): $(running_pids | tr '\n' ' ')"
    ;;
*)
    die "usage: notch-cutover.sh cutover|rollback"
    ;;
esac
