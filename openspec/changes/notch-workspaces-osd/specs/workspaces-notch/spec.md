# Workspaces Notch Specification

## Purpose

TL surface: per-monitor workspace strip that reveals on activity. Pure rules live in `shell/logic/` (node --test); painting is (manual).

## Requirements

### Requirement: Strip model

For each monitor the model MUST yield `slotCount` (token) slots for the workspaces bound to that monitor. Symbols: active = `●`; empty and inactive = `–`; occupied and inactive = the icon of the last-focused app there (lowest `focusHistoryID`), else the first letter (uppercased) of the app name when no icon resolves.

#### Scenario: Symbol table (slotCount 5)
| Active | Windows (ws: class, fhid) | Slots |
|---|---|---|
| 2 | none | `– ● – – –` |
| 1 | 3: kitty,4 / 3: firefox,1 | `● – icon(firefox) – –` |
| 1 | 2: unknownapp,0 (no icon) | `● U – – –` |
| 4 | 4: foot,0 | `– – – ● –` (active wins over icon) |

#### Scenario: Per-monitor isolation
- GIVEN workspaces 1-2 on monitor A and 3-4 on B
- WHEN a window opens on 3
- THEN only B's model changes

### Requirement: Window filtering

Only normal toplevel windows MUST count for occupancy, icons and triggers. Dialogs, popups, transient and floating-popup windows MUST be ignored.

#### Scenario: Filter table
| Window | Counts |
|---|---|
| tiled app | yes |
| floating normal app | yes |
| dialog / transient-for parent | no |
| popup, floating popup (menu, tooltip) | no |

### Requirement: Reveal triggers and debounce

The strip MUST reveal on: workspace change, counted window open, counted window move. Ignored windows MUST NOT reveal. Events within the debounce token window MUST coalesce into one reveal. After `Timings.reveal` without events the strip MUST hide. On window open the active slot MUST show the new app icon for the reveal period.

#### Scenario: Event table
| Event | Reveals |
|---|---|
| `workspace` | yes |
| `openwindow` (normal) | yes, active slot shows new icon |
| `movewindowv2` (normal) | yes |
| `openwindow` (dialog) | no |
| `closewindow` | no (occupancy updates silently) |

#### Scenario: Debounce
- GIVEN 3 counted events at t=0, 40, 80 ms and debounce 150 ms
- WHEN time passes
- THEN exactly one reveal is emitted AND hide is scheduled once from the last event

### Requirement: Special workspace pin

While a special workspace is active the strip MUST show only the Arch icon plus the special icon and MUST stay revealed. Leaving the special MUST restore normal reveal behaviour.

#### Scenario: Pin
- GIVEN `activespecial` = `special:magic`
- WHEN the model is built
- THEN output is `[arch, special-icon]` with `pinned = true`

#### Scenario: Unpin
- GIVEN pinned
- WHEN `activespecial` becomes empty
- THEN `pinned = false` AND the hide timer starts

### Requirement: Click to focus (manual)

Clicking a slot MUST focus that workspace through `Hypr.dispatch`. The surface MUST show concave ears to the top and left edges and MUST be invisible while hidden.

#### Scenario: Click (manual)
- GIVEN the strip is revealed
- WHEN the user clicks slot 3
- THEN workspace 3 becomes active
