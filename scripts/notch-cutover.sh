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

die() {
    echo "notch-cutover: $*" >&2
    exit 1
}

preflight_notch() {
    [[ -f "$NOTCH_CONFIG_DIR/shell.qml" ]] ||
        die "notch config not found at $NOTCH_CONFIG_DIR/shell.qml (run the dotfiles deploy first)"
}

case "${1:-}" in
cutover)
    preflight_notch
    ;;
rollback)
    ;;
*)
    die "usage: notch-cutover.sh cutover|rollback"
    ;;
esac
