# Story 38: Calendar month view

## Story

38. As a user, I want a month view in the expanded notch calendar with week/month scrolling and a jump back to today so that I can look beyond the current week. Requires: —

## Acceptance criteria

- [ ] Given the expanded notch, when I click the clock card's week strip, then the notch grows downwards and the whole notch shows a Monday-first grid of the current month with today marked and days outside the month dimmed, and its back control returns to the media and week view.
- [ ] Given the week strip or the month view, when I scroll, then the strip moves by whole weeks or the grid by whole months with the month and year shown, and when I click the clock (week view) or the month title (month view), then it jumps back to today.
- [ ] Given I browsed to another week or month or left the month open, when the expanded notch closes and opens again, then it shows the media and week view centred on today.

## Plan

- Pure calendar logic first: a month grid (Monday-first, leading and trailing days of the neighbouring months, today flag) and week/month offset stepping on plain y/m/d fields, like the existing week strip.
- The centre notch state gains a calendar sub-view (week or month) and an offset; opening and closing the expanded notch resets both, so a browsed date never survives a close.
- A month shape for the centre notch: its own height token so the window grows downwards while the month shows, in the same way the launcher and power menu already size the notch per mode.
- The month view replaces the whole expanded content (media and clock) with a title, weekday header, the grid and a back control; scroll on the strip and on the grid drives the offset; clicks on the clock and the title reset it.
- Tests: unit tests for the grid and stepping, reducer tests for the sub-view and resets, and QML probes for open/back, scroll and today; the look is a manual check.

## Out of scope

- Calendar events (khal + vdirsyncer): a LATER item in the plan.
- Keyboard navigation of the calendar; it is a hover surface.
- Changing the week strip's look, radius or the idle notch.
- Locale-specific week starts or month names: Monday-first and the existing English names stay.

## Suggestions (your call)

- Reuse the old shell's `CalendarCard` grid rules (Monday offset `(first + 6) % 7`, neighbouring-month fill), as the plan's reuse map lists it.
- The week strip already rolls over at midnight through `Time`'s date fields; deriving the month and the offset base from the same fields keeps the month view correct across midnight too.

## Size

normal
Risk: none

## Assumptions

- The month opens from a click on the week strip; the clock keeps its plan role (click → today).
- The month view keeps the notch open while hovered, with the same close debounce as the expanded view.
- Scrolling down moves forward in time (next week / next month).
- With a player, the media column comes back unchanged after back; without a player, the narrower clock-only notch comes back.

## Log

- L1 request: "/flow:story 38"
- L2 resolution: the month grid does not fit the 112 px expanded notch, so opening the month grows the notch downwards and the month fills the whole notch, with or without a player ("si, que crezca hacia abajo y ocupe todo el notch").
