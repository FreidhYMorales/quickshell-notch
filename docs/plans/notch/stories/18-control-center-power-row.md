# Story 18: Control center power row

## Story

18. As a user, I want a power row in the control center (lock, suspend, logout, reboot, shutdown) so that I reach session actions from the notch. Requires: #16, #10

## Acceptance criteria

- [ ] Given the control center is open, when I look under my profile, then I see a row with the lock, suspend, logout, reboot and shutdown icons.
- [ ] Given the control center is open, when I click lock or suspend, then that action runs at once and the control center collapses.
- [ ] Given the control center is open, when I click logout, reboot or shutdown, then the control center collapses and the power menu opens in the centre notch of the same monitor with that action preselected, still needing the hold to confirm.

## Plan

- Reuse the power menu pieces from #10: the action list and icons, the reducer's instant-vs-hold rule and the `Power` service (with its dry-run guard); no new action logic.
- The control center root view gains one row of five icon buttons between the profile header and the tiles, as in the plan's wireframe.
- Lock/suspend go straight to the power service; logout/reboot/shutdown open the power menu on the control center's own monitor with that action preselected.
- Any click on the row collapses the control center; the panel size grows to fit the row.

## Out of scope

- Changing the power menu itself (hold, keys, look): done in #10.
- The real lock screen (#13): lock only fires the lock request.
- Power profile and caffeine tiles (#19), keybinds (#14).
- Hover animation on the row's icons (only the power menu has it); ask if wanted.

## Suggestions (your call)

- The power menu's "open with this action on this monitor" already exists as the reducer's `PowerOpen` event with an `action`; the row can dispatch it with its own screen name instead of going through the focused-monitor IPC path.

## Size

normal
Risk: item 1 (a wiring slip could run logout/reboot/shutdown without the hold)

## Log

- L1 request: /flow:story 18
- Assumptions: the menu opens on the monitor whose control center was clicked (not the Hyprland-focused one); the row uses the same icons as the power menu; testing follows #10's rule: dry run only, never run real power actions against the live session.
- L2 build: test→code pairs b548ce7→e403a4a (row), c048ff6→b2fca67 (lock/suspend), 4f85e32→634a42d (preselected menu), 9951022→d895b64→71f319f (ink centring); manual-only look commits 2e00a9b, 77a0139, f68c93c, 8b7009f.
- L3 manual check (user, NOTCH_POWER_DRY_RUN=1 + fake binaries): asked to centre the row, add the power menu's hover colour/scale animation, align it edge to edge with tiles and the notifications card, use tile-sized glyphs, add a tinted pill, and fix the off-centre right icon (Nerd Font ink wider than advance). All approved.
- L4 evidence: make check green at 71f319f (unit, power probes, qml-test, smoke).
- L5 verifier: PASS. Follow-ups noted: no logout click in power-cc-hold; poweroff case does not assert owner.
- Risk: item 1 (a wiring slip could run logout/reboot/shutdown without the hold)
