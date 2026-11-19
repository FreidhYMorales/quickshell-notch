# Story 40: App Light/Dark switch

## Story

40. As a user, I want a Light/Dark switch in the theme view that re-themes my apps without changing the notch so that I get the old view's light mode while the notch keeps its black look. Requires: #28

## Acceptance criteria

- [ ] Given the theme view, when I flip the Light/Dark switch, then the matugen-themed apps regenerate in that variant from the current wallpaper and active scheme, while every notch keeps its black look and dark-scheme accents.
- [ ] Given the switch set to Light, when I choose a scheme or commit a wallpaper, then the apps regenerate in Light, and the notch accents and the scheme swatches stay dark.
- [ ] Given a chosen variant, when the shell restarts, then the switch shows it and the apps keep it; with no notch choice saved yet, the old shell's light/dark setting is imported once.

## Plan

- Add an app-facing variant (dark or light, default dark) next to the scheme mode in the pure theme model: the app run and the post-hook take the variant; dry-runs stay dark.
- Decouple the notch's global accents from the app-facing `colors.json`: derive them from a dark dry-run of the shared wallpaper, so a light app theme never reaches the notch.
- A switch in the theme view (keyboard and pointer) flips the variant and re-runs only the app-facing pipeline; scheme and wallpaper commits carry the current variant.
- Persist the variant in the notch's `theme.json` beside the mode, importing the old file's `isLight` once under the same rule as the mode; a broken or unknown value falls back to dark.
- Tests: pure argv, state and import logic first; QML probes for the switch, the app-only re-run and the notch palette staying dark.

## Out of scope

- Light previews in the theme view: the swatches stay dark (decided in refinement).
- matugen `--mode smart` or any automatic light/dark choice.
- Changing the matugen templates or what the post-hook themes; it already accepts `light`/`dark`.
- Any light look for the notch itself.

## Suggestions (your call)

- The post-hook already reads its first argument as the scheme (`COLOR_SCHEME="${1:-dark}"`), so passing the variant there is enough for the apps.
- The per-monitor override palettes already come from dark dry-runs; the shared wallpaper's notch palette can reuse that same path instead of a new one.

## Size

normal
Risk: item 5 (runs matugen and its post-hook, rewriting the shared app theming), item 6 (the light app theme and the dark notch are only verifiable by eye)

## Assumptions

- The switch lives in the theme view, as the old launcher's toggle did; flipping it applies at once, no confirm step.
- The old shell's `isLight` is imported once, with the same "notch file wins, never write the old file" rule #28 uses for the mode.

## Log

- L1 request: "/flow:story 40"
- L2 resolution: the scheme swatches stay dark when the switch is Light ("si, que se queden en dark").
- L3 build: test list approved (9 items, greeter stays dark). Green: 91b0174/b0b4536 (app argv takes the variant), 1007cf4/07b04e0 (restore the variant, old `isLight` imported while the notch file has no `variant`). Red: d2262b0 (switching to light reruns only the apps in light and saves `{mode, variant}`).
- L4 stop (rule 3): saving the variant beside the mode changes `theme.json`, which four existing probes pin as `{mode}` only (`theme-select`, `theme-view`, `theme-keys`, `theme-broken-state`). Waiting for the user's call.
