# Story 37: Webapp command view

## Story

37. As a user, I want the webapp command view in the launcher so that I can install a website as a desktop web app. Requires: #26.

## Acceptance criteria

- [ ] Given the launcher is in command mode, when I activate Webapp, then the notch shows a name field, a URL field and an Install action, with Esc returning to the command list and closing the view.
- [ ] Given a name and a URL, when I install, then a desktop entry under that name exists afterwards, opens the site in app mode, and I see the install confirmed.
- [ ] Given an empty field, a name with a path separator or a leading dot, a URL that is not http(s), or a missing install helper, when I install, then no file is written and the status line says which input or helper is at fault.

## Plan

- Add a webapp sub-view to the launcher's command flow, reusing the open, back and close contract the wallpaper and theme views already use, and add its row to the launcher's command table.
- Port the old form: two single-line fields with tab between them, Enter or the action to submit, one status line that changes colour for success and error, and a fixed height so the notch does not resize while typing.
- Validation is pure logic: trim both fields, require a name without separators or a leading dot, require a non-empty URL and prefix `https://` when it has no scheme; only a passing pair reaches the install step.
- Install is one process launch of the existing helper with name and URL as separate arguments (no shell string), exit code 0 confirms, anything else shows the failure, an absent helper shows it as unavailable instead of hanging.
- Tests: pure validation cases (traversal names, missing scheme, empty fields) plus the reducer's webapp open/back transitions; a QML probe for the two fields, the submit action, the status text and Esc.

## Out of scope

- Editing, updating or uninstalling an installed web app, and choosing a custom icon (the favicon comes from the helper).
- Guarding against an existing entry with the same name: the helper overwrites it, and a confirmation flow is not part of this story.
- Making the app launcher re-read `~/.local/share/applications` by force; Quickshell's own desktop-entry model is left to notice the new file.
- The keybinds, screensaver and security views (#29, #35, #36) and any shared form widget beyond this one view.

## Suggestions (your call)

- The command list still shows the "Not available yet" hint for every command except Wallpaper, so with this view everything it lists becomes real: drop that hint here rather than carrying it into a second view.
- Follow the old behaviour of closing the notch shortly after a successful install rather than leaving the form open; a short delay lets the confirmation be read.
- If the helper lives outside this repo on purpose, treat "not on PATH" as a normal state with its own message instead of an error, so a machine without the dotfiles degrades quietly.

## Size

normal
Risk: item 2 (a user-typed name and URL reach an install script that writes a desktop file under a path built from that name and fetches it)

## Log

- L1 request: "Load the `flow-story` skill and follow it. 37" (chat in Spanish, story file in English); answered the helper question: reuse the existing `webapp-install` script.
- L2 verification: FAIL; the security boundary permits control characters in names and whitespace in URLs, a nonzero helper exit has no visible failure, and the real desktop-entry creation and launch remain unverified. The original report's claimed reversed test/feature order conflicts with `git log --reverse`; the Escape test was added after the behavior already existed.
- L3 test decision: the user approved updating the existing command-padding probe to identify the final row by index; recorded in commit `ef8dce8`.
- L4 stop: the pre-verifier ref snapshots under `/tmp/opencode/dbg/` are unavailable, so the required full ref comparison cannot be completed; HEAD remains `ef8dce8`. The author started adding failing security cases to the committed `tests/webapp.test.mjs`; these edits remain uncommitted and need a decision before changing an existing test. No security fix has been made.
