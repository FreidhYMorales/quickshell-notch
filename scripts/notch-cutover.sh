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
RUN_DIR=""

KEYBINDS="$HYPR_DIR/deadlock/keybinds.lua"
EXECS="$HYPR_DIR/deadlock/execs.lua"

cleanup() {
    if [[ -n "$RUN_DIR" ]]; then
        rm -rf "$RUN_DIR"
    fi
}
trap cleanup EXIT

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

# Snapshot the files for this run. A cutover that fails must restore this
# snapshot, and only a verified run may promote it to the permanent backup: a
# drifted file saved as "the originals" would poison a later rollback.
snapshot() {
    cp -p "$KEYBINDS" "$RUN_DIR/keybinds.lua"
    cp -p "$EXECS" "$RUN_DIR/execs.lua"
}

keep_backup() {
    mkdir -p "$STATE_DIR"
    [[ -e "$STATE_DIR/keybinds.lua" ]] || cp -p "$RUN_DIR/keybinds.lua" "$STATE_DIR/keybinds.lua"
    [[ -e "$STATE_DIR/execs.lua" ]] || cp -p "$RUN_DIR/execs.lua" "$STATE_DIR/execs.lua"
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

restore_originals() {
    local src="$1"
    if [[ -e "$src/keybinds.lua" ]]; then
        cp -p "$src/keybinds.lua" "$KEYBINDS"
    fi
    if [[ -e "$src/execs.lua" ]]; then
        cp -p "$src/execs.lua" "$EXECS"
    fi
}

restore_old() {
    restore_originals "$STATE_DIR"
    rm -f "$STATE_DIR/keybinds.lua" "$STATE_DIR/execs.lua"
}

# perl -pi exits 0 when nothing matches, so a drift in the dotfiles would
# "succeed" with the old commands still in place and every keybind dead. Check
# the result and put the originals back instead.
keybinds_remapped() {
    grep -q 'qsIpc .. " controlcenter open"' "$KEYBINDS" &&
        grep -q 'qsIpc .. " controlcenter notifications"' "$KEYBINDS" &&
        grep -q 'qsIpc .. " expanded toggle"' "$KEYBINDS" &&
        grep -q 'qsIpc .. " power open"' "$KEYBINDS" &&
        grep -q '"qs -c notch ipc call lock lock"' "$KEYBINDS" &&
        ! grep -qE 'dashboard toggle|notifications toggle|calendar toggle|powermenu toggle|qs ipc call' "$KEYBINDS"
}

verify_rewrite() {
    grep -q 'local quickshell = "qs -c notch"' "$EXECS" || {
        restore_originals "$RUN_DIR"
        die "autostart not remapped in $EXECS (unexpected content; originals restored)"
    }
    if ! keybinds_remapped; then
        restore_originals "$RUN_DIR"
        die "keybinds not remapped in $KEYBINDS (unexpected content; originals restored)"
    fi
}

case "${1:-}" in
cutover)
    preflight_notch
    stop_shells
    RUN_DIR="$(mktemp -d)"
    snapshot
    rewrite_notch
    verify_rewrite
    keep_backup
    rm -rf "$RUN_DIR"
    RUN_DIR=""
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
