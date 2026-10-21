# Center Expanded View Specification

## Purpose

Hover-expanded centre notch: media column plus clock and week strip.

## Requirements

### Requirement: Media column

With a player, the notch MUST show art (generic icon if none), title, album, artist and prev/play-pause/next. The idle rings MUST be hidden while expanded.

#### Scenario: With player (manual)
- GIVEN a playing player and a hover
- WHEN the notch expands
- THEN media and the clock card show AND the rings are hidden

#### Scenario: No art (manual)
- GIVEN a player without art
- WHEN expanded
- THEN a generic icon replaces the art

### Requirement: Clock and week strip

A pure `weekStrip(date, radius)` MUST return 7 consecutive local days centred on `date` (radius from `Limits.weekRadius`, 3), each `{year, month, day, weekday, today}` with `weekday` 0 = Monday, independent of locale, with `today` true only for the centre.

| today | strip (day numbers) |
|---|---|
| 2026-03-20 | 17 18 19 20 21 22 23 |
| 2026-03-31 | 28 29 30 31 1 2 3 (Apr 1-3) |
| 2026-12-31 | 28 29 30 31 1 2 3 (Jan 1-3, 2027) |
| 2026-01-02 | 30 31 1 2 3 4 5 (Dec 30-31, 2025) |
| 2024-02-28 | 25 26 27 28 29 1 2 (Feb 29, Mar 1-2) |

#### Scenario: Midnight rollover
- GIVEN `Time.dayKey` 2026-03-20 then 2026-03-21
- WHEN `dayChanged` fires at local midnight
- THEN the strip is recomputed centred on 2026-03-21

### Requirement: No-player layout

Without a player only the clock card MUST show, and the notch MUST be narrower.

#### Scenario: No player (manual)
- GIVEN no player
- WHEN expanded
- THEN only the clock and week card show

### Requirement: Width

A pure `expandedWidth({hasPlayer, full, clockOnly, max})` MUST return `min(hasPlayer ? full : clockOnly, max)`, where `full` is `Layout.expandedWidth`, `clockOnly` is `Layout.expandedClockWidth` and `max` is the per-monitor centre max width. The widths are tokens, not literals in this spec.

| hasPlayer | full / clockOnly vs max | result |
|---|---|---|
| true | full <= max | full |
| true | full > max | max |
| false | clockOnly <= max | clockOnly |
| false | clockOnly > max | max |

#### Scenario: Narrow monitor
- GIVEN a per-monitor max narrower than `Layout.expandedWidth`
- WHEN expanded with a player
- THEN width equals that max, never above `Layout.centerMaxWidth`
