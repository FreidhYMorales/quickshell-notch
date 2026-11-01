# Story 21: Notifications subpage in the control center

## Story

21. As a user, I want a notifications subpage in the control center (full list, per-item dismiss, DND, back) that clears the unread dot so that I can manage my whole history. Requires: #20, #17

## Acceptance criteria

- [ ] Given the control center root, when I click "See all ›" under the inline list or right-click the DND tile, then the notifications subpage replaces the root with a count header, a DND toggle showing the current state, Clear and a Back button, listing the whole session history newest first in the same row style; with no history it shows only "No notifications". Opening it clears the unread dot, and hovering or toggling in the root never does.
- [ ] Given the subpage open with more entries than fit, when I scroll the list, then I reach the oldest entry and the panel keeps its size; when I click a row's ✕, then that one entry leaves the list and the count drops by one while the rest stay, and the notification's app is told it was dismissed.
- [ ] Given the subpage open, when the pointer leaves briefly, then the panel stays on the subpage; when it leaves for longer the panel collapses and the next open starts at the root, and Back returns to the root at once. When I toggle DND there or press Clear, then the root DND tile and inline list show the same result without reopening.

## Plan

- Navigation: the control center gains a two-state stack (root, notifications) held by each monitor's surface; a pure, tested function decides the view and whether closing is immediate or delayed by the longer leave.
- Seen: opening the subpage is the only thing that calls the service's mark-seen; the root stays as today.
- Service: no new store. Per-row dismiss reuses the existing tracked dismiss, so the app hears about it and the close removes the entry; Clear reuses the existing clear-all.
- UI: a "See all" link under the inline list; the subpage reuses the inline row style with a per-row ✕, the existing toggle tile for DND, and a scrollable list capped to a fixed height so the panel never grows past its window.
- Tokens: "See all", "Back" and the longer leave duration in `config/`, list height alongside the other control center sizes.

## Out of scope

- Other subpages (tray, WiFi/Bluetooth, power, profile), the power row, and clicking a row to open its app or run its default action.
- Esc and click-outside closing: a masked hover surface takes neither keyboard focus nor clicks that land outside it, so v1 closes on the longer leave and Back. Keyboard focus stays off so typing in a focused app is never stolen by a hover.
- History across shell restarts and any new persistence.
- The unread dot blink in the launcher (#08).

## Suggestions (your call)

- `NotifSection.qml` already draws the header, divider, empty line and rows with `NotifIcon` and `Strings.toastAppSeparator`; the subpage can share that row instead of a second copy.
- `ControlTiles.tilesFor` already yields the DND tile (lit state and label), so the subpage toggle can reuse `ControlTile` with the same `tileInfo.dnd` entry the root uses; today its right-click is an empty stub waiting for this story.

## Size

normal
Risk: item 4 (one global history, DND and unread flag mutated from every monitor's subpage, plus the delayed close), item 6 (scroll, look and app-side dismiss verified only manually)

## Log

- L1 request: Load the `flow-story` skill and follow it. 21
- L2 assumptions: 21 does not bind Esc or click-outside (the plan's other alternative, a longer leave, is used instead) because the surface is a masked hover window that never takes keyboard focus nor sees clicks that land elsewhere; the full history is reached by scrolling a fixed-height list so the panel keeps its 320px window; Back returns to the root and keeps the panel open rather than closing it.
- L3 approved by the user (2026-10-31): all three assumptions accepted (no Esc/click-outside, scrollable fixed-height list, Back keeps the panel open).
- L4 build: `test` → `feat` pairs c43ae4a→35d0a36 (initialView), f2bfd6c→f75a480 (openSubpage/back), 5cc0893→c226707 (closeOnLeave), ccb5913→52413d0 (panelHeight); refactor cc3e676 (export the view ids). QML, manual-driven: 5097254 (tokens), 40a22e7 (subpage), 1d5bd66 ("See all ›"), 9149d8e (wire the view + mark seen), 9d3927e (Back took no clicks: its MouseArea sat inside a Row, which a positioner sizes to zero), ef375ef (`ccHeight` 320→420: the root already needed 329 and the window was clipping it), 14ea252 (round ‹/✕ buttons + DND pill instead of the tile + label), ab86200 (white knob), d3a2384 (divider under the subpage header), 876dedd (comment-only, after the verdict).
- L5 in-run changes (user, 2026-10-31): the window grows to 420 instead of staying 320 (assumption 2 in L2 is superseded: the panel keeps the root's 289/317, the window only caps it, with room for the tray and power rows); the subpage's DND tile + "Do not disturb" label became an unlabelled pill, and Clear/Back became icon-only round buttons.
- L6 verifier (flow-verifier): FAIL — opening the subpage shrank the panel (289→256), so the mask left the pointer that clicked "See all ›" and the deferred close collapsed the panel on its own; also notes on the view reset on close and the hover/timer race. Fixed by ccb5913→52413d0 (`panelHeight` keeps the panel at least the root's height, the card fills it, the reset moved to the open path, a shape-level HoverHandler cancels the pending close). Recheck: PASS (heights recomputed from the tokens: 289 is stable across the open, the only growth case grows downward; notes: `228` in the panelHeight test is the pre-fix measurement, Clear/Back shrink only under a top-anchored pointer).
- L7 evidence: `make check` → 443 pass, 0 fail, "smoke: config loaded". Manual pass by the user on the branch: opening from "See all ›" and the DND right click, count and rows newest first, the dot cleared only on open, scrolling to the oldest, per-row ✕, Clear, the empty state, Back, a brief leave keeping the subpage and a long one closing it (reopening at the root), and the DND pill reflecting in the root tile.
- Risk: item 4 (one global history, DND and unread flag mutated from every monitor's subpage, plus the delayed close), item 6 (scroll, look and app-side dismiss verified only manually)
