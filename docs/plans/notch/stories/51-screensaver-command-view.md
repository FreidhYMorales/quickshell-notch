# Story 51: Screensaver command view

## Story

51. As a user, I want the screensaver command view in the launcher so that I can tune the screensaver, lock and suspend times and pick the screensaver wallpaper from the notch. Requires: #26, #50.

## Acceptance criteria

- [ ] Given the launcher in command mode, when I choose Screensaver, then the notch shows the screensaver, lock and suspend times as I have them now, each adjustable from Off (0) to 60 minutes in 1-minute steps, and Esc goes back to the command list.
- [ ] Given I change a time in that view, when I leave idle long enough, then the idle chain follows the new time without restarting the shell, and the value is still there after a restart.
- [ ] Given I switch off "Same as desktop wallpaper" and pick another wallpaper from the view, when the screensaver phase starts, then every monitor shows that wallpaper instead of its desktop one; switching the option back on returns each monitor to its own desktop wallpaper, and the choice survives a restart.

## Plan

- A new "Screensaver" entry in the launcher's command list opens its own sub-view in the centre notch, with the same open/back flow as the other command views.
- The view shows three steppers bound to the idle service and a "Same as desktop wallpaper" switch; with the switch off, a compact wallpaper picker from the existing wallpaper list appears.
- The idle service becomes writable: it saves times and the wallpaper choice to the notch's own idle state file (old field names kept, new fields added) and re-arms its watchers when a time changes.
- The lock's idle stage takes its image from the idle service: the chosen wallpaper when the switch is off, each monitor's own wallpaper otherwise (videos show their thumbnail, as the lock already does).
- Tests: pure logic for clamping the steps, parsing and serialising the new fields with defaults, and which image a monitor shows in the screensaver; QML probe that the view opens, shows the stored times and hides the picker while the switch is on.

## Out of scope

- The old view's Preview button and any separate screensaver surface or animation (excluded since #50).
- Changing what the stages do or how the delays add up (#31/#50 behaviour stays).
- A different wallpaper per monitor for the screensaver, or playing a video wallpaper live during the screensaver.
- The security command view (#36) and any change to how the lock authenticates.

## Suggestions (your call)

- Re-arm a watcher by switching it off and on when its timeout changes: the old shell found that an IdleMonitor whose timeout changes after creation may never fire (see the comment in the idle service).
- Reuse the wallpaper view's thumbnails and the old shell's 4 px move guard for the picker, so a pointer that merely lands on it does not change the selection.

## Size

normal
Risk: item 6 (live idle re-arming and the screensaver image are only checkable in a real idle session)

## Log

- L1 request: "si, arranquemos con la 51" (chat in Spanish, story file in English).
- L2 assumptions (from the old config's ScreensaverForm and #50's out of scope): same three times with 0 = Off and a 0-60 minute range in 1-minute steps; a "Same as desktop wallpaper" switch, on by default, with one chosen wallpaper for every monitor when off; no Preview button.
- L3 (pair): tests 1-2 green (`7022514`/`a82269f` routing, `0089341`/`b413745` stepper clamp). Test 3 red `11f933a`; its uncommitted green code passes the new probe, but the existing probe `launcher-command-description-switch` turns red: the empty command query ranks alphabetically (Keybinds, Screensaver, Theme, Wallpaper, Webapp), so its `LauncherSelect` index 1 is no longer Theme. Stop rule 3: changing that probe needs the user's call.
- L4 (user): approved selecting commands by name in `launcher-command-description-switch` (`c11a9e2`; passes with and without the story code). Test 3 green `1550d6f`; test 4 red `89df9f4`, green `f10b964`; 33/33 launcher probes pass serially.
- L5 (pair, process fault): test 5's red `1b2227b` is invalid evidence: the import edit for `serialiseIdle` silently did not apply, so the failure was `ReferenceError: serialiseIdle is not defined`, not the assertion, and a filtered output hid it. `642c3db` (the `serialiseIdle` implementation) was then committed while that test was still failing. No history rewrite; the fix needs a change to the committed test's import line (expectations untouched), which is the user's call.
