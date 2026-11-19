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
- L7 (user): chose option A for L6: command mode lists every command. 5b green `d92177e`; 38/38 launcher probes pass serially (after `mkdir -p /tmp/opencode`: keybinds and webapp probes hardcode that dir and fail with ENOENT when it is missing).
- L8 (stop, committed test setup fault): 5c red `3fb9fa5` failed for the right reason (`security fingers: no registered list`), but its green run cannot pass: the probe calls `Visual.findText(registered, label)` with one item, while `findText` iterates an array of items (`tests/qml/visual.mjs:9`), so the probe throws before printing. Fixing it means editing the committed test's setup to `findText([registered], label)` (expectations untouched). Green code for 5c is uncommitted. Needs the user's call.
- L9 (user): approved fixing only the probe setup. `41945fc` passes `[registered]` to `findText`, expectations untouched. Red re-established with the green code stashed (`security fingers: no registered list`, 0/2), green `2d05707` (2/2; security probes 4/4).
- L10 (pair): test 6 `5fd99a0` passed on first run (the view's Escape wiring came with 5b's routing); committed as a test only after a mutation check: without `Keys.onEscapePressed` it fails with `security back: Escape did not return to the commands`. Test 7 red `3de9bfd` (click left the switch unchanged) green `9180aeb`. Test 8 red `8ee64a4` against a `false` stub (`on false, off false`) green `4d25ccb`: the lock reads the switch from the security service instead of its own two state files; its probe sets `XDG_STATE_HOME` to a temp dir because the lock fixture does not. Lock probes 24/24.
- L11 (pair): test 9 split into three steps to stay under the step size, same assertions: 9a free fingers red `9940914` green `8e62e46`; 9b progress and hint red `4e67d44` (`[- | - | -]`) green `8fba014`, also pinning `fprintd-enroll` argv `-f left-thumb me`; 9c completion red `d0b80e5` (`[Right index], panel shown`) green `692248b`. Security probes 11/11. A fake enroll's `sleep` outlives `qs` for a few seconds (test-only, harmless).
- L12 (pair): test 10 red `759410a` (`[Right index], panel shown`) green `6386d33`; test 11 red `356d70f` (`no Cancel while enrolling`) green `f6ba605`, also checking the stopped fake never stored the finger; test 12 red `28b8c8e` (`no remove action for Right index`) green `afa35e2`, pinning `fprintd-delete` argv `me -f right-index-finger`. Security probes 14/14. The automated list is done; test 13 is manual.
- L13 (verifier: FAIL): criteria 2 and 3 pass their automated part; criterion 1's lock part had a trivial green: `lock-security-switch` read the new `Lock.fingerprintEnabled`, not the `LockPam` that listens, so cutting `Lock.qml`'s `fingerprintEnabled: root.fingerprintEnabled` left it green. Refs and HEAD unchanged across the run. Non-blocking notes: the enroll Process has no `onExited`, so an `fprintd-enroll` that exits without a result line leaves the panel up until Cancel; `removeFinger` accepts any name `fprintd-list` reported (still argv only); no "no reader" handling (not in the criteria); a failed `security.json` save still drives this session's lock.
- L14 (correction batch): new probe `lock-security-listen` reads the lock's PAM listener through `Lock.auth`. Red `ee75eab` (`on none, off none`), green `d6ef4b1`; mutation check: with the PAM wiring cut it fails with `on false, off false`. Lock probes 21/21. `lock-security-switch` stays as is.
