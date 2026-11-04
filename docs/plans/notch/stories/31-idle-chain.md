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
- L4 build: red→green d55a87b→1a761a6 (delays), ad2bc56→07f346f (zero stages), f19e047→6e5d220 (parseIdle), 9410f45→2502510 (import once); e479de5 smoke guard (green at once: the service already skipped loading under smoke); e9d9122 idle watchers (no automated red by user approval: they fire on the live session's real idleness; the existing lock-smoke probe caught a missing `import QtQuick` in shell.qml before the commit).
- L5 verifier FAIL → fix: the zero-stage test only covered 0/0, hiding that `{screensaver:3, lock:0}` still locked after 180 s; red 71b2aaa → 11498fb (the lock is off when its own timeout is zero; suspend still counts from the full sum). Recheck: PASS.
- L6 evidence: `make check` green at 11498fb (idleState 6/6, idle probes 3/3, `smoke: config loaded`); flaky unrelated launcher-command-filter timeout seen once in the verifier's first run. Manual (user + `qs log --log-times`, timeouts 0.25/0.25/0.5, NOTCH_POWER_DRY_RUN=1): locked at about 30 s; dry-run suspend logged 65 s after launch and again only after input in between (input restarts the count); with caffeine on, no lock and no new dry-run line for more than 75 s. The screen stays on in this check because suspend is a dry run; DPMS is out of scope.
- Risk: item 6 (idle firing and suspend only verifiable manually on the live session)
