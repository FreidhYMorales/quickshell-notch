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
