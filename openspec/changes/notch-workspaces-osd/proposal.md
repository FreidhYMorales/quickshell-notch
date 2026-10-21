# Proposal: Workspaces notch and volume/brightness OSDs

Plan row: `docs/plans/notch/plan.md` "Implementation phases" #3 `notch-workspaces-osd` (5.25 dev-days).

## Intent

The TL, BL and VR surfaces are still placeholders, so the old bar is still needed for workspaces, volume and brightness. Success: switching or opening apps reveals the workspace strip; keybinds reveal OSDs that can also be dragged, scrolled and muted.

## Scope

### In Scope
- Workspaces notch (TL, ears to top and left): Arch icon + per-monitor strip (slot-count token); ● active, – empty, last-focused app icon (`focusHistoryID`, fallback = first letter of the app name). Reveals on workspace change, window open (active slot shows the new icon briefly) and window move, then hides (`Timings.reveal`). Only normal toplevel windows count, with a debounce. An active special workspace pins the strip to Arch + special icon. Click focuses via `Hypr.dispatch`
- `Audio` rewrite on `Quickshell.Services.Pipewire`: reactive default sink volume/mute, `setVolume`, `toggleMute`
- `Brightness` port: udev watcher + `brightnessctl`, percent + set
- OSDs (BL brightness, VR volume, mirrored): one shared slider, icon inside the round thumb, numeric value; reveal on change, auto-hide, hover keeps open; drag/scroll adjust; volume right-click mutes (dimmed track, muted icon); startup gate
- Strict TDD `shell/logic/`: strip model, icon/initial fallback, slider maths, OSD reveal state
- `Flags.smoke`: no processes or udev watchers

### Out of Scope
- Fly animation on window move (SHOULD, `notch-polish-*`); brightness right-click (v2); cutover keybinds (`notch-cutover`)

## Capabilities

### New Capabilities
- `workspaces-notch`: strip model, symbols, icons, triggers, debounce, special pin, click-to-focus
- `audio-service`: Pipewire default sink volume/mute and controls
- `brightness-service`: udev-driven percent and set
- `osd-notch`: shared slider, reveal/hide, hover, drag/scroll, mute, startup gate

### Modified Capabilities
- `shell-surfaces`: "Placeholder visibility" covers only TR; "Smoke mode" also forbids process/udev watchers
- `visual-tokens`: workspace slot count, debounce, reveal and startup-gate timings, wheel step, OSD icons and strings

## Approach

Services expose raw Hyprland/Pipewire/udev data; new pure modules decide the strip, triggers and slider values; QML paints. Reuse the old `WorkspacesWidget` probe, `SpecialWorkspacesWidget` raw `activespecial` tracking and `Osd.qml` slider maths, with tokens instead of literals.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `shell/logic/`, `tests/` | New | Strip, icon fallback, slider, OSD state |
| `shell/services/` | New | Audio, Brightness, workspace data |
| `shell/components/` | New | Shared slider |
| `shell/notches/workspaces/`, `shell/notches/osd/` | Modified | Live surfaces |
| `shell/config/` | Modified | Tokens, strings |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Exceeds 400-line budget | High | Slices: (1) workspace logic, (2) workspaces surface, (3) slider/OSD logic, (4) Audio + Brightness, (5) slider + OSD surfaces |
| Hyprland ObjectModel lags events | Med | Reuse probe workaround; debounce |
| Pipewire node not bound | Med | `PwObjectTracker` on default sink; hide OSD if absent |
| OSDs flash on startup | Med | Startup gate token |

## Rollback Plan

Additive; old bar untouched. Revert slice commits; TL/BL/VR fall back to placeholders.

## Dependencies

- `notch-foundation`, `notch-center` (archived); `brightnessctl`; Quickshell Pipewire/Hyprland modules

## Success Criteria

- [ ] Workspace change, app open and move reveal the strip per monitor; special pins it
- [ ] Volume/brightness keybinds reveal the OSDs; drag, scroll and mute work
- [ ] No OSD flash on load; smoke spawns nothing
- [ ] `make check` green; logic tests cover every listed rule

## Proposal question round

Skipped by orchestrator: decisions come from the approved plan and its review resolutions.
