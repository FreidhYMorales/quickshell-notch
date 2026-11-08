# Story 28: Theme command view

## Goal

Choose light/dark appearance and an accent palette from the launcher `> Theme`, without changing the wallpaper.

## Scope

- Two modes: dark and light.
- Five presets: Wallpaper (Matugen accent), Ocean, Forest, Sunset and Violet.
- Preview changes immediately, without persistence.
- Left/Right cycles palettes, Up/Down toggles mode, Enter applies, Escape cancels.
- Pointer selection for mode, palette and apply/cancel.
- Save selected mode and preset to `$XDG_STATE_HOME/quickshell-notch/theme.json` (or `~/.local/state`).
- Preserve wallpaper-based accent when preset is Wallpaper.

## Acceptance / verification

- [x] Pure theme normalization, selection and palette tests added.
- [x] Launcher command and preview/commit/cancel UI wired.
- [ ] Run `make fmt`, `make check` and CI.
- [ ] Manual runtime validation on Arch/Hyprland: preview, Escape rollback, Enter persistence across restart.
- [ ] Verify contrast in all notch surfaces and Matugen updates in both modes.
- [ ] Confirm no QML binding loops and no regressions in Wallpaper/Quick Wallpaper.

## Implementation notes

This implementation uses the shared Colours singleton and a single persistent Theme service. It does not rewrite Matugen's generated JSON or alter wallpaper state. The light mode changes the notch background and text palette; additional surface-specific contrast adjustments may be required after runtime testing.
