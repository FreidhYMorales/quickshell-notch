# Story 36: Security command view

## Story

36. As a user, I want the security command view in the launcher so that I can enable fingerprint unlock and manage my registered fingers. Requires: #26, #30.

## Acceptance criteria

- [ ] Given the launcher in command mode, when I choose Security, then the notch shows a "Fingerprint unlock" switch in its current state and my registered fingers as fprintd reports them, Esc goes back to the command list, and flipping the switch decides whether the next lock listens for my finger, a choice that survives a restart.
- [ ] Given a finger that is not registered, when I pick it and touch the sensor until enrollment ends, then the view shows each touch's progress and hint with a Cancel, and afterwards the finger appears in the registered list; a failed or cancelled enrollment leaves the list as it was.
- [ ] Given a registered finger, when I remove it from the view, then it disappears from the list and no longer unlocks the session.

## Plan

- A new "Security" entry in the launcher's command list opens its own sub-view in the centre notch, with the same open/back flow as the other command views.
- A security service owns the switch (saved to the notch's own `security.json`, falling back to the old shell's value until first saved, the same rule the lock already uses) and the live fprintd state: the registered list, enrollment progress and removal, never cached.
- The lock reads the switch from that service, so a change applies to the next lock without a restart.
- The view paints: switch, registered fingers with a remove action, the free fingers to add, and an enrollment panel while enrolling.
- Tests: pure logic for parsing the fprintd list, mapping enrollment results to progress/hint/end, and the free-finger list; QML probes with a fake fprintd that the view opens, shows the stored switch and fingers, and goes back on Esc.

## Out of scope

- Changing how the lock or polkit authenticate (PAM stacks, the fingerprint listener, `quickshell-fprint`).
- Installing or configuring fprintd, PAM or the sensor.
- Password management or any other unlock method.
- A confirmation step for removing a finger (the old view removes on one press).
- Visual polish beyond the existing command views' style.

## Suggestions (your call)

- Port the old `services/Security.qml` (fprintd-list/-enroll/-delete, the 10 finger names, the enroll-status table) and move its parsing into `shell/logic/` so it is testable; the old view's layout (`SecurityForm.qml`) is the functional reference.
- Finger names reach `fprintd-*` only from the fixed list of 10, passed as argv entries, never through a shell.
- No reader or no fprintd: hide the finger section and `console.warn`, keep the switch.

## Size

normal
Risk: item 1, 2, 6 (removes enrolled fingerprints; unlock method; enrollment only checkable on the real sensor)

## Log

- L1 request: "/flow:story 36" (chat in Spanish, story file in English).
- L2 assumptions (from the old config's SecurityForm and Security service): same features as the old view (switch, per-finger enroll and remove for any of the 10 fprintd finger names, live progress with Cancel); removal is one press with no confirmation; the switch keeps the old default (off when neither state file has it, as `lockSecurity.mjs` already decides).
- L3 (pair): tests 1-4 green: 1 red `34ba42e` green `b225d04` (registered fingers), 2 red `16f8523` green `94f8d1e` (enroll results), 3 red `116e9f2` green `a9a256a` (free fingers), 4 red `f18563d` green `7f484f2` (switch JSON). Each red commit carries a minimal stub so the failure is the assertion. Logic returns hint keys; UI text goes to `Strings`.
- L4 (stop rule 5): test 5 (`launcher-security-view`) needs the reducer routing, the launcher entry and dispatch, a new view, a new service and two `qmldir` lines in one step. Proposed split: 5a reducer `SecurityOpen`/`SecurityBack` unit test; 5b view opens and shows the stored switch; 5c view shows the fingers from a fake `fprintd-list`. Needs the user's call.
- L5 (user): approved the 5a/5b/5c split. 5a red `c8ab499` green `dcf4b49` (reducer). 5b red `9b52ae8` (`security view: command missing from the list`); its green code (Security entry, view, read-only service, routing) passes the probe 2/2 but is uncommitted.
- L6 (stop rule 1/3): with a sixth command the existing probe `launcher-command-padding` turns red (`launcher padding: empty space -43`): command mode caps the list at `Layout.launcherRows` (5), so the last command sits below the visible rows. Either command mode shows every command (code change, probe untouched) or the probe checks the last row after scrolling (existing test changes). Needs the user's call.
