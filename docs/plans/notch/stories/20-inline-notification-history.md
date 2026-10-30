# Story 20: Latest notifications in the control center

## Story

20. As a user, I want my latest notifications in the control center (up to 3, count, clear all) so that I can review what I missed. Requires: #01, #16

## Acceptance criteria

- [ ] Given notifications arrived this session (including ones muted by DND and the shell's battery warning), when I open the control center, then under the tiles I see "Notifications (N)" and the newest 3 as rows (app icon, "App: summary"), newest first; with none, I see only a "No notifications" line.
- [ ] Given a notification in the list, when its toast times out, then it stays in the list; when its app closes it or I dismiss it from the toast, then it leaves the list and the count; past 50 the oldest is dropped.
- [ ] Given notifications in the list, when I click "Clear", then every one is dismissed (apps are told, critical `!` pins go too), the list shows "No notifications" and the unread dot goes away.

## Plan

- Logic: a pure, tested history list: newest first, an update to a known id refreshes it in place, remove by id, capped at 50, latest N for display.
- Service: the notification service keeps the history next to the toast queue; a close removes from both; clear-all dismisses every entry (DBus ones reach their app, shell-made ones are just dropped) and marks seen.
- UI: a notifications section under the tiles in the control center: header with count and "Clear", up to 3 rows, the empty line; the panel grows to fit.
- Tokens: row sizes, texts ("Notifications (%1)", "Clear", "No notifications") in `config/`.

## Out of scope

- The subpage, "See all", per-item dismiss in the list, the DND toggle there, DND right click and marking seen on open (#21).
- Clicking a row to open the app or run its default action.
- History across shell restarts (session-only by plan decision).

## Suggestions (your call)

- The toast already formats "App: summary" with `Strings.toastAppSeparator` and resolves icons through the yamis-mono theme; reuse that for rows so they match the toast.

## Size

normal
Risk: item 4 (global history kept in step with the toast queue and `!` pins across monitors), item 6 (list look and app-side dismiss verified only manually)

## Log

- L1 request: /flow:story 05
- L2 split: 05 needed a new history store plus inline list plus subpage navigation; user approved split into #20 (history + inline list + clear all) and #21 (subpage, per-item dismiss, DND, seen, stay-open rule).
- L3 build so far: addToHistory, removeFromHistory, latest (test → feat each); Notifs history + clearAll (544215c); NotifIcon refactor (1faf337); inline section (9757724) and look changes (732ff36); fixes 1742d00 (slideOffset, test-first) and 553a526 (hover via ancestor HoverHandler). `make check` → 439 pass. Manual criteria confirmed by the user. Click-to-expand deferred to #21.
- L4 paused: verifier stopped by the user before a verdict (usage limit); story stays open until a verifier PASS.
