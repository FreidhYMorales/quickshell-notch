# Story 02: Do-not-disturb and unread dot

## Story

02. As a user, I want do-not-disturb and an unread dot (blinking while the launcher is open) so that notifications never interrupt me but I still know they arrived. Requires: #01

## Acceptance criteria

- [x] Given the notch shell is running, when I run `qs -c notch ipc call notifs toggleDnd`, then DND turns on (or off); while it is on, normal notifications show no toast on any monitor, and once it is off again new notifications toast as before.
- [x] Given a notification arrived (toasted and hidden, or muted by DND), when the notch is idle, then a steady unread dot shows right of the row on every monitor, and the idle notch widens just enough on both sides (dot gap plus size) so the dot keeps the normal padding and the clock stays centred; `qs -c notch ipc call notifs markSeen` clears it and the next arrival brings it back.
- [x] Given a keyboard state or polkit flow is open (launcher, power), when a notification arrives, then no toast shows and the dot blinks; when that state closes, the dot stays steady until seen.

## Plan

- Service: the notifications service owns the DND flag and an unread count (arrivals since the last mark-seen), and exposes toggle-DND and mark-seen through one IPC target `notifs`; the reducer gets the DND flag as its existing `Dnd` event.
- Logic: tests first for the reducer/view: dot visible while unread > 0, blinking only while muted by a keyboard/polkit state, steady otherwise; DND mutes normal toasts.
- Queue: a notification muted on arrival does not toast later; when a mute lifts, the queue head is re-synced so a toast never sits without its timer (verifier follow-up from #01).
- UI: the idle notch dot reads the view's visible/blinking flags; blink half-period and size stay in config.
- Manual check: extend the `notify-send` script with DND on/off and mark-seen runs.

## Out of scope

- Seeing the blink in the real launcher: the launcher UI is #08 (criterion 3 is pinned by reducer tests until then).
- DND tile and the notifications subpage that marks seen (#04, #05); they will call the same service functions.
- Critical urgency bypassing DND, the `!` indicator and the battery toast (#03).
- History list, cap of 50, expiring tracked notifications (#05).
- Hyprland keybinds for the IPC calls (#14).
- Persisting DND across shell restarts.

## Suggestions (your call)

- `ToastShown` already sets `blinkDot: true` when suppressed and `CenterIdle` already has the dot with a blink animation; derive "visible" and "blinking" in the view from unread + mute instead of adding new global state.

## Size

normal
Risk: item 3 (new IPC target `notifs` that keybinds and the control center will call), item 4 (global mute and unread state across monitors, queue re-sync), item 6 (dot and IPC verified only manually)

## Log

- L1 request: /flow:story 02
- L2 assumptions: DND and mark-seen come through IPC until #04/#05 exist (user: "si, hazlo así con IPC"); notifications muted on arrival do not toast later; the launcher blink is visible only once #08 lands.
- L3 approved by the user (2026-10-30).
- L4 in-run change (user, 2026-10-30): the dot sat cramped against the ear curve; user: "hazlo que se expanda lo justo y necesario". Criterion 2 amended: the idle notch widens by rowGap + dotSize on both sides while the dot shows (overrides the plan rule "does not change the width").
- L5 evidence: test→feat pairs 12cd2a7→a7d94d6, f5a9b25→7b164c2, 0147a00→646a3d5, 343e7b3→eb640ed; pinning test 5982742 (mutation-checked); manual script e777274; story amend d669392. `make check`: 396 pass, 0 fail, smoke: config loaded.
- L6 manual: the user checked DND over IPC (burst muted, no late toasts, toasts back when off), the steady dot, markSeen and the widened notch live. Launcher blink reducer-tested only (#08).
- L7 verifier (flow:verifier): FAIL (no DND-off test; width change unrecorded) → fixed by 5982742 and d669392 → recheck PASS. Follow-up: `global.blinkDot` / `view.blinkDot` are now dead state (still pinned by old tests).
- Risk: item 3 (new IPC target `notifs` that keybinds and the control center will call), item 4 (global mute and unread state across monitors, queue re-sync), item 6 (dot and IPC verified only manually)
