#!/bin/sh
set -eu
repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    printf '%s\n' 'Missing sddm-greeter-qt6. Install the Qt 6 SDDM greeter to preview the theme.' >&2
    exit 1
fi

case "${1:-}" in
    '') exec sddm-greeter-qt6 --test-mode --theme "$repo_dir/sddm/notch" ;;
    --synced)
        state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
        data_dir=${NOTCH_SDDM_DATA_DIR:-}
        target="$state_home/quickshell-notch/sddm-target.txt"
        if [ -z "$data_dir" ] && [ -r "$target" ]; then
            IFS= read -r data_dir < "$target" || :
            case "$data_dir" in /*) ;; *) data_dir= ;; esac
        fi
        config="${data_dir:-$state_home/quickshell-notch/sddm}/theme.conf.user"
        if [ ! -f "$config" ]; then
            printf '%s\n' 'No synced SDDM configuration yet; apply a shared wallpaper or theme first.' >&2
            exit 1
        fi
        preview_dir=$(mktemp -d "${TMPDIR:-/tmp}/notch-sddm-preview.XXXXXXXX")
        trap 'rm -rf -- "$preview_dir"' EXIT HUP INT TERM
        cp -R "$repo_dir/sddm/notch/." "$preview_dir/"
        cp "$config" "$preview_dir/theme.conf.user"
        sddm-greeter-qt6 --test-mode --theme "$preview_dir"
        ;;
    *) printf '%s\n' 'Usage: test-sddm.sh [--synced]' >&2; exit 2 ;;
esac
