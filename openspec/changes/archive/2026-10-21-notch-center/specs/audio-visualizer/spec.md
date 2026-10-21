# Audio Visualizer Specification

## Purpose

Real audio visualizer for the idle media layer: `cava` frames become mirrored bars on the right side of the notch.

## Requirements

### Requirement: Frame parsing

A pure `parseCavaFrame(line, {max})` MUST turn one cava raw ascii line (`;`-separated integers, optional trailing `;`) into an array of values clamped and normalised to 0..1 (`v / max`). Empty, non-numeric or negative-token lines MUST return `null` (frame ignored, last good frame kept).

| line | max | result |
|---|---|---|
| `0;5;10;` | 10 | `[0, 0.5, 1]` |
| `0;5;10` | 10 | `[0, 0.5, 1]` |
| `20;3;` | 10 | `[1, 0.3]` |
| `` | 10 | `null` |
| `1;x;3;` | 10 | `null` |
| `-1;2;` | 10 | `null` |

#### Scenario: Valid frame
- GIVEN line `0;5;10;` and max 10
- WHEN parsed
- THEN `[0, 0.5, 1]`

#### Scenario: Malformed frame
- GIVEN line `1;x;3;`
- WHEN parsed
- THEN `null` AND the previous bars stay unchanged

### Requirement: Mirrored bar geometry

A pure `barGeometry({values, height, minBar})` MUST return, per value, `{top, bottom}` extents symmetric around the centre line (`top == bottom`). Half-extent is `v * height / 2`. At `v == 0` for all bars the geometry MUST be a flat line (extent 0, drawn as a `minBar`-thick line).

| values | height | extents (half) |
|---|---|---|
| `[0, 0]` | 20 | `[0, 0]` (flat line) |
| `[1]` | 20 | `[10]` |
| `[0.5, 0.25]` | 20 | `[5, 2.5]` |

#### Scenario: Rest
- GIVEN all values 0
- WHEN geometry is computed
- THEN all extents are 0 AND a flat horizontal line is drawn

#### Scenario: Symmetry
- GIVEN value 0.5, height 20
- WHEN computed
- THEN 5 above and 5 below the centre line

### Requirement: Process lifecycle

The `cava` process MUST run only while a player is playing and MUST stop on pause or when no player exists. Under `Flags.smoke` no process SHALL be spawned. If `cava` is missing or exits, bars MUST fall back to the flat line without errors.

#### Scenario: Play then pause (manual)
- GIVEN a player starts playing
- WHEN playback pauses
- THEN `cava` is stopped AND the bars settle to the flat line

#### Scenario: Smoke mode
- GIVEN `Flags.smoke`
- WHEN a player is playing
- THEN no `cava` process is spawned

### Requirement: Bar colour

Bars MUST use a colour derived from the album art via `ColorQuantizer`; without art or on failure they MUST use the matugen dark-scheme `primary`.

#### Scenario: Colours (manual)
- GIVEN art is available, then a track without art
- WHEN the layer shows
- THEN bars use the art colour, then `primary`

### Requirement: Dependency

`cava` MUST be documented as a runtime dependency.

#### Scenario: Docs
- GIVEN the dependency docs
- WHEN read
- THEN `cava` is listed
