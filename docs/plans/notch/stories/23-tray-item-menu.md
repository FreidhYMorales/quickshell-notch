# Story 23: Tray item menu

## Story

23. As a user, I want a tray icon's own menu on right click so that I can use its actions without restoring its window. Requires: #22

## Acceptance criteria

- [ ] Given the tray row is open and an app provides a menu, when I right-click its icon, then the notch expands horizontally and vertically to show that menu below the still-visible icons and a separator, sized to its contents up to half the height of that screen.
- [ ] Given an app's menu is open, when I choose an enabled action, then the app receives it; separators, checked states and disabled options are shown correctly, and disabled options cannot be activated. When I enter a submenu, its options replace the current list and I can return to the previous menu.
- [ ] Given a menu has more options than fit within the height limit, when I scroll the options, then I can reach all of them, an indicator shows there is more content, and the icons, separator and submenu back control remain visible.

## Plan

- Expose the selected app's menu and its current entries, including their states and actions.
- Expand the existing workspace notch around the tray row and menu, respecting the screen-height limit.
- Navigate submenus within the notch and scroll only the options when necessary.
- Preserve existing tray activation, row switching, workspace priority and monitor behavior.
- Verify menu interactions and overflow with a simulated tray app and check the appearance with real apps.

## Out of scope

- Replacing Quickshell's undetectable missing-icon placeholder (story #24).
- Changing left-click activation, tray overflow, or adding keyboard access to the tray row.
- Adding a separate floating or cascading submenu window.

## Suggestions (your call)

- The existing workspace surface is limited to its fixed slot height; accommodate the expanded menu without changing other notch surfaces' behavior.

## Size

normal
Risk: item 6 (visual fit and live app menu behavior require manual verification)

## Log

- L1 request: Load the `flow-story` skill and follow it. 23
- L2 presentation: user requested the notch expand horizontally and vertically, keeping the icons above a separator and the app's options below; its size follows the menu.
- L3 navigation: user approved replacing the current options with submenu options and providing a way back.
- L4 overflow: user approved a scrolling options list with an indicator, keeping the icon row and submenu back control visible; the maximum notch height is half the screen height.
- L5 assumptions for approval: an app without a menu does not open an empty menu; leaving or dismissing the menu returns to the existing tray behavior; long labels remain usable within the available screen width.
- L6 approval: user approved the story and its assumptions.
- L7 pair paused: the existing simulated tray item provides no DBusMenu; adding a menu fixture and the first surface test together exceeds the step-size stop rule. Awaiting approval to prepare and verify the fixture as a smaller separate step before the first red/green cycle.
- L8 fixture: user approved preparation. `383ad07`/`779860e` verify an advertised menu path; the simulated item does not yet provide menu entries. `6be9e5f` adds a test for one Open entry and fails as expected with missing GetLayout. Two implementation attempts failed: Quickshell crashed deserializing the returned layout, then the retry timed out. The fixture change remains uncommitted and the red marker remains active; stop rule requires user direction.
- L9 safety: the second crash relaunched the user's primary shell. `fbb5fc8`/`3ff3a4c` verify and disable crash handling in the tray runner using a simulated executable; no real shell was launched for that check. Other test entry points remain unprotected; changing existing tests requires user direction. The original fixture change and red marker remain.
- L10 diagnosis and resume: user approved further investigation and the fixture correction. A private-bus Qt probe found the child dictionary was `a{ss}` instead of `a{sv}`; the corrected fixture makes the committed Open-entry test pass. The fixture remains uncommitted and the red marker active pending the full check and tamper check.
- L11 UI red/green paused: fixture fix `4312512` and fixture registration `d939339`/`0362fb1` passed `make check`. UI test `0acfe4b` failed as expected: Open not shown after right click. The uncommitted implementation was tried twice; both runs lacked the expected success message without a diagnostic indicating whether setup or interaction failed. Stop rule: no further attempts without user direction; red marker remains active and production changes remain uncommitted.
- L12 UI green: a temporary uncommitted probe (removed) showed the shell quit silently inside `Visual.findImage` with a `TypeError`: the new `QsMenuOpener` child exposes `children` as a menu object, not a list, so the shared traversal helper crashed before the click. Fixed the helper, not the test (`6067a2e`); the red evidence stays `0acfe4b`, taken before the implementation existed, and the committed test was never edited. `e027f60` added the right-click handler, the opener and the option column; the probe then found Open after the click and the committed test passed. `make check` passes, tamper check empty. Note: the fixture does not implement the DBusMenu `Event` method, so Quickshell logs a harmless `UnknownMethod` warning when it reports the menu as opened.
- L13 sizing (`5b78e50`): the simulated menu now takes `NOTCH_TEST_MENU_COUNT`. Two cases cover the height limit on this 900 px screen (cap 450): two options grow the notch past the idle 44 px and stay below the cap; eighty options stop exactly at 450. The growth and cap already existed in `e027f60` because the first test needed the surface to grow, so both cases passed at once; a temporary removal of the window minimum height made both fail with "notch did not grow past 44", proving the assertions are real. The fixture default stays one `Open` entry.
- L14 registration (`de2bedd`/`23a648f`): `make check` now runs `tray-menu-open` and `tray-menu-size`; the new registration test and the full check pass and the tamper check is empty.
- L15 action (`4639633`): the simulated menu now implements the DBusMenu `Event` method and prints `FAKE_MENU_EVENT <item> <event>`. Red: clicking the option text printed only `opened`/`closed` for the root, never `clicked` for item 1. Green: each option text carries a `MouseArea` that calls `modelData.triggered()`. The probe asserts `FAKE_MENU_EVENT 1 clicked`. Registered in `make check` (`22318f2`/`e06e9bd`); full check green, tamper check empty.
- L16 disabled (`16e7aee`): the fixture serves a second, disabled `Disabled` entry behind `NOTCH_TEST_MENU_DISABLED`. Red: it used the enabled colour. Green: options take `scheme.muted` when disabled and their `MouseArea` is disabled. Removing the `enabled` line sent `FAKE_MENU_EVENT 2 clicked`, proving the no-action assertion is real. Registered in `make check` (`ca757c1`/`c296c60`).
