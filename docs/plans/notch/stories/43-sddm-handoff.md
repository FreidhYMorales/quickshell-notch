# Story 43: SDDM to shell handoff

## Story

43. As a user, I want the SDDM greeter to compress into the central notch when I log in, exactly like the notch shell's unlock morph, so that logging in feels like one continuous motion instead of the greeter disappearing. Requires: #33.

## Acceptance criteria

- [ ] Given the greeter shows the login form, when I submit my password (or trigger fingerprint authentication), then the whole login screen compresses into the central notch with the same duration and easing as the lock's exit morph, and SDDM only starts authenticating when the compression finishes.
- [ ] Given the compression has finished, then the last visible greeter frame is the shell's first frame: the same wallpaper with the black idle notch at the top edge, so no panel or clock is left hanging when SDDM stops the greeter.
- [ ] Given authentication fails, then the greeter expands back to the login form, shows the error and clears the password, without restarting SDDM.
- [ ] Given authentication takes too long or never answers, then the greeter expands back after a bounded timeout with a pending message and blocks another attempt until SDDM replies; the timeout does not cancel PAM.
- [ ] Given the preview keybind, then it still plays the compression and restores the greeter, and no authentication is attempted.
- [ ] Given the next session starts, then the wallpaper shown in the gap between the greeter and the notch shell is the shell's current wallpaper, not the stale hyprpaper default.
- [ ] Given `make check` runs, then the SDDM source tests and the whole suite stay green.

## Plan

- SDDM stops the greeter 74 ms after `LoginSucceeded` (measured), so a post-authentication animation cannot be seen. Move the morph before authentication: `submit()` starts the compression, and its `onFinished` calls `sddm.login()`. On success the greeter is already at the notch frame; on failure or timeout it expands back.
- Restructure the greeter so the layer behind the morph is the undimmed wallpaper, not the dark fill: the morph keeps the dimmed wallpaper plus clock and login panel, so the compression reveals the same wallpaper that the shell will show. Keep the always-visible black notch shape on top. Video backgrounds keep the dark fill (one player only) and are documented as a slower transition.
- Hide the virtual keyboard and the login panel when the compression starts; keep the footer hidden through the existing `exiting` flag.
- Sync hyprpaper with the shell's wallpaper: generate its config in the shell state dir from the saved wallpaper(s) and start hyprpaper with `-c` from the dotfiles autostart, so the gap shows the right image. This is the one change outside this repo; document it in the log.
- Tests: a source-level test that pins the order (morph first, `sddm.login` on finish), the failure expansion and the auth timeout; manual test-mode preview of the compression; real login/logout verification only with the user's approval.

## Out of scope

- A true compositor handoff. SDDM runs the greeter as an X11 client and the session as Wayland; they cannot share a surface.
- Keeping the notch visible during Hyprland's startup gap; no process that draws before the shell can draw the shell's notch.
- Autologin plus the notch lock screen as the login UI; that is a different login model and would be its own story.

## Suggestions (your call)

- Compression before authentication adds its duration (~520 ms) to every login, including a wrong-password attempt. If that feels slow, shorten the morph for the greeter only and record the chosen duration.
- The fingerprint prompt is not drawn by the theme today; the user already knows to touch the sensor. If a prompt is wanted, show it in the notch end state before calling `sddm.login`.
- Measure the real gap with `journalctl -b -u sddm` (LoginSucceeded to Greeter stopped) and the Hyprland/hyprpaper start times, the same way the 74 ms figure was measured.

## Size

normal
Risk: item 4 (auth ordering, failure and timeout state), item 6 (the result is only verifiable with a real login)

## Log

- L1 request (user): after installing the remembered-session fix, make the SDDM login compress into the central notch like the Quickshell lock's exit morph; register the work as story 43.
- L2 build: the greeter now compresses on submit and calls `sddm.login()` only when `exitMorph` finishes (~520 ms), so the animation is visible before SDDM stops the greeter 74 ms after success. A wrong password, a missed fingerprint or a 20 s timeout expands back with an error (`recover` + `returnMorph`). The layer behind the morph is now the undimmed wallpaper, so the final frame is wallpaper + black notch like the shell's first frame. New source test `tests/sddmHandoff.test.mjs`; `make test` 615 pass, `make fmt-check` clean. Test-mode greeter opened for visual confirmation; not installed yet.
- L3 pending: visual confirmation in test mode, then install `Main.qml`; hyprpaper wallpaper sync needs the dotfiles autostart change and is not done.
- L4 fix: `--test-mode` has no daemon, so `sddm.login()` never answers and the greeter stayed compressed until the 20 s timeout. The theme now detects `--test-mode` (`Qt.application.arguments`), skips `sddm.login()` and, after the compression, holds the notch frame for 1.1 s (`demoReturn`) before expanding via `recover("")`. `resetPreview()` now expands with `returnMorph` instead of snapping `reveal = 1`, and `returnMorph` starts from the current reveal so an early failure does not jump. `tests/sddmHandoff.test.mjs` pins the demo branch order and the smooth preview; 617 tests pass, `make fmt-check` clean.
- L5 visual confirmation and install: the user confirmed in `./scripts/test-sddm.sh --synced` that submit compresses, holds and expands back. Installed the theme with `pkexec install`; the installed `Main.qml` is byte-identical to the repo, root-owned and `0644`. Active theme is `notch-lock` (`/etc/sddm.conf.d/zz-notch-lock.conf`); `silent` remains as fallback. Previous installed file backed up at `/tmp/opencode/notch-lock-Main.qml.bak`. SDDM was not restarted; the next real login uses the new file.
- L6: the user confirmed a real login succeeds. Wallpaper saves now prepare an atomic hyprpaper startup configuration; GIF and video backgrounds use a cached first frame. The dotfiles autostart selects that configuration when available, otherwise the original hyprpaper configuration. The current GIF's frame was generated without restarting the session. `make check` passed; the actual next-login handoff and multi-monitor behavior remain unverified.
- L7: on a confirmed failure, clear the password immediately, shake the red lock, expand the form and show an English error until the field regains focus; the user confirmed the test-mode preview. A slow authentication expands with a pending message while retaining the in-flight guard: the theme cannot cancel PAM and must not submit a second attempt. Late success stops the return animation and restores the notch frame; late failure uses the failure feedback. An offscreen QML probe exercises the timeout and both late results; real PAM behavior is still unverified. These changes are not installed yet.
