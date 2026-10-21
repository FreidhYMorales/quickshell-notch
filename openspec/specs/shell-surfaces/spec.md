# Shell Surfaces Specification

## Purpose

Per-monitor layer surfaces, space reservation, input masks, ears and the smoke mode.

## Requirements

### Requirement: Surface set per monitor

For every connected monitor the shell MUST create a spacer plus TL, BL, C, VR and TR surfaces. Surfaces appear and disappear with hot-plugged monitors.

#### Scenario: Two monitors
- GIVEN two monitors
- WHEN `qs -c notch` starts
- THEN each monitor has its own six surfaces AND the centre shows the idle notch

#### Scenario: Hot-plug
- GIVEN one monitor
- WHEN a second is connected, then removed
- THEN surfaces appear, then are destroyed, without affecting the first

### Requirement: Single exclusive zone

The spacer MUST be the only surface with an exclusive zone, equal to the idle-height token. All other surfaces MUST use `ExclusionMode.Ignore`. With `reserveSpace` off the spacer MUST also ignore.

#### Scenario: Reserved strip
- GIVEN `reserveSpace` on
- WHEN a window is tiled
- THEN it starts exactly idle-height below the top, identical in logical units on every monitor

#### Scenario: Toggle off
- GIVEN `reserveSpace` off
- WHEN a window is tiled
- THEN it starts at the top edge

### Requirement: Input masks

Every surface MUST set a mask covering only its visible shape. Clicks outside masks MUST reach windows below. Surfaces MUST be fixed-size; shapes animate inside.

#### Scenario: Click-through
- GIVEN the idle notch
- WHEN the user clicks the top strip beside the notch
- THEN the click reaches the window or wallpaper below

#### Scenario: Hover on notch
- GIVEN the idle notch
- WHEN the pointer enters its shape
- THEN the surface receives the hover

### Requirement: Placeholder visibility

TL, BL, VR and TR placeholders MUST be invisible unless the `showPlaceholders` token is true.

#### Scenario: Debug
- GIVEN `showPlaceholders = true`
- WHEN the shell starts
- THEN the four placeholders are visible with their masks and ears

### Requirement: Concave ears

Notch shapes MUST render concave ears where they meet a screen edge, using the shared ear curve. The corner ear shape MUST support all four corners.

#### Scenario: Each corner
- GIVEN a corner ear configured for topLeft, topRight, bottomLeft and bottomRight
- WHEN rendered
- THEN each curves concavely toward the matching edge

### Requirement: Idle centre content

The idle centre notch MUST be pure `#000` and show live content as defined in `center-idle-view` (date, time, CPU/RAM rings, overlays, battery layers), with every colour, timing and string taken from tokens.

#### Scenario: Idle
- GIVEN no events
- WHEN the shell is running
- THEN the centre shows live date, time and rings on black on every monitor

#### Scenario: Smoke (manual)
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN the idle content loads without errors

### Requirement: Smoke mode

With `NOTCH_SMOKE=1` the shell MUST skip the spacer zone, NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers, the BG surface and all state import/writes. The variable MUST be read once, in the `Flags.smoke` config token. Only the spacer zone is gated in this change; NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers and the BG surface are not yet present and MUST honour the same gate when introduced.

#### Scenario: Smoke run
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN the shell loads without errors AND no zone, DBus name, agent, IPC target or state file is created

#### Scenario: Normal run
- GIVEN `NOTCH_SMOKE` unset
- WHEN the shell starts
- THEN the spacer zone applies per `reserveSpace`
