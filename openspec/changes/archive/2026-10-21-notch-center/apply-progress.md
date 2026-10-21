# Apply progress: notch-center

Mode: Strict TDD. Runner: `node --test tests/`. Chain: stacked-to-main.

## PR 1 of 5: battery and sysStats rules (tasks 1.1-1.4, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1.1/1.2 | `tests/battery.test.mjs` | Unit | N/A (new) | Written; `ERR_MODULE_NOT_FOUND` before `battery.mjs` existed | 11/11 pass | Multiple inputs per rule (table, boundaries 19/20, re-arm) | None needed |
| 1.3/1.4 | `tests/sysStats.test.mjs` | Unit | N/A (new) | Written; `ERR_MODULE_NOT_FOUND` before `sysStats.mjs` existed | 7/7 pass | Two samples per parser plus malformed cases | None needed |

Total: 18 new tests, full suite 126/126.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/battery.test.mjs tests/sysStats.test.mjs` passes |
| Runtime harness | N/A: pure logic, no runtime boundary |
| Rollback | Delete `shell/logic/{battery,sysStats}.mjs` and their two tests |

### Notes

- `fromUPower` takes `fraction` in 0-1 (verified on host: 0.34 at 34%).
- `classify`: a plugged battery that is neither charging nor full gives `none`.
- The battery test file was condensed after the first pass to fit the 400-line budget.

## Coordinator fix (PR 1)

- `classify` returns `plugged` (not `none`) when on AC but neither charging nor full, e.g. the user's laptop held at an 80% charge limit (UPower `pending-charge`). User chose a "plugged" variant of the charging layer: same symmetric layout, plug icon instead of the bolt, no animation. RED: spec-table test failed (2 new rows); GREEN after the change. PR 3/4 must add the plug glyph to `Strings` and render the `plugged` layer.

## PR 2 of 5: calendar, media, layout, format rules (tasks 2.1-2.7, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 2.1/2.2 | `tests/calendar.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` before `calendar.mjs` | 10/10 | 5 spec-table rows, radius, weekday, midnight | None needed |
| 2.3/2.4 | `tests/media.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 8/8 | 4 table rows, empty, switch, fallbacks | None needed |
| 2.5/2.6 | `tests/centerLayout.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 12/12 | 5 layers incl. `plugged`, cap, 4 expanded rows, shapeFor | None needed |
| 2.7 | `tests/format.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 6/6 (one test typo fixed, not the code) | 4 clock rows, 2 date cases | None needed |

Total: 36 new tests, full suite 162/162. `make check` green.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/calendar.test.mjs tests/media.test.mjs tests/centerLayout.test.mjs tests/format.test.mjs`: 36 pass, 0 fail |
| Runtime harness | N/A: pure logic, no runtime boundary |
| Rollback | Delete `shell/logic/{calendar,media,centerLayout,format}.mjs` and their four tests |

### Notes

- `idleWidth({base, side, layer, max})` grows for every layer other than `none` (charging, plugged, full, low).
- `weekStrip` adds `weekday` (0 = Monday) per the design contract.
- `shortDate` and `clock` take names and numbers only; no locale use.

## PR 3 of 5: services, tokens, surface height (tasks 3.1-3.7, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 3.1 | `tests/surfaceLayout.test.mjs` | Unit | 9/9 existing | 2 new tests; with the old `surfaceLayout.mjs`: 10 pass, 1 fail | 11/11 | With and without `expandedHeight`; other slots unchanged | None needed |
| 3.2-3.5 | N/A (QML) | Config / service | `make check` before | N/A: no logic; rules live in tested `.mjs` | `make check` green (164 tests, qmllint, smoke) | Scratch probe against live UPower, `/proc`, SystemClock | None needed |
| 3.6 | N/A | Verification | N/A | N/A | Confirmed 0-1 (0.34 at 34%, coordinator probe 2026-10-21); the scratch probe read 30 after rounding | N/A | N/A |
| 3.7 | N/A | Docs | N/A | N/A | AGENTS.md updated; `make smoke` loads | N/A | N/A |

Total: 2 new tests, full suite 164/164. `make check` green.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/surfaceLayout.test.mjs`: 11 pass, 0 fail |
| Runtime harness | `make smoke`: config loaded. Scratch probe (`qs -p` on a throwaway shell in the session scratchpad, timeout 15, not left running): `Battery` present=true plugged=false percentage=30 layer=none (the first read at startup was present=false and 0, then updated through signals); `Mpris` hasPlayer=false with fallback text; `SysInfo` cpu=2 ram=16; `Time` 13:02, "Oct 21", 2026-10-21 |
| Rollback | Revert the three commits: `shell/config/*` additions, `shell/services/{Battery,Time,Mpris,SysInfo,Recorder}.qml` + `qmldir`, `surfaceLayout.mjs` + test, `AGENTS.md` lines |

### Notes

- `Battery` touches `UPower.displayDevice` at startup (`Component.onCompleted: refresh()`) and refreshes from `Connections` on `ready`, `isPresent`, `state`, `percentage`, `isLaptopBattery` and `UPower.onBattery`; no timer.
- Deviation: `Time.day` is named `dayOfMonth`, because a `day` property would collide with the designed `dayChanged` signal (QML rejects the duplicate change signal).
- Singletons are lazy: `SysInfo` only polls once something reads it. PR 4's idle row (its consumer) triggers that. Under `Flags.smoke` its timer never runs.
- Added `Layout.batterySide`, `expandedWidth`, `expandedClockWidth`, `expandedHeight` (also in `tokens`); `Strings.glyphBolt` and `glyphPlug`; `Flags.batteryOverride`; `Timings.sysPoll`.

## PR 4 of 7: idle row, battery layers, shape and mask (tasks 4.1-4.5, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 4.3 (`formatPercent`, the one new rule) | `tests/format.test.mjs` | Unit | 162 pass before | 4 new cases; `SyntaxError: no export named 'formatPercent'` | 10/10 in file, 168/168 suite | 72.4, 71.6, 100, 0 | None needed |
| 4.1, 4.2, 4.4 | N/A (QML) | Component / surface | `make check` before | N/A: no logic; widths, layers and shape come from tested `.mjs` | `make check` green; scratch `qs -p` probes | Seven battery scenarios (see below) | None needed |
| 4.3 (idle row) | N/A (QML) | Component | as above | N/A | as above | clock offset 0 in every layer | None needed |
| 4.5 | N/A | Manual / scratch | N/A | N/A | Scratch probe log, see below | N/A | N/A |

Total: 4 new tests, full suite 168/168. `make check` green (qmlformat, qmllint, deno, node tests, smoke).

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/format.test.mjs`: 10 pass, 0 fail |
| Runtime harness | Scratch copy of `shell/` in the session scratchpad run with `timeout 6 qs -p`, with `Flags.batteryOverride` set per scenario and a probe timer in `CenterIdle` (never left running). `layer / glyph / pct / notch width / clock offset`: none 260 offset 0; charging bolt U+f0e7 72% 332; plugged plug U+f1e6 80% 332; full battery U+f240 100% 332; low 19% battery-low U+f243 332; 20% gives none 260; 9% unplugged plus `Recorder.recording=true`: low, rec true. Re-arming the one-shot in the scratch store logged `CenterStore: battery critical (9%)`. Real battery read 29% (layer none); `ram=16`; `cpu=null` at 1.5 s (first sample, ring at 0) |
| Rollback | Revert the `feat(center)` commit: `components/{ArcMeter,NotchZone}.qml`, `qmldir`, `notches/center/*`, token additions; the `formatPercent` commit is independent |

### Notes

- Deviation: `CenterIdle` property named `batteryLayer` (not `layer`): `layer` is a final `Item` property and the shell failed to load.
- `CenterIdle` reads `Battery` and `SysInfo`, so both lazy singletons start at load.
- The shape item (width follows `idleWidth`, clipped, `Behavior` with `Anim`) is the mask and the `NotchZone` area. Expanded shape reuses the idle size until PR 5.
- `NotchZone.openDelay` (default `Timings.hoverOpen`) applies to hover on; hover off keeps `Timings.hoverDebounce`.
- New tokens: `Layout.{arcSize,arcRing,arcIcon,dotSize,rowGap}`, `Colours.recording`, `Timings.blink`, `Fonts.{body,small}`, `Strings.{glyphCpu,glyphRam,glyphBatteryFull,glyphBatteryLow,dateTimeSeparator}`.
- Startup caveat: the critical log is lost if the battery is already at or below 10% when the shell starts (the store's `Connections` attach after the first `Battery.refresh()`); later transitions log normally.
- Rec dot sits left of the row, unread dot right of it (both outside the clock layout). The unread source is not wired in this change.

## PR 5 of 7: expanded views and ArtThumb (tasks 5.0-5.5, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 5.0-5.3 | N/A (QML) | Component / surface | `make check` before (168 tests) | N/A: no new logic; `weekStrip`, `expandedWidth`, `shapeFor`, `trackText`, `clock` already tested in PRs 1-2 | `make check` green (168/168, qmlformat, qmllint, deno, smoke) | Scratch `qs -p` with and without a fake MPRIS player | Inline `Control` component in `CenterMedia`; `pragma ComponentBehavior: Bound` for the week delegates |
| 5.4 | N/A | Manual / scratch | N/A | N/A | Probe log and screenshot, see below | N/A | N/A |
| 5.5 | N/A | Gate | N/A | N/A | `make check` green | N/A | N/A |

No new logic was needed, so no new tests: full suite stays 168/168.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `make check`: 168 pass, 0 fail; qmlformat, qmllint (only pre-existing warnings in `CenterSurface`/`Mpris`), deno, smoke green |
| Runtime harness | Scratch copy of `shell/` with a probe (forced `Hover` dispatch, log after 1.5 s), `timeout 6 qs -p`, never left running. No player: `mode=expanded shape=300x180 hasPlayer=false`. Fake MPRIS player (python Gio, own bus name, killed after 9 s): `shape=560x180 hasPlayer=true`, title shown. Screenshot (grim) confirmed: art glyph fallback, title/album/artist, prev/pause/next, clock card with week strip, today highlighted, edges faded |
| Rollback | Revert the two commits: `ArtThumb` + token additions; `CenterMedia/CenterClockCard/CenterExpanded`, `CenterSurface` wiring, `qmldir` |

### Notes

- Hover opens through the existing `Hover` event; the single shape animates width and height (`Behavior` with `Anim`) and stays the mask.
- Expanded replaces the idle row (`CenterIdle.visible = !expanded`), so rings are hidden. No player: the clock card fills the 300 px shape.
- Week strip binds to `Time.year/month/dayOfMonth`, so midnight rolls over without extra wiring. Edge fade is `1 - |index - radius| / (radius + 1)`; no literal.
- New tokens: `Layout.{expandedPad,expandedGap,clockCardWidth,cardRadius,artSize,artRadius,artGlyph,controlGap,weekRadius,weekCardPad}`, `Fonts.{title,control,display}`, `Strings.{glyphMusic,glyphPrev,glyphNext,glyphPlay,glyphPause}`, `Colours.dimAlpha`.
- Literal scan: no colour, timing or text literals outside `shell/config/` in the new files (`"transparent"` and layout margins only).
- Not exercised here: real cover art (the fake player has none), midnight rollover live, narrow monitor (covered by the tested `expandedWidth`).

### Archive notes (5.5)

- Spec "line-power device" reworded to `onBattery`.
- Recorder port deferred to notch-control-center.
- Spec names `idleLayout` / `selectIdleLayer` / `parseCavaFrame` vs design `idleWidth` / `sideLayer` / `parseFrame`.

## PR 6 of 7: side-layer and visualizer rules (tasks 6.1-6.5, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 6.1/6.2 | `tests/sideLayer.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` before `sideLayer.mjs` | 18/18 | 10-row priority table, pause release, 6 widths, composition with `idleWidth` (clock offset 0, cap) | `deno fmt` only |
| 6.3/6.4 | `tests/visualizer.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` before `visualizer.mjs` | 25/25 (one test regex typo fixed, not the code: `/rm/` matched "format") | Clamp rows incl. NaN, negative, fractional; injection string; 10 frame cases + real cava frame; flat line, mirror, spacing; accent pick, greys, darks, empty | `pickAccent` threshold condition simplified |
| 6.5 | N/A | Gate | N/A | N/A | `make check` green (211 tests) | N/A | N/A |

Total: 43 new tests, full suite 211/211.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/sideLayer.test.mjs tests/visualizer.test.mjs`: 43 pass, 0 fail |
| Runtime harness | cava 1.0.0 run for 2 s with a generated config in the scratchpad (`timeout 2 cava -p ...`): frames are `0;0;0;0;0;0;` + LF (silence), stored in `tests/fixtures/cava-frame.txt`. QML integration is PR 7 |
| Rollback | Delete `shell/logic/{sideLayer,visualizer}.mjs`, their two tests and `tests/fixtures/cava-frame.txt` |

### Notes

- cava option names verified for the generated config: `[general] bars, framerate, autosens`; `[output] method=raw, raw_target=/dev/stdout, data_format=ascii, ascii_max_range, bar_delimiter=59, frame_delimiter=10, channels=mono`. All accepted by cava 1.0.0; output is one line per frame with a trailing `;`.
- `parseFrame(line, bars, maxRange)` requires exactly `bars` tokens of digits only; values above max clamp to 1.
- `pickAccent` rejects colours with HSV saturation below 0.15 (internal constant) or luma below `minLuma`; ties keep the first.
- Only silence was captured (no audio playing); non-zero frames use the same format.

## PR 7 of 7: Cava, visualizer, media layer (tasks 7.1-7.7, 7.9 done; 7.8 partial)

Also fixed (user request): the idle width is content-driven (`idleBase`, `sideExtent`, both tested); side items sit beside the row and both sides grow equally, so the clock stays centred. `Layout.idleWidth` and `Layout.batterySide` removed; `Layout.idlePad` added.

### TDD Cycle Evidence

| Task | Test file | RED | GREEN | REFACTOR |
|------|-----------|-----|-------|----------|
| width fix | `tests/centerLayout.test.mjs` (+4) | `idleBase is not defined` | 215/215 | none |
| 7.1-7.5 | N/A (QML) | N/A: logic from PR 6 | `make check` green (215 tests) | `Cava` retry handler on `onRunningChanged` (covers a missing binary, which emits no `exited`) |

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/centerLayout.test.mjs`; `make check`: 215 pass, qmlformat, qmllint (pre-existing warnings only), deno, smoke |
| Runtime harness | Scratch copies of `shell/` with a probe, `timeout qs -p`, fake MPRIS player + 220 Hz tone. Notch widths: none 217, charging 265, media 289 (media without cava 277), low+media 265 (low wins, cava stopped). Clock offset 0 in all. Cava frames arrive and move (`[0,91,0,0,0,0]`), stop with the player. Stub cava that exits: 3 restarts then `available=false`, art kept. No `cava` on PATH: same path, no errors beyond Quickshell's own warning. Cover colour `#e0402a` picked as accent |
| Rollback | Revert both commits: Cava, Visualizer, Mpris accent, CenterIdle/CenterStore/CenterSurface, tokens, docs |

### Notes

- Pending (7.8, needs the user): real player incl. https art (Spotify), art visual check, cava CPU. `pkill cava` was not run (denied); the stub covers the same path.
- Quickshell hot-reloads: the user's running shell picks up the working tree.
- `FileView` skips `saved` when the file is unchanged, so `onLoaded` marks the config as written when the text matches.
- Archive notes: name mapping (spec `parseCavaFrame` vs `parseFrame`), https art fallback, `plugged` layer.

## Task 7.8 (user, 2026-10-21)

Confirmed live with real players (browser, ncmpcpp via mpd-mpris): art left, mirrored bars right, clock centred, pause flattens the bars, low battery (< 20%) wins over media. Follow-up tuning on this branch: battery glyph and percent use `Fonts.idleSide` (15 px, matching the idle clock). Not exercised by the user: `pkill cava` restart path and a missing cava binary (covered by the agent's stub runs).
