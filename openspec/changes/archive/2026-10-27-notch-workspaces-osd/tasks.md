# Tasks: Workspaces notch and volume/brightness OSDs

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1650 total; 300-380 per PR |
| 400-line budget risk | High (total), Low per slice |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 -> PR 2 -> PR 3 -> PR 4 -> PR 5 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: No (chain strategy already decided: stacked-to-main)
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Strip/diff rules | PR 1 | `node --test tests/workspaceStrip.test.mjs` | N/A: pure logic | Delete 2 files |
| 2 | Reveal, slider, osd, corner, heights | PR 2 | `node --test tests/` | N/A: pure logic | Delete new files; revert surfaceLayout |
| 3 | Live workspaces notch | PR 3 | `node --test tests/` + `make check` | `qs -p shell/shell.qml`: switch, open, move, special, click, hover | Revert surface + service + tokens |
| 4 | Audio and Brightness services | PR 4 | `node --test tests/brightness.test.mjs` | `qs -p shell/shell.qml`: change volume/brightness externally, check logs | Delete services |
| 5 | Slider and OSD surfaces | PR 5 | `make check` | `qs -p shell/shell.qml`: drag, wheel, mute, reload (no flash) | Revert OsdSurface + shell.qml |

Each PR tick also updates this file's progress. Every slice ends with `make check` green. Spec/design name differences (e.g. `slotRange` vs design `pageStart`) are noted for archive.

## Phase 1 (PR 1): workspaceStrip

- [x] 1.1 RED `tests/workspaceStrip.test.mjs`: isNormalWindow table (parent, small float, big float, unmapped, no class); lastFocusedClass tie by address (spec: Window filtering)
- [x] 1.2 GREEN `shell/logic/workspaceStrip.mjs`: isNormalWindow, lastFocusedClass
- [x] 1.3 RED slotRange: `1..max(minSlots 5, activeId, highest occupied id on this monitor)`; ids 2 and 4 -> 1-5; active 7 -> 1-7 (spec: Strip model)
- [x] 1.4 RED stripFor: kinds active/app/empty, per-monitor isolation, flash, special pin (spec: Strip model, Special pin)
- [x] 1.5 GREEN slotRange + stripFor, `specialName`, `appInitial`
- [x] 1.6 RED diffSnapshots: null prev -> [], workspace/open/move, dialog open ignored, move to special (spec: Reveal triggers)
- [x] 1.7 GREEN diffSnapshots; REFACTOR; `make check`

## Phase 2 (PR 2): shared reveal and slider logic

- [x] 2.1 RED `tests/reveal.test.mjs`: Ready gate, Trigger before Ready unchanged, hover/hold, pin/unpin timer (spec: Reveal state machine, Startup gate)
- [x] 2.2 GREEN `shell/logic/reveal.mjs`
- [x] 2.3 RED `tests/slider.test.mjs`: valueAt/positionOf tables, wheel steps 0.05 and 5, rounding, levelGlyph thresholds, mute (spec: Slider maths, Mute display)
- [x] 2.4 GREEN `shell/logic/slider.mjs`
- [x] 2.5 RED `tests/osd.test.mjs`: shouldReveal (unavailable, source change, mute toggle, sink switch no reveal); GREEN `osd.mjs`
- [x] 2.6 RED/GREEN `cornerLayout.mjs` (`cornerShape`) and `surfaceLayout.mjs` optional `cornerHeight`/`osdHeight` (+ existing test)
- [x] 2.7 `make check`

## Phase 3 (PR 3): workspaces notch

- [x] 3.1 Tokens in `shell/config/{Layout,Timings,Limits,Strings}.qml` (spec: Workspaces and OSD tokens); literal scan clean
- [x] 3.2 `shell/services/Workspaces.qml` + qmldir: refreshToplevels, `wsDebounce`, snapshot, `triggered`, `activespecial`
- [x] 3.3 `shell/notches/workspaces/WorkspaceSlot.qml` + qmldir (dot/icon/initial)
- [x] 3.4 Modify `WorkspacesSurface.qml`: strip, reveal Timer, hover keeps open, mask follows shape, click focus / toggle_special
- [x] 3.5 AGENTS.md `lastIpcObject` gotcha; `make check`; manual checks listed in unit 3

## Phase 4 (PR 4): services

- [x] 4.1 RED `tests/brightness.test.mjs`: parseLevel rejects garbage/negatives, percentOf, setArgs (`"50; rm"`, NaN, -5, 500) (spec: Brightness Set table)
- [x] 4.2 GREEN `shell/logic/brightness.mjs`
- [x] 4.3 `shell/services/Audio.qml`: sink + PwObjectTracker, `volume` 0..1 clamped, raw value exposed, `setVolume`, `toggleMute`, smoke no-op
- [x] 4.4 `shell/services/Brightness.qml`: udevadm monitor, brightnessctl get/max, coalesced set, no Process under smoke
- [x] 4.5 qmldir, `docs/development.md` (brightnessctl, udevadm); `make check`

## Phase 5 (PR 5): OSD surfaces

- [x] 5.1 OSD tokens in config files; `shell/components/Slider.qml` + qmldir (drag, tap, wheel, right-click mute)
- [x] 5.2 Modify `OsdSurface.qml`: `kind`, `mirrored` (number outer side, fill left-to-right), real percent above 100 with full bar, hidden under `osdMinWidth`
- [x] 5.3 Modify `shell/shell.qml`: both OSDs on every monitor; placeholders per spec; `make check`; manual checks listed in unit 5
