# Center Idle View Specification

## Purpose

Idle centre notch: CPU ring, date and time, RAM ring, overlays and battery layers.

## Requirements

### Requirement: Idle row

The idle notch MUST show `(cpu ring) date · time (ram ring)` on `#000`, symmetric about the clock, using `ArcMeter` with the monitor's dark-scheme `primary`. All colours, sizes and text MUST come from tokens.

#### Scenario: Live content (manual)
- GIVEN no events
- WHEN the shell runs
- THEN every monitor shows the date, time and both rings updating

### Requirement: Overlays

An unread-dot slot (blinking via `blinkDot`) MUST sit in the right padding and MUST NOT change the width. A red dot MUST show while `Recorder.recording`. The unread source is not wired in this change.

#### Scenario: Recording dot (manual)
- GIVEN recording is active
- WHEN the idle notch is shown
- THEN a red dot is visible AND the notch width is unchanged

### Requirement: Battery layers

For layer `charging` or `full` the notch MUST show a static battery icon left and the percentage right (`full`: full icon and "100%"). For `low` the same layout MUST be red. For `none` no battery content shows. Animations and glow are out of scope.

#### Scenario: Charging (manual)
- GIVEN plugged and charging at 72%
- WHEN idle
- THEN icon on the left and "72%" on the right

#### Scenario: Plug replaces low (manual)
- GIVEN the low layer at 18%
- WHEN the charger is connected
- THEN the charging layer replaces it

### Requirement: Symmetric widths

A pure `idleLayout({base, extra, layer})` MUST return `{left, right, total}` where for layer `none` extra is 0, otherwise `left == right == extra` and `total = base + 2*extra`. The clock position MUST NOT change.

| base | extra | layer | left | right | total |
|---|---|---|---|---|---|
| 260 | 60 | none | 0 | 0 | 260 |
| 260 | 60 | charging | 60 | 60 | 380 |
| 260 | 60 | low | 60 | 60 | 380 |
| 260 | 60 | full | 60 | 60 | 380 |

#### Scenario: Clock stays put
- GIVEN layer `none` then `charging`
- WHEN the layouts are compared
- THEN the clock's centre offset from the notch centre is 0 in both

### Requirement: Display text

`formatPercent(72.4) = "72%"`, `formatPercent(100) = "100%"`, `formatPercent(0) = "0%"`.

#### Scenario: Rounding
- GIVEN percentage 71.6
- WHEN formatted
- THEN "72%"
