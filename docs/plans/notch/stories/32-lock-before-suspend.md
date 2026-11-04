# Story 32: Lock before suspend

## Story

32. As a user, I want every suspend to lock the notch session first so that my session is already protected when it resumes. Requires: #30

## Acceptance criteria

- [ ] Given a Quickshell shell with a lock target is running unlocked (the notch shell started with `qs -p` or `qs -c notch`, or the old shell after a rollback), when the system suspends for any reason (lid, idle chain, power menu, `systemctl suspend`), then the session is already locked when it resumes.
- [ ] Given no running shell has a lock target, or the one that does never answers, when the system suspends, then the suspend still goes ahead within a few seconds.

## Plan

- A user-side lock step in this repo: list the running Quickshell instances, and ask each one that exposes the `lock` target to lock, by its pid; instances without the target (probes, smoke runs) are skipped. Tested with a fake `qs` on the PATH.
- The root sleep hook keeps its current shape (on "pre" only: find the user's runtime dir and Wayland socket, run the lock step as the user under a short timeout, then wait a moment) and calls the new lock step instead of the default config.
- Both files ship in this repo with a documented install step (sudo, run by the user): root-owned, not writable by the user, replacing today's hook.
- Verified once with a real `systemctl suspend` while the notch shell runs.

## Out of scope

- Hyprland exec, keybinds and the rollback script (#14).
- logind settings for the lid or the power key, and turning screens off (DPMS).
- Updating the copy of the hook in the dotfiles repo (`~/Mio/Configuraciones/system/...`); it keeps the old version until the cutover/rollback work decides its home.

## Suggestions (your call)

- Keep the 3 s timeout and the trailing 1 s wait of today's hook: its comments document a hung IPC call freezing the screen instead of sleeping, and logind ordering the lock before the screen goes dark.

## Size

normal
Risk: item 2, 5, 6 (root hook running commands as the user; system install of a sleep hook; real suspend only verifiable manually)

## Log

- L1 request: /flow:story 32
- L2 decision (user): option A: lock every running Quickshell instance that has a `lock` target (found with `qs list --all`, addressed with `qs ipc --pid`) instead of the plan's `qs -c notch` with a fallback to the default config, because `-c notch` only exists after the cutover (#14).
- L3 assumptions: the user runs the sudo install; I never run sudo. The hook still targets the single user `deadlock`, as today's hook does.
