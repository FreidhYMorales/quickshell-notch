# Story 03: Critical notifications and the `!` indicator

## Story

03. As a user, I want critical notifications, including the 10% battery warning even at shell start, to bypass do-not-disturb and stay as a ! until I dismiss them so that I never miss urgent ones. Requires: #01

## Acceptance criteria

- [x] Given DND is on (or off), when an app sends a critical-urgency notification, then it shows as a toast on every monitor, and after its timeout it collapses into a `!` on the idle notch instead of disappearing; if the launcher, power menu or a polkit prompt is open, it goes straight to the `!`.
- [x] Given a `!` is showing, when I click it, then that critical toast reopens expanded (body, actions, ✕); ✕ or an action dismisses it and the `!` goes away; meanwhile normal notifications keep toasting and hovering the notch still opens the usual expanded view.
- [x] Given the laptop is unplugged at or below 10%, including when the shell starts already there, when the battery check runs, then one critical battery toast appears with the same rules (bypasses DND, collapses to `!`); it does not repeat until the charger has been plugged in again.

## Plan

- Logic: tests first for the reducer/queue: a critical toast waits as the `!` without blocking later normal toasts, reopening it on click, dismiss clearing it; urgency read from the notification feeds the existing `critical` flag.
- Service: the notifications service tells critical from normal and keeps waiting criticals until dismissed; the battery's existing one-shot critical event becomes a shell-made critical notification with text from config.
- UI: a `!` in the idle notch (same slot rules as the unread dot, primary/critical colour from config) that takes a click; the toast layer shows the reopened critical expanded.
- Manual check: extend the `notify-send` script with a critical case (with DND on and off) and a way to fake the 10% battery at start.

## Out of scope

- The notifications list in the control center and dismissing from there (#05).
- Arrival glow, low-battery breathing pulse and other animations (#15).
- Changing the battery thresholds or the low-battery layer.
- Sound or any alert outside the notch.

## Suggestions (your call)

- `Flags.batteryOverride` already lets the battery be faked; reuse it for the "already at 10% at start" manual check instead of a new switch.

## Size

normal
Risk: item 4 (critical waiting state shared with the toast queue across monitors), item 6 (`!` click, battery at start and DBus urgency verified only manually)

## Log

- L1 request: /flow:story 03
- L2 assumptions: until the control center exists (#04/#05), clicking the `!` reopens the critical toast expanded and ✕/an action dismisses it (user: "si, hazlo así"); several waiting criticals share the one `!`, a click reopens the newest and the `!` stays until all are dismissed; the battery toast text lives in config strings.
- L3 approved by the user (2026-10-30).
- L4 in-run decisions (user, 2026-10-30): hovering the idle notch opens Expanded before the idle `!` can be clicked, so the `!` also shows in Expanded and is clicked there (user: "si, asi esta bien"); the Expanded notch widens just enough on both sides for the `!` column (user: "aplica lo mismo que la vez pasada que se expanda el notch"); the Expanded `!` is a round button (user: "podrias ponerlo dentro de un boton redondo?"). The idle `!` takes the unread dot's slot and width rule from story 02.
- L5 approved test list: collapse, reopen, unpin (unit); criterion 3 logic (one-shot at <= 10%, armed at start, re-arm on plug-in) relies on the existing `criticalStep` tests, the battery toast wiring is manual. Bug found in manual check: the first shell-made notification id -1 collided with the "no toast" sentinel; fixed red→green with `headChanged`.
- L6 evidence: test→feat pairs d475ba1→091473a, 1f9c6a5→8f2bd66, 0e96542→a4690d7, 04c99a6→fb3447f, dcb5fa3→1c5cf1f (fix); QML-only feats 31e8e56 (battery toast), 638524d (round button); manual script 20a68c3. `make check`: 401 pass, 0 fail, smoke: config loaded.
- L7 manual: the user checked critical with DND on/off, `!` in idle and Expanded, click reopen, ✕/action dismiss, normal toasts flowing, battery override at 9% at start (one toast, then `!`), the round button.
- L8 verifier (flow:verifier): PASS. Notes: stubs make test commits replay as import errors; `syncToast` re-entrancy can call `Notifs.collapse()` twice (harmless in every traced path, untested); a theoretical double battery post if the event fires between Connections setup and onCompleted.
- Risk: item 4 (critical waiting state shared with the toast queue across monitors), item 6 (`!` click, battery at start and DBus urgency verified only manually)
