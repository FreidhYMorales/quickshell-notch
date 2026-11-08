# Notch Lock — SDDM visual prototype

Story #33, phase 1. The theme lives here for visual development and will be
migrated to dotfiles after validation. It is **not** installed or enabled.

## Preview without changing the active login manager

Run from the repository root:

```sh
./scripts/test-sddm.sh
```

The preview uses `sddm-greeter-qt6 --test-mode --theme`. Click or press a
key to open the login form. Press Escape to return to the clock. With focus on
the theme root, Ctrl+Shift+Enter starts a **demo-only** 400 ms shrink animation.
The preview does not authenticate.

For a custom preview background, place a copy at
`sddm/notch/background.jpg` (ignored by git). Until then, the dark fallback
background is used.

## Limitations

- The demo shrink is a rectangular approximation; the wallpaper picker's
  curved ear mask is a separate implementation step.
- The greeter can exit as soon as authentication succeeds; a seamless
  handoff to Hyprland cannot be promised by SDDM alone.
- Actual SDDM user/session model roles and keyboard layout controls need
  local validation before activating this theme.
- Wallpaper and Matugen synchronization are not implemented yet.
- Never replace your active SDDM theme before a greeter preview and a
  recovery path have been tested.
