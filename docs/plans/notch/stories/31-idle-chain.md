# Story 31: Idle chain

## Story

31. As a user, I want an idle chain (screensaver and lock together, then suspend) with my old timeouts so that an unattended session locks and sleeps on its own. Requires: #30, #12

## Acceptance criteria

- [ ] Given my idle timeouts (screensaver, lock, suspend minutes; on first run imported once from the old shell's `idle.json`, which stays untouched; the old defaults 3/5/15 when there is none), when I leave the session idle for screensaver + lock minutes (6 with my values), then it locks asking for my password; any input before that restarts the count.
- [ ] Given the session stays idle, when it reaches screensaver + lock + suspend minutes (21 with my values), then the machine suspends the same way as the power menu's suspend.
- [ ] Given caffeine is on, when the session stays idle past every timeout, then it neither locks nor suspends; and a smoke run creates no idle watchers.

## Plan

- Data: an idle service reads the three timeouts from the notch state dir, importing the old `idle.json` once when the notch state has none (same pattern as the wallpaper import); deciding the effective lock and suspend delays (sums, a 0 stage disables it) lives in pure logic with tests.
- Two idle watchers that respect inhibitors: the lock one calls `Session.requestLock()`, the suspend one runs the power service's suspend (so `Flags.powerDryRun` keeps tests and manual checks from suspending).
- Caffeine needs no extra wiring: its inhibitor on the wallpaper surface already pauses watchers that respect inhibitors.
- Under `Flags.smoke` the watchers and the state import/write are not created.

## Out of scope

- The screensaver phase (lock at the screensaver timeout with password-free dismissal until the lock grace ends) and screensaver content: with the redesign (#33) or the screensaver command view (plan: SHOULD).
- Changing the timeouts from the launcher (screensaver command view, later).
- Lock before any suspend, including lid close and manual `systemctl suspend` (#32).
- Turning screens off (DPMS): the old shell did not do it either.

## Suggestions (your call)

- Wait for the timeouts to load before enabling the watchers: the old `IdleManager` documents a race where a watcher created with the default timeout and changed a moment later never fired.

## Size

normal
Risk: item 6 (idle firing and suspend only verifiable manually on the live session)

## Log

- L1 request: /flow:story 31
- L2 decision (user): option A, no screensaver phase: lock at screensaver + lock minutes asking for the password, suspend at the full sum. Editing the timeouts from the launcher comes later.
- L3 assumptions: suspend uses the power menu's command (`systemctl suspend-then-hibernate`), as the old idle chain did; only the three timeouts are imported (`screensaverUseWallpaper`/`screensaverPath` stay in the old file until the screensaver exists).
