# Story 28: Theme command view

## Story

28. As a user, I want the theme command view in the launcher so that I can change my theme from the launcher. Requires: #26.

## Acceptance criteria

- [x] Given the launcher is in command mode, when I activate Theme, then the notch lists the nine matugen scheme modes with a colour preview against the wallpaper of this monitor and marks the active one.
- [x] Given a theme mode and a wallpaper, when I choose a mode or commit a wallpaper, then every monitor and the matugen-themed apps regenerate from the current wallpaper in the active mode and the choice survives a restart.
- [x] Given the theme view, when I press Esc, then I return to the command list with the current theme unchanged.

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
- L3 build (first delivery, `story/28-theme-command-view` → 301d480): 51ceb85/021bdec (mode list), 5c96a96/fd4d39a (reducer sub-view), 316456b/87d92ec (dry-run palette), e98d3ba/b01d871 (argv), e23c954/e1792d0 (mode state), 5f4f7c3/e99120c (commit jobs), 66e3dcf/37955a9 (run matugen and save), 56fe38d/00e82da (wallpaper commits), 0525d53/c399ed8 (launcher view), 4e6b5e0/01b4684 (Esc), 2237f40 (previews), 301d480 (hint).
- L4 correction (verifier FAIL on the first delivery): a matugen or post-hook that cannot start wedged the pipeline; a second mode choice in flight was dropped; matugen cannot read a video wallpaper; palettes were not rebuilt on restart; a shared commit kept a dry-run in flight; the fallback was blue-ish; stale previews survived a commit; a broken `theme.json` was trusted; dead accessor; no keyboard navigation. Work moved to `story/28-theme-corrections` from 301d480: 9f103ea/bc34825 (failed starts), d872aba/2491b2b (app queue, last choice wins), 2dda2fa/b6e0ebe (video middle frame), 38926d2/70590d6 (restore palettes), e40595f/de02a2b (palette epoch), 7b70a94/bb726ab (grey fallback), 3e43641/4689e5d (rewrite a broken state), e5c1f48/24535d4 (preview epoch), 2bad83d/02038fb (arrows, Enter and row highlight), 6cfb013 (drop `paletteFor`), 116b9a6 (run the key-driven theme probes serially, so they stop losing the keyboard under the parallel theme run).
- L5 test edits to already-green tests, both narrowing: 70590d6 scopes `theme-wallpaper.mjs`'s "no dry-run" claim to the commit itself (startup now restores the saved override) and pins the dry-run count; 2bad83d had its expectation corrected to `scheme-neutral`, the row one step below the active `scheme-content`.
- L6 evidence: `make check` → 758 tests pass, all QML probes pass, "smoke: config loaded". Verifier recheck: PASS on all three criteria and on the ten findings, no tamper (tamper check empty apart from the stricter wallpaper probe). Palette appearance stays a by-eye check (Risk item 6). Known residuals, no fix now: the theme `mkdir` Process has no failed-start guard (an unstartable `mkdir` only leaves `saved=false`); the epoch counter and `cancelPalette`/`cancelPreview` overlap, so only removing both would fail a test.
