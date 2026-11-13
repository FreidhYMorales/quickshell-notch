# Story 29: Keybinds command view

## Story

29. As a user, I want the keybinds command view so that I can access my keybinds from the launcher. Requires: #26.

## Acceptance criteria

- [ ] Given the launcher is in command mode, when I activate Keybinds, then the notch lists my live Hyprland shortcuts with their key combination and description, and shows one clear line instead of an empty or broken view when that list cannot be read.
- [ ] Given the keybinds view, when I type, then rows narrow to those whose keys or description match, an unmatched query shows the existing "No matches" line, clearing restores the full list, and the notch keeps its fixed height.
- [ ] Given the filtered keybinds view, when I move with the arrows or j/k, hover a row or scroll with the pointer, and press Esc, then the highlighted row stays in sight and Esc returns me to the command list with app search and the other commands unchanged.

## Plan

- Read Hyprland's own bind registry each time the view opens and keep only binds that carry a description, so the cheatsheet never drifts from the dotfiles.
- Keep the registry-to-row mapping (modifier mask to `Ctrl + Alt`, the description filter, the match rule, unreadable-registry fallback) in pure logic with tests; the process read stays a thin service.
- Add a Keybinds sub-view to the launcher's command flow with the same open, back and close contract as Theme, plus its own search line above the rows.
- Render each row as the notch's key pill plus description, keep the height fixed and scroll the filtered rows inside it.
- Tests: pure mapping, filtering and fallback, the reducer's sub-view transitions, and a launcher probe with a fake bind registry for rows, filtering, "No matches" and Esc.

## Out of scope

- Editing, adding or removing binds, and running a shortcut from the list.
- Maintaining a hand-written cheatsheet or copying `keybinds.lua` into the notch.
- The screensaver, security and webapp command views (#35–#37).

## Suggestions (your call)

- The Theme view's row pattern already does what this needs (named rows, pointer tap, arrows, Esc handler); copying it keeps the command views consistent instead of inventing a shared component for two users.
- The old bar filtered text across modifiers, key and description; matching on the whole combined label keeps one rule for typing and avoids ranking noise.

## Size

normal
Risk: none

## Log

- L1 request: Load the `flow-story` skill and follow it. 29
- Assumptions: the view reads Hyprland's live registry, so binds without a description stay hidden as in the old bar; rows are read-only; the search field lives inside the view and the notch height does not follow the filtered count.
- L2: User chose type-to-filter over scroll-only, given 46 described binds against roughly 8 visible rows.
- L3 build so far (branch `story/29-keybinds-command-view`): 3a83462/42facc8 (registry mapping), 8263619/bd697b2 (unreadable registry), 8b74b1c/385f0fa (query filter), c52f80a/2ca9a4b (sub-view transitions), 15e2a01/93f0ed0 (service reads `hyprctl binds -j`; `make check` needed a Makefile line to run the probe), 7ab927f (view probe, red).
- L4 stop at step 5b: the new view makes `tests/qml/launcher-command-activate.*` fail. That test (story 26) pins activating Keybinds as an unavailable command: the launcher stays open and shows "Not available yet". No launcher command is unimplemented any more, so its premise is gone. An existing test would change, so work stopped before touching it. Uncommitted: `CenterKeybinds.qml` (new), `CenterLauncher.qml`, `Layout.qml`, `Strings.qml`, `center/qmldir`; `make check` fails on that test only.
