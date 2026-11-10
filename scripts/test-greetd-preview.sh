#!/bin/sh
# Visual simulation only: does not start greetd, PAM or a user session.
set -eu
repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
exec node "$repo_dir/scripts/test-greetd-preview.mjs" "$@"
