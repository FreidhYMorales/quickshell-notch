# Story 48: OLED pixel shift

## Story

48. As a user, I want the idle content to shift by one pixel every few minutes so that the screen is less prone to OLED burn-in.

## Acceptance criteria

- [x] Given the idle centre notch, when a shift interval passes, then its content (rings, date, time, side layer, dots) moves by exactly one pixel to the next spot of a fixed 2x2 cycle (home, right, right+down, down, back home), so it is never more than one pixel away from home on either axis.
- [x] Given the content has shifted, when I look at the notch, then the black shape keeps its size and place, and nothing in the content is clipped by the shift.
- [x] Given the expanded view, a toast, the power menu, the launcher or polkit, when they show, then their content is not shifted; back on idle, the idle content sits at the cycle's current spot.

## Plan

- A pure function maps a step count to the cycle's offset; it owns the cycle order and the one-pixel bound.
- A timer on the centre notch advances the step every interval; the interval is a new timing token in config.
- The idle content is translated by the current offset without moving it in the layout, so the notch width and the shape stay as they are.
- Tests: unit tests for the offset cycle (order, wrap-around, bound); a QML probe that the idle content's offset follows one forced step and the shape size is unchanged.

## Out of scope

- Shifting the expanded view, toast, power, launcher, polkit, the workspaces, OSD or control-center notches, or the lock screen.
- Detecting which monitor is OLED: assumption, it runs on every monitor (one pixel is invisible on any screen).
- Making the interval configurable from the UI.
- Animating the shift (it is a plain one-pixel jump; assumption: a slide would be more visible than the jump).

## Suggestions (your call)

- Assumption: interval of 3 minutes ("every few minutes" in the plan), shared by all monitors.
- Keep the step out of `CenterStore`: it is presentation only and nothing else reads it.

## Size

small
Risk: none

## Log

- L1 request: "/flow:story 48"
- L2 test list approved ("dale"); mode B. Tests: `tests/pixelShift.test.mjs` (unit), `tests/qml/idle-pixel-shift` (probe, criteria 1-3).
- L3 commits: f3ec988 test (red: actual `{x:0,y:0}` vs `{x:1,y:0}`) -> c6692ae feat (4-spot cycle, 7/7 pass); eb7ea08 test (red: `step2 0,0`) -> 4e08213 feat (shared `Translate` on every idle child but the shape, 3-minute timer, `Timings.pixelShift`). The expanded-not-shifted check in the probe would pass without the change (expanded is untouched); the step persisting back on idle is the real assertion.
- L4 `make check`: exit 0, `smoke: config loaded`.
- L5 manual: user ran the branch with `qs -p shell/shell.qml`: no clipping seen, shift not noticeable ("dentro de lo que he visto se ve bien").
- Risk: none
