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

Timings MUST include hover open (200 ms), reveal timeout (about 1.5 s) and hold-confirm (about 1 s). Layout MUST hold the idle-height token (logical units, same on all monitors), a per-monitor max centre width and the `reserveSpace`, `showPlaceholders` and smoke flags. `Layout.cornerRadius` defines the notch corner geometry. The idle notch width is content-driven (see `center-idle-view`); there is no `Layout.idleWidth` or `Layout.batterySide` token.

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

### Requirement: Centre content tokens

`shell/config/` MUST provide the centre-content tokens: battery thresholds (`Limits.batteryLow` 20, `Limits.batteryCritical` 10); the critical red colour in `Colours`; the week-strip radius (`Limits.weekRadius`); the media art and visualizer sizes in `Layout`; the expanded widths (`Layout.expandedWidth` for the full width, `Layout.expandedClockWidth` for the clock-only width); the cava and accent limits in `Limits`; and every new UI string in `Strings`, including the 24-hour clock format and the month and weekday names. Side-layer widths are derived from content, so no battery extra-width token exists. Literals for these MUST NOT appear outside `shell/config/`.

#### Scenario: Threshold tokens
- GIVEN the config module
- WHEN `classify` receives the tokens
- THEN 19% unplugged is `low` and 20% is `none`

#### Scenario: Literal scan
- GIVEN the new idle and expanded QML files
- WHEN scanned for colour, duration, font or text literals
- THEN none are found

#### Scenario: Expanded within max
- GIVEN the expanded width tokens
- WHEN compared with `Layout.centerMaxWidth`
- THEN the clamped result never exceeds it

### Requirement: Workspaces and OSD tokens

`shell/config/` MUST provide: the workspace minimum slot count (`Limits.workspaceSlots`, 5; the strip grows past it with the active or highest occupied workspace id, see `workspaces-notch`) and the workspace event debounce in `Limits`/`Timings`; the startup-gate timing in `Timings`; the OSD wheel step in `Limits`; the slider fill mix (`Colours.fillMix`) and muted fill opacity (`Colours.mutedAlpha`) in `Colours`; the volume, muted-volume and brightness OSD icons and the active/empty symbols (`●`, `–`) in `Strings`; and every new user-visible string. `Timings.reveal` (existing) MUST drive both strips and OSDs. Literals for these MUST NOT appear outside `shell/config/`.

#### Scenario: Tokens resolve
- GIVEN the config module
- WHEN QML or logic tests read the new tokens
- THEN minimum slot count, debounce, startup gate, wheel step, fill mix, muted opacity, icons and symbols are defined

#### Scenario: Literal scan
- GIVEN the new workspaces and OSD QML files
- WHEN scanned for colour, duration, font or text literals
- THEN none are found
