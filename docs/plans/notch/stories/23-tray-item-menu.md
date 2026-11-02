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
