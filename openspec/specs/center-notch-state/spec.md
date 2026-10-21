# Center Notch State Specification

## Purpose

Pure reducer deciding what the centre notch of each monitor shows. Lives in `shell/logic/*.mjs`, no Qt imports, tested with `node --test`.

Model: one root reducer `reduce(state, event) -> {state, effects}` over `{global, monitors{}}`. `mode` is never stored: `viewFor(state, monitor)` derives it as one of `idle | expanded | toast | launcher | power | polkit`. Priority (highest wins): polkit > power > launcher > toast > expanded > idle. Global inputs (toast slot, dnd, dismissed/seen ids, `locked`, keyboard slot owner = monitor name) are shared by all monitors. Hover, `expanded` and keyboard modes are per monitor. Event names are the implemented vocabulary: `Hover{monitor,on}`, `ToastShown{id,critical}`, `PolkitRequest{flowId,monitor}`, and so on.

## Requirements

### Requirement: Purity and determinism

The reducer MUST be a pure function: no I/O, no timers, no clock reads, no input mutation. Timeouts MUST arrive as events.

#### Scenario: Same input, same output
- GIVEN state S and event E
- WHEN reduce(S, E) runs twice
- THEN both results are deep-equal AND S is unchanged

### Requirement: Initial state

The initial state MUST derive `mode = idle` for every monitor, with no toast shown, `showCriticalIndicator = false` and `blinkDot = false`.

#### Scenario: Fresh monitor
- GIVEN no events
- WHEN the initial state is read
- THEN `mode` is `idle`

### Requirement: Priority ordering

The displayed `mode` MUST be the highest-priority active candidate.

#### Scenario: Higher beats lower
- GIVEN mode `toast`
- WHEN `LauncherToggle` arrives on the keyboard-owner monitor
- THEN mode is `launcher`

#### Scenario: Lower does not displace higher
- GIVEN mode `power`
- WHEN `ToastShown` or `Hover{on:true}` arrives
- THEN mode stays `power` AND the toast stays queued [DEFERRED to notch-notifications; the mode part is implemented]

#### Scenario: Polkit tops all
- GIVEN mode `launcher`
- WHEN `PolkitRequest` arrives on the keyboard-owner monitor
- THEN mode is `polkit`

### Requirement: Hover and Expanded

Hover MUST be per monitor. Hovering from `idle` MUST yield `expanded`; leaving MUST return to `idle`.

#### Scenario: Hover on A only
- GIVEN monitors A and B idle
- WHEN `Hover{on:true}` arrives for A
- THEN A is `expanded` AND B is `idle`

#### Scenario: Leave
- GIVEN A `expanded`
- WHEN `Hover{on:false}` arrives for A
- THEN A is `idle`

### Requirement: Toast lifecycle

A toast MUST preempt `expanded` and return to `expanded` if still hovered. A single global toast slot shows the newest toast; a newer toast replaces the older one. Queueing is deferred to `notch-notifications`.

#### Scenario: Preempt and return
- GIVEN A `expanded` and hovered
- WHEN `ToastShown{id:1}` then `ToastTimeout{id:1}`
- THEN mode is `toast` after the first AND `expanded` after the second

#### Scenario: Hover expands visible toast
- GIVEN mode `toast` (normal urgency)
- WHEN `ToastHover{on:true}`
- THEN the toast is in its expanded view AND the timeout is paused (`toastHovered = true`)

#### Scenario: Queue order (+1) [DEFERRED to notch-notifications]
- GIVEN toast 1 visible
- WHEN `ToastShown{id:2}`
- THEN [DEFERRED to notch-notifications] the queue holds 2 as `+1` (shown after 1 ends). Implemented: toast 2 replaces toast 1 in the single toast slot.

### Requirement: Suppression

DND MUST suppress toasts (`blinkDot` set, no mode change) except critical urgency. An open launcher, power menu or polkit on ANY monitor MUST suppress toasts on ALL monitors.

#### Scenario: DND
- GIVEN dnd on, mode `idle`
- WHEN `ToastShown{id, critical:false}`
- THEN mode stays `idle` AND `blinkDot = true`

#### Scenario: Critical bypasses DND
- GIVEN dnd on
- WHEN `ToastShown{id, critical:true}`
- THEN mode is `toast`

#### Scenario: Launcher on A mutes B
- GIVEN launcher open on A, B `idle`
- WHEN `ToastShown`
- THEN B stays `idle` AND `blinkDot = true`

### Requirement: Global dismiss

Dismiss or seen of a notification MUST apply to every monitor.

#### Scenario: Dismiss everywhere
- GIVEN toast 1 visible on A and B
- WHEN `ToastDismissed{id:1}`
- THEN both leave `toast`

### Requirement: Critical indicator

A critical toast MUST collapse after its first timeout into a persistent `showCriticalIndicator` (`!`) with mode returning to `idle`/`expanded`, until dismissed.

#### Scenario: Collapse
- GIVEN critical toast 1 visible
- WHEN `ToastTimeout{id:1}`
- THEN mode is `idle` AND `showCriticalIndicator = true`

#### Scenario: Expanded reachable
- GIVEN `showCriticalIndicator = true`, `idle`
- WHEN `Hover{on:true}`
- THEN mode is `expanded`

#### Scenario: Cleared on dismiss
- GIVEN `showCriticalIndicator = true`
- WHEN `ToastDismissed{id:1}`
- THEN `showCriticalIndicator = false`

### Requirement: Power hold preemption

An in-progress power hold MUST be cancelled when the power menu is preempted.

#### Scenario: Polkit cancels hold
- GIVEN mode `power`, a hold in progress (`hold != null`)
- WHEN `PolkitRequest`
- THEN mode is `polkit` AND the hold is cleared (`hold = null`)

### Requirement: Polkit flow cancelled externally

A null/cancelled polkit flow MUST return the monitor to the mode before polkit.

#### Scenario: Return to previous
- GIVEN `launcher` preempted by `polkit`
- WHEN `PolkitCancel`
- THEN mode is `launcher`

### Requirement: Session lock

When `locked` becomes true every monitor MUST close all states to `idle`, cancel polkit and ignore keyboard-state opens until unlock.

#### Scenario: Lock closes all
- GIVEN A `polkit`, B `expanded`
- WHEN `Locked{on:true}`
- THEN A and B are `idle` AND polkit is cancelled

#### Scenario: Open while locked
- GIVEN `locked = true`
- WHEN `LauncherToggle`
- THEN mode stays `idle`

### Requirement: Keyboard ownership

Keyboard modes MUST open only on the `keyboard.owner` monitor and stay there.

#### Scenario: Non-owner ignored
- GIVEN `keyboard.owner = A`
- WHEN `LauncherToggle` targets B
- THEN B stays `idle`

#### Scenario: Owner change does not move (reconciled: tested as an open on another monitor)
- GIVEN launcher open on A
- WHEN `LauncherToggle` arrives on B while A owns the keyboard slot
- THEN A stays `launcher` AND B is not `launcher`

### Requirement: Screen removal

Removing a monitor MUST drop its instance; if it hosted a keyboard mode, that mode closes and polkit is cancelled.

#### Scenario: Remove polkit host
- GIVEN A `polkit`
- WHEN `ScreensChanged` dropping A
- THEN A has no instance AND polkit is cancelled

#### Scenario: Remove other monitor
- GIVEN A `launcher`, B `idle`
- WHEN `ScreensChanged` dropping B
- THEN A stays `launcher`
