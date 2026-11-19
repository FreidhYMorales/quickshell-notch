# Story 41: Instant theme swatches

## Story

41. As a user, I want the theme view's colour swatches to be there the moment I open it so that browsing schemes feels instant instead of filling in over a second. Requires: #28

## Acceptance criteria

- [ ] Given the shell has started and a monitor has a wallpaper, when I open the theme view on that monitor after the background work settles, then all nine swatches show their colours at once, with no placeholder filling in.
- [ ] Given I commit a new wallpaper (shared or for one monitor), when I open the theme view on an affected monitor after the background work settles, then the swatches already match the new wallpaper and never show the old one's colours.
- [ ] Given the swatches are still being computed or matugen is missing, when I open the theme view, then it behaves as today: placeholders for missing swatches, finished ones fill in, and nothing else in the view waits.

## Plan

- Move swatch generation from "when the view opens" to "when the inputs change": once after startup restores the palettes, and after each wallpaper commit for the monitors it affects.
- Reuse the existing one-at-a-time preview queue, its cache and its epoch, so background work never runs in parallel and a commit still discards stale results.
- Opening the view keeps its current call as a fallback; with a warm cache it is a no-op.
- Tests: pure logic for which monitors need warming after startup and after a shared or per-monitor commit; a QML probe that the cache is filled before the view opens and that a commit replaces it.

## Out of scope

- Persisting swatches to disk across restarts (assumption: one background warm-up per start is enough).
- Making each dry-run faster, running them in parallel, or changing the swatch's look.
- Video wallpapers beyond what the existing middle-frame path already does.

## Suggestions (your call)

- Start the warm-up after the startup palette restore finishes, so the per-monitor palettes the notch actually paints are never queued behind nine previews.
- Keep the warm-up off under `Flags.smoke`, as `generatePreviews` already is.

## Size

normal
Risk: item 4 (background preview queue racing wallpaper commits and the startup restore)

## Log

- L1 request: "/flow:story 41"
- L2 build: 3838f99/e44e195 (warmupPath), b6d9570/3531800 (ThemeWarmup per monitor, wired in shell.qml), bc38e73 (shared commit rewarms), adabd76 (per-monitor commit rewarms only that monitor).
- L3 green on arrival: bc38e73 and adabd76 passed when written because the warm-up handler landed in 3531800. Mutation evidence: removing `onWallpaperChanged` turns bc38e73 red (`after: DP-1 0 | DP-2 0`); making it synchronous stays green because `Wallpapers.commit`'s save toggles `saved` and re-fires the warm-up, so the `Qt.callLater` is kept as an unpinned ordering guard. In adabd76 `warmupPath` is only the trigger (`generatePreviews` reads `Wallpapers.pathFor`); the case pins that DP-2 is left alone.
- L4 correction (verifier FAIL): a per-monitor commit while another monitor was still warming cleared the preview queue, and the one-mode cache check then blocked any rewarm (DP-2 stuck at 2 of 9). 97efa4d red (`settled: DP-1 9 #bbbbbb | DP-2 2 #aaaaaa`) → 6df1826 (cache hit needs all nine modes).
- L5 verifier recheck FAIL → NEEDS DECISION: the image race is closed (C1, C3 PASS; commit order and tamper PASS), but with video wallpapers a commit during the warm-up's frame extraction lets the old frame's callback start a dry-run under the new job's epoch, screen and mode, so one old colour lands in a full nine-mode set and is never recomputed (scratch repro: `scheme-tonal-spot=#aaaaaa`, the other eight `#bbbbbb`). Proposed fix: tag preview frame callbacks with `previewEpoch` or drop preview-role frame jobs in `commitWallpaper`, pinned first by a red video probe. Waiting on the user.
