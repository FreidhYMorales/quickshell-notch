# Lock notch shape: manual visual probe

Run against this checkout in a live Hyprland session with permission to lock it.
Keep the same monitor and notch width for both screenshots.

1. Start `qs -p shell/shell.qml` and capture the desktop's centre notch with
   `grim`. Record the left and right positions of its black outline at the top,
   middle and bottom rows.
2. Ask that Quickshell instance to lock using its `lock` IPC target. Once the
   animation settles, capture the same area with `grim`.
3. Compare the outlines: the locked notch must have the same concave ears and
   rounded lower corners as the desktop notch, with wallpaper visible outside
   the shape. A black rectangle at the lower corners is a failure.
4. Unlock normally; do not terminate the shell while it holds the session lock.
