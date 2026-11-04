# Story 30: Lock and unlock

## Story

30. As a user, I want to lock my session from the notch shell and unlock it with my password so that my session stays protected.

## Acceptance criteria

- [ ] Given an unlocked session, when I call `qs -c notch ipc call lock lock` or choose lock in the power menu or the control center power row, then every monitor shows the lock screen (the old lock, with its current theme config), any open notch state closes (a pending polkit prompt is cancelled) and a playing video wallpaper pauses.
- [ ] Given the session is locked, when I enter my correct password (or my fingerprint, as in the old lock), then the lock screen goes away, I am back in my session and the video wallpaper resumes; a wrong password shows an error and the session stays locked.

## Plan

- Port the old lock module and its transitive deps (LockConfig, LockLayouts, LockLanguages, Security, OsInfo, avatar, vkeyboard assets) with `Paths` tokens instead of the hardcoded `quickshell/deadlock` path; `Style.*` inside the lock stays exempt from the tokens rule.
- Adapter: the lock listens to `Session.lockRequested` (already fired by the power actions) and is the only writer of `Session.locked`; the existing centre reducer and wallpaper surface already react to it.
- IPC target `lock` (`lock`) for keybinds and the sleep hook; skipped under `Flags.smoke`, like the lock surface itself.
- Unlock reuses the existing PAM services `quickshell-password` and `quickshell-fprint` unchanged.

## Out of scope

- The idle chain (screensaver, lock and suspend timeouts, `lockFromIdle`, grace latch) (#31).
- The root-owned sleep hook and lock-before-suspend (#32).
- Hyprland keybinds, `QML_IMPORT_PATH` env for the virtual keyboard, exec and rollback (#14).
- Restyling the lock in the notch style (plan: LATER).

## Suggestions (your call)

- Test without risking a lockout: keep a TTY (Ctrl+Alt+F3) ready and set `misc:allow_session_lock_restore = 1` so a crashed lock can be recovered by relaunching `qs -c notch`; never test while the old shell holds the lock.

## Size

normal
Risk: item 2, 3, 6 (PAM unlock; `lock` IPC target consumed by keybinds and the sleep hook; session lock only verifiable manually)

## Log

- L1 request: /flow:story 13
- L2 split: #13 needed 4+ criteria (lock/unlock, idle chain, lock before suspend) → #30, #31, #32. #14 still says `Requires: #13`, which now means all three.
- L3 assumptions: the lock is ported as is (its config files, themes and avatar are read from where the old one reads them, read-only); the virtual keyboard works once #14 sets `QML_IMPORT_PATH`; this story also closes #12's pending manual check (video pause on lock).
