# Center Notch State Specification

## Purpose

Pure reducer deciding what the centre notch of each monitor shows. Lives in `shell/logic/*.mjs`, no Qt imports, tested with `node --test`.

Model: one reducer instance per monitor, `reduce(state, event) -> state`. `mode` is one of `idle | expanded | toast | launcher | powerMenu | polkit`. Priority (highest wins): polkit > powerMenu > launcher > toast > expanded > idle. Global inputs (toast queue, dnd, dismissed/seen ids, `locked`, `keyboardOwner` = monitor name) are shared by all instances. Hover, `expanded` and keyboard modes are per monitor. Event names below are illustrative of the contract; tasks fix the exact vocabulary.

## Requirements

### Requirement: Purity and determinism

The reducer MUST be a pure function: no I/O, no timers, no clock reads, no input mutation. Timeouts MUST arrive as events.

#### Scenario: Same input, same output
- GIVEN state S and event E
- WHEN reduce(S, E) runs twice
- THEN both results are deep-equal AND S is unchanged

### Requirement: Initial state

The initial state of every monitor MUST be `mode = idle`, empty queue, `criticalIndicator = false`, `unread = false`.

#### Scenario: Fresh monitor
- GIVEN no events
- WHEN the initial state is read
- THEN `mode` is `idle`

### Requirement: Priority ordering

The displayed `mode` MUST be the highest-priority active candidate.

#### Scenario: Higher beats lower
- GIVEN mode `toast`
- WHEN `launcherOpen` arrives on the keyboard-owner monitor
- THEN mode is `launcher`

#### Scenario: Lower does not displace higher
- GIVEN mode `powerMenu`
- WHEN `toastArrived` or `hoverEnter` arrives
- THEN mode stays `powerMenu` AND the toast stays queued

#### Scenario: Polkit tops all
- GIVEN mode `launcher`
- WHEN `polkitRequest` arrives on the keyboard-owner monitor
- THEN mode is `polkit`

### Requirement: Hover and Expanded

Hover MUST be per monitor. Hovering from `idle` MUST yield `expanded`; leaving MUST return to `idle`.

#### Scenario: Hover on A only
- GIVEN monitors A and B idle
- WHEN `hoverEnter` arrives for A
- THEN A is `expanded` AND B is `idle`

#### Scenario: Leave
- GIVEN A `expanded`
- WHEN `hoverLeave` arrives for A
- THEN A is `idle`

### Requirement: Toast lifecycle

A toast MUST preempt `expanded` and return to `expanded` if still hovered. Toasts are queued globally, newest first.

#### Scenario: Preempt and return
- GIVEN A `expanded` and hovered
- WHEN `toastArrived{id:1}` then `toastTimeout{id:1}`
- THEN mode is `toast` after the first AND `expanded` after the second

#### Scenario: Hover expands visible toast
- GIVEN mode `toast` (normal urgency)
- WHEN `hoverEnter`
- THEN the toast is in its expanded view AND the timeout is paused (`toastPaused = true`)

#### Scenario: Queue order
- GIVEN toast 1 visible
- WHEN `toastArrived{id:2}`
- THEN the queue holds 2 as `+1` (shown after 1 ends)

### Requirement: Suppression

DND MUST suppress toasts (unread set, no mode change) except critical urgency. An open launcher, power menu or polkit on ANY monitor MUST suppress toasts on ALL monitors.

#### Scenario: DND
- GIVEN dnd on, mode `idle`
- WHEN `toastArrived{urgency:normal}`
- THEN mode stays `idle` AND `unread = true`

#### Scenario: Critical bypasses DND
- GIVEN dnd on
- WHEN `toastArrived{urgency:critical}`
- THEN mode is `toast`

#### Scenario: Launcher on A mutes B
- GIVEN launcher open on A, B `idle`
- WHEN `toastArrived`
- THEN B stays `idle` AND `unread = true`

### Requirement: Global dismiss

Dismiss or seen of a notification MUST apply to every monitor.

#### Scenario: Dismiss everywhere
- GIVEN toast 1 visible on A and B
- WHEN `toastDismissed{id:1}`
- THEN both leave `toast`

### Requirement: Critical indicator

A critical toast MUST collapse after its first timeout into a persistent `criticalIndicator` (`!`) with mode returning to `idle`/`expanded`, until dismissed.

#### Scenario: Collapse
- GIVEN critical toast 1 visible
- WHEN `toastTimeout{id:1}`
- THEN mode is `idle` AND `criticalIndicator = true`

#### Scenario: Expanded reachable
- GIVEN `criticalIndicator = true`, `idle`
- WHEN `hoverEnter`
- THEN mode is `expanded`

#### Scenario: Cleared on dismiss
- GIVEN `criticalIndicator = true`
- WHEN `toastDismissed{id:1}`
- THEN `criticalIndicator = false`

### Requirement: Power hold preemption

An in-progress power hold MUST be cancelled when the power menu is preempted.

#### Scenario: Polkit cancels hold
- GIVEN mode `powerMenu`, `holding = true`
- WHEN `polkitRequest`
- THEN mode is `polkit` AND `holding = false`

### Requirement: Polkit flow cancelled externally

A null/cancelled polkit flow MUST return the monitor to the mode before polkit.

#### Scenario: Return to previous
- GIVEN `launcher` preempted by `polkit`
- WHEN `polkitCancelled`
- THEN mode is `launcher`

### Requirement: Session lock

When `locked` becomes true every monitor MUST close all states to `idle`, cancel polkit and ignore keyboard-state opens until unlock.

#### Scenario: Lock closes all
- GIVEN A `polkit`, B `expanded`
- WHEN `lockChanged{locked:true}`
- THEN A and B are `idle` AND polkit is cancelled

#### Scenario: Open while locked
- GIVEN `locked = true`
- WHEN `launcherOpen`
- THEN mode stays `idle`

### Requirement: Keyboard ownership

Keyboard modes MUST open only on the `keyboardOwner` monitor and stay there.

#### Scenario: Non-owner ignored
- GIVEN `keyboardOwner = A`
- WHEN `launcherOpen` targets B
- THEN B stays `idle`

#### Scenario: Owner change does not move
- GIVEN launcher open on A
- WHEN `keyboardOwner` becomes B
- THEN A stays `launcher` AND B is not `launcher`

### Requirement: Screen removal

Removing a monitor MUST drop its instance; if it hosted a keyboard mode, that mode closes and polkit is cancelled.

#### Scenario: Remove polkit host
- GIVEN A `polkit`
- WHEN `screenRemoved{A}`
- THEN A has no instance AND polkit is cancelled

#### Scenario: Remove other monitor
- GIVEN A `launcher`, B `idle`
- WHEN `screenRemoved{B}`
- THEN A stays `launcher`
