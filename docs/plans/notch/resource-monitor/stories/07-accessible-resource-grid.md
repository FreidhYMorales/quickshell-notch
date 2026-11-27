# Story 07: Keep the resource grid accessible

## Story

07. As a user inspecting resources, I want a complete keyboard- and pointer-accessible grid in a monitor-bounded viewport so that every resource remains reachable.

## Acceptance criteria

- [ ] Given the resource view contains more content than fits on the current monitor, when it opens, then every resource card remains in the same view inside a fixed viewport and the Control Center stays within the monitor's available height and safe margins.
- [ ] Given the resource grid is longer than its viewport, when I scroll with the pointer wheel or drag the content, then the grid moves within the clipped viewport and its first and last cards can be brought into view without the outer panel growing.
- [ ] Given the resource view is open, when I navigate with Tab or Shift+Tab, then focus can reach the Back control and every resource card, the focused card is brought into view, and Escape or activating Back returns to the Control Center root.

## Plan

- Keep every resource card in one complete grid and bound the outer panel to the available monitor height with safe margins.
- Put the grid in a clipped viewport that scrolls independently of the fixed panel.
- Support pointer wheel/drag scrolling and keyboard traversal through Back and the cards.
- Keep the focused card visible during keyboard navigation and preserve return-to-root behavior.
- Verify bounds, pointer scrolling, keyboard reachability, and focus visibility with QML probes on a constrained monitor fixture.

## Out of scope

- Adding or changing resource metrics, telemetry sources, or polling lifecycle.
- Hiding resource groups behind tabs or changing the compact summary and central notch.
- Changing the content or behavior of individual resource cards beyond making them reachable by keyboard.

## Suggestions (your call)

- `NotifSubpage.qml` already uses a clipped `Flickable` and exposes `focusFirst()`; it is a concrete pattern for the resource viewport and its keyboard entry point.

## Size

normal
Risk: none

## Log

- L1 request: si
- Confirmed keyboard navigation: Tab/Shift+Tab through Back and each card, with the focused card scrolled into view; no arrow-key grid navigation.
- Approved test list: bounded complete grid (integration); pointer wheel/drag scrolling (integration); Tab/Shift+Tab reachability, focus visibility, and return-to-root (integration).
- Safety net before UI changes: `node --test --test-concurrency=1 tests/sysStats.test.mjs tests/qml/controlcenter-network.mjs tests/qml/controlcenter-resource-back.mjs tests/qml/controlcenter-resource-escape.mjs tests/qml/controlcenter-keyboard.mjs` passed (19/19).
- Bounded-grid integration test `2758cbf` is red for the expected reason: `resource view: clipped scrolling viewport is missing or does not contain the complete grid`; the accompanying `tests/sysStats.test.mjs` passed 15/15.
- Paused before production changes under stop rule 5: formatting expanded the test step to 64 added lines across two files, exceeding the approximately 50-line step budget. No production code changed; the red marker records this test commit.
- User authorized continuing with the committed test. Production attempts 1 and 2 both left `controlcenter-resource-bounds.mjs` red at `resource view: resource cards are missing from the complete grid`; `tests/sysStats.test.mjs` remained 15/15. Both QML runs also logged `TypeError: Cannot read property 'height' of undefined` at `ControlCenterSurface.qml:219`.
- Stopped after two failed green attempts under stop rule 4. No production commit was made; at that pause, the experimental `ControlCenterSurface.qml` diff remained uncommitted with the marker on `2758cbf`.
- User authorized a bounded fixture diagnosis. A runtime probe confirmed Quickshell's `QuickshellScreenInfo` exposes `height` (900 in this run), while `availableGeometry` and `geometry` are undefined; the actual UI label is `Load avg 1/5/15 min`, not `Load average`.
- Authorized fixture correction `7264676` uses `screen.height`, the configured `Layout.ccPad` margin, and the actual load label. The corrected test is red for the intended missing-viewport behavior; `tests/sysStats.test.mjs` passes 15/15. The experimental production edits were removed before establishing this valid red.
- Pointer-scroll test `a988e9d` is red: `resource view: drag did not scroll the grid`; its one-file QML fixture is run directly from `make qml-test`, keeping the step to 49 added lines. `tests/sysStats.test.mjs` passes 15/15.
- An exploratory change to parent the resource column directly to `resourceViewport.contentItem` did not address the apparent failure and was reverted.
- Authorized pointer-event diagnosis found the test's failure was in its assertion: QtTest `tryVerify()` returns no useful boolean, so negating its return value always failed even when `contentY` had moved. A -90px drag reliably changes `contentY`; with an explicit post-wait value check, both drag and wheel probes pass against the original implementation. No production change is needed for this step; revert the exploratory `parent` adjustment.
- Keyboard-focus probe `3bab392` went red because the resource view's Back item and its 13 rows were not all tab stops. `29ee45c` makes Back and each row keyboard-focusable, shows focus through the palette, scrolls a focused row into view, and makes Enter/Space activate Back. The integration probe verifies Tab and Shift+Tab traversal and per-row viewport visibility; the existing Escape probe covers return to root. Focused resource/control-center tests pass 19/19; `make check-fast` passes with existing qmllint warnings.
- Full `make check` initially failed in unrelated `recording-*.mjs` tests launched together (6 failures, then 7); the initially failing cases passed serially. With user authorization, `b80f84b` serializes only that recording probe group, matching the other keyboard-sensitive QML groups. Final `make check` passes, including 47/47 recording tests, focused Control Center/resource probes, and smoke.
- Story implementation commit: `29ee45c`. Risk: none. Manual check: none required; monitor bounds, pointer wheel/drag, keyboard traversal, focus visibility, and Escape return-to-root are covered by QML integration probes.
