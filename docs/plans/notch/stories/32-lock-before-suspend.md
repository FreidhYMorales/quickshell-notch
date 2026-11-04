# Story 32: Lock before suspend

## Story

32. As a user, I want every suspend to lock the notch session first so that my session is already protected when it resumes. Requires: #30

## Acceptance criteria

- [ ] Given the notch shell is running unlocked (started with `qs -p` or, after the cutover, `qs -c notch`), when the system suspends for any reason (lid, idle chain, power menu, `systemctl suspend`), then the session is already locked when it resumes.
- [ ] Given no notch shell is running, or it never confirms the lock, when the system suspends, then the suspend still goes ahead within a few seconds.

## Plan

- The notch shell itself locks before sleep (no root hook): it holds a logind sleep inhibitor in delay mode and watches logind's PrepareForSleep signal; logind sends it before freezing user processes and waits (up to its delay limit) for delay inhibitors.
- On PrepareForSleep(true) it requests the lock and releases the inhibitor once the compositor confirms the lock (or at once if already locked); on PrepareForSleep(false) it takes the inhibitor again.
- The decisions (which signal line means what, when to lock, hold or release) live in pure logic with tests; the watcher and the inhibitor are two event-driven processes from glib2 and systemd, never a poll. Under smoke neither runs.
- The repo's root hook and its user-side step are removed; the docs tell the user how to uninstall them (or restore the old hook).
- Verified with a real `systemctl suspend` while the notch shell runs, and once with no shell running.

## Out of scope

- Hyprland exec, keybinds and the rollback script (#14).
- logind settings for the lid or the power key, and turning screens off (DPMS).
- Updating the copy of the hook in the dotfiles repo (`~/Mio/Configuraciones/system/...`); it keeps the old version until the cutover/rollback work decides its home.

## Suggestions (your call)

- Release the inhibitor on the compositor's lock confirmation rather than on a timer, so the lock is drawn before the screen goes dark; logind's own delay limit (`InhibitDelayMaxSec`, 5 s by default) bounds a shell that never confirms.

## Size

normal
Risk: item 4, 6 (ordering between logind's sleep, the lock and the inhibitor release; real suspend only verifiable manually)

## Log

- L1 request: /flow:story 32
- L2 decision (user): option A: lock every running Quickshell instance that has a `lock` target (found with `qs list --all`, addressed with `qs ipc --pid`) instead of the plan's `qs -c notch` with a fallback to the default config, because `-c notch` only exists after the cutover (#14).
- L3 assumptions: the user runs the sudo install; I never run sudo. The hook still targets the single user `deadlock`, as today's hook does.
- L4 build (superseded by L6): lock-sessions (all shells with a lock target), guard (no shell), hung shell in parallel with per-call timeouts, hook post exits; hook pre branch + install docs a6faca8 (no automated red: needs root).
- L5 manual finding (stop, design decision needed): installed and ran `systemctl suspend` with the notch running: suspends but does not lock. Journal: systemd 262 logs "Successfully froze unit 'user.slice'" before the sleep hook runs, so every Quickshell instance is frozen and the hook's IPC calls time out (runuser ends after ~2 s). Any system-sleep hook that talks to a user process is broken by this freeze (systemd >= 256), the old shell's hook included.
- L6 decision (user): option A: the notch shell locks on logind's PrepareForSleep under a delay inhibitor; the root hook approach (and its tests) is dropped; the old shell's hook was broken by the same freeze. Criteria now name the notch shell only (the old shell after a rollback is out of reach without a hook).
