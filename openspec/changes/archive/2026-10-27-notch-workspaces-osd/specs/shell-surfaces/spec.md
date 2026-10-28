# Delta for Shell Surfaces

## MODIFIED Requirements

### Requirement: Placeholder visibility

Only the TR placeholder MUST be invisible unless the `showPlaceholders` token is true. TL, BL and VR are live surfaces (see `workspaces-notch`, `osd-notch`).
(Previously: TL, BL, VR and TR placeholders were invisible unless `showPlaceholders`.)

#### Scenario: Debug
- GIVEN `showPlaceholders = true`
- WHEN the shell starts
- THEN the TR placeholder is visible with its mask and ear AND TL, BL, VR show only their live content

#### Scenario: Default
- GIVEN `showPlaceholders = false`
- WHEN the shell starts
- THEN TR is invisible AND TL, BL, VR are hidden until their triggers fire

### Requirement: Smoke mode

With `NOTCH_SMOKE=1` the shell MUST skip the spacer zone, NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers, the BG surface, all state import/writes, and MUST NOT start processes or udev watchers (including `brightnessctl`). The variable MUST be read once, in the `Flags.smoke` config token. NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers and the BG surface are not yet present and MUST honour the same gate when introduced.
(Previously: only the spacer zone was gated; no process or udev watcher prohibition.)

#### Scenario: Smoke run
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN the shell loads without errors AND no zone, DBus name, agent, IPC target, state file, process or udev watcher is created

#### Scenario: Normal run
- GIVEN `NOTCH_SMOKE` unset
- WHEN the shell starts
- THEN the spacer zone applies per `reserveSpace` AND the brightness watcher runs
