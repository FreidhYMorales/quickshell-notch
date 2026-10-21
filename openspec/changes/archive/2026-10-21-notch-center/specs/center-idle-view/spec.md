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

For layer `charging`, `plugged` or `full` the notch MUST show a static battery icon left and the percentage right (`full`: full icon and "100%"). For `low` the same layout MUST be red. For `none` no battery content shows. Animations and glow are out of scope. While the `media` layer wins (see Side-layer priority), no battery content shows; charging is then signalled only by the plug-in glow pulse (SHOULD, later change).
(Previously: `plugged` was not listed; battery layers always displayed when active.)

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
(Previously: `media` and `plugged` layers were not listed.)

| base | extra | layer | left | right | total |
|---|---|---|---|---|---|
| 260 | 60 | none | 0 | 0 | 260 |
| 260 | 60 | charging | 60 | 60 | 380 |
| 260 | 60 | plugged | 60 | 60 | 380 |
| 260 | 60 | low | 60 | 60 | 380 |
| 260 | 60 | full | 60 | 60 | 380 |
| 260 | 60 | media | 60 | 60 | 380 |

#### Scenario: Clock stays put
- GIVEN layer `none` then `charging`
- WHEN the layouts are compared
- THEN the clock's centre offset from the notch centre is 0 in both

### Requirement: Side-layer priority

A pure `selectIdleLayer({battery, mediaPlaying})` MUST return exactly one layer by priority: `low` (below 20%, unplugged) > `media` (a player is playing) > `charging` / `plugged` / `full` (battery layer) > `none`. Plugging in during `low` yields the battery layer per the battery classification, then priority applies.

| battery layer | mediaPlaying | result |
|---|---|---|
| none | false | none |
| none | true | media |
| low | false | low |
| low | true | low |
| charging | false | charging |
| charging | true | media |
| plugged | true | media |
| full | true | media |
| full | false | full |
| plugged | false | plugged |

#### Scenario: Low beats media
- GIVEN battery `low` and a playing player
- WHEN selected
- THEN `low`

#### Scenario: Media beats charging
- GIVEN battery `charging` and a playing player
- WHEN selected
- THEN `media`

#### Scenario: Pause releases the layer
- GIVEN `media` active while charging
- WHEN playback pauses
- THEN `charging`

### Requirement: Media layer

While the `media` layer is selected the notch MUST grow symmetrically (same mechanism as battery layers) showing mini album art on the left and the audio visualizer (capability `audio-visualizer`) on the right. Without art a generic music glyph MUST replace the art. The clock MUST NOT move. Layer content MUST come from tokens.

#### Scenario: Playing (manual)
- GIVEN a player is playing and the notch is idle
- WHEN the layer shows
- THEN art left, bars right, clock centred

#### Scenario: No art (manual)
- GIVEN playing without art
- WHEN the layer shows
- THEN a music glyph is shown left

### Requirement: Display text

`formatPercent(72.4) = "72%"`, `formatPercent(100) = "100%"`, `formatPercent(0) = "0%"`.

#### Scenario: Rounding
- GIVEN percentage 71.6
- WHEN formatted
- THEN "72%"
