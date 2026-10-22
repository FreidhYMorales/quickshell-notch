# Apply progress: notch-workspaces-osd

Mode: Strict TDD. Chain: stacked-to-main.

## PR 1 of 5: workspaceStrip (tasks 1.1-1.7) - done

| Task | RED (observed) | GREEN | Triangulation |
|------|----------------|-------|---------------|
| 1.1/1.2 | module not found | filter + focus tests pass | 11 filter rows, tie, thresholds |
| 1.3-1.5 | `slotRange is not defined`, missing exports | strip tests pass | range rows, isolation, flash, pin |
| 1.6/1.7 | missing export `diffSnapshots` | 29/29 pass | open, move, special, cross-monitor |

Focused test: `node --test tests/workspaceStrip.test.mjs`, 29 pass, 0 fail.
Runtime harness: N/A, pure logic. Rollback: delete `shell/logic/workspaceStrip.mjs` and `tests/workspaceStrip.test.mjs`.

Decisions and deviations:

- `slotRange({activeId, windows, monitor, minSlots})` replaces design `pageStart`; `stripFor` and `slotRange` filter by `monitor` themselves.
- A float is a popup when either side is below `minFloatWidth`/`minFloatHeight`.
- A move to a special workspace is a `move`; a cross-monitor move reaches both monitors.
- `stripFor` with a special returns `items: []`; QML paints the Arch icon.

## PR 2 of 5: reveal, slider, osd, cornerLayout, surfaceLayout heights (tasks 2.1-2.7) - done

| Task | RED (observed) | GREEN | Triangulation |
|------|----------------|-------|---------------|
| 2.1/2.2 | `reveal.mjs` not found | gate, hover/hold, pin/unpin rows pass | 12-row spec transition table, flash, pin, unpin+hover |
| 2.3/2.4 | `slider.mjs` not found | maths, wheel, glyph, percent rows pass | spec tables, round-trip, degenerate track, >100% |
| 2.5 | `osd.mjs` not found | 16 `shouldReveal` rows pass | unavailable, sink switch, mute, epsilon, null samples |
| 2.6 | `cornerLayout.mjs` not found; 2 `surfaceLayout` tests fail | 8 corner rows, 4 height tests pass | caps, negatives, x/width unchanged |

Focused test: `node --test tests/` 339 pass, 0 fail. Coverage of new modules (lines): all 100%; slider 95% branches.
Runtime harness: N/A, pure logic. `make check` green. Rollback: delete the 4 new modules and tests, revert `surfaceLayout.mjs` and its test.

Decisions and deviations:

- `displayPercent(value, geo)` added to `slider.mjs` (not in design): the label is not clamped, so volume above 100% shows its real percent while `positionOf` pins the bar full.
- `shouldReveal` ignores a changed `source` (default-sink switch) and the unavailable to available read. OSDs reveal on every monitor (service level, PR 5).
- `cornerShape` = content + 2*pad + ear wide, content + ear high, capped to the slot; revisit in PR 3 if the ear geometry needs other padding.
- `notchesOf` truncates: touchpad deltas under 120 do not step.
- Size: about 660 changed lines against the 400 budget (tests are about 490). Commits are independent units, so PR 2 can split at a commit boundary.

- PR 2 split for the 400-line budget: 2a = reveal + corner/surface layout (commits 77adfaf, 2143f9f), 2b = slider + osd + these docs. Coordinator fix in 2b: `accumulateWheel(carry, delta)` keeps the sub-notch remainder so touchpad deltas (e.g. 15) add up to whole notches instead of being dropped by `notchesOf` (RED: missing export; GREEN: 2 new tests).

## PR 3 of 6: live workspaces notch (tasks 3.1-3.5) - done

| Task | RED (observed) | GREEN | Triangulation |
|------|----------------|-------|---------------|
| IPC adapters (new, `workspaceStrip.mjs`) | missing export `parseActiveSpecial` | 363/363 pass | garbage client fields, negative special ids, comma in names, non-snapshot events |
| 3.1-3.4 | QML: `make check` (fmt, lint, smoke) | scratch `qs -p` runs | startup, workspace switch, special toggle |

Evidence: `node --test tests/` 363 pass (24 new); `make check` green. Runtime (scratch copy of `shell/` with a debug logger, `timeout 9 qs -p`): idle strip `1..5` with ws 1 active (kitty), hidden, mask 0; `hl.dsp.focus({workspace=2})` -> Trigger, strip `kitty, active, -, -, -`, mask 44, Timeout after `Timings.reveal`; `toggle_special("messaging")` -> Pin, `{pinned, special: messaging}`, 74x44, unpin -> Timeout/Trigger. No errors beyond the portal warning. Rollback: revert the surface, `WorkspaceSlot`, `Workspaces.qml`, tokens and the adapters.

Decisions and deviations:

- Added pure `windowFrom`, `parseActiveSpecial`, `refreshesSnapshot` (not in design) so the Hyprland IPC mapping is tested; the service stays glue.
- The service seeds `specialByMonitor` from the monitor `lastIpcObject` once; later changes come from `activespecial`. It also keeps `normalWindows`.
- Slots beyond ~6 overflow the 200 px TL slot (content is clipped); `Layout.cornerWidth` is unchanged.
- Icon rendering and click focus are not verified visually (manual checks).
