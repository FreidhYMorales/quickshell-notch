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
- L5 correction: user approved moving the new security cases into a separate file; `tests/webapp.test.mjs` is unchanged. `f2125b6` records two red tests: name control characters and URL whitespace were accepted. The tentative fix passes both, but `make check` fails `fmt-check` because the committed test needs formatting. The production fix remains uncommitted and the red marker remains in place pending a decision.
- L6 correction stop: user approved formatting only; `2af2bb8` applies it without changing test assertions. Both security tests pass with the tentative uncommitted fix. Two full-check attempts failed: first `lint-js` rejected a control-character regex; after rewriting it, `qml-test` failed in `theme-view.mjs` with exit code 2. Per the two-failure stop rule, the code remains uncommitted and the red marker remains in place.
- L7 correction: user authorized another `make check` without investigating Theme; it passed. Security validation was committed as `a17c28c`. Nonzero installer exits now show an error (`42ffed9` red, `7543eba` green); missing-name and invalid-URL messages received green-on-introduction coverage (`ee9e33c`). Full checks passed after both steps.
- L8 external helper check: the real installer produced a desktop entry in an isolated HOME and `desktop-file-validate` passed; the real launcher passed `--app=https://example.com` to an isolated stub. No real browser or network was used; desktop-environment activation and favicon download remain unverified.
- L9 stop: before testing stale URL on reopen, the safety net `node --test --test-concurrency=1 tests/qml/launcher-webapp-back.mjs tests/qml/launcher-command-webapp.mjs` failed in the existing command probe with `webapp view: command missing from the list`; the back probe passed. No new stale-URL test or production change was made.
- L10 correction: the user attributed that failure to unintended keystrokes; the rerun passed. The reopen probe `5d2486d` failed because the URL survived leaving and reopening the form, and `1145d8d` clears it whenever the view becomes visible. Full check passed, tamper diff empty.
- L11 correction: `d4d18da` isolates the missing-helper probe — `qs` is resolved before spawning and the child gets one empty directory as its whole `PATH`, so no system directory can ever supply the helper; a manual contrast run with a stub helper in that directory made the probe fail as expected. `0b75aa7` drops the unused `../../services` import from `CenterWebapp.qml`. Full check passed.
