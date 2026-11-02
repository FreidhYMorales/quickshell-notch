# Story 23: Tray item menu

## Story

23. As a user, I want a tray icon's own menu on right click so that I can use its actions without restoring its window. Requires: #22

## Acceptance criteria

- [ ] Given the tray row is open and an app provides a menu, when I right-click its icon, then the notch expands horizontally and vertically to show that menu below the still-visible icons and a separator, sized to its contents up to half the height of that screen.
- [ ] Given an app's menu is open, when I choose an enabled action, then the app receives it; separators, checked states and disabled options are shown correctly, and disabled options cannot be activated.
- [ ] Given a menu has more options than fit within the height limit, when I scroll the options, then I can reach all of them, an indicator shows there is more content, and the icons and separator remain visible.

## Plan

- Expose the selected app's root menu and its current entries, including their states and actions.
- Expand the existing workspace notch around the tray row and menu, respecting the screen-height limit.
- Scroll only the options when necessary.
- Preserve existing tray activation, row switching, workspace priority and monitor behavior.
- Verify menu interactions and overflow with a simulated tray app and check the appearance with real apps.

## Out of scope

- Replacing Quickshell's undetectable missing-icon placeholder (story #24).
- Changing left-click activation, tray overflow, or adding keyboard access to the tray row.
- Adding a separate floating or cascading submenu window.
- Navigating submenus inside the notch (deferred to story #25, blocked by Quickshell's submenu loading).

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
- L17 separator and check (`a85becf`): `NOTCH_TEST_MENU_TYPES` serves Open, a separator, a checked option and an unchecked one. Red: the separator was not drawn. The probe first asked `Strings.glyphCheck` in the probe file, which resolves to `undefined` there because the config singletons are not exposed to the root config without a qualifier; `findHorizontalDivider` then found the new 308 px rule but the run quit silently on the glyph read. The probe now reads the check mark structurally (exactly one extra short text beside the checked label, none beside the unchecked one) in `72a2b56`, keeping the same assertions; the earlier buggy `countText` helper was removed. Green: each entry is a row; separators draw a divider across the option column, checked options show `Strings.glyphCheck` and rows reserve the glyph width so labels line up. Hiding the separator failed with "separator not drawn as a divider"; showing every glyph failed with "unchecked option marks: 1". Registered in `make check` (`37d7f71`/`8b8babc`). The option column now takes `Layout.cornerMaxWidth - 2*wPad - ear` (308 px) while a menu is open so separators span the body.
- L18 hover paused: the user verified the text changes colour visually. The committed test compared a live QML colour reference against itself after hover; taking an independent `Qt.rgba` snapshot makes the modified probe pass. An earlier explanation attributing the failure to a rebuilt menu was unverified. The probe and production changes remain uncommitted; the red marker remains active. The strict TDD stop rule prohibits modifying the committed test to reach green, so user direction is needed before proceeding.
- L19 hover resumed: user explicitly approved correcting the defective committed probe. `46c5ed9` snapshots the colour; disabling the hover colour made it fail, and `9a78d88` passed it. `make check` passed after one intermittent long-menu size failure (the isolated retry passed); the corrected probe was unchanged after its commit.
- L20 closing and registration: `9618264`/`6c84eec` toggle the selected tray menu on a second right click; `0f6f1b5`/`c5a1312` clear it when the notch closes. `013bdab`/`e8caed9` register the look, hover, toggle and leave probes in `make check`, which passes.
- L21 scrolling paused: the new uncommitted scroll probe fails as expected (`Item 30` remains at y=730 after wheel events). The proposed test step exceeds the roughly 50-line stop limit; no scrolling implementation was added. Awaiting user direction on splitting the probe into a smaller reusable setup and the scroll assertion before continuing.
- L22 scrolling resumed and paused: user approved splitting setup. `a6cf12d` adds reusable setup and red test `73545fa` still reports y=730. Two uncommitted implementation attempts (a Flickable, then a WheelHandler) both moved the last option only to y=658, still outside the viewport. Strict TDD stops after two failed attempts; the production change and red marker remain for investigation after user direction.
- L23 investigation: user approved diagnosis. A temporary copy of the probe passed with 50 ms between wheel events; the committed probe sends all 40 synchronously, and the Flickable only moves 72 px under that burst. Instrumentation showed the added WheelHandler did not receive the events; it and the temporary probe were removed. The uncommitted Flickable remains. Correcting the committed probe requires user direction under Strict TDD.
- L24 overflow: user approved correcting the probe timing (`56036e8`). The corrected probe failed with Flickable interaction disabled and passed with scrolling (`c23fe8c`); icons remain fixed. `018c7bf`/`1abdbc7` add the more-options indicator, and `f0f1a02`/`d97b29f` register both probes. `make check` passes.
- L25 scope: user approved deferring submenu navigation to a separate story blocked by Quickshell's submenu loading; submenus must remain inside the notch, never in floating windows.
- L26 independent verification: FAIL. The required fixed horizontal separator between tray icons and menu options is missing; horizontal expansion and the fixed separator need direct coverage. The checked-state probe accepts any short glyph instead of the actual check mark. The verifier also flagged sizing implemented before its test (`e027f60`/`5b78e50`) and a modified check-mark assertion (`d266dfe`/`72a2b56`) as Strict TDD exceptions. Real-app visual verification is still pending. `make check` passed; the story remains open pending corrections and recheck.
- L27 header: `9879cb9`/`8fe1e16` add and verify a fixed divider between the icons and options; `e8bad11`/`2e00467` register its probe. `make check` passes.
- L28 manual verification: user tested the tray and reported that everything works. No particular applications or individual cases were identified; direct coverage of horizontal growth and the exact checked glyph, and the independent recheck, remain pending.
- L29 review coverage: `8d864f1` checks horizontal growth and `ab4a1eb` checks the exact glyph on checked but not unchecked entries. Both behaviors already existed when tested; temporarily forcing the old width and an incorrect glyph made the respective new probes fail, and restoring the implementation made them pass. `73de0d7`/`5c43e62` register both probes; `make check` passes. This additional evidence does not change the historical TDD exceptions recorded in L26.
- L30 independent recheck: FAIL. The fixed header separator now masks the existing app-provided separator probe: it finds the header first, so removing the app separator would not fail that assertion. The verifier requests a separate probe between adjacent menu options, demonstrated failing with only the app separator hidden. C1 and C3 pass; action, disabled, and exact-checkmark probes pass; C2 lacks valid app-separator coverage. The historical TDD exceptions in L26 remain and require an explicit decision. User's manual report was positive but did not identify apps or cases. `make check` passed. Under the review stop rule, the story remains open pending user direction.
