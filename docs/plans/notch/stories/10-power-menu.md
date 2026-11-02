# Story 10: Power menu

## Story

10. As a user, I want a power menu (Ctrl+Alt+Del, hold to confirm) so that I can lock, suspend, log out, reboot and shut down safely.

## Acceptance criteria

- [ ] Given the power menu is closed, when the `power` IPC target is called (what Ctrl+Alt+Del will trigger), then the centre notch of the focused monitor shows lock, suspend, logout, reboot and shutdown, arrows/hjkl move the selection, and Esc closes it.
- [ ] Given the power menu is open, when I choose lock or suspend (Enter or click), then the action runs at once and the menu closes.
- [ ] Given logout, reboot or shutdown is selected, when I hold Enter or the mouse button, then a progress bar fills over ~1s and the action runs only when it is full; releasing early cancels with nothing run, and key auto-repeat does not restart the hold.

## Plan

- Reuse the existing centre reducer: `PowerOpen`, `HoldStart`/`HoldCancel`/`HoldComplete` and the `power.run` effect already exist; add only what the criteria still miss (selection movement, close after an immediate action).
- A power-actions service maps each action to its command (from the old config: `systemctl poweroff`/`reboot`/`suspend-then-hibernate`, `hl.dsp.exit()` for logout) and lock to `Session.requestLock()`; the centre store executes `power.run` through it.
- A power view inside the centre notch paints the five icons, the selection and the hold progress bar; the hold timer starts on the first press and ignores auto-repeat. Exclusive keyboard focus only while open.
- An IPC handler `power` (skipped under `Flags.smoke`) opens the menu on the focused monitor, with an optional preselected action.
- Icons, labels, hold duration and commands live in `shell/config/`.

## Out of scope

- The Hyprland Ctrl+Alt+Del keybind itself (story 14, cutover); here it is exercised with `qs ipc call power ...`.
- The control center power row (story 18).
- The actual lock screen (story 13): lock only fires `Session.requestLock()`; nothing visible locks until #13 lands.
- Laptop power button -> power menu (plan: LATER).

## Suggestions (your call)

- Keep the selection index in the reducer's `keyboard` state (it already carries `sub` for the preselected action) so the preselection and the moves are unit-testable.

## Size

normal
Risk: item 1 (logout/reboot/shutdown end the session irreversibly)

## Log

- L1 request: /flow:story 10
- Assumptions: IPC opens on the Hyprland-focused monitor; commands reused verbatim from the old `PowerActions`; lock is a request only until #13.
- L2 approval constraint: never run logout, reboot, shutdown or suspend against the live session during testing; manual and automated checks must stub or intercept the commands (e.g. log instead of execute).
