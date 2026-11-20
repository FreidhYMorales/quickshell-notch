# Story 53: Workspace icon fly

## Story

53. As a user, I want an app icon to fly between workspace slots when I move its window so that I can follow the move. Requires: #52

## Acceptance criteria

- [ ] Given both workspaces are slots in this monitor's strip, when I move a normal window from one to the other, then the strip reveals and the app's icon slides from the source slot to the destination slot, after which both slots show what they show today for the new layout.
- [ ] Given I move a normal window to a special workspace, when the strip reveals, then the app's icon fades out at its source slot instead of flying.
- [ ] Given the source or the destination is not a slot in this strip (another monitor, or beyond the shown slots), or the strip shows the tray row or a pinned special, when the window moves, then nothing flies and the strip behaves as today.

## Plan

- A pure function turns a move event and the current strip into a flight (from slot, to slot, app) or a fade (from slot, app), or nothing when either end is missing.
- The workspaces surface reacts to the existing move events (today it only reacts to opens), reveals as it already does, and runs one flight at a time; a new move replaces the one in progress.
- The flying or fading icon is drawn above the slots, reusing the slot's icon look, with the existing animation timing tokens.
- Tests: unit tests for the flight decision (both ends shown, to special, missing end, tray or pinned row); a QML probe that emits a move and finds the flying icon between the two slots mid-flight and gone after it.

## Out of scope

- Flying across monitors (assumption: each monitor's strip only animates moves within itself).
- Changing which events the service detects, its debounce, or the open-window flash.
- Animating workspace switches or window opens and closes.

## Suggestions (your call)

- Assumption: the flight lasts `Timings.animSlow` (400 ms) so it is easy to follow; the reveal timer already keeps the strip up longer than that.

## Size

normal
Risk: none

## Log

- L1 request: "/flow:story 46"
- L2 approved as #46, then split: the user asked that the active slot show its app icon tinted with the palette (new #52, built first) so the flight reads as "where I am -> where I go". Renumbered to #53, Requires: #52.
