# Story 26: Launcher command browser

## Story

26. As a user, I want to browse and search launcher commands with a description pane so that I can understand the available setup actions. Requires: #08

## Acceptance criteria

- [ ] Given the app launcher is open, when I enter `>`, then it shows Wallpaper, Theme and Keybinds as commands instead of apps and replaces the search icon with `#`; removing the prefix returns to app search and its search icon.
- [ ] Given command mode is open, when I type after `>` or move the selection with the keyboard or mouse, then the list filters, the selected command's description is shown, and an empty result shows "No matches".
- [ ] Given a command view is not yet implemented, when I select or try to open that command, then it is clearly marked unavailable and no setup change occurs; Esc closes the launcher from command mode.

## Plan

- Extend launcher search and selection to distinguish app and command modes.
- Present command results and the selected description in the notch, preserving keyboard and mouse navigation.
- Indicate unavailable command views without executing an action; retain existing app launcher behavior.
- Cover mode changes, filtering, selection and unavailable actions with tests.

## Out of scope

- Implementing wallpaper, theme or keybinds views; these are stories 27–29 and each needs its own mini-plan.
- Screensaver, security and webapp command views.
- Changing wallpaper, theme or keybind settings.

## Suggestions (your call)

- The current launcher already keeps query and selection in its center state and supports keyboard and mouse selection; extend that behavior rather than adding a separate launcher.

## Size

normal
Risk: none

## Log

- L1 request: Load the `flow-story` skill and follow it. 09
- Assumptions: `>` is the leading command prefix; matching is case-insensitive; commands are visible but marked unavailable until their respective views are implemented. Esc closes the launcher because no command view exists yet.
- L2: User approved splitting story 09 into the command browser and three separate command views.
- L3: User approved the story with the addition that command mode replaces the search icon with a command symbol; `#` is proposed, matching the existing launcher mode icon.
- L4: User approved tests for mode and icon, filtering and empty results, selection descriptions, unavailable actions, Escape, and app regression. Existing launcher QML safety net: 4 passed. First test needs splitting into smaller TDD steps before implementation.
- L5: User approved retrying in a separate worktree after a committed test formatting blocker. Icon 9d50a16→1b27676, command list 762f770→232fdc9, filtering feb3552→d3c1825, wallpaper description b976533→004f59c, selection c5ad5e8→ea4721f, keybinds 3f9dfe6→a5b2471; no-match regression 6ef518b passed immediately. Each completed step passed make check.
- L6: Unavailable notice probe failed as expected but logged `Apps: launch chromium`, indicating possible live keyboard input in the exclusive-focus probe. Stopped before committing the test or changing production; use a safe dry-run approach before retrying.
- L7: User confirmed no app launched, but the probe captured a live key; approved dry-run protection. Unavailable notice e068697→75d9f17; activation regression f54b567 was green immediately. Both passed make check.
- L8: App-mode return probe passed immediately, but its combined app-and-icon test exceeds the step size limit; left uncommitted pending a smaller split.
