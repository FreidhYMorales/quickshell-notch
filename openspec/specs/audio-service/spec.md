# Audio Service Specification

## Purpose

Reactive default sink volume and mute on `Quickshell.Services.Pipewire`.

## Requirements

### Requirement: Reactive default sink

`Audio` MUST expose the default sink `volume` (0..1) and `muted`, bound through a tracker so changes made elsewhere (keybinds, other apps) update it. With no default sink it MUST report `available = false` and not error.

#### Scenario: External change (manual)
- GIVEN the shell is running
- WHEN volume is changed with `wpctl`
- THEN `Audio.volume` updates

#### Scenario: No sink
- GIVEN no default sink
- WHEN `Audio` is read
- THEN `available` is false AND no errors are logged

### Requirement: Controls

`Audio.setVolume(v)` MUST clamp `v` to 0..1 before applying. `toggleMute()` MUST invert `muted`.

#### Scenario: Clamp table
| Input | Applied |
|---|---|
| -0.2 | 0 |
| 0.5 | 0.5 |
| 1.4 | 1 |

#### Scenario: Toggle
- GIVEN `muted` false
- WHEN `toggleMute()` runs twice
- THEN `muted` is true, then false

### Requirement: Smoke safety

With `Flags.smoke` the service MUST NOT start processes.

#### Scenario: Smoke
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN no error occurs
