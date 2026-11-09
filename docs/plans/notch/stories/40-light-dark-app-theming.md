# Story 40: Light/Dark switch for app theming

## Story

40. As a user, I want a Light/Dark switch in the theme view that re-themes my apps without changing the notch so that I get the old view's light mode while the notch keeps its black look. Requires: #28.

## Acceptance criteria

- [ ] Given the theme view, when I switch between Light and Dark, then the notch keeps its dark palette while the matugen-themed apps regenerate in the chosen mode, and the choice survives a restart.
- [ ] Given Light is active, when I commit a wallpaper, then the apps regenerate in Light and the notch stays dark.
- [ ] Given matugen is unavailable, when I open the theme view, then the switch is disabled and the current colours are left untouched.

## Plan

- Add the light flag to the theme state and one Light/Dark control in the theme view.
- Feed the flag only to the app-facing matugen run and the post-hook; derive the notch's global and per-monitor palettes from a separate dark dry-run so they never follow it.
- Re-run both sources on a toggle so the change is immediate, and keep the switch in step with the imported state.
- Tests: flag persistence and import, plus the separation between the app scheme and the notch palette; a QML probe for the control and the unchanged dark notch.

## Out of scope

- matugen's `smart` mode and any automatic light/dark decision from the wallpaper.
- Per-app theming or extra matugen templates.
- The notch palette ever following the light scheme; ADR 0005 keeps it dark.

## Suggestions (your call)

- If you would rather not choose by hand, `--mode smart` could drive this switch from the wallpaper; it is a one-line change to the app-facing command once this story exists.

## Size

normal
Risk: item 5 (the post-hook re-themes the shared app config), item 6 (the result is only verifiable by eye)

## Log

- L1 request: "lo de dynamic, podemos integrar eso de una vez? ... en el toggle de light/dark tendria que considerar a ver si no lo integro aunque no cambie el color del notch y solo el de las apps que reciven esta config, no se que dices?"
