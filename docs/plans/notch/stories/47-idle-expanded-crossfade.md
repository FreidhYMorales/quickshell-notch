# Story 47: Idle/expanded cross-fade

## Story

47. As a user, I want a cross-fade between idle and expanded notch content so that opening and closing the expanded view feels smooth.

## Acceptance criteria

- [ ] Given the idle centre notch, when I hover it and it expands, then the idle content fades out while the expanded content fades in over the same time the shape takes to grow, instead of swapping in one frame.
- [ ] Given the expanded centre notch, when the hover leaves and it collapses, then the expanded content fades out while the idle content fades back in over the shape's shrink, and a hover that comes back mid-fade reverses it from where it is, with no jump.
- [ ] Given a toast, the power menu, the launcher or polkit takes the notch, when it opens or closes, then it behaves as today: neither the idle nor the expanded content shows through it.

## Plan

- Replace the instant idle/expanded swap with an opacity driven by the expanded state, animated with the existing shape-morph timing token so content and shape move together.
- Each layer stays rendered only while its opacity is above zero, so a fully faded layer still takes no input and costs nothing.
- The other modes (toast, power, launcher, polkit) keep their instant switch and hide both layers at once.
- Tests: a QML probe that after expanding and settling the idle layer is invisible and the expanded one opaque (and the reverse on collapse), and that while the launcher is open neither layer is visible. Smoothness itself is checked manually with `qs -c notch`.

## Out of scope

- Fading the toast, power, launcher, polkit or month views (the month already has its own staggered morph from story 38).
- Changing the shape's size animation, its timings or easing.
- The workspaces, OSD or control-center notches.

## Suggestions (your call)

- Assumption to confirm: a true overlap (both layers half-visible mid-morph). If the overlap looks cluttered, the clock card's approach (one fades in each half, `Timings.calendarMorph` comment) is the fallback.

## Size

small
Risk: none

## Log

- L1 request: "/flow:story 47"
