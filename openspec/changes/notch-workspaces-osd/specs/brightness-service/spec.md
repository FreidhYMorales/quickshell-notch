# Brightness Service Specification

## Purpose

Backlight percent and set, driven by a udev watcher plus `brightnessctl`.

## Requirements

### Requirement: Percent and set

`Brightness` MUST expose `percent` (0..100) and `set(p)`, which MUST clamp `p` to 0..100 and round to an integer before invoking `brightnessctl`.

#### Scenario: Set table
| Input | Applied |
|---|---|
| -5 | 0 |
| 42.6 | 43 |
| 130 | 100 |

#### Scenario: Parse (pure)
| `brightnessctl` current / max | percent |
|---|---|
| 50 / 100 | 50 |
| 96 / 255 | 38 |

### Requirement: Reactive updates

A udev watcher MUST refresh `percent` when the backlight changes externally. With no backlight device the service MUST report `available = false` and not error.

#### Scenario: External change (manual)
- GIVEN the shell is running
- WHEN `brightnessctl s 10%+` runs
- THEN `percent` updates

### Requirement: Smoke safety

With `Flags.smoke` the service MUST NOT start `brightnessctl` or udev watchers.

#### Scenario: Smoke
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN no process or watcher is started
