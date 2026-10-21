# Tasks: Centre notch content

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~2200 total (PRs 1-3 merged); PR 4 ~340, PR 5 ~340 (incl. ArtThumb), PR 6 ~260, PR 7 ~270-300 |
| 400-line budget risk | Medium (per PR, hard cap 400); High if unsplit. PR 5 and PR 7 are the tightest |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 -> PR 2 -> PR 3 (merged) -> PR 4 -> PR 5 -> PR 6 -> PR 7 |
| Delivery strategy | chained PRs |
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
| 5 | Expanded views + ArtThumb | 5 | `make check` | `qs -p shell/shell.qml` | revert `notches/center/` additions and `ArtThumb` |
| 6 | sideLayer + visualizer rules | 6 | `node --test tests/sideLayer.test.mjs tests/visualizer.test.mjs` | N/A: pure logic | delete 4 files |
| 7 | Cava service, Visualizer, media layer wiring, docs | 7 | `make check` | `qs -p shell/shell.qml` with a real player | revert services/components/idle wiring |

Naming (design wins over spec wording; note for archive): spec `idleLayout({base, extra, layer})` = merged `idleWidth({base, side, layer, max})` (caller passes `side = sideWidth(layer, {battery, media})`); spec `selectIdleLayer({battery, mediaPlaying})` = `sideLayer(batteryLayer, playing)`; spec `parseCavaFrame(line, {max})` = `parseFrame(line, bars, maxRange)`.

## PR 1: Battery and system stats rules

- [x] 1.1 RED: `tests/battery.test.mjs` covering fromUPower (plugged = !onBattery or charging/full/pending-charge; percentage rounding and clamp; no battery), classify (19 vs 20, plug replaces low, full, none), applyOverride, criticalStep (fires once at <=10, re-arm on plugged, plugged never fires), edges.
- [x] 1.2 GREEN: `shell/logic/battery.mjs` (no spread; `v4Compat`).
- [x] 1.3 RED: `tests/sysStats.test.mjs` (parseCpu, cpuPercent, parseRam, malformed input gives null).
- [x] 1.4 GREEN: `shell/logic/sysStats.mjs`.

## PR 2: Calendar, media, layout, format rules

- [x] 2.1 RED: `tests/calendar.test.mjs` (weekStrip radius 3, today flag, month/year/leap edges, dayKey, midnight change).
- [x] 2.2 GREEN: `shell/logic/calendar.mjs` (Date.UTC math).
- [x] 2.3 RED: `tests/media.test.mjs` (prefers playing, else first, empty gives null, switch on state change, trackText fallbacks).
- [x] 2.4 GREEN: `shell/logic/media.mjs`.
- [x] 2.5 RED: `tests/centerLayout.test.mjs` (idleWidth symmetric, cap at max; expandedWidth with/without player, narrow monitor; shapeFor).
- [x] 2.6 GREEN: `shell/logic/centerLayout.mjs`.
- [x] 2.7 RED then GREEN: `tests/format.test.mjs` and `shell/logic/format.mjs` (24-hour clock, shortDate with names from caller).

## PR 3: Services, tokens, surface height

- [x] 3.1 RED: extend `tests/surfaceLayout.test.mjs` (optional `expandedHeight` on `c`; absent keeps idleHeight). GREEN: `shell/logic/surfaceLayout.mjs`.
- [x] 3.2 Create `shell/config/Limits.qml` (batteryLow 20, batteryCritical 10, weekRadius 3) and register in `shell/config/qmldir`.
- [x] 3.3 Modify `shell/config/{Layout,Colours,Strings,Flags}.qml`: widths/heights, `critical` red, `trackAlpha`, month/weekday names, fallbacks, glyphs, 24-hour clock token, `batteryOverride`.
- [x] 3.4 Create `shell/services/Battery.qml` (UPower displayDevice, enum mapping, `criticalReached`, signals) and `Time.qml` (`SystemClock.Minutes`, `dayChanged`).
- [x] 3.5 Create `Mpris.qml` (playbackState binding, controls), `SysInfo.qml` (FileView, `Timings.sysPoll`), `Recorder.qml` (`recording`, `setRecording()`); update `shell/services/qmldir`.
- [x] 3.6 Verify `UPowerDevice.percentage` range: confirmed 0-1 on the host (0.34 at 34%, then 30 after rounding in the scratch probe); `fromUPower` already takes a 0-1 fraction, so no change or test needed.
- [x] 3.7 Fix `AGENTS.md` Mpris gotcha (`playbackState`/`isPlaying`). Smoke: `make smoke` loads with UPower/Mpris absent.

## PR 4: Idle row, battery layers, shape and mask

- [ ] 4.1 Create `shell/components/ArcMeter.qml` (colours as properties, `Fonts.family`, `Anim`) and register in `qmldir`.
- [ ] 4.2 Modify `shell/components/NotchZone.qml`: `openDelay` (`Timings.hoverOpen`) separate from close debounce.
- [ ] 4.3 Modify `CenterIdle.qml`: live row `[bat] (cpu) date time (ram) [percent]`, rec/unread dots, battery layers (`charging`, `plugged` with plug glyph, `full`, `low`; `plugged` renders like `charging`), fixed `Layout.batterySide`.
- [ ] 4.4 Modify `CenterSurface.qml`: single shape item = mask + NotchZone, sized by `centerLayout`; `CenterStore.qml` logs `criticalReached`.
- [ ] 4.5 Manual: plug/unplug, `Flags.batteryOverride` (19/20, charging, plugged, full, none), clock stays centred, rec dot via `setRecording(true)`, hover delay.

## PR 5: Expanded views

- [ ] 5.0 Create `shell/components/ArtThumb.qml` (`ClippingRectangle` from `Quickshell.Widgets` + `Image`, music-glyph fallback when no art; sizes/radius/glyph from tokens); register in `shell/components/qmldir`. Shared by `CenterMedia` and the PR 7 idle media layer.
- [ ] 5.1 Create `CenterMedia.qml` (uses `ArtThumb`, track text, prev/play/next) and `CenterClockCard.qml` (clock, week strip, midnight rollover).
- [ ] 5.2 Create `CenterExpanded.qml`; register the three in `shell/notches/center/qmldir`.
- [ ] 5.3 Wire `CenterSurface.qml` expanded mode; no-player layout shows clock card only; width capped by `centerMaxWidth`.
- [ ] 5.4 Manual: player appears/quits, no art, no player, narrow monitor, midnight; run literal scan (no colours/timings/text outside `shell/config/`).
- [ ] 5.5 `make check` green; record archive notes (spec "line-power device" reworded to `onBattery`; Recorder port deferred to notch-control-center; spec names `idleLayout`/`selectIdleLayer`/`parseCavaFrame` vs design `idleWidth`/`sideLayer`/`parseFrame`).

## PR 6: Side-layer and visualizer rules (pure logic, test-first)

Spec: center-idle-view (Side-layer priority, Symmetric widths), audio-visualizer (Frame parsing, Mirrored bar geometry, Bar colour).

- [ ] 6.1 RED: `tests/sideLayer.test.mjs`: full 10-row priority table (low > media > charging/plugged/full > none; charging+playing = media; low+playing = low; pause releases to charging); `sideWidth(layer, {battery, media})` returns 0 for none, `battery` for charging/plugged/low/full, `media` for media; widths composed with merged `idleWidth` keep clock offset 0 and cap at max.
- [ ] 6.2 GREEN: `shell/logic/sideLayer.mjs` (`sideLayer`, `sideWidth`; no spread; `v4Compat`).
- [ ] 6.3 RED: `tests/visualizer.test.mjs`:
  - `cavaConfig({bars, framerate, maxRange})`: expected text; clamping to [1,64], [1,60], [1,1000]; injection input (`"6\n[output]"`), NaN, negative and fractional values emit clamped integers only.
  - `parseFrame(line, bars, maxRange)`: trailing delimiter, no trailing delimiter, clamp above max, short and long frame, empty, non-numeric (`1;x;3;`), negative token -> `null`.
  - `barGeometry(levels, {height, barWidth, gap, minHeight})`: all-zero flat line (`minHeight` thick), mirror symmetry (`y = (height - h)/2`), x spacing.
  - `pickAccent(colours, {minLuma})`: most saturated pick, greys and darks rejected -> -1, empty -> -1.
- [ ] 6.4 GREEN: `shell/logic/visualizer.mjs` (`cavaConfig`, `parseFrame`, `barGeometry`, `pickAccent`).
- [ ] 6.5 Acceptance: `node --test tests/` green; `make check` green. Runtime: N/A (pure logic, not yet imported by QML).

## PR 7: Cava service, visualizer, media layer wiring

Spec: audio-visualizer (Process lifecycle, Bar colour, Dependency), center-idle-view (Media layer, Battery layers). Depends on PR 5 (`ArtThumb`) and PR 6.

- [ ] 7.1 Modify `shell/config/{Layout,Limits,Timings}.qml`: `mediaSide`, `artSize`, `vizBarWidth`, `vizGap`, `vizMinHeight`, `vizHeight`; `cavaBars` 6, `cavaFps` 30, `cavaMaxRange` 100, `cavaRetries` 3, `accentMinLuma`; `cavaRestart` 2000. Update `Colours`/`Strings` only if a glyph token is missing.
- [ ] 7.2 Create `shell/services/Cava.qml` (`wanted`, `running = wanted && !Flags.smoke && available`, `available`, `levels`): `FileView.setText(cavaConfig(...))` to `Quickshell.cachePath("cava.conf")` (rewrite only when text changes), start on `saved`; `Process` fixed argv `["cava", "-p", path]` with `SplitParser` -> `parseFrame` (malformed keeps last frame); on stop reset `levels` to zeros; `onExited` while wanted restarts after `Timings.cavaRestart`, at most `Limits.cavaRetries` per play session, then `available=false` + `console.warn`. Register in `shell/services/qmldir`.
- [ ] 7.3 Modify `shell/services/Mpris.qml`: `ColorQuantizer { source: artUrl; depth: 2; rescaleSize: 64 }`, `artAccent` via `pickAccent`, `hasArtAccent`; fallback matugen `primary` when no art, no accent or load failure (https/remote art may take this path; accepted).
- [ ] 7.4 Create `shell/components/Visualizer.qml` (`Repeater` of `Rectangle`s from `barGeometry`, no `Behavior` on height, colour property, hidden when `!Cava.available`); register in `qmldir`.
- [ ] 7.5 Modify `CenterStore.qml` (`sideLayer` from `sideLayer(Battery.layer, Mpris.playing)`; `Binding` sets `Cava.wanted` from `sideLayer === "media"`) and `CenterIdle.qml` (left = media ? `ArtThumb` : battery icon; right = media ? `Visualizer(Cava.levels, Mpris.artAccent)` : percent; width via `idleWidth({base, side: sideWidth(layer, {battery, media}), layer, max})`).
- [ ] 7.6 Docs: `docs/development.md` lists `cava` in the toolchain table and prerequisites (`sudo pacman -S cava`; optional at runtime, only the visualizer hides without it); `AGENTS.md` gotcha: visualizer/`cava` never runs under `Flags.smoke`.
- [ ] 7.7 Smoke: `make smoke` loads `Cava` with no process spawned under `Flags.smoke`; `make check` green.
- [ ] 7.8 Manual (`qs -p shell/shell.qml`, real player): play -> art left, bars right, clock centred; pause -> bars flat, cava gone from `pgrep cava`, layer released; quit player; charging while playing stays `media`, pause -> `charging`; `low` battery beats media (`Flags.batteryOverride`); `pkill cava` restarts then gives up after 3 with the art kept; track with no art -> glyph + `primary` bars; art colour matches cover; https art (e.g. Spotify) falls back to `primary` if not loadable; cava uninstalled/renamed -> no errors, visualizer hidden; CPU of cava below ~2% of a core.
- [ ] 7.9 Record archive notes (name mapping, https art fallback, `plugged` layer added to spec) and update `apply-progress.md`.
