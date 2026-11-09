# Story 41: Instant scheme previews

## Story

41. As a user, I want the theme view's colour swatches to be there the moment I open it so that browsing schemes feels instant instead of filling in over a second. Requires: #28.

## Acceptance criteria

- [ ] Given a wallpaper and a scheme already previewed once, when I open the theme view (also after a restart), then all nine swatches show without running matugen again.
- [ ] Given a wallpaper that was never previewed, when the launcher opens, then the nine dry-runs are already running, so the swatches are there by the time the theme view is opened.
- [ ] Given previews still have to be computed, then at most three dry-runs run at once, and a changed wallpaper (same path, new file) invalidates that monitor's cached swatches.

## Plan

- Cache each parsed palette on disk under `Quickshell.cachePath`, keyed by the wallpaper path, its mtime/size and the scheme id; a cache hit paints the row immediately and never spawns matugen.
- Warm the previews when the launcher opens rather than when the theme view becomes visible, so the work overlaps with the user typing.
- Replace the one-at-a-time preview queue with a bounded runner (three at a time) while keeping the existing epoch guard, so a wallpaper commit still drops stale results.
- Tests: pure cache-key and cache-hit logic, plus a QML probe where a second open runs zero matugen and a changed mtime re-runs one.

## Out of scope

- Faster matugen itself, or computing Material You palettes in-house instead of calling it.
- Previewing schemes for wallpapers of other monitors, or a background daemon that keeps every palette warm.
- The theme view's layout and interaction; this story only changes when and how fast the swatches arrive.

## Suggestions (your call)

- Measured on the host: one dry-run ≈ 130 ms, the nine in series ≈ 1.1 s, the nine unbounded ≈ 0.18 s at a peak of ~5.7 cores. Three at a time lands near 0.4 s, which is why the bounded runner is the chosen middle ground.
- The startup palette restore already runs one dry-run per monitor; it could fill the same cache for the active scheme for free.

## Size

small
Risk: item 6 (the result is only verifiable by eye)

## Log

- L1 request (user): "se puede hacer mas rapido lo de mostrar los temas, o que se generen los temas, asi al ir al comando ya aparezcan sus colores?" → chose the combined option: disk cache plus prefetch on launcher open, with the bounded runner as the third piece.
