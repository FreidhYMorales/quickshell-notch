# Story 42: Multi-monitor validation sweep

## Story

42. As a user who works with external monitors, I want every notch surface and session behaviour checked on more than one screen so that multi-monitor use is verified once, as a whole, instead of finding defects one at a time. Requires: #30, #33.

## Acceptance criteria

- [ ] Given the laptop panel plus at least one external monitor with a different resolution and scale, when the shell starts, then every monitor has exactly one idle notch centred on its top edge, each monitor reserves the idle height once, no surface overlaps another monitor, and with `reserveSpace` off the full screen stays usable.
- [ ] Given two monitors, when I hover monitor A's notch, then only A expands; when I open the launcher, the power menu or a polkit prompt on A, then the keyboard state, its field and its input focus stay on A while B stays idle; closing it returns both to idle.
- [ ] Given two monitors, when workspaces change on A (including special workspaces) or an app opens, moves or closes there, then only A's workspace strip reacts, A shows only its own workspaces, B keeps its own, and the strip fits inside the notch on the narrower screen.
- [ ] Given two monitors, when volume or brightness changes, then the OSD appears only on the focused monitor with that monitor's palette and its intended placement; when a notification arrives, the toast shows on every monitor, dismissing it on one dismisses it everywhere, and a critical `!` stays until dismissed on all.
- [ ] Given a different wallpaper per monitor (image and video), when the shell starts or I change one monitor's wallpaper, then only that monitor's background and palette change, the other keeps its own, video plays independently, and background video pauses while locked.
- [ ] Given two monitors, when I lock the session, then every screen is covered by its own secure surface with its own frozen desktop around the notch, all notches morph together, entering the password or a fingerprint on any screen unlocks every screen, and every captured frame is released.
- [ ] Given two monitors and the theme installed as `notch-lock`, when SDDM starts, then the greeter is fully usable and correctly positioned without duplicated or half-drawn elements on any output, and logging in leaves no monitor black before the notch shell appears.
- [ ] Given a running session, when I plug in or unplug an external monitor while idle, expanded or locked, then the new monitor immediately gets its own surfaces and palette, the removed monitor's surfaces disappear without QML errors, and a keyboard state on the removed monitor closes or moves to the focused screen instead of being stranded.
- [ ] Given all of the above, when `make check` runs, then it stays green, and the log records the exact monitor configuration used (output names, resolutions, scales, primary) plus every defect found and where it was fixed.

## Plan

- Validation story: change code only for defects found here. A fix that touches `shell/logic/` gets a failing test first; a QML-only fix gets a `qs` probe where practical, otherwise a manual check recorded in the log.
- Walk the criteria in order on the laptop panel plus one external monitor, then repeat the pressure points (hover, keyboard states, lock, hotplug) with the second external connected. Update a checkbox only after observing it.
- If only one output is available, mark the story blocked and say so; do not mark criteria as passed from single-monitor evidence.
- Keep defects found in other unfinished stories (#34 picker, #35-#40) out of this story unless they are multi-monitor specific; note them in the log instead.
- Read the QML and quickshell logs during hotplug and lock rather than relying on appearance alone, because stale surfaces and stranded keyboard owners often only show as warnings.

## Out of scope

- New multi-monitor features (for example per-monitor notification routing or mirrored OSD configuration); this story verifies the behaviour the plan already promises.
- Re-validating single-monitor behaviour already covered by #30 and #33.
- Compositors other than Hyprland, X11, and fractional-scale arrangements Hyprland itself does not support.

## Suggestions (your call)

- Start with the laptop panel plus one external; add the second external only after the basics pass, so a defect is attributable to one change.
- Confirm with `qs list --all` and the log that a single instance serves every screen; a second instance would explain duplicated notches.
- Validate hotplug once while locked: lock surfaces are created per screen and are the most likely place for a stale frame or a leftover mask.
- Check a narrow external at its native resolution before changing scale; the notch width tokens are per monitor and are the first thing to overflow.

## Size

normal
Risk: item 4 (per-monitor state, keyboard ownership and lock surfaces across screens), item 6 (the result is only verifiable by eye on real outputs)

## Log

- L1 request (user): after closing #33, move multi-monitor validation out of the lock story into one story that covers every multi-monitor check.
