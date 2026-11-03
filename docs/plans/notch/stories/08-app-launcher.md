# Story 08: App launcher

## Story

08. As a user, I want an app launcher that morphs out of the centre notch so that I can find and open apps from the keyboard.

## Acceptance criteria

- [ ] Given the launcher is closed, when the `launcher` IPC target is called, then the centre notch of the focused monitor morphs into a search field with keyboard focus and a list of apps (icon, name, short description); calling it again or pressing Esc closes it.
- [ ] Given the launcher is open, when I type, then the list narrows to ranked fuzzy matches (name prefix first, then word starts, then any in-order match), the first result is selected, arrows move the selection, and "No matches" shows when nothing fits.
- [ ] Given an app is selected (keyboard or mouse hover), when I press Enter or click it, then the app starts and the launcher closes.

## Plan

- Reuse the existing centre reducer: `LauncherToggle` and the keyboard owner already exist; add the query and selection to the launcher keyboard state, plus close-on-launch.
- A pure ranking function takes the app list and the query and returns the ordered matches; fully unit-tested.
- An apps service exposes the visible desktop entries (no-display entries hidden) and launches one through `DesktopEntry.execute()`.
- A launcher view inside the centre notch paints the field, the list, the selection and "No matches", with the same morph animation as the power menu; exclusive keyboard focus only while open.
- An IPC handler `launcher` (skipped under `Flags.smoke`) toggles it on the focused monitor; sizes, row count, timings and strings live in `shell/config/`.

## Out of scope

- Commands (`>` prefix), the description pane and command views (story 09).
- The Hyprland keybind itself (story 14, cutover); exercised here with `qs -c notch ipc call launcher ...`.
- Ranking by usage frequency or history.
- The blinking unread dot while open (already done in story 02).

## Suggestions (your call)

- Keep `query` and the selected index in the reducer's `keyboard` state (as power keeps `sub`) so typing, moves and launch are unit-testable without QML.

## Size

normal
Risk: none

## Log

- L1 request: /flow:story 08
- Assumptions: matching is case-insensitive on the app name, falling back to generic name and keywords; the empty query lists all apps alphabetically; arrows only (no hjkl, since letters type); launch via `DesktopEntry.execute()` rather than the Hypr dispatch wrapper; the list shows a fixed number of rows and scrolls.
