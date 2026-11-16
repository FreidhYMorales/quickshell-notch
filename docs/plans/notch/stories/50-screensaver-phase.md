# Story 50: Screensaver phase

## Story

50. As a user, I want the screensaver phase so that my session locks at my screensaver time showing only my wallpaper, goes black before suspending, and comes back with the lock form on any input. Requires: #30, #31.

## Acceptance criteria

- [ ] Given I have been idle for my screensaver minutes, when that time is reached, then the session locks with the same animation as today and every monitor shows only the wallpaper, with no clock, no password form and no hint, keeping the padlock notch.
- [ ] Given the screensaver is showing, when I move the mouse more than a few pixels or press a key, then the lock form appears with the usual animation and only a correct password returns me to my session.
- [ ] Given I stay away, when my lock minutes pass since the screensaver appeared, then the screen turns pure black (monitors still on, machine awake, session still locked: no DPMS), and the first input paints a black frame and then replays the same animation into the lock form; suspend still fires my suspend minutes after that, and caffeine still stops the whole chain.

## Plan

- Three sequential stages on the idle watchers, still inhibitor-aware and disabled under smoke: screensaver at its minutes, black at screensaver + lock, suspend at the full sum. The stored values and the sums stay as they are; only what each stage does changes.
- A lock request can say it came from idleness, so the lock after its usual morph enters the screensaver state: clock, hint and login panel hidden, wallpaper alone with the padlock notch; a manual lock, the sleep lock and a polkit flow behave exactly as today.
- The first real input leaves that state with the usual transition into the lock form, with the movement threshold the old shell needed so a pointer that merely lands on the surface does not count; no input unlocks without the password.
- The black stage paints the lock surface pure black and keeps the session locked and the outputs untouched; waking paints black first and then replays the existing reveal into the form, so an OLED never flashes the wallpaper or a stale frame.
- Tests: pure stage logic (each stage off at 0, sums unchanged, screensaver before black before suspend) plus QML probes for the three looks (wallpaper only with padlock, pure black with nothing, and the form after input).

## Out of scope

- Choosing a screensaver image other than the desktop wallpaper, and the command view that edits the three times: both are #51. Here the screensaver shows each monitor's own wallpaper.
- Free dismissal without a password during the lock minutes (the old shell's grace): any input leads to the password.
- Turning the monitors off by DPMS, hypridle or any external idle daemon, and any separate screensaver surface, preview button or animation beyond the lock's existing morph.
- The keybinds, security and webapp views (#29, #36, #37).

## Suggestions (your call)

- Use true black (`#000000`, not the theme's dark surface) for the black stage and drop the padlock notch there: on OLED the pixels are off, which is the point, and nothing static stays on screen.
- Reuse the old shell's 4 px movement threshold: a surface that has just gained pointer focus reports the pointer's resting position as movement and would end the phase on its own.
- Replaying the reveal for the wake can reuse the existing morph with its reveal property reset, which avoids a second animation or a second code path in the lock.

## Size

normal
Risk: item 6 (screensaver timing, the black stage and the wake are only verifiable manually on the live session)

## Log

- L1 request: "Load the `flow-story` skill and follow it. 35" (chat in Spanish, story file in English).
- L2 decision (user): #35 covers both the command view and the real screensaver phase, so it splits into #50 (the phase) and #51 (the view); #50 is refined first.
- L3 decision (user): the phase reuses the lock's animation and flow and locks at the screensaver time; it shows the wallpaper (the same as the desktop or another one, as the old config allowed) with no clock and nothing else, keeps the padlock notch, and nothing suspends or turns the machine off until the times are met.
- L4 decision (user): any input while the screensaver shows brings up the lock form as it is today, with no password-free dismissal. The second time is how long the screensaver stays before the screen goes black; the third is the wait before suspending.
- L5 decision (user): the blackening is Quickshell painting a black frame, not DPMS (the screen is OLED); on the first input it paints a black frame and then runs the existing lock animation into the form.
- L6 assumptions: the screensaver shows each monitor's own desktop wallpaper and the choice of another image belongs to #51; the black stage keeps the monitors on and the machine awake with the session locked; the sums stay exactly as #31 defined them (screensaver + lock + suspend).
