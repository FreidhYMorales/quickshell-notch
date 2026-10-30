# Story 01: Notification toast in the centre notch

## Story

01. As a user, I want incoming notifications to show as a compact toast in the centre notch that expands on hover with its actions so that I see them without leaving my work.

## Acceptance criteria

- [ ] Given the notch shell is running, when an app sends a notification, then the centre notch shows a compact toast (icon, app, summary) that hides after its timeout; several in a row show one at a time, newest first, with `+N` for the ones waiting.
- [ ] Given a visible toast, when I hover it, then it expands to show the body, the notification's own action buttons and ✕, and it does not time out while hovered; clicking an action, the body (default action) or ✕ runs it and closes the toast.
- [ ] Given a toast is showing, when the app replaces that notification (same id) or closes it, then the toast refreshes in place or disappears.

## Plan

- Service: a new notifications service owns the DBus notification server (tracked, with actions, real dismiss), keyed by id, and feeds the existing centre reducer; it is not started under smoke.
- Logic: a pure queue module decides what shows now, the `+N` count, replace-by-id and close handling; unit-tested first.
- State: reuse the reducer's existing toast events (shown, hover, timeout, dismissed) and the single queue timer from config timings.
- UI: a toast layer in the centre notch with compact and expanded variants, hover preempting Expanded and returning to it, sizes/strings/timings from `shell/config/`.
- Manual check: a `notify-send` script for normal, with actions, replacing (same id) and a burst of 5.

## Out of scope

- Do-not-disturb, unread dot, blinking dot and launcher/power/polkit suppression (#02).
- Critical urgency handling, the persistent `!` and the 10% battery toast (#03).
- History list, cap of 50, clear all, seen-marking (#05).
- Arrival glow pulse and other animations (#15).
- Inline reply.

## Suggestions (your call)

- `CenterStore` already logs a placeholder where the battery toast will plug in; keep the new service's wiring next to it so #03 lands in one place.

## Size

normal
Risk: item 4 (global toast queue and ordering across monitors), item 6 (DBus server and toast UI verified only manually)

## Log

- L1 request: /flow:story 01
- L2 approved by the user (2026-10-29).
