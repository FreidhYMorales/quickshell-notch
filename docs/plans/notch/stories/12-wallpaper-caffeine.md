# Story 12: Wallpaper and caffeine

## Story

12. As a user, I want the notch shell to render my wallpaper (including video) and keep caffeine working so that it can replace the old shell.

## Acceptance criteria

- [ ] Given a saved wallpaper per monitor (image or video; on first run imported from the old shell's state, which stays untouched), when the notch shell starts, then each monitor shows its own wallpaper behind the notches, with videos playing muted and looping.
- [ ] Given caffeine is off, when I toggle it with `qs -c notch ipc call caffeine toggle`, then the session never goes idle until I toggle it off again, and it starts off after a restart.
- [ ] Given a video wallpaper is playing, when the session locks, then the video pauses, and it resumes when the session unlocks.

## Plan

- Data: a wallpaper service that reads the per-monitor wallpaper from the notch state dir, importing the old shell's `wallpaper-screens.json` / `wallpaper.txt` once if the notch state is empty; decisions (which path per screen, image vs video, import or not) live in pure logic with tests.
- Paint: one always-mapped background-layer surface per monitor (reused from the old Background/BackgroundSurface) drawing the image or video, transparent until ready so hyprpaper shows through.
- Caffeine: a session-only flag on a service, an `IpcHandler` target `caffeine` (toggle/on/off), and an idle inhibitor on the background surface enabled by that flag.
- Lock: the video's playing state follows `Session.locked`.
- Smoke: under `Flags.smoke` the background surface, the state import/writes and the IPC handler are not created.

## Out of scope

- Changing the wallpaper and the hyprpaper fallback write (#27); theme and per-monitor palette regeneration from the wallpaper (#28).
- The caffeine tile in the control center (#19); the idle manager (screensaver/lock timeouts) and the lock screen (#13).
- Hyprland exec/keybinds that call the `caffeine` IPC target (#14).

## Suggestions (your call)

- Port the old `Wallpapers.isVideoPath` check into `shell/logic/` so the import and the surface share one tested rule.

## Size

normal
Risk: item 3, 6 (new `caffeine` IPC target that keybinds consume; wallpaper/video rendering and idle inhibition only verifiable manually)

## Log

- L1 request: /flow:story 12
- L2 assumptions: caffeine is reachable by IPC only in this story (the tile comes with #19); a missing or unreadable wallpaper file leaves the surface transparent (hyprpaper shows) and logs a `console.warn`.
