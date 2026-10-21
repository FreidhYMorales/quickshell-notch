# Visual Tokens Specification

## Purpose

Single source of fonts, timings, layout, colours and UI strings in `shell/config/`.

## Requirements

### Requirement: Token singletons

`shell/config/` MUST provide Fonts, Timings, Layout, Colours and Strings singletons registered in its `qmldir`. Colours, timings, fonts and UI text MUST NOT appear as literals outside `shell/config/`.

#### Scenario: Import
- GIVEN the config module
- WHEN QML imports it
- THEN all five singletons resolve

#### Scenario: Literal scan
- GIVEN QML files outside `shell/config/` and the exempt lock
- WHEN scanned for colour, duration, font-family or user-visible literals
- THEN none are found

### Requirement: Font

The family "IosevkaTerm Nerd Font" MUST be defined once, in Fonts.

#### Scenario: Swap
- GIVEN the family changed in Fonts
- WHEN the shell reloads
- THEN all text uses the new family

### Requirement: Timings and layout

Timings MUST include hover open (200 ms), reveal timeout (about 1.5 s) and hold-confirm (about 1 s). Layout MUST hold the idle-height token (logical units, same on all monitors), a per-monitor max centre width and the `reserveSpace`, `showPlaceholders` and smoke flags.

#### Scenario: Max width
- GIVEN a narrow monitor
- WHEN the max centre width is requested for it
- THEN the value does not overlap the OSD and corner surfaces

### Requirement: Per-monitor palette

`Colours.paletteFor(screen)` MUST return the matugen dark-scheme palette of that screen's wallpaper (primary, on_surface, muted text). Notch background MUST be `#000`.

#### Scenario: Two wallpapers
- GIVEN monitors with different wallpapers
- WHEN paletteFor is called for each
- THEN each returns its own dark-scheme `primary`

#### Scenario: Light mode
- GIVEN the system is in light mode
- WHEN paletteFor is called
- THEN the dark-scheme values are still returned

#### Scenario: No matugen output
- GIVEN matugen output is missing
- WHEN paletteFor is called
- THEN a defined fallback palette is returned without errors
