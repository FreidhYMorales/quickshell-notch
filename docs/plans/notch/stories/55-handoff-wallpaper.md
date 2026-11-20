# Story 55: Current wallpaper in the greeter-to-shell gap

## Story

55. As a user, I want the gap between the SDDM greeter and the notch shell to show my current wallpaper so that the login handoff does not flash the stale default image. Requires: #54

## Acceptance criteria

- [x] Given I saved a still image as my wallpaper in the shell, when I log in through SDDM on the next boot, then the gap between the greeter and the notch shows that image, not the hyprpaper default.
- [ ] Given I saved a GIF or video as my wallpaper, when I log in through SDDM, then the gap shows a frame of that wallpaper, not the hyprpaper default.
- [ ] Given the shell has never saved a wallpaper (no generated startup configuration), when I log in, then the session still starts and shows the original hyprpaper wallpaper.

## Plan

- The behaviour is already built and merged (story 43 L6): wallpaper saves write a hyprpaper startup configuration, GIF and video use a cached first frame, and the dotfiles autostart picks that configuration when it exists. This story closes the gap between the code and a real login.
- Confirm the generated configuration and the dotfiles autostart match the current wallpaper before each check.
- Verify each criterion on a real SDDM login, reading the gap visually and the session journal for the hyprpaper start.
- Fix only what the real login shows to be wrong, test first for anything the existing hyprpaper sync tests can pin.

## Out of scope

- Multi-monitor behaviour, including per-screen wallpapers (#42).
- Keeping the notch visible during Hyprland's startup, or shortening the gap itself.
- Animated playback in the gap: one still frame is enough.
- The greeter's own background and morph (#54).

## Suggestions (your call)

- Criterion 3 can be exercised by moving `hyprpaper.conf` aside for one login and putting it back afterwards, instead of wiping the shell state.
- `hyprpaper-frames/` already holds three cached frames; the GIF check can reuse the screensaver GIF that is already set up.

## Size

normal
Risk: item 5 (session autostart of hyprpaper in the dotfiles), item 6 (only a real login shows the gap)

## Log

- L1 request (user): "/flow:story 55"
- L2 state (2026-11-19): `wallpaper.txt` and the generated `hyprpaper.conf` both point to `arch.png` (21:49); the running hyprpaper was started with `-c` on that file by `~/.config/hypr/deadlock/execs.lua`. The 22:01 SDDM login likely already used it, but nobody looked at the gap. Origin: split from #43 (L6, L8).
- L3 manual C1 (2026-11-19): saved the still `black-cat-…-6597.jpg` at 22:22:13; `hyprpaper.conf` regenerated to that path. SDDM logout/login: greeter stopped 22:22:47 (`HELPER_SUCCESS`), hyprpaper started the same second with `-c ~/.local/state/quickshell-notch/hyprpaper.conf`. The user saw the black cat in the gap, not `arch.png` (the hyprpaper default).
