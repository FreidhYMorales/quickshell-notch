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
- L5 resolution (user, stop rule 3): the four probes pinning `theme.json` as `{mode}` now expect `{mode, variant: "dark"}` (ba8c43d, narrowing). Build: d2262b0+ba8c43d/ce99739 (switch reruns only the apps), bc0219d/ed5a1c4 (light keeps the notch accents dark via a shared dark dry-run), 41591e4/6d5e264 (test 4b, added with the user's approval: back in dark the shared palette is dropped after the dark app run), 99650a0/ed67a26 (commits in light), 070deeb/318c759 (light restart), ffe6caf/bc3dc74 (Tab and click switch; probe added to `THEME_KEYS`), 5f7bb77/b1e3cf0 (greeter staged dark; user decided the greeter counts as a notch).
- L6 verifier (first run on b1e3cf0): NEEDS DECISION. All three criteria pass automatically, commit order and tamper clean, `make check` green. Finding 1: a notch `theme.json` without `variant` was never rewritten, so the old `isLight` was re-read on every start. User chose to fix it here: 840642c/71b9cae (`savedVariant`), ef3dcec/288ba49 (write the imported variant once). Findings 2-3 (a brief light accent until the dark dry-run returns; a harmless light→dark race) are by-eye only, Risk item 6. Minor: `theme-variant-greeter.mjs` leaves its temp dir.
- L7 evidence: `make check` on 288ba49 → exit 0, 711 unit tests pass, every QML probe passes (2 pre-existing nested Cage skips), "smoke: config loaded".
- L8 manual check (test 9, by eye on the live notch run from the branch): the user confirmed light apps with a black notch and dark accents ("se ve bien"), then asked for a slider instead of the text. Resolution: a sliding pill, knob left with the moon for Dark and right with the sun for Light (aa56f55/273386f; the `theme-switch` probe now reads the knob side and icon instead of the label, at the user's request). The user then asked for a visible track: 1px border and fill like the notification card (ab382ad), then, after pixel measurement showed the card and the track were both rgb(44,32,40), the lighter notification-row tone for the track and the selected theme row via `Colours.raisedAlpha` (1a84fdb). User: "si, se ve bien".
- L9 evidence: `make check` on 1a84fdb → exit 0, 711 unit tests pass, every QML probe passes (2 pre-existing nested Cage skips), "smoke: config loaded".
