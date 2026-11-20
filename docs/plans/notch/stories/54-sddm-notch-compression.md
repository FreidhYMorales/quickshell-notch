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
- L6 verifier FAIL (correction to L3/L4): the installed `Main.qml` is the old eea4bac version (sha256 19d09d3e…), not the repo (f1be4408…). The journal shows that at 20:43, five minutes after the L3 install, the restore command from the instructions was run from a terminal in the session (pts/2): the new theme was moved to `/tmp/notch-lock-broken` (lost on reboot), the backup was moved back and SDDM was restarted. The new theme was never exercised, so the L4 checks ran on the old behaviour and do not count. `notch-lock-backup/` is now empty. Reinstall and repeat the three checks.
- L7 reinstall (2026-11-19): the user confirmed the restore ran by accident while copying the message. Removed the empty `notch-lock-backup/` and reran `scripts/update-sddm-theme.py` via `pkexec`. sha256 check: installed `Main.qml` = repo = f1be4408…; backup `notch-lock-backup/notch-lock/Main.qml` = eea4bac version 19d09d3e…. Pending: repeat the three real-login checks.
- L8 checks invalid (display manager): the user reported "si, funciona", but the journal shows that login ran through greetd. Since 2026-11-11 13:46, `display-manager.service` points to `greetd.service`; SDDM is inactive. SDDM only ran between 20:43 and the 20:47 reboot, after the accidental restore restarted it by hand. The 21:57 wrong password appears as `greetd ... AUTH_ERR`. No check of story 54 has run on SDDM yet. To test, SDDM must be enabled as the display manager (user decision pending).
- L9 display manager (user approved): `systemctl disable greetd && systemctl enable sddm` via `pkexec`; `display-manager.service` now points to `sddm.service` (greetd installed but disabled). The active theme is `notch-lock` (`zz-notch-lock.conf`). Pending: reboot and the three real-login checks on SDDM.
- L10 real SDDM checks (boot 2026-11-19 22:01): the user reported that all three work. The journal confirms the SDDM greeter loaded `notch-lock/Main.qml` (installed sha256 == repo f1be4408…). 22:01:45-47: wrong password, `LoginFailed` (criterion 2). 22:01:59: correct password, "Authentication for user deadlock successful" (criterion 1). Criterion 3 was not exercised: `/etc/pam.d/sddm` has no `pam_fprintd` (password-only stack, on purpose for the keyring), so an untouched fingerprint cannot stall SDDM, and the journal shows no attempt lasting 20 s. The timeout path is covered only by `tests/qml/sddm-timeout.mjs` and the source tests. User decision pending.
- L11 decision (user): accept criterion 3 as verified by `tests/qml/sddm-timeout.mjs` (offscreen run of the real QML: timeout pending message, no second attempt, late success and late failure) plus `tests/sddmHandoff.test.mjs`. Known limitation: the password-only SDDM PAM stack cannot be stalled on a real login without editing `/etc/pam.d/sddm`, which was not done.
