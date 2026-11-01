# Story 22: Tray row in the workspaces notch

## Story

22. As a user, I want the tray icons in the workspaces notch to open on hover so that I can see and restore apps minimised to the tray.

## Acceptance criteria

- [ ] Given the notch is hidden and at least one app sits in the tray, when I rest the pointer in the left corner zone, then the notch slides down showing the Arch icon, a separator and an icon for each tray app; when an icon is detectably unavailable, a generic icon is shown, and when its failure cannot be detected, Quickshell's placeholder is accepted; with no tray apps, hovering that zone opens nothing.
- [ ] Given the tray row is open, when I switch workspace or open a window, then the row stays as it is; given the row is closed, when I switch workspace, then the workspace strip reveals exactly as it does today.
- [ ] Given the tray row is open, when I right-click the Arch icon, then the notch switches between the workspace strip and the tray icons; when I left-click a tray icon, then that app's window comes back on screen.

## Plan

- Expose tray items and activation, with graceful degradation when the tray host is unavailable.
- Choose the visible row and preserve the existing workspace and special-workspace priorities.
- Show tray icons in the existing notch; use a generic icon for detectable failures without guessing whether an ambiguous pixmap is valid.
- Open on hover, switch rows from the Arch icon and activate tray apps on left click.
- Keep visual dimensions and interaction timing in the existing configuration tokens.

## Out of scope

- The tray icon's own menu (story #23); right click on an icon does nothing yet.
- Detecting failures hidden by Quickshell's pixmap provider and replacing its placeholder in those ambiguous cases (story #24).
- A tray row in the control center (dropped on 2026-10-31: the plan now puts the tray in the workspaces notch).
- Notification badges over tray icons, icon-theme overrides, and the OLED pixel shift of this row (polish, #15).
- Overflow when there are more icons than the notch's max width: the row is clipped, no scroll or "more" affordance.
- Keyboard access to the tray row.

## Suggestions (your call)

- `logic/reveal.mjs` is already shared by the strip and both OSDs; the priority rule is most likely one more event in that reducer (row not overridable while open) instead of a second state machine.
- The strip's mask covers only the visible shape; the tray row needs the same treatment so the empty corner stays click-through.

## Size

normal
Risk: item 6 (tray activation, the hover/priority feel and the row's fit on the notch verified only manually with live tray apps)

## Log

- L1 request: Load the `flow-story` skill and follow it. 06
- L2 direction (user, 2026-10-31): the tray moves out of the control center into the workspaces notch — hovering the left zone shows the OSD with the Arch icon, a separator and the background apps; right click on the Arch icon swaps views; the row keeps priority over workspace reveals. Plan updated (`plan.md`: workspaces section, data table, scope, phases 3/5, R1-5) and backlog: `06. [-] split → #22, #23` because this is more than 3 criteria. #22 is the row, #23 the item menu. Assumptions for approval: with an empty tray the row is hidden entirely (no Arch + separator alone); the special workspace pin still beats the tray row; right click on a tray icon belongs to #23, so it does nothing in #22.
- L3 menu placement (user): undecided in the plan, so the item menu (story #23) is written as its own story rather than guessed here.
- L4 pair paused: `dffb631` adds the first test; red was `false !== true`, and the focused test passes with the uncommitted implementation. `make check` fails because the committed test import is not formatted by `deno fmt`; editing a committed test to reach green requires a user decision. The red marker remains in place.
- L5 restart: user approved restarting on `story/22-tray-row-restart`, retaining the old branch as a backup. The stale marker was removed; new red/green pairs are `2ebc79e`/`9b83773`, `8477bee`/`1695cd7`, `2603b0f`/`d54532a`, and `3201ca0`/`59f11b1`; characterization test `84af106` was green without a code change. `make check`: 448 tests pass, smoke loaded. Paused before QML integration: the project has no component-test harness; introducing one requires a decision. No red marker remains.
- L6 probe: user approved a Qt Quick Test harness. Offscreen `qmltestrunner` could not load the actual workspace surface: `module "Quickshell" plugin "quickshell-coreplugin" not found`. A plain Qt Quick component could be tested separately, but that would not exercise the full Quickshell panel; awaiting direction before choosing a test boundary.
- L7 harness: user approved a `qs`-hosted harness and an isolated simulated tray item. Commits `4772db4`, `339b5b2`, `b42e589`, `2fddba4` add and verify the harness; `make check` passes 448 logic tests, 2 QML harness checks and smoke. A real-surface test in untracked `tests/qml/tray-surface.qml` and `.mjs` fails with `tray surface: simulated app is not shown` after loading the fake item. Paused because the test step exceeds the pair step size; split out reusable runner setup before continuing. No production UI was changed and no red marker was created.
- L8 hover restart: after diagnosing the earlier test's startup-gate race, user approved a new branch from `4505ca4`. `991a7b9`/`769d42e` cover hover after startup; `7add87f`/`fcd2e39` cover the empty corner. The pixmap fixture is `eb1589f`; icon test `63a18af` fails before implementation and passes with the uncommitted changes. Full `make check` still fails the pre-existing empty-icon fallback test after two attempts (`tray surface: simulated app is not shown`). Paused per pair stop rule, leaving implementation uncommitted and the red marker active.
- L9 scope change (user): defer reliable missing-icon fallback to story #24. The existing committed fallback test still fails against the uncommitted icon implementation; it has not been modified or skipped.
- L10 fallback direction (user): use normal icons first and a generic icon for detectable missing icons; accept Quickshell's placeholder as a last resort when its pixmap provider does not expose the failure. Menus and activation remain available. The committed initial-fallback test conflicts with this revised scope and remains unchanged.
- L11 refinement: user asked to reopen story 22 with the new fallback decision. Criteria and scope updated for approval; no committed test or production code was changed during refinement.
- L12 approval: user approved the revised story, including the generic fallback for detectable failures and Quickshell's placeholder as the accepted last resort for undetectable failures.
