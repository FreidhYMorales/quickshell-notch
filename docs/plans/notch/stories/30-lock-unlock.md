# Story 30: Lock and unlock

## Story

30. As a user, I want to lock my session from the notch shell and unlock it with my password so that my session stays protected.

## Acceptance criteria

- [ ] Given an unlocked session, when I call `qs -c notch ipc call lock lock` or choose lock in the power menu or the control center power row, then every monitor shows a minimal lock screen (clock, password field, fingerprint state and errors over the wallpaper), any open notch state closes (a pending polkit prompt is cancelled) and a playing video wallpaper pauses.
- [ ] Given the session is locked, when I enter my correct password (or my fingerprint, as in the old lock), then the lock screen goes away, I am back in my session and the video wallpaper resumes; a wrong password shows an error and the session stays locked.

## Plan

- A minimal lock screen of our own (no port of the old SDDM-derived lock): a per-monitor session lock surface with the wallpaper, a clock, a masked password field, the fingerprint state and the last error, using the shell tokens.
- Adapter: the lock listens to `Session.lockRequested` (already fired by the power actions) and is the only writer of `Session.locked`; the existing centre reducer and wallpaper surface already react to it.
- IPC target `lock` (`lock`) for keybinds and the sleep hook; skipped under `Flags.smoke`, like the lock surface itself.
- Fingerprint on/off is read (read-only) from the notch state `security.json`, falling back to the old shell's one; unlock reuses the existing PAM services `quickshell-password` and `quickshell-fprint` unchanged.

## Out of scope

- The idle chain (screensaver, lock and suspend timeouts, `lockFromIdle`, grace latch) (#31).
- The root-owned sleep hook and lock-before-suspend (#32).
- Hyprland keybinds, exec and rollback (#14).
- The full notch-style lock redesign (#33): themes, avatar, virtual keyboard, layout selector, power menu inside the lock, animations.

## Suggestions (your call)

- Test without risking a lockout: keep a TTY (Ctrl+Alt+F3) ready and set `misc:allow_session_lock_restore = 1` so a crashed lock can be recovered by relaunching `qs -c notch`; never test while the old shell holds the lock.

## Size

normal
Risk: item 2, 3, 6 (PAM unlock; `lock` IPC target consumed by keybinds and the sleep hook; session lock only verifiable manually)

## Log

- L1 request: /flow:story 13
- L2 split: #13 needed 4+ criteria (lock/unlock, idle chain, lock before suspend) → #30, #31, #32. #14 still says `Requires: #13`, which now means all three.
- L3 assumptions: this story also closes #12's pending manual check (video pause on lock).
- L4 build: unlock first by user request (password and fingerprint proven before any real lock): red→green c35ef73→6efb1b2, 7442e83→3c6184f, 86681aa→7c12f1e, 3ac01ff→a804851; lock IPC 4319db4→9f0c139; smoke guard 8fced0e (green at once: the IPC LazyLoader already covered it).
- L5 scope change (user approved): instead of porting the old SDDM "silent" lock (about 2600 lines plus themes) only to redesign it later, this story builds a minimal lock of our own on top of `LockPam`; the full notch-style redesign moves to #33 (needs a mini-plan first). Lost until #33: virtual keyboard, layout selector, lock power menu, themes.
- L6 build: lock content 67c964b→88e2eb2; fingerprint setting 31ba132→a51e251; lock wiring 5c837f5 (no automated red by user approval: testing it locks the live session). Manual run found the password never reached PAM (`auth: auth` self-reference in LockContent) → fixed in 5b49c55 with the qs log as evidence. lock-smoke changed in 2906af5 (user approved) to talk only to its own instance via `--pid`; assertions unchanged.
- L7 evidence: `make check` green at 5b49c55 (lock probes 7/7, lockSecurity 3/3, `smoke: config loaded`); flaky unrelated probes seen once each (polkit-side-margin, polkit-fingerprint-cancel), both pass alone. Manual (user): lock via IPC, power menu and control center on every monitor; password+Enter and fingerprint unlock; wrong password shows "Login failed" and empties the field; launcher closes on lock. Closes #12's pending video-pause-on-lock wiring. Verifier: PASS (minor: `LockPam.stop()` untested; if `passwordPam.start()` fails no error is shown).
- L8 note: a wrong password answers after ~2 s (pam_unix fail delay) and faillock locks the password path after 3 failures for 10 min (fingerprint unaffected); system PAM config left unchanged.
- Risk: item 2, 3, 6 (PAM unlock; `lock` IPC target consumed by keybinds and the sleep hook; session lock only verifiable manually)
