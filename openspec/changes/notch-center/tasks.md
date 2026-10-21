# Tasks: Centre notch content

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1640 total; 300-350 per PR |
| 400-line budget risk | Medium (per PR); High if unsplit |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 -> PR 2 -> PR 3 -> PR 4 -> PR 5 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: Medium

Each PR also updates tasks.md, apply-progress.md, state.yaml. Planning artifacts are committed to main beforehand. Gate: `make check` green per PR.

### Suggested Work Units

| Unit | Goal | PR | Focused test | Runtime harness | Rollback |
|------|------|----|--------------|-----------------|----------|
| 1 | battery + sysStats rules | 1 | `node --test tests/battery.test.mjs tests/sysStats.test.mjs` | N/A: pure logic | delete 4 files |
| 2 | calendar, media, centerLayout, format rules | 2 | `node --test tests/calendar.test.mjs tests/media.test.mjs tests/centerLayout.test.mjs tests/format.test.mjs` | N/A: pure logic | delete 8 files |
| 3 | Services, tokens, expandedHeight | 3 | `node --test tests/surfaceLayout.test.mjs` | `make smoke`; `qs -p shell/shell.qml` (log percentage) | revert services/config |
| 4 | Idle row, layers, shape/mask | 4 | `make check` | `qs -p shell/shell.qml` | revert idle files |
| 5 | Expanded views | 5 | `make check` | `qs -p shell/shell.qml` | revert `notches/center/` additions |

## PR 1: Battery and system stats rules

- [ ] 1.1 RED: `tests/battery.test.mjs` covering fromUPower (plugged = !onBattery or charging/full/pending-charge; percentage rounding and clamp; no battery), classify (19 vs 20, plug replaces low, full, none), applyOverride, criticalStep (fires once at <=10, re-arm on plugged, plugged never fires), edges.
- [ ] 1.2 GREEN: `shell/logic/battery.mjs` (no spread; `v4Compat`).
- [ ] 1.3 RED: `tests/sysStats.test.mjs` (parseCpu, cpuPercent, parseRam, malformed input gives null).
- [ ] 1.4 GREEN: `shell/logic/sysStats.mjs`.

## PR 2: Calendar, media, layout, format rules

- [ ] 2.1 RED: `tests/calendar.test.mjs` (weekStrip radius 3, today flag, month/year/leap edges, dayKey, midnight change).
- [ ] 2.2 GREEN: `shell/logic/calendar.mjs` (Date.UTC math).
- [ ] 2.3 RED: `tests/media.test.mjs` (prefers playing, else first, empty gives null, switch on state change, trackText fallbacks).
- [ ] 2.4 GREEN: `shell/logic/media.mjs`.
- [ ] 2.5 RED: `tests/centerLayout.test.mjs` (idleWidth symmetric, cap at max; expandedWidth with/without player, narrow monitor; shapeFor).
- [ ] 2.6 GREEN: `shell/logic/centerLayout.mjs`.
- [ ] 2.7 RED then GREEN: `tests/format.test.mjs` and `shell/logic/format.mjs` (24-hour clock, shortDate with names from caller).

## PR 3: Services, tokens, surface height

- [ ] 3.1 RED: extend `tests/surfaceLayout.test.mjs` (optional `expandedHeight` on `c`; absent keeps idleHeight). GREEN: `shell/logic/surfaceLayout.mjs`.
- [ ] 3.2 Create `shell/config/Limits.qml` (batteryLow 20, batteryCritical 10, weekRadius 3) and register in `shell/config/qmldir`.
- [ ] 3.3 Modify `shell/config/{Layout,Colours,Strings,Flags}.qml`: widths/heights, `critical` red, `trackAlpha`, month/weekday names, fallbacks, glyphs, 24-hour clock token, `batteryOverride`.
- [ ] 3.4 Create `shell/services/Battery.qml` (UPower displayDevice, enum mapping, `criticalReached`, signals) and `Time.qml` (`SystemClock.Minutes`, `dayChanged`).
- [ ] 3.5 Create `Mpris.qml` (playbackState binding, controls), `SysInfo.qml` (FileView, `Timings.sysPoll`), `Recorder.qml` (`recording`, `setRecording()`); update `shell/services/qmldir`.
- [ ] 3.6 Verify `UPowerDevice.percentage` range: temporary log in a scratch run via `qs -p shell/shell.qml`; handle 0-1 vs 0-100 in `fromUPower` input, with a test if 0-100; remove the log.
- [ ] 3.7 Fix `AGENTS.md` Mpris gotcha (`playbackState`/`isPlaying`). Smoke: `make smoke` loads with UPower/Mpris absent.

## PR 4: Idle row, battery layers, shape and mask

- [ ] 4.1 Create `shell/components/ArcMeter.qml` (colours as properties, `Fonts.family`, `Anim`) and register in `qmldir`.
- [ ] 4.2 Modify `shell/components/NotchZone.qml`: `openDelay` (`Timings.hoverOpen`) separate from close debounce.
- [ ] 4.3 Modify `CenterIdle.qml`: live row `[bat] (cpu) date time (ram) [percent]`, rec/unread dots, battery layers, fixed `Layout.batterySide`.
- [ ] 4.4 Modify `CenterSurface.qml`: single shape item = mask + NotchZone, sized by `centerLayout`; `CenterStore.qml` logs `criticalReached`.
- [ ] 4.5 Manual: plug/unplug, `Flags.batteryOverride` (19/20, charging, full, none), clock stays centred, rec dot via `setRecording(true)`, hover delay.

## PR 5: Expanded views

- [ ] 5.1 Create `CenterMedia.qml` (art with fallback, track text, prev/play/next) and `CenterClockCard.qml` (clock, week strip, midnight rollover).
- [ ] 5.2 Create `CenterExpanded.qml`; register all three in `shell/notches/center/qmldir`.
- [ ] 5.3 Wire `CenterSurface.qml` expanded mode; no-player layout shows clock card only; width capped by `centerMaxWidth`.
- [ ] 5.4 Manual: player appears/quits, no art, no player, narrow monitor, midnight; run literal scan (no colours/timings/text outside `shell/config/`).
- [ ] 5.5 Final `make check`; record archive notes (spec "line-power device" reworded to `onBattery`; Recorder port deferred to notch-control-center).
