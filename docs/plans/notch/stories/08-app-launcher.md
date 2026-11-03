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
- L2 test list approved; added mid-run with approval: 8b (shapeFor sizes the launcher), 8c (viewFor exposes query/index); step 9 split into 9a (view) / 9b (typing, keys, IPC).
- L3 build: test→code pairs 93b0726→e40693b, 485be46→52441aa, 39876e2→3de6e12, 4f80065→814c7bf, 51eaf9f→ce0479b, 4473b99→5ffd322, 382f7d3→612bb53, 9869270→7c0ea64, 39a322e→dacd203, 14b3130→d74ddfa, fb11c62+7373c42→93998ef, 53234a2→d536378, 819fbdb→00b737f; pinning test f7347ad (empty result, already green; mutation of the filter made it fail); 5a7a623 runs launcher probes serially (parallel probes fight over the exclusive keyboard).
- L4 decisions: generic name/keywords match only on prefix or word start and rank after name matches; query/index live in the keyboard state, added on first event; viewFor adds them only in launcher mode; launch via DesktopEntries.byId(id).execute(), logged only under NOTCH_LAUNCH_DRY_RUN=1 or smoke. User approved relaxing 9b's probe to compare the store query with the field text (live keystrokes leak into exclusive-keyboard probes).
- L5 manual check (user, `qs -p shell/shell.qml`, `qs -p shell/shell.qml ipc call launcher toggle`): works. Fixes from feedback: the centre window was only expandedHeight tall and clipped the launcher (2 rows, no bottom corners) → minHeight follows the launcher (773dffa); description removed, hover/click rows, scroll follows selection; then text/icon +20% (18 px / 29 px), even padding on all sides (height from content), search glyph by mode (magnify; pound reserved for #09 commands), divider, selected row scales 1.1, 5 visible rows (6584f09).
- L6 evidence: make check green at 6584f09 (unit 491 pass, launcher probes 4/4 serial, smoke loaded).
- Risk: none
