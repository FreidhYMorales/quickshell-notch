# Story 50: Screensaver phase

## Story

50. As a user, I want the screensaver phase so that my session locks at my screensaver time showing only my wallpaper, goes black before suspending, and comes back with the lock form on any input. Requires: #30, #31.

## Acceptance criteria

- [ ] Given I have been idle for my screensaver minutes, when that time is reached, then the session locks with the same animation as today and every monitor shows only the wallpaper, with no clock, no password form, no hint and no pointer, keeping the padlock notch.
- [ ] Given the screensaver is showing, when I move the mouse more than a few pixels or press a key, then that layer contracts into the notch with the lock's own animation while the lock form is already painted underneath, and only a correct password returns me to my session.
- [ ] Given I stay away, when my lock minutes pass since the screensaver appeared, then the outputs turn off (DPMS, the session still locked) over a pure black frame, and the first input turns them back on and contracts that black frame into the notch revealing the lock form, never a desktop capture; suspend still fires my suspend minutes after that, and caffeine still stops the whole chain.

## Plan

- Three sequential stages on the idle watchers, still inhibitor-aware and disabled under smoke: screensaver at its minutes, black at screensaver + lock, suspend at the full sum. The stored values and the sums stay as they are; only what each stage does changes.
- A lock request can say it came from idleness, so the lock after its usual morph enters the screensaver state: clock, hint and login panel hidden, wallpaper alone with the padlock notch and the pointer hidden; a manual lock, the sleep lock and a polkit flow behave exactly as today.
- The first real input ends that state the way the lock ends: the wallpaper layer contracts into the notch with the lock's own morph while the lock form, painted underneath, comes out; the movement threshold the old shell needed keeps a pointer that merely lands on the surface from counting. No input unlocks without the password.
- The black stage paints the lock surface pure black and turns the outputs off (Hyprland's DPMS, no external idle daemon) with the session still locked; the first input turns them back on, keeps the black frame full screen until the outputs report awake (a short delay, so the panel is lit), and only then contracts that black frame into the notch over the already painted lock form, so nothing of the desktop is ever shown and the animation is not spent in the dark. Both the pointer and the outputs are restored when a stage ends, when the session unlocks, and when the shell stops, so nothing stays hidden behind a killed process.
- Tests: pure stage logic (each stage off at 0, sums unchanged, screensaver before black before suspend, what each stage asks of the compositor, when the outputs count as awake) plus QML probes for the looks (wallpaper only with padlock, nothing while the outputs are off, and the form once the layer contracts).

## Out of scope

- Choosing a screensaver image other than the desktop wallpaper, and the command view that edits the three times: both are #51. Here the screensaver shows each monitor's own wallpaper.
- Free dismissal without a password during the lock minutes (the old shell's grace): any input leads to the password.
- Turning the outputs off through hypridle or any external idle daemon, and any separate screensaver surface, preview button or animation beyond the lock's existing morph.
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
- L6 assumptions: the screensaver shows each monitor's own desktop wallpaper and the choice of another image belongs to #51; the sums stay exactly as #31 defined them (screensaver + lock + suspend).
- L7 decision (user, live test): the screensaver hides the pointer; the way into the lock form is the lock's contract — the wallpaper (or the black frame) contracts into the notch while the lock form is already painted underneath, so the desktop capture is never shown; and the black stage does turn the outputs off (DPMS through Hyprland), still with caffeine stopping the chain.
- L8: criteria 2 and 3 and the plan rewritten for L7; the black stage keeps the session locked and lets the compositor bring the outputs back on the input that ends it.
- L9 (live test): the screensaver contraction works, but the black one plays unseen because it starts while the panel is still waking from DPMS. The black stage now keeps its frame full screen after the input, polls `hyprctl monitors -j` until every output reports `dpmsStatus` true (never more than a deadline), and only then contracts, with the padlock notch dropping in with the contraction; `Timings.lockWakeDelay` is the minimum time the panel gets.
- L10 (user): the black frame has to be seen before the screen goes off, and for a second after the input; the screen-off now waits `Timings.lockBlackDelay` (300 ms) behind the painted black frame and the wake holds it `Timings.lockWakeDelay` (1000 ms) before contracting. The run that reported "no animation" was `qs -c notch`, whose dotfiles submodule is a 10 Nov checkout with none of this code; the live test has to run this checkout (`qs -p shell/shell.qml`).
- L11 (live test, root cause): the wake still stayed dark. Hyprland 0.57's Lua bridge parses `hl.dsp.dpms("on")` as a **toggle**: the string is ignored and every call flips the output, so the input that already woke the panel (the compositor's own wake) was turned back off by the shell's `dpms on`, and the retries alternated on/off. `hyprDsp.dpmsExpr` now emits the idempotent table form, `hl.dsp.dpms({action="enable"|"disable"})`, and `Hypr.setOutputsOn` is the only way the lock and the session ask for the outputs. With that, the probe sees `dpmsStatus` true at ~600 ms, the black frame holds until `lockWakeDelay` and the contraction runs in the light; captured mid-contraction to confirm the sheet shrinks and uncovers the already-painted lock form.
