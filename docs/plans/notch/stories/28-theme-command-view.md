# Story 28: Theme command view

## Story

28. As a user, I want the theme command view in the launcher so that I can change my theme from the launcher. Requires: #26.

## Acceptance criteria

- [ ] Given the launcher is in command mode, when I activate Theme, then the notch lists the nine matugen scheme modes with a colour preview against the wallpaper of this monitor and marks the active one.
- [ ] Given a theme mode and a wallpaper, when I choose a mode or commit a wallpaper, then every monitor and the matugen-themed apps regenerate from the current wallpaper in the active mode and the choice survives a restart.
- [ ] Given the theme view, when I press Esc, then I return to the command list with the current theme unchanged.

## Plan

- Add a theme sub-view to the launcher's command flow, with the same open, back and close contract the wallpaper view already uses.
- Port the nine matugen scheme modes and make the colour service own generation instead of only watching matugen's output: one app-facing run writes `colors.json`, the templates and the post-hook from the shared default wallpaper; one dry-run per monitor derives that monitor's notch palette from its own wallpaper.
- Dynamic is permanent: a primary or all-monitors wallpaper commit re-runs the app-facing pipeline, a per-monitor override only recomputes that monitor's palette, and a mode choice re-runs both.
- Persist the mode in the notch's own state directory, importing the old shell's mode once when the notch has none and never writing the old file; a missing matugen leaves the fallback palette in place.
- Tests: pure mode list, selection and import logic plus the reducer's sub-view transitions; a QML probe for the rows, the active marker, the preview placeholder and Esc.

## Out of scope

- The app-facing Light/Dark switch and the old `dynamic` flag: here dynamic is always on, and the switch is #40.
- Adding matugen templates or changing what the post-hook already themes; this story only drives the existing pipeline.
- The keybinds view (#29) and the screensaver, security and webapp views (#35-#37).

## Suggestions (your call)

- Reuse the video-wallpaper behaviour: show a neutral placeholder until a frame is extracted, then the swatch, like the old theme row did.
- If nine previews make the first commit too slow, land the rows with names and the active marker first, then add the previews once the apply path is green.
- matugen 4.2 also has `--mode smart`, which picks light or dark from the wallpaper; that belongs to #40 if you prefer it over a manual switch.

## Size

normal
Risk: item 5 (runs matugen and its post-hook, rewriting the shared app theming), item 6 (the resulting palette is only verifiable by eye)

## Log

- L1 request: "si, anota las historias que faltan, luego vamos con la 28"
- L2 request: "lo de dynamic, podemos integrar eso de una vez? para que tome segun el wallpaper seleccionado, esto porque asi ya voy pensando en la integracion a mis dotfiles, y paso del antiguo a esta configuracion, el resto esta bien, aunque en el toggle de light/dark tendria que considerar a ver si no lo integro aunque no cambie el color del notch y solo el de las apps que reciven esta config, no se que dices?"
- L2 resolution: dynamic becomes permanent behaviour in #28 (the old flag is ignored); the app-only Light/Dark switch is split into #40 because the notch palette must then come from a separate dark dry-run.
