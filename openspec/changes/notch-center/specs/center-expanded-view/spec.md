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

A pure `weekStrip(date, radius=3)` MUST return 7 consecutive local days centred on `date`, each `{year, month, day, today}`, independent of locale, with `today` true only for the centre.

| today | strip (day numbers) |
|---|---|
| 2026-03-20 | 17 18 19 20 21 22 23 |
| 2026-03-31 | 28 29 30 31 1 2 3 (Apr 1-3) |
| 2026-12-31 | 28 29 30 31 1 2 3 (Jan 1-3, 2027) |
| 2026-01-02 | 30 31 1 2 3 4 5 (Dec 30-31, 2025) |
| 2024-02-28 | 25 26 27 28 29 1 2 (Feb 29, Mar 1-2) |

#### Scenario: Midnight rollover
- GIVEN 2026-03-20 23:59:59 then 00:00:01
- WHEN the day-change signal fires
- THEN the strip is recomputed centred on 2026-03-21

### Requirement: No-player layout

Without a player only the clock card MUST show, and the notch MUST be narrower.

#### Scenario: No player (manual)
- GIVEN no player
- WHEN expanded
- THEN only the clock and week card show

### Requirement: Width

A pure `expandedWidth({hasPlayer, full, clockOnly, max})` MUST return `min(hasPlayer ? full : clockOnly, max)`.

| hasPlayer | full | clockOnly | max | result |
|---|---|---|---|---|
| true | 560 | 300 | 600 | 560 |
| false | 560 | 300 | 600 | 300 |
| true | 560 | 300 | 400 | 400 |
| false | 560 | 300 | 250 | 250 |

#### Scenario: Narrow monitor
- GIVEN max 400
- WHEN expanded with a player
- THEN width is 400, never above `Layout.centerMaxWidth`
