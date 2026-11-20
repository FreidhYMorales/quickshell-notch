# Story 52: Active slot tinted icon

## Story

52. As a user, I want the active workspace slot to show its app icon tinted with the palette so that I can tell where I am at a glance.

## Acceptance criteria

- [x] Given the active workspace has normal windows, when the strip shows, then the active slot shows the icon of its last-focused app tinted with the monitor's palette accent, instead of the dot, while the other occupied slots keep their untinted icons.
- [x] Given I open a window on the active workspace, when the strip reveals, then the active slot shows the new app's icon, tinted the same way.
- [x] Given the active workspace is empty (or the app has no icon), when the strip shows, then the active slot shows what it shows today: the dot, or the app's initial in the accent colour.

## Plan

- The strip logic gives the active slot its last-focused app, the same way it already does for the other occupied slots; a flashed new window still wins.
- The slot paints the active app's icon with a colour layer in the palette accent, the same colourisation the notification icon already uses.
- Tests: unit tests for the active slot's app (occupied, flashed open, empty); a QML probe that the active slot shows a tinted icon while an inactive one shows a plain icon.

## Out of scope

- The flying icon (story 53).
- Changing the slot sizes, the empty or special slots, or the tray row.
- Tinting the inactive slots.

## Suggestions (your call)

- Existing `stripFor` tests pin `cls: null` on a non-flashed active slot; this story changes that behaviour, so `/flow:pair` will ask before updating those tests (stop rule 3).
- Accent = `scheme.primary`, as the active dot and the notification icon tint use today.

## Size

small
Risk: none

## Log

- L1 request: "si, agrega que mejor se muestren el icono de la app activa en el workspace activo, y en lugar de dejarlo de mostrar agregale una capa para colorearlo segun la paleta, asi se distingue donde estamos y a donde vamos."
- L2 test list approved ("si"), including changing the existing test `stripFor: active wins over an occupying window` (`cls` null -> "foot") per stop rule 3; mode B.
- L3 commits: c010e68 test (red: actual `null` vs expected `'foot'`) -> d517c5f feat (active slot gets `lastFocusedClass`, flash still wins; 52/52 pass); 01fa32f feat (accent `MultiEffect` colourisation on the active slot icon; visual criterion, manual); 6a9aef4 test (pins flash-wins and empty-active; green on arrival, characterisation).
- L4 `make check`: exit 0, `smoke: config loaded`.
- L5 manual: user ran the branch with `qs -p shell/shell.qml` and approved the tint ("si, se ve bien, sigue con el cierre").
- Risk: none
