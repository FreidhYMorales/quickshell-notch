# Audio Visualizer Specification

## Purpose

Real audio visualizer for the idle media layer: `cava` frames become mirrored bars on the right side of the notch.

## Requirements

### Requirement: Frame parsing

A pure `parseFrame(line, bars, maxRange)` MUST turn one cava raw ascii line (`;`-separated integers, optional trailing `;`) into an array of exactly `bars` values, each `min(1, v / maxRange)` (0..1). A token count different from `bars`, an empty line, a non-numeric token or a negative token MUST return `null` (frame ignored, last good frame kept).

The pure `cavaConfig({bars, framerate, maxRange})` MUST clamp each value to its documented range in `shell/logic/visualizer.mjs` and emit integers only, so that cava's configuration cannot be injected through the inputs.

| line | bars | maxRange | result |
|---|---|---|---|
| `0;5;10;` | 3 | 10 | `[0, 0.5, 1]` |
| `0;5;10` | 3 | 10 | `[0, 0.5, 1]` |
| `20;3;` | 2 | 10 | `[1, 0.3]` |
| `0;5;` | 3 | 10 | `null` (token count differs from bars) |
| `` | 2 | 10 | `null` |
| `1;x;3;` | 3 | 10 | `null` |
| `-1;2;` | 2 | 10 | `null` |

#### Scenario: Valid frame
- GIVEN line `0;5;10;`, bars 3 and maxRange 10
- WHEN parsed
- THEN `[0, 0.5, 1]`

#### Scenario: Malformed frame
- GIVEN line `1;x;3;`
- WHEN parsed
- THEN `null` AND the previous bars stay unchanged

### Requirement: Mirrored bar geometry

A pure `barGeometry(levels, {height, barWidth, gap, minHeight})` MUST return, per level, `{x, y, height}` where `barHeight = max(minHeight, level * height)`, `x = index * (barWidth + gap)`, `height = barHeight` and `y = (height - barHeight) / 2`. Every bar is therefore centred on the same horizontal line (mirrored). When all levels are 0, every bar has height `minHeight`, which draws a flat line.

#### Scenario: Rest
- GIVEN all levels 0
- WHEN geometry is computed
- THEN every bar has height `minHeight` AND a flat horizontal line is drawn

#### Scenario: Symmetry
- GIVEN a level of 0.5 and height H
- WHEN computed
- THEN the bar's distance above the centre line equals its distance below it

### Requirement: Process lifecycle

The `cava` process MUST run only while the idle notch shows the `media` layer (`Cava.wanted`, true when `sideLayer` is `media`, i.e. a player is playing and no `low` battery layer overrides it). It MUST stop when the layer is released. `Cava.running` is `wanted && !Flags.smoke && available`; under `Flags.smoke` no process SHALL be spawned. A cava process that exits while wanted MUST restart after `Timings.cavaRestart`, at most `Limits.cavaRetries` times per play session; after that `available` becomes false and a warning is logged. If `cava` is missing or fails, bars MUST fall back to the flat line (levels reset to zero) without errors.

#### Scenario: Play then pause (manual)
- GIVEN a player starts playing
- WHEN playback pauses
- THEN `cava` is stopped AND the bars settle to the flat line

#### Scenario: Smoke mode
- GIVEN `Flags.smoke`
- WHEN a player is playing
- THEN no `cava` process is spawned

### Requirement: Bar colour

Bars MUST use the accent colour of the album art: `ColorQuantizer` samples the art, and `pickAccent(colours, {minLuma})` (`Limits.accentMinLuma`) picks the most saturated bright colour, rejecting greys and darks. Without art, without an accent or on load failure they MUST use the matugen dark-scheme `primary`. Remote (https) art that cannot be loaded takes the `primary` fallback; this is accepted for this change.

#### Scenario: Colours (manual)
- GIVEN art is available, then a track without art
- WHEN the layer shows
- THEN bars use the art colour, then `primary`

### Requirement: Dependency

`cava` MUST be documented as a runtime dependency. It is optional: without it only the visualizer is hidden and no error is raised.

#### Scenario: Docs
- GIVEN the dependency docs
- WHEN read
- THEN `cava` is listed
