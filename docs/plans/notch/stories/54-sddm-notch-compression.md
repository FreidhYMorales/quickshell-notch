# Story 54: SDDM greeter compresses into the notch

## Story

54. As a user, I want the SDDM greeter to compress into the central notch when I log in, and to expand back with clear feedback when the login fails or stalls, so that logging in feels like one continuous motion. Requires: #33

## Acceptance criteria

- [ ] Given the installed greeter shows the login form, when I submit the correct password, then the whole login screen compresses into the central notch with the lock's exit morph before authentication runs, and my session starts.
- [ ] Given the installed greeter, when I submit a wrong password, then the greeter expands back to the form, clears the password, shakes the lock and shows an error, without restarting SDDM.
- [ ] Given authentication does not answer within the timeout (for example a fingerprint I never touch), then the greeter expands back with a pending message, refuses a second attempt until SDDM replies, and a late success or failure is then shown correctly.

## Plan

- The behaviour is already built and merged into `main` (split from #43, log L2-L7); this story closes the gap between the repo and the real greeter.
- Install the current theme over the installed one, after the user approves the privileged install, and confirm the installed copy matches the repo.
- Verify each criterion on a real login: correct password, wrong password, and an untouched fingerprint for the timeout path.
- Fix only what the real login shows to be wrong, test first for anything the source tests can pin; keep the existing preview behaviour and tests green.

## Out of scope

- The wallpaper shown in the gap between the greeter and the shell (#55).
- greetd: SDDM stays the default greeter (autologin and related features); the greetd login surface is not touched.
- A true compositor handoff or keeping the notch visible during Hyprland's startup.
- Shortening or restyling the morph.

## Suggestions (your call)

- fprintd's own timeout (about 30 s) is longer than the theme's 20 s guard, so not touching the sensor is a natural way to exercise the timeout and the late failure without faking PAM.
- The nearly complete greetd setup (`greetd/`, `greetd-shell.qml`, `scripts/test-greetd-*.mjs`, `shell/logic/greetd*.mjs`) is a reference for failure and timeout handling if the SDDM theme needs a fix; read it, do not change it.
- Keep the backup of the installed file next to the previous one before overwriting it, so a broken greeter can be restored from a TTY.

## Size

normal
Risk: item 2 (authentication flow of the login screen), item 4 (ordering between the morph, the auth call and the timeout), item 5 (privileged install of the system theme), item 6 (only a real login can verify the result)

## Log

- L1 request (user): "si, dividila en #54 y #55, si al final voy a dejar sddm como greater por defecto, en lugar de greetd, por lo del autologin y esas cosas"
- L2 origin: split from #43 (see `43-sddm-handoff.md`, L2-L7). Built and merged into `main`; verified so far: real correct-password login (L6), test-mode preview and failure feedback (L5, L7), `make check`. The L7 changes are not installed: `/usr/share/sddm/themes/notch-lock/Main.qml` differs from `sddm/notch/Main.qml`.
- L3 install (2026-11-19): with the user's approval, removed the stale 2026-11-09 backup and ran `scripts/update-sddm-theme.py` via `pkexec`. The installed `Main.qml` is byte-identical to `sddm/notch/Main.qml` (root, 0644); the previous install (the L5/L6 version that logged in fine) is the new `/usr/share/sddm/themes/notch-lock-backup/notch-lock`. SDDM not restarted. Pending: the three real-login checks.
- L4 manual (user): after a real logout the user ran the three real-login checks (wrong password, untouched fingerprint timeout, correct password) and reported "se ve bien".
- L5 check (stopped, rule 4): `/tmp/opencode` was gone after the logout, so 20+ SDDM tests failed on their hardcoded `mkdtempSync("/tmp/opencode/...")` path; recreated the directory (no test changed). Then three full `make check` runs on 57198fa each failed a different QML runtime test (power hover, theme view, then sleep delays + launcher dry run); each one passes when run alone (power 3/3, theme view 2/2). The branch changes no code, only docs. Not green yet; user decision pending.
