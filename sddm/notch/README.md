# Notch Lock — SDDM visual prototype

Story #33, phase 1. The theme lives here for visual development and will be
migrated to dotfiles after validation. It is installed as
`/usr/share/sddm/themes/notch-lock` and active through
`/etc/sddm.conf.d/zz-notch-lock.conf`; the previous `silent` theme remains
configured as fallback.

## Preview without changing the active login manager

Run from the repository root:

```sh
./scripts/test-sddm.sh
```

To preview the last shared wallpaper and matugen palette staged by the notch,
without changing the installed greeter, run:

```sh
./scripts/test-sddm.sh --synced
```

Apply a shared wallpaper or choose a theme first so the staged configuration
exists. The synced preview uses the original video or a GIF converted to video;
its colours are generated from the video's midpoint frame. It runs as your user,
so it does not verify that the SDDM system account can access those files.

The preview uses `sddm-greeter-qt6 --test-mode --theme`. Click or press a
key to open the login form. Press Escape to return to the clock.

`--test-mode` has no daemon, so `sddm.login()` can never answer. When you submit
a password, the theme compresses into the notch (520 ms, same easing as the
shell lock), holds the notch frame for 1.1 s and expands back to the form; no
authentication is attempted. Ctrl+Shift+Enter plays the same compression and
smooth return from the clock view.

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
- Staging follows the shared wallpaper and matugen palette, but deployment to
  a location readable by the SDDM system account is not implemented yet.
- Never replace your active SDDM theme before a greeter preview and a
  recovery path have been tested.
