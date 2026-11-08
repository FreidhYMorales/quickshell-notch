#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    exec sddm-greeter-qt6 --test-mode --theme "$repo_dir/sddm/notch"
fi
printf '%s\n' 'Missing sddm-greeter-qt6. Install the Qt 6 SDDM greeter to preview the theme.' >&2
exit 1
